extends SceneTree
# B.2 §14/§17 — physics root-cause instrumentation and dense-board stress.
# Measures boundary penetration with the SAME definition the A.1 bot used
# (depth beyond left/right wall inner edge and floor top edge), and records the
# per-event context required by the brief: seed, tick, animal id, radius,
# position, velocity, boundary side, depth and duration.
var scene := preload("res://scenes/game/Game.tscn")
var chosen_policy := 0
# 100 seeds per body count for the baseline (600 cases across both policies);
# the merged-board variant runs 100 too so the two are directly comparable.
var policy_cases := 100
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("policy="): chosen_policy = int(arg.split("=")[1])
	call_deferred("run")
func run() -> void:
	print("PHYSICS_CONFIG ticks=%d wall_left_x=91 wall_right_x=629 wall_half_thickness=16 floor_top_y=1094 gravity=%s" % [Engine.physics_ticks_per_second, str(ProjectSettings.get_setting("physics/2d/default_gravity"))])
	print("PHYSICS_POLICY policy=%d max_level=%d merge_enabled=%s" % [chosen_policy, 11 if chosen_policy == 0 else 2, str(chosen_policy == 1)])
	print("PHYSICS_CSV seed,target,spawned,policy,frames,max_depth,mean_depth,events,escape,duration_frames,bodies_end,worst_side,worst_id,worst_radius,worst_x,worst_y,worst_vx,worst_vy")
	for count in [10, 20, 40]:
		for seed_value in range(policy_cases):
			await run_case(count, seed_value)
	print("PHYSICS_COMPLETE policy=%d cases=%d" % [chosen_policy, 3 * policy_cases])
	quit()
func run_case(count: int, seed_value: int) -> void:
	# Policy 1 re-seeds so the merged-board cases are an independent sample
	# rather than a repeat of the same lattices.
	var seed_base: int = 70000 if chosen_policy == 0 else 80000
	var game = scene.instantiate()
	game.test_seed = seed_value
	game.persist_best = false
	game.combo_enabled = false
	root.add_child(game)
	await process_frame
	game.danger_monitor.set_physics_process(false)
	# Legal, seeded shelf packing: each row is filled left to right with random
	# levels whose diameter still fits, leaving a 1 px gap, and rows stack with
	# a 1 px gap. No body overlaps another body or a wall at spawn (asserted
	# below), so every depth that follows is produced by the solver, not by the
	# fixture. The first audit attempt mixed levels on a fixed 42 px lattice and
	# therefore reported overlap it had created itself.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_base + seed_value
	var inside_left: float = float(game.left_bound) + 1.0
	var inside_right: float = float(game.right_bound) - 1.0
	var cursor_x: float = inside_left
	var cursor_y: float = float(game.floor_height) - 1.0
	var row_top: float = cursor_y
	var spawned := 0
	var levels_used := {}
	var top_level: int = 11 if chosen_policy == 0 else 2
	# Policy 0: natural board, all levels, merges disabled so the measurement is
	# pure contact penetration. Policy 1: levels 1-3 only, merges live, i.e. the
	# real dense-chain and merge-placement path under compression.
	var merge_enabled: bool = chosen_policy == 1
	for i in range(count):
		var pick: int = rng.randi_range(0, top_level)
		var tries := 0
		while tries < 12:
			var radius: float = game.animals[pick].radius
			if cursor_x + radius * 2.0 <= inside_right and cursor_y - radius * 2.0 >= 300.0:
				break
			# This level no longer fits the remaining width: start a new row.
			cursor_x = inside_left
			cursor_y = row_top - 1.0
			row_top = cursor_y
			pick = rng.randi_range(0, top_level)
			tries += 1
		var r: float = game.animals[pick].radius
		if cursor_x + r * 2.0 > inside_right or cursor_y - r * 2.0 < 300.0:
			break
		var body: Animal = game.create_animal(game.animals[pick], Vector2(cursor_x + r, cursor_y - r))
		if not merge_enabled:
			# Policy 0 measures contact penetration of a static legal stack, so
			# the merge path is suppressed for the packed bodies only (a body
			# flag, no manager state is written).
			body.merge_locked = true
		levels_used[str(game.animals[pick].id)] = int(levels_used.get(str(game.animals[pick].id), 0)) + 1
		spawned += 1
		cursor_x += r * 2.0 + 1.0
		# The next row starts under the tallest body of this one.
		row_top = minf(row_top, cursor_y - r * 2.0)
	# Cases whose target body count could not be reached are reported honestly
	# instead of silently measured at a lower density.
	var shortfall: bool = spawned < count
	# A fixture that starts overlapped cannot measure solver penetration.
	var initial_overlap := 0.0
	var nodes: Array = game.pieces.get_children()
	for x in range(nodes.size()):
		for y in range(x + 1, nodes.size()):
			var a: Animal = nodes[x]
			var b: Animal = nodes[y]
			var penetration: float = a.data.radius + b.data.radius - a.position.distance_to(b.position)
			initial_overlap = maxf(initial_overlap, penetration)
	for node in nodes:
		var a2: Animal = node
		initial_overlap = maxf(initial_overlap, float(game.left_bound) - (a2.position.x - a2.data.radius))
		initial_overlap = maxf(initial_overlap, (a2.position.x + a2.data.radius) - float(game.right_bound))
		initial_overlap = maxf(initial_overlap, (a2.position.y + a2.data.radius) - float(game.floor_height))
	print("PHYSICS_FIXTURE seed=%d bodies=%d spawned=%d shortfall=%s initial_overlap=%.3f levels=%s merges=%d" % [seed_base + seed_value, count, spawned, str(shortfall), initial_overlap, str(levels_used), game.merge_manager.merge_count])
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
	print("PHYSICS_CSV %d,%d,%d,%d,%d,%.3f,%.3f,%d,%s,%d,%d,%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f" % [seed_base + seed_value, count, spawned, chosen_policy, frames, max_depth, mean_depth, events, str(escape), duration, body_end, worst_side, str(worst.get("id", "")), float(worst.get("radius", 0.0)), float(worst.get("x", 0.0)), float(worst.get("y", 0.0)), float(worst.get("vx", 0.0)), float(worst.get("vy", 0.0))])
	if max_depth > 0.0:
		print("PHYSICS_EVENT seed=%d bodies=%d policy=%d frame=%d side=%s depth=%.3f id=%s radius=%.2f pos=(%.2f,%.2f) vel=(%.2f,%.2f) duration_frames=%d" % [seed_base + seed_value, count, chosen_policy, int(worst.get("frame", 0)), worst_side, max_depth, str(worst.get("id", "")), float(worst.get("radius", 0.0)), float(worst.get("x", 0.0)), float(worst.get("y", 0.0)), float(worst.get("vx", 0.0)), float(worst.get("vy", 0.0)), duration])
	game.queue_free()
	await process_frame
