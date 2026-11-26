extends Control
var buttons: Array[Button] = []
var status: Label
func _ready() -> void:
	SettingsStore.apply(SettingsStore.load_values())
	theme = ThemeStore.ui_theme()
	_build()
func _build() -> void:
	var loaded := ThemeStore.refresh()
	var available: bool = loaded.status == "ok"
	var state: Dictionary = loaded.get("data", ThemeStore.empty())
	var title := Label.new(); title.position = Vector2(60, 55); title.size = Vector2(600, 60); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36); title.add_theme_color_override("font_color", Color("263e2b")); title.text = tr("THEMES"); add_child(title)
	var panel := PanelContainer.new(); panel.position = Vector2(65, 145); panel.size = Vector2(590, 1040); add_child(panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]: margin.add_theme_constant_override(side, 18)
	panel.add_child(margin)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 9); margin.add_child(column)
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; column.add_child(scroll)
	var list := VBoxContainer.new(); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; list.add_theme_constant_override("separation", 12); scroll.add_child(list)
	for i in range(3):
		var id: String = ThemeStore.IDS[i]; var unlocked: bool = available and id in state.unlocked
		var card := PanelContainer.new(); card.custom_minimum_size.y = 270; list.add_child(card)
		var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
		var preview := TextureRect.new(); preview.texture = ThemeStore.BACKGROUNDS[i]; preview.custom_minimum_size = Vector2(120, 200); preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; row.add_child(preview)
		var stack := VBoxContainer.new(); stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(stack)
		var info := Label.new(); info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; info.add_theme_font_size_override("font_size", 23)
		info.text = "%s\n%s\n%s" % [tr(["THEME_FOREST", "THEME_SUNSET", "THEME_SNOW"][i]), tr(["THEME_DEFAULT", "THEME_SCORE", "THEME_CHALLENGES"][i]), tr("THEME_SELECTED") if state.selected == id else tr("UNLOCKED") if unlocked else tr("LOCKED")]; stack.add_child(info)
		var apply := Button.new(); apply.name = "Apply_" + id; apply.text = tr("THEME_APPLY"); apply.custom_minimum_size.y = 60; apply.disabled = not unlocked or state.selected == id; stack.add_child(apply); buttons.append(apply)
		apply.pressed.connect(_select.bind(id))
	status = Label.new(); status.name = "Status"; status.text = "" if available else tr("DATA_UNAVAILABLE"); status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; column.add_child(status)
	var back := Button.new(); back.name = "Back"; back.text = tr("BACK"); back.custom_minimum_size.y = 60; column.add_child(back); back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn"))
func _select(id: String) -> void:
	if ThemeStore.select(id) != OK: status.text = tr("SAVE_FAILED"); return
	FeelAudio.set_music(id)
	get_tree().reload_current_scene()
func _draw() -> void: draw_texture_rect(ThemeStore.background(), Rect2(0, 0, 720, 1280), false)
