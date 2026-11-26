extends Control
const FOREST := preload("res://assets/backgrounds/forest_garden.svg")
const THEME := preload("res://assets/ui/themes/forest.tres")
var buttons: Array[Button] = []
var status_label: Label
var scroll: ScrollContainer
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SettingsStore.apply(SettingsStore.load_values())
	theme = THEME
	var loaded := ChallengeStore.load_results()
	var available: bool = loaded.status in ["ok", "recovered", "missing"]
	var completed := 0
	if available:
		for item in loaded.data.entries:
			if item.completed: completed += 1
	var title := Label.new(); title.name = "Progress"; title.text = "%s  %d/%d" % [tr("CHALLENGE_SELECT"), completed, ChallengeStore.COUNT]
	title.position = Vector2(50, 70); title.size = Vector2(620, 65)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 34); title.add_theme_color_override("font_color", Color("334b36")); add_child(title)
	var card := PanelContainer.new(); card.position = Vector2(65, 165); card.size = Vector2(590, 1000); add_child(card)
	var margins := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]: margins.add_theme_constant_override(side, 20)
	card.add_child(margins)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 8); margins.add_child(column)
	scroll = ScrollContainer.new(); scroll.name = "ChallengeScroll"; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; column.add_child(scroll)
	var list := VBoxContainer.new(); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; list.add_theme_constant_override("separation", 8); scroll.add_child(list)
	for def in ChallengeManager.DEFINITIONS:
		if (def.id - 1) % 5 == 0:
			var header := Label.new(); header.name = "Difficulty%d" % def.id
			header.text = tr(["CH_BEGINNER", "CH_INTERMEDIATE", "CH_ADVANCED", "CH_EXPERT"][(def.id - 1) / 5])
			header.add_theme_font_size_override("font_size", 24); list.add_child(header)
		var unlocked := available and ChallengeStore.is_unlocked(loaded.data, def.id)
		var b := Button.new(); b.name = "Challenge%02d" % def.id; b.custom_minimum_size.y = 110
		b.add_theme_font_size_override("font_size", 19)
		var state := tr("CH_LOCKED") if not unlocked else (tr("CH_COMPLETED") if loaded.data.entries[def.id - 1].completed else tr("CH_READY"))
		var stats := ""
		if unlocked:
			var record: Dictionary = loaded.data.entries[def.id - 1]
			var best_time := "—" if float(record.best_time) < 0 else "%d:%02d" % [int(record.best_time) / 60, int(record.best_time) % 60]
			stats = "\n%s %d  ·  %s %s" % [tr("CH_BEST_SCORE"), int(record.best), tr("CH_BEST_TIME"), best_time]
		b.text = "%02d  %s  ·  %s\n%s%s" % [def.id, tr(def.title_key), state, tr(def.objective_key), stats]
		b.disabled = not unlocked; list.add_child(b); buttons.append(b)
		b.pressed.connect(_start.bind(def.id))
	status_label = Label.new(); status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 40; status_label.text = "" if available else tr("CH_SAVE_UNAVAILABLE"); column.add_child(status_label)
	var back := Button.new(); back.name = "Back"; back.text = tr("BACK"); back.custom_minimum_size.y = 55; column.add_child(back)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn"))
func _start(id: int) -> void:
	var loaded := ChallengeStore.load_results()
	if loaded.status not in ["ok", "recovered", "missing"] or id < 1 or id > ChallengeManager.DEFINITIONS.size() or not ChallengeStore.is_unlocked(loaded.data, id):
		status_label.text = tr("CH_SAVE_UNAVAILABLE"); return
	get_tree().set_meta("challenge_id", id)
	if get_tree().has_meta("continue_requested"): get_tree().remove_meta("continue_requested")
	if get_tree().has_meta("tutorial_requested"): get_tree().remove_meta("tutorial_requested")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game/ChallengeGame.tscn")
func _draw() -> void:
	draw_texture_rect(FOREST, Rect2(0, 0, 720, 1280), false)
