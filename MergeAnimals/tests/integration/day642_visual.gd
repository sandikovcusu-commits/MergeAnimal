extends SceneTree
# Real X11 screenshots. Progression is from the preceding real gameplay suite.
var failures := 0
func _initialize() -> void: call_deferred("run")
func frames(n := 3) -> void:
	for i in range(n): await process_frame
func capture(name: String) -> bool:
	await create_timer(0.2, true).timeout
	await RenderingServer.frame_post_draw
	var out := []
	if OS.execute("xdotool", ["search", "--onlyvisible", "--pid", str(OS.get_process_id())], out, true) != 0 or out.is_empty(): return false
	var ids := str(out[0]).strip_edges().split("\n", false)
	if ids.is_empty(): return false
	var filename := OS.get_environment("CAPTURE_PREFIX") + "_" + name
	var path := OS.get_environment("CAPTURE_DIR") + "/" + filename + ".png"
	if OS.execute("import", ["-window", ids[0], path]) != 0: return false
	var image := Image.new()
	var expected := Vector2i(int(OS.get_environment("CAPTURE_WIDTH")), int(OS.get_environment("CAPTURE_HEIGHT")))
	if image.load(path) != OK or image.get_size() != expected: return false
	print("CAPTURE %s %dx%d X11 fixture" % [filename, expected.x, expected.y]); return true
func go_back(game) -> void:
	if game.result_finished:
		game._main_menu(); await frames(); return
	game._toggle_pause(); game._main_menu(); await frames()
	if is_instance_valid(game.confirm_exit): game.confirm_exit.confirmed.emit()
	await frames()
func start(selection, id: int):
	selection.buttons[id - 1].pressed.emit(); await frames()
	return current_scene
func run() -> void:
	var loaded := ChallengeStore.load_results()
	if loaded.status not in ["ok", "recovered"] or not loaded.data.entries[19].completed:
		printerr("FAIL visual fixture requires real completed progression"); quit(1); return
	change_scene_to_file("res://scenes/ui/ChallengeSelection.tscn"); await frames()
	var selection = current_scene
	if selection.buttons.size() != 20 or not await capture("selection_20"): printerr("FAIL selection"); quit(1); return
	for entry in [[0, "beginner"], [5, "intermediate"], [10, "advanced"], [15, "expert"]]:
		selection.scroll.ensure_control_visible(selection.buttons[entry[0]])
		await frames()
		if not await capture(entry[1]): printerr("FAIL category capture"); quit(1); return
	var game = await start(selection, 7)
	if not await capture("timer_challenge"): printerr("FAIL timer capture"); quit(1); return
	await go_back(game); selection = current_scene
	game = await start(selection, 10)
	if not await capture("limited_drops"): printerr("FAIL limit capture"); quit(1); return
	await go_back(game); selection = current_scene
	game = await start(selection, 20)
	if not await capture("golden_garden"): printerr("FAIL golden capture"); quit(1); return
	await go_back(game); selection = current_scene
	# Real goal: configured raccoon falls into the initial raccoon, creating koala.
	game = await start(selection, 11)
	for i in range(100): await physics_frame
	game._set_aim(360); game.drop_animal()
	for i in range(500):
		await process_frame
		if game.result_finished: break
	if not game.result_success or not game.result_saved or game.merge_manager.merge_count < 1:
		printerr("FAIL visual real collision success"); quit(1); return
	if not await capture("success"): printerr("FAIL success capture"); quit(1); return
	await go_back(game); selection = current_scene
	game = await start(selection, 7)
	game.danger_monitor.overflow.emit(); await frames()
	if not game.result_finished or game.result_success: printerr("FAIL visual failure fixture"); quit(1); return
	if not await capture("failed"): printerr("FAIL failed capture"); quit(1); return
	print("PASS expansion X11 visual fixtures"); quit()
