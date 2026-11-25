extends SceneTree

var failures := 0

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		printerr("FAIL: ", description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene := load("res://scenes/game/Game.tscn") as PackedScene
	check(scene != null, "main scene loads")
	if scene == null:
		quit(1)
		return
	var game = scene.instantiate()
	game.test_seed = 42
	root.add_child(game)
	await process_frame
	check(game.animals.size() == 3, "three AnimalData resources load")
	check(game.current_data != null and game.next_data != null, "current and next selected")
	var first_id: StringName = game.current_data.id
	var next_id: StringName = game.next_data.id
	var game2 = scene.instantiate()
	game2.test_seed = 42
	root.add_child(game2)
	await process_frame
	check(game2.current_data.id == first_id and game2.next_data.id == next_id, "seed repeats sequence")
	game2.queue_free()
	game._set_aim(-1000)
	check(is_equal_approx(game.aim_x, game.left_bound + game.current_data.radius), "aim clamps to left")
	game._set_aim(1000)
	check(is_equal_approx(game.aim_x, game.right_bound - game.current_data.radius), "aim clamps to right")
	game._set_aim(360)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(360, 500)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = Vector2(360, 500)
	game._unhandled_input(press)
	game._unhandled_input(release)
	check(game.pieces.get_child_count() == 1, "mouse press and release drops")
	check(not game.drop_animal(), "cooldown rejects immediate second drop")
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(360, 500)
	touch.pressed = true
	game._unhandled_input(touch)
	touch.pressed = false
	game._unhandled_input(touch)
	check(game.pieces.get_child_count() == 1, "touch during cooldown cannot add a second body")
	check(game.pieces.get_child_count() == 1, "one body spawned")
	var body = game.pieces.get_child(0)
	var initial_y: float = body.position.y
	for i in range(180):
		await physics_frame
	check(body.position.y > initial_y + 100.0, "gravity moves body down")
	check(body.position.y <= game.floor_height - body.data.radius + 2.0, "floor contains body after settling")
	check(body.position.x >= game.left_bound + body.data.radius - 2.0 and body.position.x <= game.right_bound - body.data.radius + 2.0, "body remains between walls")
	check(game.drop_animal(), "drop accepted after cooldown")
	print("Day 1 smoke failures: ", failures)
	quit(1 if failures else 0)
