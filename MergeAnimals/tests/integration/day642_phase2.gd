extends SceneTree
# Real gravity/contact, deterministic queue; no direct scoring, merges or removals.
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1; print("%s: %s" % ["PASS" if ok else "FAIL", text])
	if not ok: failures += 1
func frames(n := 3) -> void:
	for i in range(n): await process_frame
func game_for(id: int):
	set_meta("challenge_id", id)
	var game = (load("res://scenes/game/ChallengeGame.tscn") as PackedScene).instantiate()
	game.test_seed = 42; root.add_child(game); current_scene = game
	return game
func dispose(game) -> void:
	paused = false; game.queue_free(); await frames()
func run() -> void:
	var phase := OS.get_environment("PHASE2")
	if phase == "read": read_phase(); return
	if phase == "migrate": migrate_phase(); return
	for id in range(6, 11):
		var game = game_for(id); await frames()
		check(game.challenge != null and game.challenge_id == id, "challenge %d unlocked and starts" % id)
		var attempts := 0
		while not game.result_finished and attempts < 30:
			for tick in range(220):
				await physics_frame
				if game.result_finished: break
			if game.result_finished: break
			game.current_data = game.animals[4]
			game._set_aim(360)
			if game.drop_animal(): attempts += 1
			if not game.is_playing(): break
		for tick in range(500):
			await process_frame
			if game.result_finished: break
		check(game.result_success and game.result_saved and game.merge_manager.merge_count > 0, "challenge %d achieved via real drop and collision" % id)
		print("PHASE2_RESULT id=%d drops=%d merges=%d score=%d combo=%d elapsed=%.2f success=%s" % [id, game.spawn_count, game.merge_manager.merge_count, game.score, game.max_combo, game.challenge.elapsed, game.result_success])
		var saved := ChallengeStore.load_results()
		check(saved.status in ["ok", "recovered"] and saved.data.entries[id - 1].completed and float(saved.data.entries[id - 1].best_time) >= 0, "challenge %d saves completion and best time" % id)
		if id < 10: check(ChallengeStore.is_unlocked(saved.data, id + 1), "challenge %d unlocks next" % id)
		await dispose(game)
	# Expiration is measured in game simulation time, not wall time.
	var timer = game_for(7); await frames()
	var before: float = timer.challenge.elapsed
	timer._toggle_pause()
	for i in range(120): await process_frame
	check(is_equal_approx(before, timer.challenge.elapsed), "timer stops on pause")
	timer._toggle_pause()
	for i in range(8000):
		await physics_frame
		if timer.result_finished: break
	check(timer.result_finished and not timer.result_success and timer.challenge.elapsed >= 60.0, "quick merge fails at actual 60 second limit")
	await dispose(timer)
	# Fill an untouched board with real drops across lanes; low scoring and not edited.
	var limited = game_for(10); await frames()
	for i in range(20):
		for tick in range(150): await physics_frame
		if not limited.is_playing(): break
		limited.current_data = limited.animals[0]
		limited._set_aim(130 + (i % 7) * 75)
		var prior: int = limited.spawn_count
		if limited.drop_animal():
			for tick in range(120):
				await physics_frame
				if limited.spawn_count > prior or limited.result_finished: break
		if limited.result_finished: break
	var count: int = limited.spawn_count
	if count >= 20:
		var refused: bool = not limited.drop_animal()
		check(refused and limited.spawn_count == 20, "drop limit refuses a 21st successful drop")
		for tick in range(1000):
			await physics_frame
			if limited.result_finished: break
		check(limited.result_finished and not limited.result_success, "under-target board fails only after last drop settles")
	else:
		check(false, "20 real drops reached the limit (actual=%d score=%d)" % [count, limited.score])
	await dispose(limited)
	print("PHASE2 checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
func migrate_phase() -> void:
	var old := {"version": 1, "entries": []}
	for i in range(5): old.entries.append({"completed": true, "best": i * 100, "attempts": i + 1})
	check(SaveManager.save_progress(old, ChallengeStore.PATH, false) == OK, "write actual legacy v1 fixture")
	var loaded := ChallengeStore.load_results()
	check(loaded.status == "ok" and int(loaded.data.version) == 2 and loaded.data.entries.size() == 20 and int(loaded.data.entries[4].best) == 400 and int(loaded.data.entries[4].attempts) == 5, "v1 migration preserves five results")
	check(ChallengeStore.is_unlocked(loaded.data, 6) and float(loaded.data.entries[4].best_time) == -1.0, "migration opens challenge 6 without inventing old times")
	print("PHASE2_MIGRATE checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
func read_phase() -> void:
	var loaded := ChallengeStore.load_results()
	check(loaded.status in ["ok", "recovered"], "separate process reads progression")
	for id in range(1, 11):
		check(loaded.data.entries[id - 1].completed, "separate process restores challenge %d" % id)
	print("PHASE2_READ checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
