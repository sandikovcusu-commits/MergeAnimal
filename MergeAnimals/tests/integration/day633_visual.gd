extends SceneTree
# Seeded physics/GUI fixture; not a human playtest.
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> bool:
	await create_timer(0.35, true).timeout
	await RenderingServer.frame_post_draw
	var out := []
	var status := OS.execute("xdotool", ["search", "--onlyvisible", "--pid", str(OS.get_process_id())], out, true)
	if status != 0 or out.is_empty(): return false
	var ids := str(out[0]).strip_edges().split("\n", false)
	if ids.is_empty(): return false
	var path := OS.get_environment("CAPTURE_DIR") + "/" + name + ".png"
	if OS.execute("import", ["-window", ids[0], path]) != 0: return false
	var image := Image.new()
	if image.load(path) != OK or image.get_size() != Vector2i(720,1280): return false
	print("CAPTURE ", name, " 720x1280 seeded fixture")
	return true
func click(point: Vector2) -> void:
	var down := InputEventMouseButton.new(); down.button_index = MOUSE_BUTTON_LEFT; down.pressed = true; down.position = point; down.global_position = point
	Input.parse_input_event(down); await process_frame
	var up := InputEventMouseButton.new(); up.button_index = MOUSE_BUTTON_LEFT; up.pressed = false; up.position = point; up.global_position = point
	Input.parse_input_event(up); await process_frame; await process_frame
func run() -> void:
	var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.test_seed = 33; game.persist_best = false
	root.add_child(game); current_scene = game; await process_frame
	game.danger_monitor.set_physics_process(false)
	var a: Animal = game.create_animal(game.animals[0], Vector2(360, 430)); a.freeze = true
	var b: Animal = game.create_animal(game.animals[8], Vector2(260, 800)); b.freeze = true
	await physics_frame
	game._on_game_over(); await process_frame
	if not await capture("game_over") or not await capture("rescue_button") or not await capture("before_rescue"): printerr("FAIL capture before"); quit(1); return
	await click(Vector2(360, 790))
	if not game.rescue_processing: printerr("FAIL mouse rescue start"); quit(1); return
	if not await capture("rescue_animation"): printerr("FAIL animation capture"); quit(1); return
	await create_timer(0.2, true).timeout
	if game.rescue_remaining != 0 or game.game_state != game.GameState.PLAYING: printerr("FAIL mouse rescue"); quit(1); return
	print("PASS viewport mouse Rescue")
	if not await capture("after_rescue"): printerr("FAIL after capture"); quit(1); return
	game._on_game_over(); await process_frame
	if not game.rescue_button.disabled or not await capture("rescue_used"): printerr("FAIL used capture"); quit(1); return
	await click(Vector2(360, 790))
	if game.rescue_remaining != 0 or game.game_state != game.GameState.GAME_OVER: printerr("FAIL disabled button"); quit(1); return
	# A second independent fixture uses touch on the actual GUI button.
	paused = false; game.queue_free(); await process_frame
	game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.test_seed = 34; game.persist_best = false
	root.add_child(game); current_scene = game; await process_frame
	game.danger_monitor.set_physics_process(false)
	a = game.create_animal(game.animals[0], Vector2(360,430)); a.freeze = true
	await physics_frame; game._on_game_over(); await process_frame
	var down := InputEventScreenTouch.new(); down.index = 0; down.pressed = true; down.position = Vector2(360, 790)
	Input.parse_input_event(down); await process_frame
	var up := InputEventScreenTouch.new(); up.index = 0; up.pressed = false; up.position = down.position
	Input.parse_input_event(up); await create_timer(0.7, true).timeout
	if game.rescue_remaining != 0 or game.game_state != game.GameState.PLAYING: printerr("FAIL simulated touch rescue"); quit(1); return
	print("PASS viewport simulated touch Rescue")
	quit()
