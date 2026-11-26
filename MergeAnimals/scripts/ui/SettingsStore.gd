class_name SettingsStore
extends RefCounted
const PATH := "user://wild_garden_settings.json"
const LEGACY_PATH := "user://wild_garden_settings.cfg"
const DEFAULTS := {"master": 1.0, "music": 1.0, "sfx": 1.0, "mute": false, "reduced_effects": false, "language": "en"}
static func load_values(path: String = PATH) -> Dictionary:
	var values := DEFAULTS.duplicate()
	var saved := SaveManager.load_progress(path)
	if saved.status in ["ok", "recovered"]:
		for key in values: values[key] = saved.data.get(key, values[key])
	elif saved.status == "missing":
		var cfg := ConfigFile.new()
		var legacy := LEGACY_PATH if path == PATH else path
		if cfg.load(legacy) == OK:
			for key in values: values[key] = cfg.get_value("settings", key, values[key])
	for key in ["master", "music", "sfx"]:
		if typeof(values[key]) != TYPE_FLOAT and typeof(values[key]) != TYPE_INT:
			values[key] = 1.0
		values[key] = clampf(float(values[key]), 0.0, 1.0)
	if values.language not in ["en", "az", "tr", "ru"]:
		values.language = "en"
	if typeof(values.mute) != TYPE_BOOL: values.mute = false
	if typeof(values.reduced_effects) != TYPE_BOOL: values.reduced_effects = false
	return values
static func save_values(values: Dictionary, path: String = PATH) -> Error:
	var clean := DEFAULTS.duplicate()
	for key in clean: clean[key] = values.get(key, DEFAULTS[key])
	return SaveManager.save_progress(clean, path)
static func apply(values: Dictionary) -> void:
	ThemeDB.fallback_font = preload("res://assets/fonts/DejaVuSans.ttf")
	UIStrings.install()
	TranslationServer.set_locale(values.language)
	for bus in ["Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "SFX" if bus == "UI" else "Master")
	for entry in [["Master", "master"], ["Music", "music"], ["SFX", "sfx"]]:
		var index := AudioServer.get_bus_index(entry[0])
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, float(values[entry[1]]))))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), values.mute)
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		var manager := tree.root.get_node_or_null("AudioManager")
		if manager: manager.reduced_effects = values.reduced_effects
