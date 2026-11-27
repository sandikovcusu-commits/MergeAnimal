extends Control
const FOREST := preload("res://assets/backgrounds/forest_garden.svg")
const THEME := preload("res://assets/ui/themes/forest.tres")
const DESIGN := preload("res://scripts/ui/GardenDesign.gd")
var progress: Dictionary
var rows: Array[Control] = []
func _ready() -> void:
	SettingsStore.apply(SettingsStore.load_values())
	theme = ThemeStore.ui_theme()
	progress = SessionSave.load_progression()
	var background := TextureRect.new(); background.texture = ThemeStore.background(); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; background.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(background)
	var heading := Label.new(); heading.position = Vector2(60, 45); heading.size = Vector2(600, 55); heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; heading.text = tr("STATISTICS"); heading.add_theme_font_size_override("font_size", 38); heading.add_theme_color_override("font_color", Color("263e2b")); add_child(heading)
	if SessionSave.load_document().status in ["corrupt", "future", "io_error"]:
		var warning := Label.new(); warning.position = Vector2(100, 300); warning.size = Vector2(520, 180); warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; warning.text = tr("DATA_UNAVAILABLE"); warning.add_theme_font_size_override("font_size", 26); warning.add_theme_color_override("font_color", Color("263e2b")); add_child(warning)
		_add_back()
		return
	var panel := PanelContainer.new(); panel.position = Vector2(75, 130); panel.size = Vector2(570, 970); add_child(panel)
	panel.add_theme_stylebox_override("panel", DESIGN.surface(ThemeStore.current_index()))
	var margins := MarginContainer.new(); margins.add_theme_constant_override("margin_left", 22); margins.add_theme_constant_override("margin_right", 22); margins.add_theme_constant_override("margin_top", 15); panel.add_child(margins)
	var scroll := ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; margins.add_child(scroll)
	TouchScroll.install(scroll)
	var list := VBoxContainer.new(); list.name = "StatisticsRows"; list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; list.add_theme_constant_override("separation", 8); scroll.add_child(list)
	var discovered := Progression.discovered(progress)
	var highest := "—" if int(progress.highest_animal) == 0 else CollectionNames.name_for_level(int(progress.highest_animal))
	var values := [["TOTAL_GAMES", int(progress.total_games)], ["COMPLETED_GAMES", int(progress.completed_games)], ["TOTAL_DROPS", int(progress.total_drops)], ["TOTAL_MERGES", int(progress.total_merges)], ["BEST_SCORE", int(progress.best_score)], ["HIGHEST_ANIMAL", highest], ["MAX_COMBO", int(progress.max_combo)], ["GOLDEN_MERGES", int(progress.golden_merges)], ["PLAY_TIME", _format_time(float(progress.play_seconds))], ["DISCOVERED", "%d / 12" % discovered], ["COMPLETION", "%d%%" % roundi(discovered * 100.0 / 12.0)]]
	for pair in values: _add_row(list, tr(pair[0]), str(pair[1]))
	var section := Label.new(); section.text = tr("ANIMAL_COUNTS"); section.add_theme_font_size_override("font_size", 25); section.add_theme_color_override("font_color", DESIGN.INK); list.add_child(section)
	for i in range(12): _add_row(list, CollectionNames.name_for_level(i + 1), str(int(progress.animals[Progression.IDS[i]].count)))
	_add_back()
func _add_row(list: VBoxContainer, key: String, value: String) -> void:
	var card := PanelContainer.new(); card.custom_minimum_size.y = 58
	var index := ThemeStore.current_index()
	card.add_theme_stylebox_override("panel", DESIGN._box(DESIGN.SECONDARY[index], DESIGN.BORDER_COLORS[index], 10))
	list.add_child(card); rows.append(card)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 12); card.add_child(row)
	var title := Label.new(); title.text = key; title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; title.add_theme_font_size_override("font_size", 22); title.add_theme_color_override("font_color", DESIGN.INK); row.add_child(title)
	var number := Label.new(); number.text = value; number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; number.add_theme_font_size_override("font_size", 23); number.add_theme_color_override("font_color", DESIGN.PRIMARY[index]); row.add_child(number)
func _add_back() -> void:
	var back := Button.new(); back.name = "Back"; back.text = tr("BACK"); back.position = Vector2(210, 1160); back.size = Vector2(300, 65); DESIGN.menu_button(back, ThemeStore.current_index()); add_child(back); back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn"))
func _format_time(seconds: float) -> String:
	var n := int(seconds)
	return "%02d:%02d:%02d" % [n / 3600, (n / 60) % 60, n % 60]
