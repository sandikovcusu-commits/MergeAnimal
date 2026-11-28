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
	var escaped := false
	for i in range(tick_rate * 3):
		await physics_frame
		min_left = minf(min_left, left.position.x - left.data.radius - game.left_bound)
		min_right = minf(min_right, game.right_bound - right.position.x - right.data.radius)
		min_floor = minf(min_floor, game.floor_height - maxf(left.position.y + left.data.radius, right.position.y + right.data.radius))
		escaped = escaped or left.position.x + left.data.radius < game.left_bound - 32.0 or right.position.x - right.data.radius > game.right_bound + 32.0 or left.position.y - left.data.radius > game.floor_height + 32.0 or right.position.y - right.data.radius > game.floor_height + 32.0
	var landed: bool = left.position.y > 900 and right.position.y > 900
	var center_in_wall: bool = left.position.x < game.left_bound or right.position.x > game.right_bound or left.position.y > game.floor_height or right.position.y > game.floor_height
	var ok: bool = not escaped and not center_in_wall and landed
	print("INFO: CCD mode=%d ticks=%d left_gap=%.3f right_gap=%.3f floor_gap=%.3f landed=%s full_escape=%s center_in_wall=%s" % [mode, tick_rate, min_left, min_right, min_floor, landed, escaped, center_in_wall])
	game.queue_free()
	await process_frame
	return ok

func run() -> void:
	# Only whole-body escape/center trapped in wall is asserted; overlap is measured separately.
	var ok: bool = await measure(RigidBody2D.CCD_MODE_CAST_RAY, 60)
	print("%s: no full escape or trapped center; overlap measurement is not a zero-penetration pass" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
