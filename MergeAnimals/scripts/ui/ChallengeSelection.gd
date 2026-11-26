extends Control
const FOREST := preload("res://assets/backgrounds/forest_garden.svg")
const THEME := preload("res://assets/ui/themes/forest.tres")
var buttons: Array[Button] = []
var status_label: Label
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SettingsStore.apply(SettingsStore.load_values())
	theme = THEME
	var title := Label.new(); title.text = tr("CHALLENGE_SELECT"); title.position = Vector2(60, 100); title.size = Vector2(600, 65)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size", 36); title.add_theme_color_override("font_color", Color("334b36")); add_child(title)
	var card := PanelContainer.new(); card.position = Vector2(65, 205); card.size = Vector2(590, 930); add_child(card)
	var margins := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]: margins.add_theme_constant_override(side, 25)
	card.add_child(margins)
	var list := VBoxContainer.new(); list.add_theme_constant_override("separation", 12); margins.add_child(list)
	var loaded := ChallengeStore.load_results()
	var available: bool = loaded.status in ["ok", "recovered", "missing"]
	for def in ChallengeManager.DEFINITIONS:
		var unlocked := available and ChallengeStore.is_unlocked(loaded.data, def.id)
		var b := Button.new(); b.name = "Challenge%02d" % def.id; b.custom_minimum_size.y = 110
		b.add_theme_font_size_override("font_size", 21)
		var state := tr("CH_LOCKED") if not unlocked else (tr("CH_COMPLETED") if loaded.data.entries[def.id - 1].completed else tr("CH_READY"))
		b.text = "%02d  %s  ·  %s\n%s" % [def.id, tr(def.title_key), state, tr(def.objective_key)]
		b.disabled = not unlocked; list.add_child(b); buttons.append(b)
		b.pressed.connect(_start.bind(def.id))
	status_label = Label.new(); status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 65; status_label.text = "" if available else tr("CH_SAVE_UNAVAILABLE"); list.add_child(status_label)
	var back := Button.new(); back.name = "Back"; back.text = tr("BACK"); back.custom_minimum_size.y = 65; list.add_child(back)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn"))
func _start(id: int) -> void:
	var loaded := ChallengeStore.load_results()
	if loaded.status not in ["ok", "recovered", "missing"] or not ChallengeStore.is_unlocked(loaded.data, id):
		status_label.text = tr("CH_SAVE_UNAVAILABLE"); return
	get_tree().set_meta("challenge_id", id)
	if get_tree().has_meta("continue_requested"): get_tree().remove_meta("continue_requested")
	if get_tree().has_meta("tutorial_requested"): get_tree().remove_meta("tutorial_requested")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game/ChallengeGame.tscn")
func _draw() -> void:
	draw_texture_rect(FOREST, Rect2(0, 0, 720, 1280), false)
