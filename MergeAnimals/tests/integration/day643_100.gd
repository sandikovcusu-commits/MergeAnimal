extends SceneTree
# Access to level 17 is a seeded unlock fixture. All 100+ merges under test
# are new actual drops and collisions, with no score mutation or board cleanup.
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for path in [AchievementManager.PATH, ChallengeStore.PATH, SessionSave.PATH, SessionSave.POWERUP_PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	var access := ChallengeStore.empty()
	for i in range(16): access.entries[i].completed = true
	if SaveManager.save_progress(access, ChallengeStore.PATH) != OK: printerr("FAIL access fixture"); quit(1); return
	for run_index in range(4):
		set_meta("challenge_id", 17)
		var game = (load("res://scenes/game/ChallengeGame.tscn") as PackedScene).instantiate()
		game.test_seed = 88; root.add_child(game); current_scene = game
		await process_frame; await process_frame
		var attempts := 0
		while not game.result_finished and attempts < 48:
			for i in range(220):
				await physics_frame
				if game.result_finished: break
			if game.result_finished: break
			game._set_aim(360)
			if game.drop_animal(): attempts += 1
		for i in range(500):
			await process_frame
			if game.result_finished: break
		if not game.result_success or game.merge_manager.merge_count != 31:
			printerr("FAIL 100-merge clean replay ", run_index + 1, " merges=", game.merge_manager.merge_count); failures += 1
		print("CLEAN_MERGES run=%d drops=%d merges=%d" % [run_index + 1, game.spawn_count, game.merge_manager.merge_count])
		paused = false; game.queue_free(); current_scene = null; await process_frame; await process_frame
	var state := AchievementManager.load_state()
	var count: int = int(state.data.events.total_merges)
	var good: bool = count >= 100 and state.data.entries.A13.unlocked and not str(state.data.entries.A13.date).is_empty()
	print("%s: A13 with %d new physical merges and seeded access only" % ["PASS" if good else "FAIL", count])
	if not good: failures += 1
	print("ACHIEVEMENT_100 failures=%d" % failures); quit(1 if failures else 0)
