extends SceneTree
# Seeded scripted fixture, not a human playtest.
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> bool:
	await create_timer(0.4, true).timeout
	await RenderingServer.frame_post_draw
	var out := []
	var status := OS.execute("xdotool", ["search", "--onlyvisible", "--pid", str(OS.get_process_id())], out, true)
	if status != 0 or out.is_empty(): return false
	var ids := str(out[0]).strip_edges().split("\n", false)
	if ids.is_empty(): return false
	var path := OS.get_environment("CAPTURE_DIR") + "/" + name + ".png"
	if OS.execute("import", ["-window", ids[0], path]) != 0: return false
	var image := Image.new()
	if image.load(path) != OK or image.get_size() != Vector2i(720, 1280): return false
	print("CAPTURE " + name + " 720x1280 seeded fixture")
	return true
func run() -> void:
	var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.test_seed = 7; game.persist_best = false
	root.add_child(game); current_scene = game
	await process_frame
	var body: Animal = game.create_animal(game.animals[2], Vector2(360, 800)); body.freeze = true
	await process_frame
	if not await capture("remove_button") or not await capture("before_remove"):
		printerr("FAIL capture before"); quit(1); return
	# Route a real synthetic mouse click through Godot's viewport/GUI, not a
	# direct signal, to verify the HUD consumes input before gameplay.
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true
	press.position = Vector2(150, 238); press.global_position = press.position
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT; release.pressed = false
	release.position = press.position; release.global_position = press.position
	Input.parse_input_event(release)
	await process_frame; await process_frame
	if game.spawn_count != 0 or game.drop_requested:
		printerr("FAIL UI click triggered drop"); quit(1); return
	print("PASS viewport GUI mouse click did not drop")
	if not game.remove_selecting or not await capture("remove_selecting"):
		printerr("FAIL selection capture"); quit(1); return
	var touch := InputEventScreenTouch.new(); touch.index = 0; touch.pressed = true; touch.position = body.global_position
	Input.parse_input_event(touch)
	await process_frame; await process_frame
	var touch_end := InputEventScreenTouch.new(); touch_end.index = 0; touch_end.pressed = false; touch_end.position = touch.position
	Input.parse_input_event(touch_end)
	await process_frame; await process_frame
	if is_instance_valid(body) or game.remove_remaining != 0 or not await capture("after_remove") or not await capture("remove_used"):
		printerr("FAIL removal capture"); quit(1); return
	quit()
