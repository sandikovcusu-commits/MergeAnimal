extends SceneTree
# Synthetic stress, not natural gameplay. 100 seeds at each fixed body count;
# reservations/commit and snapshots use real manager methods. Frozen mice avoid
# timing-dependent motion; pending duration is measured wall-clock only.
var scene := preload("res://scenes/game/Game.tscn")
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	print("MERGE_STRESS_CSV seed,bodies,reserved,queue_max,locks_max,pending_ms,blocked_drop_ms,save_delay_ms,merges,score,lost,duplicates,stop")
	for count in [10,20,40]:
		for seed_value in range(100):
			var game = scene.instantiate()
			game.test_seed = 41000 + seed_value
			game.persist_best = false
			game.combo_enabled = false
			root.add_child(game); await process_frame
			game.danger_monitor.set_physics_process(false); game.merge_manager.set_physics_process(false)
			var rng := RandomNumberGenerator.new(); rng.seed = 41000 + seed_value
			var animals: Array[Animal] = []
			for i in range(count):
				var row: int = i / 8
				var col: int = i % 8
				var animal: Animal = game.create_animal(game.animals[0], Vector2(216 + col * 36, 820 + row * 36))
				animal.freeze = true; animals.append(animal)
			var first: int = rng.randi_range(0, count / 2 - 2) * 2
			var start := Time.get_ticks_usec()
			var reserved := 0
			if game.merge_manager.request_merge(animals[first], animals[first+1]): reserved += 1
			var duplicate: bool = game.merge_manager.request_merge(animals[first], animals[first+2])
			if game.merge_manager.request_merge(animals[first+2], animals[first+3]): reserved += 1
			var qmax: int = game.merge_manager.pending.size()
			var locks := 0
			for animal in animals:
				if animal.merge_locked: locks += 1
			game._attempt_drop()
			var rejected_drop: bool = game.spawn_count == 0
			var rejected_snapshot: bool = game.save_session() == ERR_BUSY
			game.merge_manager._commit_pending()
			var pending_ms := (Time.get_ticks_usec() - start) / 1000.0
			var remaining: int = game.pieces.get_child_count()
			var merges: int = game.merge_manager.merge_count
			var lost: int = count - merges - remaining
			var bad_locks := 0
			for animal in game.pieces.get_children():
				if animal.merge_locked: bad_locks += 1
			var valid: bool = game.merge_manager.pending.is_empty() and bad_locks == 0 and merges <= reserved and game.score == 4 * merges and lost == 0 and not duplicate and rejected_drop and rejected_snapshot and not game._session_snapshot().is_empty()
			if not valid: failures += 1
			print("MERGE_STRESS_CSV %d,%d,%d,%d,%d,%.3f,%.3f,%.3f,%d,%d,%d,%d,%s" % [41000+seed_value,count,reserved,qmax,locks,pending_ms,pending_ms,pending_ms,merges,game.score,lost,int(duplicate),"ok" if valid else "failure"])
			game.queue_free(); await process_frame
	print("MERGE_STRESS_COMPLETE cases=300 seeds=100 failures=%d" % failures)
	quit(1 if failures else 0)
