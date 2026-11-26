extends SceneTree
# Historical save fixtures test migration only; no synthetic result is gameplay evidence.
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1; print("%s: %s" % ["PASS" if ok else "FAIL", text])
	if not ok: failures += 1
func frames(n := 3) -> void:
	for i in range(n): await process_frame
func run() -> void:
	if OS.get_environment("THEME_PHASE") == "read":
		var saved := ThemeStore.load_state()
		check(saved.status in ["ok", "recovered"] and saved.data.selected == "snow" and saved.data.unlocked.size() == 3, "separate process restores selection and unlocks")
		print("THEME_READ checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0); return
	for path in [ThemeStore.PATH, SessionSave.PATH, SessionSave.POWERUP_PATH, ChallengeStore.PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	var start := ThemeStore.refresh()
	check(start.status == "ok" and start.data.selected == "forest" and start.data.unlocked == ["forest"], "forest default; other themes locked")
	check(ThemeStore.select("sunset") != OK and ThemeStore.select("snow") != OK, "locked theme application rejected")
	change_scene_to_file("res://scenes/ui/MainMenu.tscn"); await frames()
	var button := current_scene.find_child("Themes", true, false) as Button
	check(button != null and not button.disabled, "themes button accessible from main menu")
	if button != null: button.pressed.emit(); await frames()
	check(current_scene.scene_file_path.ends_with("ThemeSelection.tscn") and current_scene.buttons[1].disabled and current_scene.buttons[2].disabled, "theme selection shows locked cards")
	var old := Progression.empty(500)
	check(SessionSave.clear_session(old) == OK, "write old score migration fixture")
	var ch := ChallengeStore.empty()
	for i in range(9): ch.entries[i].completed = true
	check(SaveManager.save_progress(ch, ChallengeStore.PATH) == OK, "write nine challenge migration fixture")
	var nine := ThemeStore.refresh()
	check("sunset" in nine.data.unlocked and "snow" not in nine.data.unlocked, "500 opens sunset, nine challenges do not open snow")
	check(ThemeStore.select("sunset") == OK and ThemeStore.current_index() == 1, "sunset applies")
	ch.entries[9].completed = true
	check(SaveManager.save_progress(ch, ChallengeStore.PATH) == OK, "write ten challenge historical fixture")
	var ten := ThemeStore.refresh()
	check("snow" in ten.data.unlocked and ThemeStore.select("snow") == OK and ThemeStore.current_index() == 2, "ten distinct opens and applies snowy")
	for id in ThemeStore.IDS:
		check(ThemeStore.select(id) == OK, "select " + id)
		change_scene_to_file("res://scenes/game/Game.tscn"); await frames()
		var game = current_scene
		check(game.visual_theme == ThemeStore.IDS.find(id) and game.get_node("HUD").theme == ThemeStore.ui_theme(), "game applies visual theme " + id)
		check(game.left_bound == 91.0 and game.right_bound == 629.0 and game.floor_height == 1094.0, "physics bounds unchanged " + id)
	check(ThemeStore.select("snow") == OK, "save snowy for separate process")
	print("THEME checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
