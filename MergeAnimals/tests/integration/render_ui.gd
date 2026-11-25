extends SceneTree
# Full X11 capture of actual Godot controls; fixture transitions are not human play.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var screen := OS.get_environment("CAPTURE_SCREEN")
	var dims := OS.get_environment("CAPTURE_SIZE").split("x")
	if dims.size() != 2 or screen not in ["menu", "pause", "settings", "gameover", "tutorial"]:
		printerr("FAIL: invalid UI capture parameters"); quit(1); return
	var size := Vector2i(int(dims[0]), int(dims[1]))
	var path := "res://scenes/ui/MainMenu.tscn" if screen == "menu" else "res://scenes/game/Game.tscn"
	if screen == "tutorial": set_meta("tutorial_requested", true)
	var node = (load(path) as PackedScene).instantiate()
	if screen != "menu": node.persist_best = false
	root.add_child(node)
	await process_frame
	if screen == "pause" or screen == "settings":
		node._toggle_pause()
		if screen == "settings": node._open_settings()
	elif screen == "gameover":
		node.score = 124; node.highest_level = 6; node.max_combo = 3
		node._on_game_over()
	await create_timer(1.5, true).timeout
	await RenderingServer.frame_post_draw
	var ids := []
	var search := OS.execute("xdotool", ["search", "--onlyvisible", "--pid", str(OS.get_process_id())], ids, true)
	var list := str(ids[0]).strip_edges().split("\n", false) if not ids.is_empty() else PackedStringArray()
	if search != 0 or list.is_empty():
		printerr("FAIL: UI capture could not locate X11 window"); quit(1); return
	var out_path := "%s/ui_%s_%s.png" % [OS.get_environment("CAPTURE_DIR"), screen, OS.get_environment("CAPTURE_SIZE")]
	var output := []
	var code := OS.execute("import", ["-window", list[0], out_path], output, true)
	var image := Image.new()
	var loaded := image.load(out_path) if code == 0 else ERR_CANT_OPEN
	print("UI_RENDER screen=%s size=%s image=%s code=%d" % [screen, size, image.get_size(), code])
	if code != 0 or loaded != OK or image.get_size() != size:
		printerr("FAIL: UI capture dimensions or image error: %s" % output); quit(1); return
	paused = false
	quit()
