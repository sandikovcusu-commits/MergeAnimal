extends SceneTree
# A.4 synthetic stress with the automatic contact-retry scheduler enabled.
# Same 100-seed lattice as merge_stress.gd; after the first commit, blockers
# are removed and the scheduler must finish the merge without explicit input.
var scene := preload("res://scenes/game/Game.tscn")
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	print("MERGE_STRESS_A4_CSV seed,bodies,reserved,cancelled,auto_attempts,auto_successes,merges,score,lost,duplicates,pending_max,ok")
	for count in [10,20,40]:
		for seed_value in range(100):
			var game = scene.instantiate()
			game.test_seed = 41000 + seed_value
			game.persist_best = false
			game.combo_enabled = false
			root.add_child(game); await process_frame
			game.danger_monitor.set_physics_process(false)
			var rng := RandomNumberGenerator.new(); rng.seed = 41000 + seed_value
			var animals: Array[Animal] = []
			for i in range(count):
				var row: int = i / 8
				var col: int = i % 8
				var animal: Animal = game.create_animal(game.animals[0], Vector2(216 + col * 36, 820 + row * 36))
				animal.freeze = true; animals.append(animal)
			var first: int = rng.randi_range(0, count / 2 - 2) * 2
			var before: Dictionary = game.merge_manager.retry_state()
			var reserved := 0
			if game.merge_manager.request_merge(animals[first], animals[first+1]): reserved += 1
			var duplicate: bool = game.merge_manager.request_merge(animals[first], animals[first+2])
			if game.merge_manager.request_merge(animals[first+2], animals[first+3]): reserved += 1
			var pending_max: int = game.merge_manager.pending.size()
			for i in range(6): await physics_frame
			pending_max = maxi(pending_max, game.merge_manager.pending.size())
			# Remove every blocker; only the two reserved pairs remain. Removed
			# blockers are accounted for separately (they are not body loss).
			var removed := 0
			for animal in animals:
				if animal != animals[first] and animal != animals[first+1] and animal != animals[first+2] and animal != animals[first+3]:
					if is_instance_valid(animal) and animal.get_parent() == game.pieces:
						game.pieces.remove_child(animal); animal.queue_free(); removed += 1
			# The first commit runs on the physics tick after the drop/removal, so
			# wait for a settled state (no pending reservation and no tracked
			# failure) instead of a fixed number of frames.
			for i in range(180):
				pending_max = maxi(pending_max, game.merge_manager.pending.size())
				if game.merge_manager.pending.is_empty() and game.merge_manager.retry_state().failed == 0 and game.merge_manager.merge_count >= 1:
					break
				await physics_frame
			var state: Dictionary = game.merge_manager.retry_state()
			var remaining: int = game.pieces.get_child_count()
			var merges: int = game.merge_manager.merge_count
			var lost: int = count - removed - merges - remaining
			var bad_locks := 0
			for animal in game.pieces.get_children():
				if animal.merge_locked: bad_locks += 1
			var valid: bool = reserved == 2 and not duplicate and game.merge_manager.pending.is_empty() and bad_locks == 0 and merges <= 2 and game.score == 4 * merges and lost == 0 and remaining == count - removed - merges and state.failed == 0 and not game._session_snapshot().is_empty()
			if not valid: failures += 1
			print("MERGE_STRESS_A4_CSV %d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s" % [41000+seed_value,count,reserved,state.cancelled-before.cancelled,state.attempts-before.attempts,state.successes-before.successes,merges,game.score,lost,int(duplicate),pending_max,"ok" if valid else "failure"])
			game.queue_free(); await process_frame
	print("MERGE_STRESS_A4_COMPLETE cases=300 seeds=100 failures=%d" % failures)
	quit(1 if failures else 0)
