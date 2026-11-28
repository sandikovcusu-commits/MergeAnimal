extends SceneTree
# B.2 §14/§17 — physics root-cause instrumentation and dense-board stress.
# Measures boundary penetration with the SAME definition the A.1 bot used
# (depth beyond left/right wall inner edge and floor top edge), and records the
# per-event context required by the brief: seed, tick, animal id, radius,
# position, velocity, boundary side, depth and duration.
var scene := preload("res://scenes/game/Game.tscn")
var chosen_policy := 0
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("policy="): chosen_policy = int(arg.split("=")[1])
	call_deferred("run")
func run() -> void:
	print("PHYSICS_CONFIG ticks=%d wall_left_x=91 wall_right_x=629 wall_half_thickness=16 floor_top_y=1094 gravity=%s" % [Engine.physics_ticks_per_second, str(ProjectSettings.get_setting("physics/2d/default_gravity"))])
	print("PHYSICS_POLICY policy=%d" % chosen_policy)
	print("PHYSICS_CSV seed,bodies,policy,frames,max_depth,mean_depth,events,escape,duration_frames,bodies_end,worst_side,worst_id,worst_radius,worst_x,worst_y,worst_vx,worst_vy")
	for count in [10, 20, 40]:
		for seed_value in range(100):
			await run_case(count, seed_value)
	print("PHYSICS_COMPLETE cases=%d" % 300)
	quit()
func run_case(count: int, seed_value: int) -> void:
	var game = scene.instantiate()
	game.test_seed = seed_value
	game.persist_best = false
	game.combo_enabled = false
	root.add_child(game)
	await process_frame
	game.danger_monitor.set_physics_process(false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 70000 + seed_value
	# Fill the board bottom-up so compression builds naturally, then release
	# the bodies into real gravity.
	for i in range(count):
		var row: int = i / 8
		var col: int = i % 8
		var level: int = rng.randi_range(0, 3)
		var point := Vector2(200 + col * 42, 1040 - row * 44)
		var body: Animal = game.create_animal(game.animals[level], point)
		body.linear_velocity = Vector2(rng.randf_range(-40, 40), 0)
	var max_depth := 0.0
	var depth_sum := 0.0
	var depth_samples := 0
	var events := 0
	var escape := false
	var duration := 0
	var streaks := {}
	var worst := {}
	var worst_side := ""
	var frames := 0
	# 240 physics frames = 2 s at 120 Hz, enough for settling and compression.
	while frames < 240:
		await physics_frame
		frames += 1
		var updated := {}
		for body in game.pieces.get_children():
			if not body is Animal: continue
			var r: float = body.data.radius
			var left_depth: float = game.left_bound - (body.position.x - r)
			var right_depth: float = (body.position.x + r) - game.right_bound
			var floor_depth: float = (body.position.y + r) - game.floor_height
			var depth: float = maxf(0.0, maxf(left_depth, maxf(right_depth, floor_depth)))
			var side := "left" if left_depth >= right_depth and left_depth >= floor_depth else ("right" if right_depth >= floor_depth else "floor")
			if depth > 0.01:
				depth_sum += depth
				depth_samples += 1
				var uid: int = body.get_instance_id()
				updated[uid] = int(streaks.get(uid, 0)) + 1
				duration = maxi(duration, updated[uid])
				if depth > max_depth:
					max_depth = depth
					worst_side = side
					worst = {"frame": frames, "id": str(body.data.id), "radius": r, "x": body.position.x, "y": body.position.y, "vx": body.linear_velocity.x, "vy": body.linear_velocity.y}
			# Body fully outside the playable area is a real escape, not overlap.
			if body.position.x + r < game.left_bound - 1.0 or body.position.x - r > game.right_bound + 1.0 or body.position.y - r > game.floor_height + 1.0:
				escape = true
		streaks = updated
		events += updated.size()
	var body_end: int = game.pieces.get_child_count()
	var mean_depth: float = depth_sum / float(maxi(1, depth_samples))
	print("PHYSICS_CSV %d,%d,%d,%d,%.3f,%.3f,%d,%s,%d,%d,%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f" % [70000 + seed_value, count, chosen_policy, frames, max_depth, mean_depth, events, str(escape), duration, body_end, worst_side, str(worst.get("id", "")), float(worst.get("radius", 0.0)), float(worst.get("x", 0.0)), float(worst.get("y", 0.0)), float(worst.get("vx", 0.0)), float(worst.get("vy", 0.0))])
	if max_depth > 0.0:
		print("PHYSICS_EVENT seed=%d bodies=%d policy=%d frame=%d side=%s depth=%.3f id=%s radius=%.2f pos=(%.2f,%.2f) vel=(%.2f,%.2f) duration_frames=%d" % [70000 + seed_value, count, chosen_policy, int(worst.get("frame", 0)), worst_side, max_depth, str(worst.get("id", "")), float(worst.get("radius", 0.0)), float(worst.get("x", 0.0)), float(worst.get("y", 0.0)), float(worst.get("vx", 0.0)), float(worst.get("vy", 0.0)), duration])
	game.queue_free()
	await process_frame
