extends SceneTree
# Complete configured levels with their own starter boards and spawn queues.
# Only actual drop input and gravity/contact; no body moves, removals or score injection.
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1; print("%s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok: failures += 1
func run() -> void:
	if OS.get_environment("PHASE4") == "read": read_phase(); return
	for id in range(16, 21):
		set_meta("challenge_id", id)
		var game = (load("res://scenes/game/ChallengeGame.tscn") as PackedScene).instantiate()
		game.test_seed = 88; root.add_child(game); current_scene = game
		await process_frame; await process_frame
		if game.challenge == null:
			check(false, "challenge %d unlocked" % id); quit(1); return
		check(not game.remove_button.visible and not game.undo_button.visible and not game.rescue_button.visible, "challenge %d disables powerups" % id)
		var attempts := 0
		while not game.result_finished and attempts < 48:
			for tick in range(220):
				await physics_frame
				if game.result_finished: break
			if game.result_finished: break
			game._set_aim(360)
			if game.drop_animal(): attempts += 1
			if not game.is_playing(): break
		for tick in range(500):
			await process_frame
			if game.result_finished: break
		check(game.result_finished and game.result_success and game.result_saved and game.merge_manager.merge_count > 0, "challenge %d real gameplay success" % id)
		print("PHASE4_RESULT id=%d drops=%d merges=%d score=%d combo=%d elapsed=%.2f success=%s" % [id, game.spawn_count, game.merge_manager.merge_count, game.score, game.max_combo, game.challenge.elapsed, game.result_success])
		if id == 17: check(game.max_combo >= 5, "real combo x5")
		if id == 20: check(game.challenge.count == 1 and game.score >= 1000, "real golden merge event")
		var saved := ChallengeStore.load_results()
		check(saved.status in ["ok", "recovered"] and saved.data.entries[id - 1].completed, "challenge %d completion persisted" % id)
		paused = false; game.queue_free(); await process_frame; await process_frame
		if failures > 0: break
	print("PHASE4 checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)

func read_phase() -> void:
	var saved := ChallengeStore.load_results()
	check(saved.status in ["ok", "recovered"], "separate process loads all challenge results")
	if saved.status not in ["ok", "recovered"]: quit(1); return
	for id in range(1, 21):
		check(saved.data.entries[id - 1].completed and ChallengeStore.is_unlocked(saved.data, id), "challenge %d completion and unlock restored" % id)
	for id in range(6, 21):
		check(float(saved.data.entries[id - 1].best_time) >= 0.0, "challenge %d best time restored" % id)
	var file := FileAccess.open("user://classic-fixture-hashes.json", FileAccess.READ)
	var hashes: Variant = JSON.parse_string(file.get_as_text()) if file else null
	check(typeof(hashes) == TYPE_DICTIONARY and FileAccess.get_sha256(SessionSave.PATH) == hashes.primary and FileAccess.get_sha256(SessionSave.POWERUP_PATH) == hashes.checkpoint, "classic session and progression files remain byte identical")
	check(SessionSave.load_progression().best_score == 123, "classic record and collection/statistics progression preserved")
	print("PHASE4_READ checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
