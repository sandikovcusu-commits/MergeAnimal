extends SceneTree
# Diagnostic measurements, not a claim of zero visible overlap.
var scene := preload("res://scenes/game/Game.tscn")
func _initialize() -> void:
	call_deferred("run")
func run_case(level: int, ccd: int, ticks: int, thickness: float, speed: float, bounce: float, radius_scale: float) -> bool:
	Engine.physics_ticks_per_second = ticks
	var game = scene.instantiate()
	game.persist_best = false
	game.test_seed = 123
	root.add_child(game)
	await process_frame
	game.danger_monitor.set_physics_process(false)
	# Duplicate wall shape and keep its INNER face fixed at x=629.
	var wall: CollisionShape2D = game.get_node("Walls/Right")
	wall.shape = wall.shape.duplicate()
	wall.shape.size.x = thickness
	wall.position.x = game.right_bound + thickness / 2.0
	var data = game.animals[level - 1].duplicate()
	data.radius *= radius_scale
	data.bounce = bounce
	var body = game.create_animal(data, Vector2(360, 600))
	body.gravity_scale = 0.0
	body.continuous_cd = ccd
	body.linear_velocity = Vector2(speed, 0)
	var max_depth := 0.0
	var frames_over := 0
	var max_streak := 0
	var streak := 0
	var center_escaped := false
	var final_depth := 0.0
	for i in range(ticks * 3):
		await physics_frame
		var depth: float = maxf(0.0, body.position.x + data.radius - game.right_bound)
		max_depth = maxf(max_depth, depth)
		if depth > 0.01:
			frames_over += 1
			streak += 1
			max_streak = maxi(max_streak, streak)
		else:
			streak = 0
		center_escaped = center_escaped or body.position.x - data.radius > game.right_bound + thickness
		final_depth = depth
	var stuck: bool = final_depth > 2.0 and absf(body.linear_velocity.x) < 1.0
	print("WALL level=%d radius=%.1f ccd=%d ticks=%d thickness=%.0f speed=%.0f bounce=%.2f max_px=%.3f overlap_frames=%d max_consecutive=%d fully_escaped=%s stuck=%s final_depth=%.3f" % [level, data.radius, ccd, ticks, thickness, speed, bounce, max_depth, frames_over, max_streak, center_escaped, stuck, final_depth])
	game.queue_free()
	await process_frame
	return not center_escaped and not stuck
func run() -> void:
	var cases := [
		[1,0,60,32,120,0.1,1.0], [1,1,60,32,120,0.1,1.0], [1,2,60,32,120,0.1,1.0],
		[1,0,60,32,700,0.1,1.0], [1,1,60,32,700,0.1,1.0], [1,2,60,32,700,0.1,1.0],
		[1,1,120,32,700,0.1,1.0], [1,1,240,32,700,0.1,1.0],
		[1,1,60,64,700,0.1,1.0], [1,1,60,32,700,0.0,1.0], [1,1,60,32,700,0.5,1.0],
		[1,1,60,32,700,0.1,0.8], [5,1,60,32,120,0.1,1.0], [5,1,60,32,700,0.1,1.0],
		[12,1,60,32,120,0.1,1.0], [12,1,60,32,700,0.1,1.0]
	]
	var failures := 0
	for c in cases:
		if not await run_case(c[0], c[1], c[2], c[3], c[4], c[5], c[6]):
			failures += 1
	Engine.physics_ticks_per_second = 60
	print("Wall matrix cases=%d full_escape_or_stuck=%d" % [cases.size(), failures])
	quit(1 if failures else 0)
