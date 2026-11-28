extends SceneTree
# Uses real drops, gravity, contact and untouched boards. To keep the test
# deterministic it chooses the drop animal; that is a fixture-controlled queue.
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for id in range(2, 6):
		set_meta("challenge_id", id)
		var game = (load("res://scenes/game/ChallengeGame.tscn") as PackedScene).instantiate()
		game.test_seed = 42; root.add_child(game); current_scene = game
		await process_frame; await process_frame
		var index: int = [0, 1, 2, 3, 4][id - 1]
		var attempts := 0
		while not game.result_finished and attempts < 38:
			for tick in range(220):
				await physics_frame
				if game.result_finished: break
			if game.result_finished: break
			game.current_data = game.animals[index]
			game._set_aim(360)
			if game.drop_animal(): attempts += 1
			if not game.is_playing(): break
		for tick in range(400):
			await process_frame
			if game.result_finished: break
		var ok: bool = game.result_finished and game.result_success and game.result_saved and game.merge_manager.merge_count > 0
		print("%s: untouched-board challenge %d drops=%d merges=%d score=%d" % ["PASS" if ok else "FAIL", id, game.spawn_count, game.merge_manager.merge_count, game.score])
		if not ok: failures += 1
		paused = false; game.queue_free(); await process_frame; await process_frame
	print("NATURAL_CHALLENGES failures=%d" % failures)
	quit(1 if failures else 0)
