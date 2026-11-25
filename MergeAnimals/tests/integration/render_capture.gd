extends SceneTree
# X11 window captures are real Godot output, not generated concepts.
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
	var positions := [Vector2(120,530), Vector2(180,530), Vector2(250,530), Vector2(330,530), Vector2(420,530), Vector2(520,530), Vector2(160,670), Vector2(300,680), Vector2(455,680), Vector2(185,830), Vector2(425,850), Vector2(300,1040-125)]
	for index in range(12):
		var piece = game.create_animal(game.animals[index], positions[index])
		piece.freeze = true
	game.highest_level = 12
	game._update_hud()
	var out_dir := OS.get_environment("CAPTURE_DIR")
	if out_dir.is_empty():
		printerr("FAIL: CAPTURE_DIR is required")
		quit(1)
		return
	var dimensions := [Vector2i(360,640), Vector2i(360,800), Vector2i(720,1280), Vector2i(1080,1920), Vector2i(1366,768), Vector2i(1920,1080)]
	for theme in range(3):
		game.visual_theme = theme
		game.queue_redraw()
		for size in dimensions:
			DisplayServer.window_set_size(size)
			DisplayServer.window_set_position(Vector2i(0, 0))
			await create_timer(0.8).timeout
			await RenderingServer.frame_post_draw
			var path := "%s/theme%d_%dx%d.png" % [out_dir, theme, size.x, size.y]
			var output := []
			# Xvfb has no window manager: the client is placed at (0,0).
			# Capture that exact rectangle from the X11 root, including letterboxing.
			var crop := "%dx%d+0+0" % [size.x, size.y]
			var result := OS.execute("import", ["-window", "root", "-crop", crop, path], output, true)
			var image := Image.new()
			var loaded := image.load(path)
			print("RENDER theme=%d requested=%s window=%s root_viewport=%s image=%s result=%d" % [theme, size, DisplayServer.window_get_size(), root.get_texture().get_image().get_size(), image.get_size(), result])
			if result != 0 or loaded != OK or image.get_size() != size:
				printerr("FAIL: full-window screenshot failed or has unexpected size: %s %s" % [path, output])
				quit(1)
				return
	quit()
