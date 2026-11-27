extends Node
## TEST ONLY: injected into a separate QA export, never the standard PCK.
var last_id := -1
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(_delta: float) -> void:
	var raw: Variant = JavaScriptBridge.eval("JSON.stringify(window.__saveQACommand || null)")
	if typeof(raw) != TYPE_STRING: return
	var cmd: Variant = JSON.parse_string(raw)
	if not cmd is Dictionary or int(cmd.get("id", -1)) == last_id: return
	last_id = int(cmd.id)
	var op := str(cmd.get("op", "read"))
	var result: Variant = null
	if op == "burst":
		var count := clampi(int(cmd.get("count", 1)), 1, 100)
		var generations := []
		var errors := []
		for i in range(count):
			var progress := Progression.empty(500 + i)
			progress.total_games = 2
			progress.total_merges = 7
			progress.animals.mouse = {"count": 3, "date": "2024-01-02"}
			var err := SessionSave.clear_session(progress)
			errors.append(err)
			var doc := SessionSave.load_document()
			generations.append(int(doc.get("data", {}).get("generation", -1)))
		result = {"errors": errors, "generations": generations}
	elif op == "other_stores":
		var settings := SettingsStore.DEFAULTS.duplicate()
		settings.master = 0.45; settings.music = 0.35; settings.sfx = 0.25; settings.language = "az"; settings.mute = true
		var a := SettingsStore.save_values(settings)
		var b := ChallengeStore.record_result(1, true, 123, 8.0)
		var c := ThemeStore._save({"version":1, "selected":"sunset", "unlocked":["forest", "sunset"]})
		var ach := {"version":1, "generation":1, "entries":{"A01":{"unlocked":true,"date":"2024-01-02", "progress":1}}}
		var d := SaveManager.save_progress(ach, AchievementManager.CHECKPOINT_PATH, false)
		var e := SaveManager.save_progress(ach, AchievementManager.PATH)
		result = [a,b,c,d,e]
	elif op == "seed_capture":
		var files: Variant = cmd.get("files", {})
		var written := []
		if files is Dictionary:
			for filename in files:
				if not str(filename).begins_with("wild_garden_") or "/" in str(filename): continue
				var f := FileAccess.open("user://" + str(filename), FileAccess.WRITE)
				if f: f.store_string(str(files[filename])); f.close(); written.append(filename)
		result = written
	elif op == "continue":
		get_tree().set_meta("continue_requested", true)
		result = get_tree().change_scene_to_file("res://scenes/game/Game.tscn") == OK
	elif op == "save_live":
		var game := get_tree().current_scene
		if game and game.has_method("save_session"):
			get_tree().paused = true
			result = game.save_session()
	elif op == "local_failure":
		var dir := ProjectSettings.globalize_path(SettingsStore.PATH + ".tmp")
		DirAccess.make_dir_absolute(dir)
		var err := SettingsStore.save_values(SettingsStore.DEFAULTS)
		DirAccess.remove_absolute(dir)
		result = err
	elif op == "corrupt_primary":
		var f := FileAccess.open(SessionSave.PATH, FileAccess.WRITE)
		if f: f.store_string("broken"); f.close(); result = true
	elif op == "legacy_cfg":
		var c := ConfigFile.new(); c.set_value("scores", "best", 501); c.save("user://wild_garden.cfg")
		c = ConfigFile.new(); c.set_value("settings", "language", "tr"); c.set_value("settings", "music", 0.4); c.save("user://wild_garden_settings.cfg")
		result = SaveManager.legacy_seed()
	var state := {"id":last_id, "result":result, "document":SessionSave.load_document(), "progress":SessionSave.load_progression(), "settings":SettingsStore.load_values(), "challenges":ChallengeStore.load_results(), "theme":ThemeStore.load_state(), "achievements":AchievementManager.load_state(), "observer":get_node("/root/SaveDurability").state()}
	JavaScriptBridge.eval("window.__saveQAResult=" + JSON.stringify(state))
