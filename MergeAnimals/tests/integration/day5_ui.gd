extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", message])
	if not ok: failures += 1
func frames(count: int = 3) -> void:
	for i in range(count): await process_frame
func run() -> void:
	var old_settings := SettingsStore.load_values()
	var tutorial_path := "user://wild_garden_tutorial.cfg"
	var tutorial_existed := FileAccess.file_exists(tutorial_path)
	var tutorial_backup := FileAccess.get_file_as_bytes(tutorial_path) if tutorial_existed else PackedByteArray()
	var startup := load("res://scenes/ui/MainMenu.tscn") as PackedScene
	var menu = startup.instantiate()
	root.add_child(menu); current_scene = menu
	await frames()
	check(is_instance_valid(menu.play_button) and not menu.play_button.disabled, "main menu exposes working Play")
	check(not menu.find_child("Collection", true, false).disabled and not menu.find_child("Challenges", true, false).disabled, "collection and challenge selection enabled")
	menu.settings_button.pressed.emit()
	await frames()
	check(is_instance_valid(menu.settings_panel), "menu opens settings")
	var settings = menu.settings_panel
	settings.sliders.master.value = 0.4
	settings.language_select.select(1); settings.language_select.item_selected.emit(1)
	await frames()
	check(is_equal_approx(SettingsStore.load_values().master, 0.4), "volume change persisted")
	check(TranslationServer.get_locale() == "az" and TranslationServer.translate("SETTINGS") == "Tənzimləmələr", "Azerbaijani translation applied")
	check(AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("SFX") >= 0, "audio bus infrastructure exists")
	for i in range(4):
		settings.language_select.select(i); settings.language_select.item_selected.emit(i)
		var expected: String = ["Play", "Oyna", "Oyna", "Играть"][i]
		check(TranslationServer.translate("PLAY") == expected and SettingsStore.load_values().language == ["en", "az", "tr", "ru"][i], "language %d translates and persists" % i)
	settings.find_child("Back", true, false).pressed.emit()
	await frames()
	check(not is_instance_valid(menu.settings_panel), "settings back closes modal")
	SettingsStore.save_values(old_settings); SettingsStore.apply(old_settings)
	set_meta("tutorial_requested", true)
	menu.play_button.pressed.emit()
	await frames()
	if is_instance_valid(menu.new_game_dialog):
		menu.new_game_dialog.confirmed.emit()
	await frames(5)
	var game = current_scene
	check(game != menu and game.has_method("_toggle_pause") and game.is_playing(), "Play transitions to live game")
	check(game.tutorial_stage == 0 and game.current_data.id == game.next_data.id, "tutorial starts with matching pair")
	var tutorial_panel: Control = game.get_node("HUD/Tutorial/Panel")
	check(not tutorial_panel.get_global_rect().intersects(game.remove_button.get_global_rect()) and not tutorial_panel.get_global_rect().intersects(game.undo_button.get_global_rect()), "tutorial banner does not overlap power-up buttons")
	check(tutorial_panel.position.y > game.spawn_height + 42.0, "tutorial banner does not obscure spawn preview")
	game.get_node("HUD/Tutorial/Skip").pressed.emit(); await frames()
	check(game.tutorial_stage == -1 and FileAccess.file_exists(tutorial_path), "tutorial skip persists completion")
	game.drop_requested = true
	game.spawn_state = game.SpawnState.DROPPING
	game.pause_button.pressed.emit()
	await frames()
	check(not game.drop_requested and game.spawn_state == game.SpawnState.READY, "pause cancels an uncommitted drop")
	check(paused and game.game_state == game.GameState.PAUSED and game.overlay.visible, "pause freezes game and shows overlay")
	game.get_node("HUD/Overlay/SettingsButton").pressed.emit()
	await frames()
	check(is_instance_valid(game.settings_panel) and paused, "settings opens while paused")
	var card: Control = game.settings_panel.find_child("SettingsCard", true, false)
	check(game.settings_panel.size == Vector2(720, 1280) and card.position == Vector2(75, 170) and game.settings_panel.z_index > game.overlay.z_index, "settings card is centered above gameplay overlay")
	game.settings_panel.find_child("Back", true, false).pressed.emit()
	await frames()
	check(not is_instance_valid(game.settings_panel) and paused and game.overlay.visible, "settings back preserves pause")
	game.resume_button.pressed.emit()
	await frames()
	check(not paused and game.is_playing() and not game.overlay.visible, "resume restores gameplay")
	game.pause_button.pressed.emit(); await frames()
	game.get_node("HUD/Overlay/SettingsButton").pressed.emit(); await frames()
	game.settings_panel.find_child("ReplayTutorial", true, false).pressed.emit(); await frames(5)
	game = current_scene
	check(not paused and game.tutorial_stage == 0 and game.current_data.id == game.next_data.id, "replay tutorial restarts with matching pair")
	game.get_node("HUD/Tutorial/Skip").pressed.emit(); await frames()
	game._on_game_over()
	await frames()
	check(paused and game.game_state == game.GameState.GAME_OVER and not game.resume_button.visible, "game over freezes and cannot resume")
	game.get_node("HUD/Overlay/RestartButton").pressed.emit()
	await frames(5)
	var fresh = current_scene
	check(fresh != game and fresh.score == 0 and not paused and fresh.is_playing(), "game-over restart resets scene")
	fresh.pause_button.pressed.emit(); await frames()
	fresh.get_node("HUD/Overlay/MainMenuButton").pressed.emit(); await frames(5)
	check(not paused and current_scene.has_method("_play"), "pause to main menu unpauses tree")
	SettingsStore.save_values(old_settings); SettingsStore.apply(old_settings)
	if tutorial_existed:
		var file := FileAccess.open(tutorial_path, FileAccess.WRITE); file.store_buffer(tutorial_backup); file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tutorial_path))
	print("Day5 UI integration: checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
