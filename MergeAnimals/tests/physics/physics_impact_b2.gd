extends SceneTree
# B.2 §14 — real drop-impact penetration per animal level.
#
# The dense-board audit showed a constant 1.842 px floor depth for a level-1
# body released from y = 1040, i.e. a body arriving at 265.94 px/s: one physics
# step (1/120 s) covers 2.22 px, and the solver resolves it to 1.84 px on the
# next scan. The A.1 maximum of 9.190 px matches sqrt(2*g*h)/120 for the
# level-12 body dropped from the real spawn height, so the hypothesis under test
# is "penetration = one step of free fall at the moment of contact", not a
# solver defect. This suite measures that directly for all 12 levels.
#
# Geometry is the production one: the body is created at spawn_height with the
# same wall clamp _set_aim() applies, and only gravity moves it. No velocity is
# written and no penetration is injected.
var scene := preload("res://scenes/game/Game.tscn")
# Candidate B (CCD) is evaluated by setting the mode on the test body only; the
# product scene keeps continuous_cd = 1 (CAST_RAY). 0 = product, 1 = CAST_SHAPE,
# 2 = disabled. This is instrumentation for comparison, not a product change.
var chosen_policy := 0
const CCD_MODES := [1, 2, 0]
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("policy="): chosen_policy = int(arg.split("=")[1])
	call_deferred("run")
func run() -> void:
	var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
	var step: float = 1.0 / float(Engine.physics_ticks_per_second)
	print("IMPACT_CONFIG ticks=%d gravity=%.1f step=%.6f policy=%d floor_top_y=1094 wall_left_x=91 wall_right_x=629" % [Engine.physics_ticks_per_second, gravity, step, chosen_policy])
	print("IMPACT_CSV level,id,radius,mass,drop_height,v_pred,step_pred,frames_to_contact,max_impact_depth,rest_depth,recovery_frames,escape,bodies_end")
	var worst := 0.0
	var worst_line := ""
	var escapes := 0
	for level in range(12):
		for repeat in range(5):
			var game = scene.instantiate()
			game.test_seed = 9000 + level * 10 + repeat
			game.persist_best = false
			game.combo_enabled = false
			root.add_child(game)
			await process_frame
			game.danger_monitor.set_physics_process(false)
			var data: AnimalData = game.animals[level]
			var x: float = clampf(360.0, game.left_bound + data.radius + game.spawn_margin, game.right_bound - data.radius - game.spawn_margin)
			var body: Animal = game.create_animal(data, Vector2(x, game.spawn_height))
			body.continuous_cd = CCD_MODES[clampi(chosen_policy, 0, 2)]
			var drop_height: float = float(game.floor_height) - float(data.radius) - float(game.spawn_height)
			var v_pred: float = sqrt(2.0 * gravity * maxf(0.0, drop_height))
			var max_depth := 0.0
			var frames_to_contact := -1
			var recovery := -1
			var escape := false
			var frames := 0
			# 3 s at 120 Hz: enough for the fall plus 60 frames of rest.
			while frames < 360:
				await physics_frame
				frames += 1
				if not is_instance_valid(body) or body.is_queued_for_deletion():
					break
				var depth: float = maxf(0.0, (body.position.y + data.radius) - float(game.floor_height))
				if depth > 0.01 and frames_to_contact < 0:
					frames_to_contact = frames
				if frames_to_contact >= 0 and recovery < 0 and depth <= 0.01 and frames > frames_to_contact + 1:
					recovery = frames - frames_to_contact
				max_depth = maxf(max_depth, depth)
				if body.position.x + data.radius < float(game.left_bound) - 1.0 or body.position.x - data.radius > float(game.right_bound) + 1.0 or body.position.y - data.radius > float(game.floor_height) + 1.0:
					escape = true
			# Rest depth is the residual penetration after the body settles.
			var rest_depth := 0.0
			if is_instance_valid(body) and not body.is_queued_for_deletion():
				rest_depth = maxf(0.0, (body.position.y + data.radius) - float(game.floor_height))
			var line := "IMPACT_CSV %d,%s,%.2f,%.2f,%.2f,%.2f,%.4f,%d,%.3f,%.3f,%d,%s,%d" % [level + 1, str(data.id), data.radius, data.body_mass, drop_height, v_pred, v_pred * step, frames_to_contact, max_depth, rest_depth, recovery, str(escape), game.pieces.get_child_count()]
			print(line)
			if max_depth > worst:
				worst = max_depth
				worst_line = line
			if escape:
				escapes += 1
			game.queue_free()
			await process_frame
	print("IMPACT_WORST %s" % worst_line)
	print("IMPACT_COMPLETE cases=%d max_depth=%.3f escapes=%d" % [60, worst, escapes])
	quit()
