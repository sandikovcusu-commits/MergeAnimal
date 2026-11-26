extends SceneTree
# All seeded progress below is visual-only fixture data, not a gameplay claim.
func _initialize() -> void: call_deferred("run")
func frames(n := 3) -> void:
	for i in range(n): await process_frame
func capture(name: String) -> bool:
	await create_timer(0.25, true).timeout; await RenderingServer.frame_post_draw
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
func screenshot(name: String) -> void:
	if not await capture(name): printerr("FAIL visual capture ", name); quit(1)
func clear_files() -> void:
	for path in [AchievementManager.PATH, ChallengeStore.PATH, SessionSave.PATH, SessionSave.POWERUP_PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
func run() -> void:
	clear_files()
	change_scene_to_file("res://scenes/ui/MainMenu.tscn"); await frames()
	await screenshot("main_menu")
	current_scene.find_child("Achievements", true, false).pressed.emit(); await frames()
	await screenshot("locked_screen")
	var partial := Progression.empty(100); partial.total_merges = 30; partial.highest_animal = 1
	partial.animals.mouse = {"count": 1, "date": "2025-01-01"}
	if SessionSave.clear_session(partial) != OK: printerr("FAIL partial fixture"); quit(1); return
	change_scene_to_file("res://scenes/ui/Achievements.tscn"); await frames()
	await screenshot("unlocked_achievement")
	current_scene.scroll.ensure_control_visible(current_scene.cards[12]); await frames()
	await screenshot("progress_bar")
	var complete := Progression.empty(2500); complete.total_merges = 100; complete.golden_merges = 1; complete.max_combo = 5; complete.highest_animal = 12
	for id in Progression.IDS: complete.animals[id] = {"count": 1, "date": "2025-01-01"}
	if SessionSave.clear_session(complete) != OK: printerr("FAIL complete fixture"); quit(1); return
	var ch := ChallengeStore.empty()
	for i in range(10): ch.entries[i].completed = true
	if SaveManager.save_progress(ch, ChallengeStore.PATH) != OK: printerr("FAIL challenge fixture"); quit(1); return
	change_scene_to_file("res://scenes/ui/Achievements.tscn"); await frames()
	await screenshot("completed_collection")
	change_scene_to_file("res://scenes/game/Game.tscn"); await frames()
	var notifier = current_scene.discovery_notifier
	notifier.enqueue_achievement(AchievementManager.definitions()[0]); await frames()
	await screenshot("achievement_notification")
	print("PASS seeded achievement visual fixtures"); quit()
