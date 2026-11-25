extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok: failures += 1
func frames(count: int = 3) -> void:
	for i in range(count): await process_frame
func click(control: Control) -> void:
	var point := control.get_global_transform_with_canvas() * (control.size / 2.0)
	var motion := InputEventMouseMotion.new(); motion.position = point; motion.global_position = point
	root.push_input(motion, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down; event.position = point; event.global_position = point
		root.push_input(event, true)
		await process_frame
func touch(control: Control) -> void:
	var point := control.get_global_transform_with_canvas() * (control.size / 2.0)
	for down in [true, false]:
		var event := InputEventScreenTouch.new(); event.index = 1; event.pressed = down; event.position = point
		root.push_input(event, true)
		await process_frame
func run() -> void:
	var tutorial_path := "user://wild_garden_tutorial.cfg"
	var tutorial_existed := FileAccess.file_exists(tutorial_path)
	var tutorial_backup := FileAccess.get_file_as_bytes(tutorial_path) if tutorial_existed else PackedByteArray()
	var menu = (load("res://scenes/ui/MainMenu.tscn") as PackedScene).instantiate()
	root.add_child(menu); current_scene = menu; await frames()
	await click(menu.settings_button); await frames()
	check(is_instance_valid(menu.settings_panel), "mouse click opens Settings through viewport GUI dispatch")
	if is_instance_valid(menu.settings_panel):
		await click(menu.settings_panel.find_child("Back", true, false)); await frames()
		check(not is_instance_valid(menu.settings_panel), "mouse click Back closes Settings")
	set_meta("tutorial_requested", true)
	await click(menu.play_button); await frames(5)
	var game = current_scene
	check(game.has_method("_toggle_pause") and game.is_playing(), "mouse click Play transitions to game")
	if game.has_method("_toggle_pause"):
		if game.has_node("HUD/Tutorial/Skip"):
			await touch(game.get_node("HUD/Tutorial/Skip")); await frames()
			check(game.tutorial_stage == -1 and game.spawn_count == 0 and not game.drop_requested, "touch Skip is consumed without dropping a piece")
		await touch(game.pause_button); await frames()
		check(paused and game.game_state == game.GameState.PAUSED, "simulated touch opens Pause")
		if paused:
			game.resume_button.grab_focus()
			check(game.resume_button.has_focus(), "keyboard focus reaches Resume")
			var action := InputEventAction.new(); action.action = "ui_accept"; action.pressed = true; root.push_input(action, true)
			var release := InputEventAction.new(); release.action = "ui_accept"; release.pressed = false; root.push_input(release, true)
			await frames()
			check(not paused and game.is_playing(), "keyboard accept activates focused Resume")
	paused = false
	if tutorial_existed:
		var file := FileAccess.open(tutorial_path, FileAccess.WRITE); file.store_buffer(tutorial_backup); file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tutorial_path))
	print("Day5 GUI dispatch: checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
