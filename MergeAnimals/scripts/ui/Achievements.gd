extends Control
const FOREST := preload("res://assets/backgrounds/forest_garden.svg")
const THEME := preload("res://assets/ui/themes/forest.tres")
var scroll: ScrollContainer
var cards: Array[Control] = []
func _ready() -> void:
	SettingsStore.apply(SettingsStore.load_values()); theme = ThemeStore.ui_theme()
	var sync := AchievementManager.migrate()
	var state: Dictionary = sync.get("data", {})
	var available: bool = sync.status == "ok"
	var defs := AchievementManager.definitions()
	var count := 0
	if available:
		for entry in state.entries.values():
			if entry.unlocked: count += 1
	var heading := Label.new(); heading.name = "Progress"; heading.text = "%s  %d/%d" % [tr("ACHIEVEMENTS").to_upper(), count, defs.size()]
	heading.position = Vector2(50, 60); heading.size = Vector2(620, 60); heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 34); heading.add_theme_color_override("font_color", Color("334b36")); add_child(heading)
	var panel := PanelContainer.new(); panel.position = Vector2(65, 150); panel.size = Vector2(590, 1050); add_child(panel)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]: margin.add_theme_constant_override(side, 18)
	panel.add_child(margin)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 10); margin.add_child(column)
	scroll = ScrollContainer.new(); scroll.name = "AchievementScroll"; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; column.add_child(scroll)
	TouchScroll.install(scroll)
	var list := VBoxContainer.new(); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; list.add_theme_constant_override("separation", 9); scroll.add_child(list)
	if not available:
		var warning := Label.new(); warning.text = tr("ACH_DATA_UNAVAILABLE"); list.add_child(warning)
	else:
		for def in defs:
			var entry: Dictionary = state.entries.get(def.id, {"unlocked": false, "date": "", "progress": 0})
			var card := PanelContainer.new(); card.name = def.id; card.custom_minimum_size.y = 170; list.add_child(card); cards.append(card)
			var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 12); card.add_child(row)
			var icon := TextureRect.new(); icon.texture = def.icon; icon.custom_minimum_size = Vector2(64, 64); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			# The original dark line artwork needs a light backing on dark cards.
			var icon_frame := PanelContainer.new()
			var icon_back := StyleBoxFlat.new(); icon_back.bg_color = Color("c8ddcb") if not entry.unlocked else Color("f5dd9b")
			icon_frame.add_theme_stylebox_override("panel", icon_back)
			icon_frame.add_child(icon); row.add_child(icon_frame)
			var stack := VBoxContainer.new(); stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(stack)
			var label := Label.new(); label.name = "Details"; label.add_theme_font_size_override("font_size", 23); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var name := "???" if def.hidden and not entry.unlocked else def.localized_title()
			var description := tr("ACH_HIDDEN") if def.hidden and not entry.unlocked else def.localized_description()
			var date := " · " + str(entry.date).substr(0, 10) if entry.unlocked and not str(entry.date).is_empty() else ""
			label.text = "%s · %s%s\n%s\n%d / %d" % [name, tr("UNLOCKED") if entry.unlocked else tr("LOCKED"), date, description, int(entry.progress), def.target]; stack.add_child(label)
			var bar := ProgressBar.new(); bar.name = "ProgressBar"; bar.max_value = def.target; bar.value = entry.progress; bar.show_percentage = false; bar.custom_minimum_size.y = 14; stack.add_child(bar)
	var back := Button.new(); back.name = "Back"; back.text = tr("BACK"); back.custom_minimum_size.y = 60; column.add_child(back)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn"))
func _draw() -> void: draw_texture_rect(ThemeStore.background(), Rect2(0, 0, 720, 1280), false)
