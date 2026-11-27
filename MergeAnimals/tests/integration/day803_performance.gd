extends SceneTree
var checks := 0
var failures := 0
func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures += 1
	print("%s: %s" % ["PASS" if condition else "FAIL", label])
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/game/Game.tscn").instantiate()
	game.persist_best = false
	root.add_child(game); current_scene = game
	await process_frame
	var audio = root.get_node("AudioManager")
	audio.reduced_effects = false
	var body = game.create_animal(game.animals[0], Vector2(360, 800))
	body.freeze = true
	await process_frame
	var scheduler = root.get_node_or_null("AnimalVisualScheduler")
	var active: bool = scheduler.visuals.has(body.visual) if scheduler else body.visual.is_processing()
	var phase: float = body.visual.idle_phase
	for i in range(3): await process_frame
	check(active and body.visual.idle_phase > phase, "animal idle animation advances when effects enabled")
	body.visual.animate_action("drop")
	audio.reduced_effects = true
	active = scheduler.visuals.has(body.visual) if scheduler else body.visual.is_processing()
	check(not active and body.visual.scale == Vector2.ONE, "reducing effects stops idle updates and cancels action tween")
	audio.reduced_effects = false
	active = scheduler.visuals.has(body.visual) if scheduler else body.visual.is_processing()
	phase = body.visual.idle_phase
	for i in range(3): await process_frame
	check(active and body.visual.idle_phase > phase, "enabling effects resumes idle animation")
	var small = load("res://resources/animals/mouse.tres")
	var middle = load("res://resources/animals/rabbit.tres")
	var large = load("res://resources/animals/elephant.tres")
	check(small.sprite.get_width() == 256 and middle.sprite.get_width() == 256 and large.sprite.get_width() == 512, "selected small sprites are imported at 256; larger sprites remain 512")
	var shape_id: int = game._spawn_query_shape.get_instance_id()
	var query_id: int = game._spawn_query.get_instance_id()
	var clear: bool = game._spawn_clear(game.animals[0], 360)
	game._spawn_clear(game.animals[1], 360)
	check(clear and shape_id == game._spawn_query_shape.get_instance_id() and query_id == game._spawn_query.get_instance_id() and is_equal_approx(game._spawn_query_shape.radius, game.animals[1].radius + 1.0), "spawn query reuses objects and updates radius")
	body.position = Vector2(360, game.spawn_height)
	await physics_frame
	await physics_frame
	check(not game._spawn_clear(game.animals[0], 360) and game._spawn_clear(game.animals[0], 150), "cached spawn query detects occupied and clear positions")
	print("PERFORMANCE_REGRESSION checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
