extends SceneTree
# Automated policies use real spawn/merge/danger physics; never presented as human play.
var scene := preload("res://scenes/game/Game.tscn")
var chooser := RandomNumberGenerator.new()
var strategies := ["random", "same_target", "lowest_stack", "merge_priority"]
func _initialize() -> void:
	call_deferred("run")
func choose_x(game, strategy: int) -> float:
	var left: float = game.left_bound + game.current_data.radius + game.spawn_margin
	var right: float = game.right_bound - game.current_data.radius - game.spawn_margin
	if strategy == 0:
		return chooser.randf_range(left, right)
	var candidates: Array = []
	for body in game.pieces.get_children():
		if body.data.id == game.current_data.id and not body.merge_locked:
			candidates.append(body)
	if strategy == 1 and not candidates.is_empty():
		return clampf(candidates[chooser.randi_range(0, candidates.size() - 1)].position.x, left, right)
	if strategy == 3 and not candidates.is_empty():
		var target = candidates[0]
		for body in candidates:
			if body.position.y > target.position.y:
				target = body
		return clampf(target.position.x, left, right)
	var best_x := left
	var best_height := -INF
	for i in range(9):
		var x: float = lerpf(left, right, i / 8.0)
		var top: float = game.floor_height
		for body in game.pieces.get_children():
			if absf(body.position.x - x) < body.data.radius + game.current_data.radius:
				top = minf(top, body.position.y - body.data.radius)
		if top > best_height:
			best_height = top
			best_x = x
	return best_x
func run() -> void:
	print("BOT_CSV seed,strategy,drops,merges,highest_level,score,combo_events,end_reason,sim_seconds,full_escape_frames,max_overlap_px,overlap_frames,max_body_streak")
	for i in range(100):
		var game = scene.instantiate()
		var seed_value := 30000 + i
		game.test_seed = seed_value
		game.persist_best = false
		chooser.seed = seed_value + 7777
		root.add_child(game)
		await process_frame
		var elapsed := 0.0
		var next_drop := 0.0
		var escaped := 0
		var max_overlap := 0.0
		var overlap_frames := 0
		var max_body_streak := 0
		var streaks := {}
		var strategy: int = i % 4
		# Time cap is reported as such, not mislabelled game-over.
		while game.is_playing() and elapsed < 90.0:
			await physics_frame
			elapsed += 1.0 / 60.0
			if elapsed >= next_drop:
				game._set_aim(choose_x(game, strategy))
				if game.drop_animal():
					next_drop = elapsed + 1.2
				else:
					next_drop = elapsed + 0.2
			var any_escape := false
			var any_overlap := false
			var updated_streaks := {}
			for body in game.pieces.get_children():
				if body.position.x + body.data.radius < game.left_bound or body.position.x - body.data.radius > game.right_bound or body.position.y - body.data.radius > game.floor_height:
					any_escape = true
				var depth: float = maxf(0.0, maxf(game.left_bound - (body.position.x - body.data.radius), maxf(body.position.x + body.data.radius - game.right_bound, body.position.y + body.data.radius - game.floor_height)))
				max_overlap = maxf(max_overlap, depth)
				if depth > 0.01:
					any_overlap = true
					var uid: int = body.get_instance_id()
					var streak: int = int(streaks.get(uid, 0)) + 1
					updated_streaks[uid] = streak
					max_body_streak = maxi(max_body_streak, streak)
			streaks = updated_streaks
			if any_escape:
				escaped += 1
			if any_overlap:
				overlap_frames += 1
		var reason := "overflow" if game.game_state == game.GameState.GAME_OVER else "time_cap"
		print("BOT_CSV %d,%s,%d,%d,%d,%d,%d,%s,%.2f,%d,%.3f,%d,%d" % [seed_value, strategies[strategy], game.spawn_count, game.merge_manager.merge_count, game.highest_level, game.score, game.combo_events, reason, elapsed, escaped, max_overlap, overlap_frames, max_body_streak])
		paused = false
		game.queue_free()
		await process_frame
	print("BOT_COMPLETE sessions=100")
	quit()
