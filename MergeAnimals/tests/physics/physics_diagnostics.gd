extends SceneTree
# Controlled fixtures, not natural gameplay. Automated metrics are not a feel review.
const SCENE := preload("res://scenes/game/Game.tscn")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	Engine.physics_ticks_per_second = 120
	print("DROP_CSV level,id,radius,mass,friction,bounce,max_floor_px,max_speed,first_contact_s,final_gap_px,final_speed,sleeping")
	for level in range(12):
		var game = SCENE.instantiate(); game.persist_best = false; game.test_seed = 42
		root.add_child(game); await process_frame
		game.danger_monitor.set_physics_process(false)
		var data: AnimalData = game.animals[level]
		var body: Animal = game.create_animal(data, Vector2(360, game.spawn_height))
		var max_depth := 0.0; var max_speed := 0.0; var first := -1.0
		for i in range(120 * 5):
			await physics_frame
			var gap: float = game.floor_height - body.position.y - data.radius
			max_depth = maxf(max_depth, -gap)
			max_speed = maxf(max_speed, body.linear_velocity.length())
			if first < 0.0 and gap <= 1.0: first = float(i) / 120.0
		var gap: float = game.floor_height - body.position.y - data.radius
		print("DROP_CSV %d,%s,%.1f,%.2f,%.2f,%.2f,%.4f,%.2f,%.3f,%.4f,%.4f,%s" % [level+1, data.id, data.radius, data.body_mass, data.friction, data.bounce, max_depth, max_speed, first, gap, body.linear_velocity.length(), str(body.sleeping)])
		game.queue_free(); await process_frame
	print("PILE_CSV bodies,max_floor_px,max_pair_penetration_px,full_escape_frames,final_count,merges")
	for count in [10, 20, 40]:
		var game = SCENE.instantiate(); game.persist_best = false; game.test_seed = 42
		root.add_child(game); await process_frame
		game.danger_monitor.set_physics_process(false)
		for i in range(count):
			var data: AnimalData = game.animals[i % 2]
			var body: Animal = game.create_animal(data, Vector2(145 + (i % 8)*54, 500 + int(i / 8)*54))
			body.merge_locked = true # Fixed count; suppress merges only in this fixture.
		var max_floor := 0.0; var max_pair := 0.0; var escaped := 0
		for frame in range(120 * 6):
			await physics_frame
			var bodies := game.pieces.get_children(); var any_escape := false
			for i in range(bodies.size()):
				var a: Animal = bodies[i]
				max_floor = maxf(max_floor, a.position.y + a.data.radius - game.floor_height)
				if a.position.y - a.data.radius > game.floor_height or a.position.x + a.data.radius < game.left_bound or a.position.x - a.data.radius > game.right_bound: any_escape = true
				for j in range(i+1,bodies.size()):
					var b: Animal = bodies[j]
					max_pair = maxf(max_pair, a.data.radius + b.data.radius - a.position.distance_to(b.position))
			if any_escape: escaped += 1
		print("PILE_CSV %d,%.4f,%.4f,%d,%d,%d" % [count,max_floor,max_pair,escaped,game.pieces.get_child_count(),game.merge_manager.merge_count])
		game.queue_free(); await process_frame
	print("PHYSICS_DIAGNOSTICS complete")
	quit()
