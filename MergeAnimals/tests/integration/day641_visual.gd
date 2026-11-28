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
func drop(game, x: float) -> Animal:
	for i in range(180):
		if game._can_aim(): break
		await physics_frame
	game.current_data = game.animals[0]; game._set_aim(x)
	var n: int = game.spawn_count
	game.drop_animal()
	for i in range(120):
		await physics_frame
		if game.spawn_count > n: return game.pieces.get_child(game.pieces.get_child_count()-1)
	return null
func run() -> void:
	for path in [ChallengeStore.PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	change_scene_to_file("res://scenes/ui/ChallengeSelection.tscn"); await process_frame; await process_frame
	var selection = current_scene
	if not await capture("challenge_selection_locked"): printerr("FAIL selection capture"); quit(1); return
	selection.buttons[0].pressed.emit(); await process_frame; await process_frame
	var game = current_scene
	game.danger_monitor.set_physics_process(false)
	if not await capture("challenge_gameplay"): printerr("FAIL gameplay capture"); quit(1); return
	var a := await drop(game, 230)
	if a == null: printerr("FAIL first drop"); quit(1); return
	a.freeze = true; a.position = Vector2(290,800); a.linear_velocity = Vector2.ZERO
	var b := await drop(game, 490)
	if b == null: printerr("FAIL second drop"); quit(1); return
	b.freeze = true; b.position = Vector2(430,800); b.linear_velocity = Vector2.ZERO
	await physics_frame
	a.freeze = false; b.freeze = false; a.linear_velocity = Vector2(240,0); b.linear_velocity = Vector2(-240,0)
	for i in range(240):
		await process_frame
		if game.result_finished: break
	if not game.result_success or not game.result_saved: printerr("FAIL collision success"); quit(1); return
	if not await capture("challenge_success"): printerr("FAIL success capture"); quit(1); return
	game._restart(); await process_frame; await process_frame
	game = current_scene
	game.danger_monitor.overflow.emit(); await process_frame; await process_frame
	if not game.result_finished or game.result_success: printerr("FAIL failure fixture"); quit(1); return
	if not await capture("challenge_failed"): printerr("FAIL failed capture"); quit(1); return
	game._main_menu(); await process_frame; await process_frame
	if current_scene.buttons[1].disabled or not await capture("challenge_selection_unlocked"): printerr("FAIL unlock capture"); quit(1); return
	print("PASS Challenge X11 scripted fixtures")
	quit()
