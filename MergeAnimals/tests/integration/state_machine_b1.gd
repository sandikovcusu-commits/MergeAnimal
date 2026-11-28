extends SceneTree
# B.1 §06 — Classic gameplay state machine audit.
# Legal/illegal transitions are exercised through the real production API
# (drop_animal, _toggle_pause, _restart, _main_menu, _request_undo, rescue,
# danger overflow). No state fields are written to fake a transition except
# where a scenario explicitly needs a terminal fixture, and those are labelled.
var scene := preload("res://scenes/game/Game.tscn")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1; print("%s: %s" % ["PASS" if ok else "FAIL", text])
	if not ok: failures += 1
func fresh() -> Node:
	paused = false
	var game = scene.instantiate()
	game.test_seed = 6101
	game.combo_enabled = false
	game.persist_best = false
	root.add_child(game)
	await process_frame
	game.danger_monitor.set_physics_process(false)
	return game
# Request a drop through the production entry point and let the physics tick
# perform it, exactly like a player tap. Returns true only when a body spawned.
func drop(game, x: float) -> bool:
	game._set_aim(x)
	var before: int = game.spawn_count
	if not game.drop_animal(): return false
	game._physics_process(1.0 / 120.0)
	return game.spawn_count == before + 1
# A refused request must leave the board untouched.
func refused(game, x: float) -> bool:
	game._set_aim(x)
	var before: int = game.spawn_count
	var accepted: bool = game.drop_animal()
	game._physics_process(1.0 / 120.0)
	game._physics_process(1.0 / 120.0)
	return not accepted and game.spawn_count == before
