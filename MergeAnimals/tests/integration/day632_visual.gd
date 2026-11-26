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
func drop(game, x: float) -> bool:
	var count: int = game.spawn_count
	game._set_aim(x); game.drop_animal()
	for i in range(120):
		await physics_frame
		if game.spawn_count > count: return true
	return false
func run() -> void:
	var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.test_seed = 33; game.persist_best = false
	root.add_child(game); current_scene = game; await process_frame
	if not await capture("undo_no_snapshot"): printerr("FAIL capture"); quit(1); return
	await click(Vector2(350, 238))
	if game.spawn_count != 0 or game.drop_requested: printerr("FAIL disabled GUI triggered drop"); quit(1); return
	if not await drop(game, 360) or game.undo_button.disabled: printerr("FAIL drop fixture"); quit(1); return
	if not await capture("undo_button") or not await capture("before_undo"): printerr("FAIL before"); quit(1); return
	await click(Vector2(350, 238))
	if game.undo_remaining != 0 or game.spawn_count != 0 or game.pieces.get_child_count() != 0: printerr("FAIL mouse GUI undo"); quit(1); return
	print("PASS viewport mouse Undo did not drop")
	if not await capture("after_undo") or not await capture("undo_used"): printerr("FAIL after"); quit(1); return
	# Separate fixture resets the balance only for a second visual scenario.
	game.undo_remaining = 1; game.current_data = game.animals[0]; game.next_data = game.animals[1]
	var a: Animal = game.create_animal(game.animals[0], Vector2(200, 900)); a.freeze = true
	var b: Animal = game.create_animal(game.animals[1], Vector2(500, 900)); b.freeze = true
	if not await drop(game, 360): printerr("FAIL chain drop"); quit(1); return
	if not await capture("chain_before"): printerr("FAIL chain before"); quit(1); return
	var dropped: Animal = null
	for node in game.pieces.get_children():
		if node is Animal and node != a and node.data.level == 1: dropped = node
	if dropped == null or not game.merge_manager.request_merge(a, dropped): printerr("FAIL chain pair"); quit(1); return
	game.merge_manager._commit_pending(); await process_frame
	var h: Animal = null
	for node in game.pieces.get_children():
		if node is Animal and node != b and node.data.level == 2: h = node
	if h == null or not game.merge_manager.request_merge(h, b): printerr("FAIL chain pair two"); quit(1); return
	game.merge_manager._commit_pending(); await process_frame
	if game.merge_manager.merge_count != 2 or not await capture("chain_after"): printerr("FAIL chain after"); quit(1); return
	var down := InputEventScreenTouch.new(); down.index = 0; down.pressed = true; down.position = Vector2(350, 238)
	Input.parse_input_event(down); await process_frame
	var up := InputEventScreenTouch.new(); up.index = 0; up.pressed = false; up.position = down.position
	Input.parse_input_event(up); await process_frame; await process_frame; await process_frame
	if game.undo_remaining != 0 or game.merge_manager.merge_count != 0 or game.pieces.get_child_count() != 2:
		printerr("FAIL viewport touch Undo"); quit(1); return
	print("PASS viewport simulated touch Undo")
	if not await capture("chain_undo"): printerr("FAIL chain undo"); quit(1); return
	quit()
