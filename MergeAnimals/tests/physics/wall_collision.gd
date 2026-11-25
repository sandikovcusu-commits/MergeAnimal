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
	var ok: bool = minf(min_left, minf(min_right, min_floor)) >= -10.0 and landed
	print("INFO: CCD mode=%d ticks=%d left_gap=%.3f right_gap=%.3f floor_gap=%.3f landed=%s within_10px=%s" % [mode, tick_rate, min_left, min_right, min_floor, landed, ok])
	game.queue_free()
	await process_frame
	return ok

func run() -> void:
	# The tolerance is diagnostic, not a claim of zero visual interpenetration.
	var ok: bool = await measure(RigidBody2D.CCD_MODE_CAST_RAY, 60)
	print("%s: fast-wall containment with 10px overlap tolerance" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
