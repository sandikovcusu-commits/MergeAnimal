class_name SettingsStore
extends RefCounted
const PATH := "user://wild_garden_settings.cfg"
const DEFAULTS := {"master": 1.0, "music": 1.0, "sfx": 1.0, "mute": false, "reduced_effects": false, "language": "en"}
static func load_values(path: String = PATH) -> Dictionary:
	var cfg := ConfigFile.new()
	var values := DEFAULTS.duplicate()
	if cfg.load(path) == OK:
		for key in values:
			values[key] = cfg.get_value("settings", key, values[key])
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
	var cfg := ConfigFile.new()
	for key in DEFAULTS:
		cfg.set_value("settings", key, values.get(key, DEFAULTS[key]))
	return cfg.save(path)
static func apply(values: Dictionary) -> void:
	ThemeDB.fallback_font = preload("res://assets/fonts/DejaVuSans.ttf")
	UIStrings.install()
	TranslationServer.set_locale(values.language)
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")
	for entry in [["Master", "master"], ["Music", "music"], ["SFX", "sfx"]]:
		var index := AudioServer.get_bus_index(entry[0])
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.0001, float(values[entry[1]]))))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), values.mute)
