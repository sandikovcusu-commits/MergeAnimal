extends Control
const FOREST := preload("res://assets/backgrounds/forest_garden.svg")
const THEME := preload("res://assets/ui/themes/forest.tres")
const SETTINGS := preload("res://scenes/ui/SettingsPanel.tscn")
const GAME := "res://scenes/game/Game.tscn"
const DECOR := [preload("res://assets/animals/mouse/normal.png"), preload("res://assets/animals/cat/normal.png"), preload("res://assets/animals/elephant/normal.png")]
var play_button: Button
var settings_button: Button
var best_label: Label
var settings_panel: Control
var navigating := false
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SettingsStore.apply(SettingsStore.load_values())
	theme = THEME
	_build()

func _build() -> void:
	var card := PanelContainer.new()
	card.offset_left = 105; card.offset_right = 615; card.offset_top = 570; card.offset_bottom = 1170
	add_child(card)
	if not bool(SettingsStore.load_values().reduced_effects):
		card.modulate.a = 0.0
		create_tween().tween_property(card, "modulate:a", 1.0, 0.3)
	var margins := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]: margins.add_theme_constant_override(side, 28)
	card.add_child(margins)
	var list := VBoxContainer.new(); list.add_theme_constant_override("separation", 20); margins.add_child(list)
	play_button = _button("Play", "PLAY", "play", 110); list.add_child(play_button); play_button.pressed.connect(_play)
	var collection := _button("Collection", "COLLECTION", "collection", 80); collection.disabled = true; list.add_child(collection)
	var challenges := _button("Challenges", "CHALLENGES", "challenge", 80); challenges.disabled = true; list.add_child(challenges)
	settings_button = _button("Settings", "SETTINGS", "settings", 80); list.add_child(settings_button); settings_button.pressed.connect(_settings)
	best_label = Label.new(); best_label.name = "Best"; best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_label.add_theme_font_size_override("font_size", 27); best_label.add_theme_color_override("font_color", Color("f3ecd7")); list.add_child(best_label)
	_refresh_best()
	play_button.grab_focus()

func _button(node_name: String, key: String, icon: String, height: float) -> Button:
	var button := Button.new(); button.name = node_name; button.text = key
	button.icon = load("res://assets/ui/icons/%s.svg" % icon)
	button.custom_minimum_size.y = height; button.add_theme_font_size_override("font_size", 27)
	button.expand_icon = true; button.add_theme_constant_override("icon_max_width", 44)
	return button

func _refresh_best() -> void:
	var cfg := ConfigFile.new(); var best := 0
	if cfg.load("user://wild_garden.cfg") == OK:
		var saved: Variant = cfg.get_value("scores", "best", 0)
		if typeof(saved) == TYPE_INT: best = maxi(saved, 0)
	best_label.text = "%s  %d" % [tr("BEST_SCORE"), best]
func _play() -> void:
	if navigating or is_instance_valid(settings_panel): return
	navigating = true
	play_button.disabled = true
	var config := ConfigFile.new()
	if config.load("user://wild_garden_tutorial.cfg") != OK or not bool(config.get_value("tutorial", "completed", false)):
		get_tree().set_meta("tutorial_requested", true)
	get_tree().change_scene_to_file(GAME)
func _settings() -> void:
	if is_instance_valid(settings_panel): return
	settings_panel = SETTINGS.instantiate()
	add_child(settings_panel)
	settings_panel.replay_requested.connect(func():
		get_tree().set_meta("tutorial_requested", true)
		get_tree().change_scene_to_file(GAME)
	)
	settings_panel.settings_changed.connect(func(_values: Dictionary): _refresh_best())
	settings_panel.closed.connect(func(): settings_panel = null; settings_button.grab_focus())
func _draw() -> void:
	draw_texture_rect(FOREST, Rect2(0, 0, 720, 1280), false)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, 190), "MERGE ANIMALS", HORIZONTAL_ALIGNMENT_CENTER, 720, 60, Color("334b36"))
	draw_string(font, Vector2(0, 250), "WILD GARDEN", HORIZONTAL_ALIGNMENT_CENTER, 720, 37, Color("73513b"))
	draw_texture_rect(DECOR[0], Rect2(95, 345, 150, 150), false)
	draw_texture_rect(DECOR[1], Rect2(278, 305, 180, 180), false)
	draw_texture_rect(DECOR[2], Rect2(478, 345, 150, 150), false)
