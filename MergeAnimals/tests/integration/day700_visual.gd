extends SceneTree
# X11 captures; deterministic previews are not a human playtest.
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> bool:
	await create_timer(0.2, true).timeout; await RenderingServer.frame_post_draw
	var out := []
	if OS.execute("xdotool", ["search", "--onlyvisible", "--pid", str(OS.get_process_id())], out, true) != 0 or out.is_empty(): return false
	var ids := str(out[0]).strip_edges().split("\n", false)
	if ids.is_empty(): return false
	return OS.execute("import", ["-window", ids[0], OS.get_environment("CAPTURE_DIR") + "/" + name + ".png"]) == 0
func run() -> void:
	change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	for i in range(10): await process_frame
	if not await capture("menu_logo"): printerr("FAIL menu capture"); quit(1); return
	var game = load("res://scenes/game/Game.tscn").instantiate()
	game.test_seed = 7; current_scene.queue_free(); root.add_child(game); current_scene = game
	for i in range(60): await physics_frame
	for drop in range(5):
		game.current_data = game.animals[drop % 3]; game._set_aim(220 + drop * 70); game.drop_animal()
		for i in range(150): await physics_frame
	if not await capture("gameplay"): printerr("FAIL gameplay capture"); quit(1); return
	game.queue_free(); current_scene = null
	for i in range(3): await process_frame
	game = load("res://scenes/game/Game.tscn").instantiate(); game.test_seed = 9
	root.add_child(game); current_scene = game
	for i in range(60): await physics_frame
	game.current_data = game.animals[0]; game._set_aim(360); game.drop_animal()
	for i in range(220): await physics_frame
	game.current_data = game.animals[0]; game._set_aim(360); game.drop_animal()
	for i in range(600):
		await physics_frame
		if game.merge_manager.merge_count > 0: break
	if game.merge_manager.merge_count != 1 or not await capture("physical_merge"): printerr("FAIL merge capture"); quit(1); return
	print("PASS V070 X11 screenshots: deterministic drops, not human play")
	quit()
