extends SceneTree
# Historical progress fixtures unlock themes for rendering only.
func _initialize() -> void: call_deferred("run")
func frames(n := 3) -> void:
	for i in range(n): await process_frame
func capture(name: String) -> bool:
	await create_timer(0.12, true).timeout; await RenderingServer.frame_post_draw
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
	print("CAPTURE %s %dx%d seeded X11 fixture" % [filename, expected.x, expected.y]); return true
func run() -> void:
	for path in [ThemeStore.PATH, SessionSave.PATH, SessionSave.POWERUP_PATH, ChallengeStore.PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	if SessionSave.clear_session(Progression.empty(500)) != OK: printerr("FAIL score fixture"); quit(1); return
	var ch := ChallengeStore.empty()
	for i in range(10): ch.entries[i].completed = true
	if SaveManager.save_progress(ch, ChallengeStore.PATH) != OK: printerr("FAIL challenge fixture"); quit(1); return
	ThemeStore.refresh()
	for id in ThemeStore.IDS:
		if ThemeStore.select(id) != OK: printerr("FAIL select ", id); quit(1); return
		for locale in ["en", "az", "tr", "ru"]:
			var values := SettingsStore.load_values(); values.language = locale
			if SettingsStore.save_values(values) != OK: printerr("FAIL locale fixture"); quit(1); return
			change_scene_to_file("res://scenes/ui/MainMenu.tscn"); await frames()
			if not await capture("menu_%s_%s" % [id, locale]): printerr("FAIL capture menu"); quit(1); return
		change_scene_to_file("res://scenes/ui/ThemeSelection.tscn"); await frames()
		if not await capture("themes_%s" % id): printerr("FAIL capture themes"); quit(1); return
	for locale in ["az", "tr", "ru"]:
		var values := SettingsStore.load_values(); values.language = locale; SettingsStore.save_values(values)
		change_scene_to_file("res://scenes/ui/Achievements.tscn"); await frames()
		if not await capture("achievements_" + locale): printerr("FAIL achievements"); quit(1); return
		change_scene_to_file("res://scenes/ui/ChallengeSelection.tscn"); await frames()
		if not await capture("challenges_" + locale): printerr("FAIL challenges"); quit(1); return
		change_scene_to_file("res://scenes/ui/MainMenu.tscn"); await frames()
		current_scene._settings(); await frames()
		if not await capture("settings_" + locale): printerr("FAIL settings"); quit(1); return
	print("PASS themed localization X11 fixtures"); quit()
