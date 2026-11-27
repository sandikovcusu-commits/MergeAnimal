extends SceneTree
# Native test fixture: two real terminal animals collide, using normal merge
# manager and current VFX; test-created bodies, not a human gameplay capture.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/game/Game.tscn").instantiate()
	game.persist_best = false
	root.add_child(game)
	await process_frame
	game.danger_monitor.set_physics_process(false)
	var a: Animal = game.create_animal(game.animals[11], Vector2(225, 700))
	var b: Animal = game.create_animal(game.animals[11], Vector2(495, 700))
	a.linear_velocity = Vector2(200, 0)
	b.linear_velocity = Vector2(-200, 0)
	for i in range(240):
		await physics_frame
		if game.merge_manager.merge_count > 0: break
	if game.merge_manager.merge_count != 1: printerr("FAIL golden collision not observed"); quit(1); return
	var has_echo := false
	for effect in game.get_tree().get_nodes_in_group("visual_effects"):
		if effect.effect_kind == "golden_echo": has_echo = true
	if not has_echo: printerr("FAIL golden echo absent"); quit(1); return
	await create_timer(0.08).timeout
	await RenderingServer.frame_post_draw
	var out := []
	var code := OS.execute("xdotool", ["search", "--onlyvisible", "--pid", str(OS.get_process_id())], out, true)
	var windows := str(out[0]).strip_edges().split("\n", false) if not out.is_empty() else PackedStringArray()
	if code != 0 or windows.is_empty(): printerr("FAIL no X11 window"); quit(1); return
	var destination: String = OS.get_environment("CAPTURE_DIR") + "/golden-merge-fixture.png"
	code = OS.execute("import", ["-window", windows[0], destination])
	var image := Image.new()
	if code != 0 or image.load(destination) != OK or image.get_size() != Vector2i(720, 1280):
		printerr("FAIL golden screenshot"); quit(1); return
	print("GOLDEN_COLLISION_CAPTURE ", destination, " merges=", game.merge_manager.merge_count)
	quit()
