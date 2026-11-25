extends SceneTree
var scene := preload("res://scenes/game/Game.tscn")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = scene.instantiate()
	game.test_seed = 42
	game.persist_best = false
	root.add_child(game)
	await process_frame
	game.danger_monitor.set_physics_process(false)
	var left = game.create_animal(game.animals[0], Vector2(200, 550))
	var right = game.create_animal(game.animals[1], Vector2(520, 550))
	left.linear_velocity = Vector2(-700, 0)
	right.linear_velocity = Vector2(700, 0)
	var escaped := false
	for i in range(180):
		await physics_frame
		if left.position.x - left.data.radius < game.left_bound - 2.0 or right.position.x + right.data.radius > game.right_bound + 2.0 or left.position.y + left.data.radius > game.floor_height + 2.0 or right.position.y + right.data.radius > game.floor_height + 2.0:
			escaped = true
	var landed: bool = left.position.y > 900 and right.position.y > 900
	print("%s: left/right walls and floor contain fast bodies; escaped=%s landed=%s" % ["PASS" if not escaped and landed else "FAIL", escaped, landed])
	quit(0 if not escaped and landed else 1)
