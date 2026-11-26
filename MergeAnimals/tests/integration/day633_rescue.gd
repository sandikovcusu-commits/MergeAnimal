extends SceneTree
# Automated deterministic fixtures, not a human playtest.
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", message])
	if not ok: failures += 1
func frames(n := 3) -> void:
	for i in range(n): await process_frame
func clear_save() -> void:
	for path in [SessionSave.PATH, SessionSave.POWERUP_PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
func make_game(persist := true):
	var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.test_seed = 123; game.persist_best = persist
	root.add_child(game); current_scene = game
	return game
func dispose(game) -> void:
	paused = false; game.queue_free(); await frames()
func go(game) -> void:
	game._on_game_over(); await frames()
func rescue(game) -> void:
	game._request_rescue()
	for i in range(120):
		await process_frame
		if not game.rescue_processing: break
func make_board(game) -> Array:
	game.danger_monitor.set_physics_process(false)
	game.current_data = game.animals[0]; game.next_data = game.animals[1]
	var a: Animal = game.create_animal(game.animals[0], Vector2(360, 430)); a.freeze = true
	var b: Animal = game.create_animal(game.animals[8], Vector2(220, 800)); b.freeze = true
	return [a, b]
func run() -> void:
	var phase := OS.get_environment("RESCUE_PHASE")
	if phase == "read": await read_phase(); return
	if phase == "verify": await verify_phase(); return
	clear_save()
	var game = make_game(); await frames()
	var board := make_board(game); await physics_frame
	game.score = 42; game.best_score = 42; game.progression.best_score = 42
	game.spawn_count = 7; game.merge_manager.merge_count = 5
	game.progression.total_drops = 7; game.progression.total_merges = 5; game.progression.golden_merges = 1
	game.progression.animals.mouse = {"count": 2, "date": "2025-01-01 00:00:00"}
	game.undo_remaining = 0; game.remove_remaining = 0
	game.undo_snapshot = game._session_snapshot(false)
	var before: Dictionary = game._session_snapshot().duplicate(true)
	game._request_rescue(); await frames()
	check(game.rescue_remaining == 1 and game.pieces.get_child_count() == 2, "rescue blocked during playing")
	await go(game)
	before = game._session_snapshot().duplicate(true)
	var pending := SessionSave.load_session()
	check(game.game_state == game.GameState.GAME_OVER and paused and pending.data.get("game_over_pending", false), "game over pauses and saves pending session")
	check(int(game.progression.completed_games) == 0 and not game.rescue_button.disabled, "pending game is not counted and rescue available")
	if phase == "write":
		print("RESCUE_WRITE checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0); return
	var obstruction := ProjectSettings.globalize_path(SessionSave.POWERUP_PATH + ".tmp")
	check(DirAccess.make_dir_absolute(obstruction) == OK, "obstruct checkpoint write")
	var hash := FileAccess.get_sha256(SessionSave.POWERUP_PATH)
	await rescue(game)
	check(game.rescue_remaining == 1 and game.pieces.get_child_count() == 2 and FileAccess.get_sha256(SessionSave.POWERUP_PATH) == hash, "failed checkpoint leaves board and use unchanged")
	DirAccess.remove_absolute(obstruction)
	game.rescue_max_remove = 1
	# Two mandatory bodies exceed cap.
	var extra: Animal = game.create_animal(game.animals[1], Vector2(500, 430)); extra.freeze = true
	await rescue(game)
	check(game.rescue_remaining == 1 and game.pieces.get_child_count() == 3 and not game.rescue_processing, "limit failure is nonmutating")
	game.pieces.remove_child(extra); extra.queue_free(); await frames()
	await rescue(game)
	check(game.game_state == game.GameState.PLAYING and not paused and game.rescue_remaining == 0, "rescue resumes and consumes exactly one use")
	check(not is_instance_valid(board[0]) and is_instance_valid(board[1]) and game.pieces.get_child_count() == 1, "danger animal removed, lower large animal preserved")
	check(game.score == before.score and game.best_score == before.best_score and game.spawn_count == before.spawn_count and game.merge_manager.merge_count == before.merge_count, "score best drops merges preserved")
	var progress_after: Dictionary = game.progression.duplicate(true)
	var progress_before: Dictionary = before.progression.duplicate(true)
	progress_after.erase("play_seconds"); progress_before.erase("play_seconds")
	check(progress_after == progress_before and str(game.rng.state) == before.rng_state and str(game.current_data.id) == before.current and str(game.next_data.id) == before.next, "progression discoveries queue and RNG preserved")
	check(game.undo_remaining == 0 and game.remove_remaining == 0 and game.undo_snapshot.is_empty(), "undo snapshot invalidated and limits preserved")
	check(game.danger_monitor.timers.is_empty() and game.danger_monitor.peak_time == 0.0, "danger timers reset")
	for i in range(5): await physics_frame
	check(game._spawn_clear(game.current_data, game.aim_x), "actual physics spawn is clear after rescue")
	check(game.save_session() == OK, "post rescue save")
	var f := FileAccess.open(SessionSave.PATH, FileAccess.WRITE); f.store_string("broken"); f.close()
	var recovered := SessionSave.load_session()
	check(recovered.status == "recovered" and int(recovered.data.rescue_remaining) == 0, "corrupt primary does not replenish rescue")
	await go(game)
	check(game.rescue_button.disabled and game.rescue_remaining == 0, "repeat rescue disabled")
	check(game._finalize_game() == OK and game._finalize_game() == OK and int(game.progression.completed_games) == 1, "finalization increments once")
	check(SessionSave.load_session().status == "missing", "tombstone removes continue")
	f = FileAccess.open(SessionSave.PATH, FileAccess.WRITE); f.store_string("broken"); f.close()
	check(SessionSave.load_session().status == "missing", "corrupt primary cannot resurrect tombstoned session")
	await dispose(game); clear_save()
	await backup_failure_test(); clear_save()
	await pending_merge_test(); clear_save()
	await blocked_spawn_test(); clear_save()
	await overflow_test(); clear_save()
	# Planner evaluates all danger bodies and chooses fewest blockers, with a cap.
	var sample := [{"uid":1,"x":360.0,"y":430.0,"radius":30.0,"level":1}, {"uid":2,"x":360.0,"y":530.0,"radius":60.0,"level":10}]
	var plan := RescuePlanner.plan(sample,465,350,20,110,610,360,1)
	check(plan.get("remove_uids", []) == [1] and int(plan.spawn_x) == 360, "deterministic danger selection preserves lower large animal")
	check(RescuePlanner.plan(sample,465,350,20,110,610,360,0).is_empty(), "zero cap rejected")
	for i in range(30):
		var g = make_game(false); await frames(1); make_board(g); await physics_frame
		await go(g); await rescue(g)
		check(g.rescue_remaining == 0 and g.pieces.get_child_count() == 1 and g.game_state == g.GameState.PLAYING, "stress rescue %d" % (i+1))
		await dispose(g)
	print("RESCUE checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
func backup_failure_test() -> void:
	var game = make_game(); await frames(); make_board(game); await physics_frame
	await go(game)
	var obstruction := ProjectSettings.globalize_path(SessionSave.PATH + ".bak.tmp")
	check(DirAccess.make_dir_absolute(obstruction) == OK, "obstruct ordinary rescue mirror")
	await rescue(game)
	check(game.rescue_remaining == 0 and game.game_state == game.GameState.PLAYING, "checkpoint commits even when mirror fails")
	DirAccess.remove_absolute(obstruction)
	var f := FileAccess.open(SessionSave.PATH, FileAccess.WRITE); f.store_string("broken"); f.close()
	var doc := SessionSave.load_session()
	check(doc.status == "recovered" and int(doc.data.rescue_remaining) == 0 and doc.data.bodies.size() == 1, "checkpoint prevents refund after failed mirror and corrupt primary")
	await dispose(game)
func pending_merge_test() -> void:
	var game = make_game(); await frames()
	game.danger_monitor.set_physics_process(false)
	game.merge_manager.set_physics_process(false)
	var a: Animal = game.create_animal(game.animals[0], Vector2(300,430)); a.freeze = true
	var b: Animal = game.create_animal(game.animals[0], Vector2(400,430)); b.freeze = true
	check(game.merge_manager.request_merge(a, b), "fixture reserves pending merge")
	await go(game)
	var doc := SessionSave.load_session()
	check(game.merge_manager.pending.is_empty() and not a.merge_locked and not b.merge_locked and doc.data.bodies.size() == 2, "game over cancels merge reservations without losing bodies")
	game.merge_manager._commit_pending()
	check(game.pieces.get_child_count() == 2 and game.merge_manager.merge_count == 0, "deferred merge cannot mutate paused game over")
	await dispose(game)
func blocked_spawn_test() -> void:
	var game = make_game(); await frames(); make_board(game)
	# Restrict the lane to one point and place a non-animal collider there.
	game.current_data = game.animals[0]
	game.left_bound = 360.0 - game.current_data.radius - game.spawn_margin
	game.right_bound = 360.0 + game.current_data.radius + game.spawn_margin
	var wall := StaticBody2D.new(); wall.collision_layer = 1
	var shape := CollisionShape2D.new(); var circle := CircleShape2D.new(); circle.radius = 12
	shape.shape = circle; wall.add_child(shape); game.add_child(wall)
	wall.position = Vector2(360, game.spawn_height)
	await physics_frame; await go(game)
	var hash := FileAccess.get_sha256(SessionSave.POWERUP_PATH)
	await rescue(game)
	check(game.rescue_remaining == 1 and game.pieces.get_child_count() == 2 and game.game_state == game.GameState.GAME_OVER and FileAccess.get_sha256(SessionSave.POWERUP_PATH) == hash, "actual spawn blocker fails before commit")
	await dispose(game)
func overflow_test() -> void:
	var game = make_game(); await frames()
	game.danger_monitor.set_physics_process(false)
	var a: Animal = game.create_animal(game.animals[0], Vector2(360, 430)); a.freeze = true; a.supported = true
	game.danger_monitor._physics_process(game.danger_monitor.grace_period + 0.1)
	await frames()
	check(game.game_state == game.GameState.GAME_OVER and paused and SessionSave.load_session().data.get("game_over_pending", false), "supported danger timer triggers real game-over signal and checkpoint")
	await rescue(game)
	game.danger_monitor._physics_process(0.1)
	check(game.game_state == game.GameState.PLAYING and game.danger_monitor.peak_time == 0.0, "no immediate repeat overflow after rescue")
	await dispose(game)
func read_phase() -> void:
	var before := SessionSave.load_session()
	check(before.data.get("game_over_pending", false), "separate process reads pending game over")
	set_meta("continue_requested", true)
	var game = make_game(); await frames()
	check(game.game_state == game.GameState.GAME_OVER and paused and game.rescue_remaining == 1, "continue restores paused game over and free rescue")
	await process_frame
	await rescue(game)
	check(game.rescue_remaining == 0 and game.game_state == game.GameState.PLAYING, "separate process performs rescue")
	print("RESCUE_READ checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
func verify_phase() -> void:
	var saved := SessionSave.load_session()
	check(saved.status in ["ok", "recovered"] and int(saved.data.rescue_remaining) == 0 and not saved.data.game_over_pending, "third process reads committed rescued board")
	set_meta("continue_requested", true)
	var game = make_game(); await frames()
	check(game.rescue_remaining == 0 and game.game_state == game.GameState.PLAYING and game.pieces.get_child_count() == 1, "third process continues with consumed rescue")
	print("RESCUE_VERIFY checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
