extends Control
const FOREST := preload("res://assets/backgrounds/forest_garden.svg")
const THEME := preload("res://assets/ui/themes/forest.tres")
var progress: Dictionary
var text_label: Label
func _ready() -> void:
	SettingsStore.apply(SettingsStore.load_values())
	theme = THEME
	progress = SessionSave.load_progression()
	var background := TextureRect.new(); background.texture = FOREST; background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; background.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(background)
	var heading := Label.new(); heading.position = Vector2(60, 45); heading.size = Vector2(600, 55); heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; heading.text = tr("STATISTICS"); heading.add_theme_font_size_override("font_size", 38); heading.add_theme_color_override("font_color", Color("263e2b")); add_child(heading)
	if SessionSave.load_document().status in ["corrupt", "future", "io_error"]:
		var warning := Label.new(); warning.position = Vector2(100, 300); warning.size = Vector2(520, 180); warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; warning.text = tr("DATA_UNAVAILABLE"); warning.add_theme_font_size_override("font_size", 26); warning.add_theme_color_override("font_color", Color("263e2b")); add_child(warning)
		_add_back()
		return
	var panel := PanelContainer.new(); panel.position = Vector2(75, 130); panel.size = Vector2(570, 970); add_child(panel)
	var style := StyleBoxFlat.new(); style.bg_color = Color("304735"); style.set_corner_radius_all(14); panel.add_theme_stylebox_override("panel", style)
	var margins := MarginContainer.new(); margins.add_theme_constant_override("margin_left", 22); margins.add_theme_constant_override("margin_right", 22); margins.add_theme_constant_override("margin_top", 15); panel.add_child(margins)
	var scroll := ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; margins.add_child(scroll)
	text_label = Label.new(); text_label.name = "StatisticsText"; text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; text_label.add_theme_font_size_override("font_size", 24); scroll.add_child(text_label)
	var discovered := Progression.discovered(progress)
	var highest := "—" if int(progress.highest_animal) == 0 else CollectionNames.name_for_level(int(progress.highest_animal))
	var values := [["TOTAL_GAMES", int(progress.total_games)], ["COMPLETED_GAMES", int(progress.completed_games)], ["TOTAL_DROPS", int(progress.total_drops)], ["TOTAL_MERGES", int(progress.total_merges)], ["BEST_SCORE", int(progress.best_score)], ["HIGHEST_ANIMAL", highest], ["MAX_COMBO", int(progress.max_combo)], ["GOLDEN_MERGES", int(progress.golden_merges)], ["PLAY_TIME", _format_time(float(progress.play_seconds))], ["DISCOVERED", "%d / 12" % discovered], ["COMPLETION", "%d%%" % roundi(discovered * 100.0 / 12.0)]]
	var lines: Array[String] = []
	for pair in values: lines.append("%s: %s" % [tr(pair[0]), str(pair[1])])
	lines.append("\n" + tr("ANIMAL_COUNTS"))
	for i in range(12): lines.append("%s: %d" % [CollectionNames.name_for_level(i + 1), int(progress.animals[Progression.IDS[i]].count)])
	text_label.text = "\n\n".join(lines)
	_add_back()
func _add_back() -> void:
	var back := Button.new(); back.name = "Back"; back.text = tr("BACK"); back.position = Vector2(210, 1160); back.size = Vector2(300, 65); add_child(back); back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn"))
func _format_time(seconds: float) -> String:
	var n := int(seconds)
	return "%02d:%02d:%02d" % [n / 3600, (n / 60) % 60, n % 60]
