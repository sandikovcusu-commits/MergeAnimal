extends SceneTree
var scene := preload("res://scenes/game/Game.tscn")
func _initialize() -> void:
	call_deferred("run")

func measure(mode: int, tick_rate: int) -> bool:
	Engine.physics_ticks_per_second = tick_rate
	var game = scene.instantiate()
	game.test_seed = 42
	game.persist_best = false
	root.add_child(game)
	await process_frame
	game.danger_monitor.set_physics_process(false)
	var left = game.create_animal(game.animals[0], Vector2(200, 550))
	var right = game.create_animal(game.animals[1], Vector2(520, 550))
	left.continuous_cd = mode
	right.continuous_cd = mode
	left.linear_velocity = Vector2(-700, 0)
	right.linear_velocity = Vector2(700, 0)
	var min_left := INF
	var min_right := INF
	var min_floor := INF
	for i in range(tick_rate * 3):
		await physics_frame
		min_left = minf(min_left, left.position.x - left.data.radius - game.left_bound)
		min_right = minf(min_right, game.right_bound - right.position.x - right.data.radius)
		min_floor = minf(min_floor, game.floor_height - maxf(left.position.y + left.data.radius, right.position.y + right.data.radius))
	var landed: bool = left.position.y > 900 and right.position.y > 900
	var ok: bool = minf(min_left, minf(min_right, min_floor)) >= -2.0 and landed
	print("INFO: CCD mode=%d ticks=%d left_gap=%.3f right_gap=%.3f floor_gap=%.3f landed=%s within_2px=%s" % [mode, tick_rate, min_left, min_right, min_floor, landed, ok])
	game.queue_free()
	await process_frame
	return ok

func run() -> void:
	var ray60: bool = await measure(RigidBody2D.CCD_MODE_CAST_RAY, 60)
	var ray120: bool = await measure(RigidBody2D.CCD_MODE_CAST_RAY, 120)
	var shape120: bool = await measure(RigidBody2D.CCD_MODE_CAST_SHAPE, 120)
	var ray240: bool = await measure(RigidBody2D.CCD_MODE_CAST_RAY, 240)
	print("CCD comparison: ray60=%s ray120=%s shape120=%s ray240=%s" % [ray60, ray120, shape120, ray240])
	quit(0 if ray120 or shape120 or ray240 else 1)
