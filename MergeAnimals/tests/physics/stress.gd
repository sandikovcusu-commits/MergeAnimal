extends SceneTree

# Isolated diagnostic benchmark; intentionally disables merge and danger ONLY
# here to maintain a fixed body count. Not a normal-game performance result.
var scene := preload("res://scenes/game/Game.tscn")
var game

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for count in [100, 150, 200]:
		game = scene.instantiate()
		game.test_seed = 42
		game.persist_best = false
		root.add_child(game)
		await process_frame
		game.danger_monitor.set_physics_process(false)
		game.merge_manager.set_physics_process(false)
		for i in range(count):
			var x: float = 112 + (i % 14) * 37
			var y: float = 450 + floori(float(i) / 14.0) * 37
			var body = game.create_animal(game.animals[0], Vector2(x, y))
			body.merge_locked = true
		for frame in range(300):
			await physics_frame
		var escaped := 0
		for body in game.pieces.get_children():
			if body.position.x - body.data.radius < game.left_bound - 2.0 or body.position.x + body.data.radius > game.right_bound + 2.0 or body.position.y + body.data.radius > game.floor_height + 2.0:
				escaped += 1
		print("count=%d actual=%d fps=%.1f physics_seconds=%.6f static_bytes=%.0f escaped=%d merge_count=%d pending=%d" % [count, game.pieces.get_child_count(), Performance.get_monitor(Performance.TIME_FPS), Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS), Performance.get_monitor(Performance.MEMORY_STATIC), escaped, game.merge_manager.merge_count, game.merge_manager.pending.size()])
		game.queue_free()
		await process_frame
	quit()
