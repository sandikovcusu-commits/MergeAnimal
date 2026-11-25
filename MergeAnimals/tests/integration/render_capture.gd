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
	var theme := int(OS.get_environment("CAPTURE_THEME"))
	var size_parts := OS.get_environment("CAPTURE_SIZE").split("x")
	if size_parts.size() != 2 or theme < 0 or theme > 2:
		printerr("FAIL: invalid capture parameters")
		quit(1)
		return
	var size := Vector2i(int(size_parts[0]), int(size_parts[1]))
	game.visual_theme = theme
	game.queue_redraw()
	await create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	var ids := []
	var find_result := OS.execute("xdotool", ["search", "--onlyvisible", "--pid", str(OS.get_process_id())], ids, true)
	var id_list := str(ids[0]).strip_edges().split("\n", false) if not ids.is_empty() else PackedStringArray()
	if find_result != 0 or id_list.is_empty():
		printerr("FAIL: X11 game window not found: %s" % ids)
		quit(1)
		return
	var path := "%s/theme%d_%dx%d.png" % [out_dir, theme, size.x, size.y]
	var output := []
	var result := OS.execute("import", ["-window", id_list[0], path], output, true)
	var image := Image.new()
	var loaded := image.load(path) if result == 0 else ERR_CANT_OPEN
	print("RENDER theme=%d requested=%s window=%s root_viewport=%s image=%s result=%d id=%s" % [theme, size, DisplayServer.window_get_size(), root.get_texture().get_image().get_size(), image.get_size(), result, id_list[0]])
	if result != 0 or loaded != OK or image.get_size() != size or DisplayServer.window_get_size() != size:
		printerr("FAIL: full-window screenshot failed or has unexpected size: %s %s" % [path, output])
		quit(1)
		return
	quit()