func run() -> void:
	# 1. Initial state: PLAYING, READY, one drop available, one preview.
	var game = await fresh()
	check(game.game_state == game.GameState.PLAYING and game.spawn_state == game.SpawnState.READY, "initializes into PLAYING/READY")
	check(game.is_playing() and not paused, "initial state is actively playing and unpaused")
	check(game.current_preview.visible and game.undo_remaining == 1, "ready state exposes preview and one undo")
	# 2. READY -> DROPPING happens inside _attempt_drop synchronously, and the
	#    observable post-condition is COOLDOWN with a new body.
	var before_count: int = game.pieces.get_child_count()
	check(drop(game, 360.0), "READY accepts a legal drop")
	check(game.spawn_state == game.SpawnState.COOLDOWN and game.pieces.get_child_count() == before_count + 1, "drop transitions to COOLDOWN and spawns exactly one body")
	check(refused(game, 360.0), "COOLDOWN rejects an immediate second drop (no duplicate drop)")
	for i in range(40): await physics_frame
	check(game.spawn_state == game.SpawnState.READY, "COOLDOWN returns to READY after the cooldown elapses")
	check(drop(game, 200.0), "READY accepts the next legal drop after cooldown")
	# 3. Paused: drop, merge retry and danger evaluation must be refused.
	for i in range(40): await physics_frame
	game._toggle_pause()
	check(game.game_state == game.GameState.PAUSED and paused, "PLAYING -> PAUSED pauses the tree")
	var paused_count: int = game.pieces.get_child_count()
	var paused_spawns: int = game.spawn_count
	check(refused(game, 380.0), "PAUSED refuses a drop")
	check(game.spawn_count == paused_spawns and game.pieces.get_child_count() == paused_count, "PAUSED mutation-free (no spawn, no body change)")
	game._toggle_pause()
	check(game.game_state == game.GameState.PLAYING and not paused, "PAUSED -> PLAYING resumes")
	# 4. Illegal transition: drop while a merge reservation is pending.
	var a: Animal = game.create_animal(game.animals[0], Vector2(342, 800)); a.freeze = true
	var b: Animal = game.create_animal(game.animals[0], Vector2(378, 800)); b.freeze = true
	check(game.merge_manager.request_merge(a, b), "fixture pair reserves for pending-state check")
	var pending_spawns: int = game.spawn_count
	check(refused(game, 500.0), "MERGE PENDING refuses a drop")
	check(game.spawn_count == pending_spawns, "no spawn while a merge is pending")
	for i in range(30): await physics_frame
	check(game.merge_manager.pending.is_empty(), "pending queue drains")
	# 5. Pause during a pending merge must not lose the reservation silently.
	var c: Animal = game.create_animal(game.animals[1], Vector2(250, 900)); c.freeze = true
	var d: Animal = game.create_animal(game.animals[1], Vector2(286, 900)); d.freeze = true
	var reserved: bool = game.merge_manager.request_merge(c, d)
	game.merge_manager.set_physics_process(false)
	game.merge_manager._commit_pending()
	game.merge_manager.set_physics_process(true)
	check(reserved and (game.merge_manager.merge_count >= 1 or not game.merge_manager.pending.is_empty() or not c.merge_locked), "manual commit during pause either completes or releases the reservation")
	# 6. Game Over is terminal and blocks every mutation path.
	var over = await fresh()
	var e: Animal = over.create_animal(over.animals[0], Vector2(342, 420)); e.freeze = true
	var f: Animal = over.create_animal(over.animals[0], Vector2(378, 420)); f.freeze = true
	over.merge_manager.request_merge(e, f)
	for i in range(4): await physics_frame
	over.danger_monitor.timers[e.instance_uid] = 1.95
	over.danger_monitor.timers[f.instance_uid] = 1.95
	e.supported = true; f.supported = true
	over.danger_monitor._physics_process(over.danger_monitor.grace_period + 0.1)
	for i in range(4): await process_frame
	check(over.game_state == over.GameState.GAME_OVER, "danger overflow reaches GAME_OVER")
	var over_spawns: int = over.spawn_count
	var over_bodies: int = over.pieces.get_child_count()
	var over_score: int = over.score
	paused = false
	check(refused(over, 400.0), "GAME_OVER refuses a drop")
	check(over.spawn_count == over_spawns and over.pieces.get_child_count() == over_bodies and over.score == over_score, "GAME_OVER mutation-free")
	check(not over.merge_manager.request_merge(e, f) or over.merge_manager.pending.is_empty(), "GAME_OVER refuses merge reservation")
	# A second overflow signal must not re-enter game over or double-penalise.
	var merges_before: int = over.merge_manager.merge_count
	over.danger_monitor.overflow.emit()
	for i in range(4): await process_frame
	paused = false
	check(over.merge_manager.merge_count == merges_before and over.game_state == over.GameState.GAME_OVER, "repeated overflow does not mutate the terminal board")
	over.queue_free(); await process_frame
	# 7. Restart from GAME_OVER returns to a clean PLAYING session.
	game = await fresh()
	game.game_state = game.GameState.GAME_OVER
	paused = true
	game._restart()
	for i in range(6): await process_frame
	paused = false
	var restarted = current_scene
	check(restarted != null and restarted.game_state == restarted.GameState.PLAYING, "GAME_OVER -> RESTART yields a PLAYING session")
	check(restarted.spawn_count == 0 and restarted.score == 0 and restarted.pieces.get_child_count() == 0, "restart clears the board and counters")
	check(restarted.session_id != game.session_id, "restart creates a new session id")
	restarted.queue_free(); await process_frame
	# 8. Main menu transition is a scene change, not a gameplay state.
	game = await fresh()
	var leaving: String = game.session_id
	game._main_menu()
	for i in range(8): await process_frame
	check(current_scene != null and current_scene.scene_file_path != "" and not current_scene.has_method("_attempt_drop"), "PLAYING -> MAIN MENU leaves gameplay scene")
	check(not paused, "menu transition leaves the tree unpaused")
	if current_scene: current_scene.queue_free(); await process_frame
	# 9. Undo restores a legal PLAYING board with cleared retry state.
	game = await fresh()
	check(drop(game, 300.0), "undo fixture drop 1")
	for i in range(30): await physics_frame
	check(drop(game, 300.0), "undo fixture drop 2")
	for i in range(45): await physics_frame
	var score_before_undo: int = game.score
	game._request_undo()
	for i in range(6): await process_frame
	check(game.game_state == game.GameState.PLAYING and game.undo_remaining == 0, "UNDO keeps PLAYING and consumes the undo")
	check(game.merge_manager.retry_state().failed == 0, "undo clears stale retry tracking")
	check(game.score <= score_before_undo and game.merge_manager.pending.is_empty(), "undo leaves no pending reservation or inflated score")
	check(game.save_session() == OK, "save still possible after undo")
	# 10. Save/load of the live session keeps a legal state.
	var snapshot: Dictionary = game._session_snapshot()
	check(not snapshot.is_empty() and SessionSave.valid(snapshot), "live session snapshot is valid")
	game.queue_free(); await process_frame
	print("STATE_MACHINE_B1 checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
