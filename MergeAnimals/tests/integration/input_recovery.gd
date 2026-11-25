extends SceneTree
# Regression: after a blocked spawn, a new quick tap/click elsewhere must not
# be swallowed merely because no physics frame occurred between press/release.
var scene := preload("res://scenes/game/Game.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures += 1

func run() -> void:
	for use_touch in [true, false]:
		var game = scene.instantiate()
		game.test_seed = 42
		game.persist_best = false
		root.add_child(game)
		await process_frame
		game.create_animal(game.current_data, Vector2(360, game.spawn_height))
		await physics_frame
		await physics_frame
		game.spawn_state = game.SpawnState.COOLDOWN
		game.cooldown_left = 0.0
		if use_touch:
			var touch := InputEventScreenTouch.new()
			touch.index = 0
			touch.position = Vector2(500, 600)
			touch.pressed = true
			game._unhandled_input(touch)
			touch.pressed = false
			game._unhandled_input(touch)
		else:
			var mouse := InputEventMouseButton.new()
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.position = Vector2(500, 600)
			mouse.pressed = true
			game._unhandled_input(mouse)
			mouse.pressed = false
			game._unhandled_input(mouse)
		var label: String = "touch" if use_touch else "mouse"
		check(game.drop_requested, label + " quick tap accepted at clear x after blocked cooldown")
		await physics_frame
		await physics_frame
		check(game.spawn_count == 1, label + " creates exactly one drop")
		game.queue_free()
		await process_frame
	print("Input recovery failures: ", failures)
	quit(1 if failures else 0)
