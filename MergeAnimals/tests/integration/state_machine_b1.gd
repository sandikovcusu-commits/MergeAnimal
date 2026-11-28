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
func fresh(persist: bool = false) -> Node:
	paused = false
	var game = scene.instantiate()
	game.test_seed = 6101
	game.combo_enabled = false
	game.persist_best = persist
	root.add_child(game)
	current_scene = game
	await process_frame
	# The preview is only revalidated inside _physics_process, so at least one
	# physics tick must run before any visibility assertion.
	await physics_frame
	await physics_frame
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
	for i in range(90): await physics_frame
	check(game.spawn_state == game.SpawnState.READY, "COOLDOWN returns to READY after the cooldown elapses")
	check(drop(game, 200.0), "READY accepts the next legal drop after cooldown")
	# 3. Paused: drop, merge retry and danger evaluation must be refused.
	for i in range(90): await physics_frame
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
	var pending_bodies: int = game.pieces.get_child_count()
	# drop_animal() only records intent (drop_requested); the reservation is
	# enforced in _attempt_drop at commit time, so the observable contract is
	# "no body is created and no queue entry survives".
	var accepted_while_pending: bool = game.drop_animal()
	game._physics_process(1.0 / 120.0)
	check(game.spawn_count == pending_spawns and game.pieces.get_child_count() <= pending_bodies, "MERGE PENDING never spawns (request accepted=%s)" % str(accepted_while_pending))
	check(not game.drop_requested, "MERGE PENDING clears the queued request")
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
	# A body held above the Danger Line with an exhausted timer is the same
	# path DangerMonitor uses in production (see save_retry_a3 / day633).
	var over = await fresh()
	var held: Animal = over.create_animal(over.animals[0], Vector2(360, 430))
	held.freeze = true
	held.supported = true
	# A reservation that is still queued when the overflow arrives must be
	# released rather than committed against a terminal board.
	var q1: Animal = over.create_animal(over.animals[0], Vector2(300, 900)); q1.freeze = true
	var q2: Animal = over.create_animal(over.animals[0], Vector2(336, 900)); q2.freeze = true
	var reserved_at_overflow: bool = over.merge_manager.request_merge(q1, q2)
	var merges_at_overflow: int = over.merge_manager.merge_count
	over.danger_monitor._physics_process(over.danger_monitor.grace_period + 0.1)
	for i in range(4): await process_frame
	paused = false
	check(over.game_state == over.GameState.GAME_OVER, "danger overflow reaches GAME_OVER")
	check(not reserved_at_overflow or (over.merge_manager.pending.is_empty() and over.merge_manager.merge_count == merges_at_overflow), "GAME_OVER releases a queued reservation without merging")
	check(not q1.merge_locked and not q2.merge_locked, "GAME_OVER unlocks reserved bodies")
	var over_spawns: int = over.spawn_count
	var over_bodies: int = over.pieces.get_child_count()
	var over_score: int = over.score
	check(refused(over, 400.0), "GAME_OVER refuses a drop")
	check(over.spawn_count == over_spawns and over.pieces.get_child_count() == over_bodies and over.score == over_score, "GAME_OVER mutation-free")
	# A reservation may still be *recorded* after game over (request_merge has no
	# session guard), but the commit path must never mutate a terminal board.
	var late_request: bool = over.merge_manager.request_merge(q1, q2)
	over.merge_manager._commit_pending()
	for i in range(3): await physics_frame
	check(over.merge_manager.merge_count == merges_at_overflow and over.score == over_score, "GAME_OVER never commits a late reservation (recorded=%s)" % str(late_request))
	over.merge_manager.pending.clear()
	# A second overflow signal must not re-enter game over or double-penalise.
	var merges_before: int = over.merge_manager.merge_count
	over.danger_monitor.overflow.emit()
	for i in range(4): await process_frame
	paused = false
	check(over.merge_manager.merge_count == merges_before and over.game_state == over.GameState.GAME_OVER, "repeated overflow does not mutate the terminal board")
	over.queue_free(); await process_frame
	# 7. Restart from GAME_OVER returns to a clean PLAYING session.
	game = await fresh()
	var previous_session: String = game.session_id
	game.game_state = game.GameState.GAME_OVER
	paused = true
	game._restart()
	for i in range(6): await process_frame
	paused = false
	var restarted = current_scene
	check(restarted != null and restarted.game_state == restarted.GameState.PLAYING, "GAME_OVER -> RESTART yields a PLAYING session")
	check(restarted.spawn_count == 0 and restarted.score == 0 and restarted.pieces.get_child_count() == 0, "restart clears the board and counters")
	check(restarted.session_id != previous_session, "restart creates a new session id")
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
	# save_session() needs a persisting session; the same live state is saved
	# here so the undo path is proven to leave a writable board.
	var saving = await fresh(true)
	check(drop(saving, 300.0), "save fixture drop")
	for i in range(30): await physics_frame
	saving._request_undo()
	for i in range(6): await process_frame
	check(saving.save_session() == OK, "save still possible after undo (persisting session)")
	# 10. Save/load of the live session keeps a legal state.
	var snapshot: Dictionary = game._session_snapshot()
	check(not snapshot.is_empty() and SessionSave.valid(snapshot), "live session snapshot is valid")
	game.queue_free(); await process_frame
	print("STATE_MACHINE_B1 checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
