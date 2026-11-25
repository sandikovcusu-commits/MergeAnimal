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
	var startup := load("res://scenes/ui/MainMenu.tscn") as PackedScene
	var menu = startup.instantiate()
	root.add_child(menu); current_scene = menu
	await frames()
	check(is_instance_valid(menu.play_button) and not menu.play_button.disabled, "main menu exposes working Play")
	check(menu.find_child("Collection", true, false).disabled and menu.find_child("Challenges", true, false).disabled, "unfinished modes disabled")
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
	settings.find_child("Back", true, false).pressed.emit()
	await frames()
	check(not is_instance_valid(menu.settings_panel), "settings back closes modal")
	SettingsStore.save_values(old_settings); SettingsStore.apply(old_settings)
	menu.play_button.pressed.emit()
	await frames(5)
	var game = current_scene
	check(game != menu and game.has_method("_toggle_pause") and game.is_playing(), "Play transitions to live game")
	game.pause_button.pressed.emit()
	await frames()
	check(paused and game.game_state == game.GameState.PAUSED and game.overlay.visible, "pause freezes game and shows overlay")
	game.get_node("HUD/Overlay/SettingsButton").pressed.emit()
	await frames()
	check(is_instance_valid(game.settings_panel) and paused, "settings opens while paused")
	game.settings_panel.find_child("Back", true, false).pressed.emit()
	await frames()
	check(not is_instance_valid(game.settings_panel) and paused and game.overlay.visible, "settings back preserves pause")
	game.resume_button.pressed.emit()
	await frames()
	check(not paused and game.is_playing() and not game.overlay.visible, "resume restores gameplay")
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
	print("Day5 UI integration: checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
