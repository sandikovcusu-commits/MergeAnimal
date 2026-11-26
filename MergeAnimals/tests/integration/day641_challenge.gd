extends SceneTree
# Scripted input and repositioned bodies; goals and scores come from real drops
# and Godot collision signals, never a direct success/merge/score call.
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, msg: String) -> void:
	checks += 1; print("%s: %s" % ["PASS" if ok else "FAIL", msg])
	if not ok: failures += 1
func frames(n := 3) -> void:
	for i in range(n): await process_frame
func clear_files() -> void:
	for path in [ChallengeStore.PATH, SessionSave.PATH, SessionSave.POWERUP_PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
func new_game(id: int):
	set_meta("challenge_id", id)
	var game = (load("res://scenes/game/ChallengeGame.tscn") as PackedScene).instantiate()
	game.test_seed = 31
	root.add_child(game); current_scene = game
	return game
func dispose(game) -> void:
	paused = false; game.queue_free(); await frames()
func drop(game, data: AnimalData, x: float) -> Animal:
	for i in range(180):
		if game._can_aim(): break
		await physics_frame
	if not game.is_playing(): return null
	game.current_data = data; game._set_aim(x)
	var count: int = game.spawn_count
	if not game.drop_animal(): return null
	for i in range(120):
		await physics_frame
		if game.spawn_count > count:
			for body in game.pieces.get_children():
				if body is Animal and body.save_uid == game.next_body_uid - 1: return body
	return null
func collision_pair(game, index: int) -> bool:
	var before: int = game.merge_manager.merge_count
	var a := await drop(game, game.animals[index], 230)
	if a == null: return false
	# Fixture placement and velocity make the physical contact repeatable.
	a.freeze = true; a.position = Vector2(290, 800); a.linear_velocity = Vector2.ZERO
	var b := await drop(game, game.animals[index], 490)
	if b == null: return false
	b.freeze = true; b.position = Vector2(430, 800); b.linear_velocity = Vector2.ZERO
	await physics_frame
	a.freeze = false; b.freeze = false
	a.linear_velocity = Vector2(240, 0); b.linear_velocity = Vector2(-240, 0)
	for i in range(240):
		await process_frame
		if game.merge_manager.merge_count > before: return true
	return false
func clear_board(game) -> void:
	# Only the test fixture clears results to keep score stress bounded.
	for b in game.pieces.get_children(): game.pieces.remove_child(b); b.queue_free()
	await frames()
func run() -> void:
	if OS.get_environment("CHALLENGE_PHASE") == "read": await read_phase(); return
	clear_files()
	var loaded := ChallengeStore.load_results()
	check(loaded.status == "missing" and ChallengeStore.is_unlocked(loaded.data, 1) and not ChallengeStore.is_unlocked(loaded.data, 2), "first challenge only unlocked")
	var classic = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	classic.test_seed = 41; root.add_child(classic); current_scene = classic; await frames()
	classic.score = 123; classic.best_score = 123; classic.progression.best_score = 123
	check(SessionSave.write_snapshot(classic._session_snapshot(), true) == OK, "classic session fixture saved")
	var classic_hash := FileAccess.get_sha256(SessionSave.PATH)
	var checkpoint_hash := FileAccess.get_sha256(SessionSave.POWERUP_PATH)
	await dispose(classic)
	for id in range(1, 6):
		var game = new_game(id); await frames()
		check(game.challenge != null and game.challenge_id == id, "challenge %d loads" % id)
		check(not game.persist_best and not game.remove_button.visible and not game.undo_button.visible and not game.rescue_button.visible, "challenge %d disables classic powerups" % id)
		game._toggle_remove(); game._request_undo(); game._request_rescue()
		check(not game.remove_selecting and not game.undo_processing and not game.rescue_processing, "challenge %d powerup actions blocked" % id)
		game.danger_monitor.set_physics_process(false)
		if id == 1:
			var time_before: float = game.challenge.elapsed
			game._toggle_pause(); await create_timer(0.2, true).timeout
			check(is_equal_approx(game.challenge.elapsed, time_before), "challenge timer stops during pause")
			game._toggle_pause()
		var index: int = [0, 1, 2, 3, 4][id - 1]
		var n := 0
		while not game.result_finished and n < 20:
			var ok := await collision_pair(game, index)
			check(ok, "challenge %d physical dropped pair %d merged" % [id, n + 1])
			if not ok: break
			n += 1
			await frames()
			if not game.result_finished: await clear_board(game)
		check(game.result_finished and game.result_success and game.result_saved and game.game_state == game.GameState.GAME_OVER, "challenge %d success from real collisions and saved" % id)
		if id == 5: check(game.score >= 300 and game.merge_manager.merge_count >= 1, "score hunter reached 300 through collision score")
		loaded = ChallengeStore.load_results()
		check(loaded.status in ["ok", "recovered"] and loaded.data.entries[id - 1].completed, "challenge %d completion persisted" % id)
		if id < 5: check(ChallengeStore.is_unlocked(loaded.data, id + 1) and game.next_button.visible, "challenge %d unlocks next" % id)
		await dispose(game)
	# Replaying a completed task and losing must not revoke its unlock.
	var replay = new_game(1); await frames()
	check(replay.challenge.count == 0 and replay.score == 0, "replay starts a fresh attempt")
	replay._restart(); await frames(5)
	replay = current_scene
	check(replay.challenge_id == 1 and replay.score == 0 and replay.challenge.count == 0, "restart reloads same challenge")
	replay.danger_monitor.overflow.emit(); await frames()
	loaded = ChallengeStore.load_results()
	check(replay.result_finished and not replay.result_success and replay.result_saved, "overflow displays and saves challenge failure")
	check(loaded.data.entries[0].completed and int(loaded.data.entries[0].attempts) == 2 and ChallengeStore.is_unlocked(loaded.data, 2), "failed replay retains completion and unlock")
	check(FileAccess.get_sha256(SessionSave.PATH) == classic_hash and FileAccess.get_sha256(SessionSave.POWERUP_PATH) == checkpoint_hash, "challenge leaves both classic files byte-identical")
	check(SessionSave.load_session().data.score == 123 and SessionSave.load_progression().best_score == 123, "classic session and record preserved")
	await dispose(replay)
	print("CHALLENGE checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
func read_phase() -> void:
	var loaded := ChallengeStore.load_results()
	check(loaded.status in ["ok", "recovered"], "separate process loads results")
	for id in range(1, 6): check(loaded.data.entries[id - 1].completed and ChallengeStore.is_unlocked(loaded.data, id), "separate process restores challenge %d" % id)
	check(int(loaded.data.entries[4].best) >= 300, "separate challenge best restored")
	check(SessionSave.load_session().data.score == 123 and SessionSave.load_progression().best_score == 123, "separate process restores unchanged classic score and session")
	print("CHALLENGE_READ checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
