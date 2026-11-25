extends Control
const FOREST := preload("res://assets/backgrounds/forest_garden.svg")
const THEME := preload("res://assets/ui/themes/forest.tres")
const IDS := Progression.IDS
var progress: Dictionary
var cards: Array[Button] = []
var detail: PanelContainer
var detail_label: Label
var detail_image: TextureRect
var detail_close: Button
var scroll: ScrollContainer

func _ready() -> void:
	SettingsStore.apply(SettingsStore.load_values())
	theme = THEME
	progress = SessionSave.load_progression()
	_build()

func _build() -> void:
	var background := TextureRect.new(); background.texture = FOREST; background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; background.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(background)
	var heading := Label.new(); heading.position = Vector2(80, 38); heading.size = Vector2(560, 55); heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; heading.add_theme_font_size_override("font_size", 36); heading.add_theme_color_override("font_color", Color("263e2b")); heading.text = tr("COLLECTION_TITLE"); add_child(heading)
	if SessionSave.load_document().status in ["corrupt", "future", "io_error"]:
		var warning := Label.new(); warning.position = Vector2(100, 300); warning.size = Vector2(520, 180); warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; warning.text = tr("DATA_UNAVAILABLE"); warning.add_theme_font_size_override("font_size", 26); warning.add_theme_color_override("font_color", Color("263e2b")); add_child(warning)
		_add_back()
		return
	var progress_text := Label.new(); progress_text.position = Vector2(80, 108); progress_text.size = Vector2(560, 35); progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; progress_text.add_theme_font_size_override("font_size", 24); progress_text.add_theme_color_override("font_color", Color("263e2b")); progress_text.text = "%s  %d / 12" % [tr("DISCOVERED"), Progression.discovered(progress)]; add_child(progress_text)
	var bar := ProgressBar.new(); bar.position = Vector2(110, 150); bar.size = Vector2(500, 24); bar.max_value = 12; bar.value = Progression.discovered(progress); bar.show_percentage = false; add_child(bar)
	scroll = ScrollContainer.new(); scroll.name = "CollectionScroll"; scroll.position = Vector2(55, 195); scroll.size = Vector2(610, 938); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; add_child(scroll)
	var grid := GridContainer.new(); grid.name = "AnimalGrid"; grid.columns = 3; grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL; grid.add_theme_constant_override("h_separation", 8); grid.add_theme_constant_override("v_separation", 8); scroll.add_child(grid)
	for i in range(12):
		var index := i
		var data := load("res://resources/animals/%s.tres" % IDS[i]) as AnimalData
		var entry: Dictionary = progress.animals[IDS[i]]
		var unlocked := int(entry.count) > 0
		var card := Button.new(); card.name = "AnimalCard%d" % (i + 1); card.custom_minimum_size = Vector2(190, 340); card.size_flags_horizontal = Control.SIZE_EXPAND_FILL; grid.add_child(card); cards.append(card)
		var column := VBoxContainer.new(); column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); column.offset_left = 5; column.offset_right = -5; column.offset_top = 5; column.offset_bottom = -5; column.mouse_filter = Control.MOUSE_FILTER_IGNORE; card.add_child(column)
		var art := TextureRect.new(); art.name = "Sprite"; art.custom_minimum_size = Vector2(100, 86); art.texture = data.sprite; art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not unlocked: art.modulate = Color(0.12, 0.16, 0.13, 0.92)
		column.add_child(art)
		for line in ["%s · %s %d" % [tr(data.translation_key), tr("LEVEL"), i + 1], tr("UNLOCKED") if unlocked else tr("LOCKED"), "%s: %d" % [tr("CREATED"), int(entry.count)], str(entry.date).substr(0, 10) if unlocked else tr("UNDISCOVERED"), tr("ANIMAL_DESC_" + IDS[i].to_upper()) if unlocked else _unlock_hint(i)]:
			var label := Label.new(); label.text = line; label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size", 18); label.add_theme_color_override("font_color", Color("203a28")); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; label.mouse_filter = Control.MOUSE_FILTER_IGNORE; column.add_child(label)
		if not unlocked:
			var lock := TextureRect.new(); lock.name = "Lock"; lock.texture = load("res://assets/ui/icons/lock.svg"); lock.position = Vector2(148, 10); lock.size = Vector2(24, 24); lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; lock.mouse_filter = Control.MOUSE_FILTER_IGNORE; card.add_child(lock)
		card.pressed.connect(func(): _show_detail(index))
	_add_back()
	_build_detail()

func _add_back() -> void:
	var back := Button.new(); back.name = "Back"; back.text = tr("BACK"); back.position = Vector2(210, 1160); back.size = Vector2(300, 65); add_child(back); back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn"))

func _build_detail() -> void:
	detail = PanelContainer.new(); detail.name = "AnimalDetails"; detail.position = Vector2(95, 300); detail.size = Vector2(530, 600); detail.z_index = 10; detail.visible = false; add_child(detail)
	var style := StyleBoxFlat.new(); style.bg_color = Color("304735"); style.set_corner_radius_all(14); style.set_content_margin_all(16); detail.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 12); detail.add_child(column)
	detail_image = TextureRect.new(); detail_image.custom_minimum_size = Vector2(200, 200); detail_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; detail_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; column.add_child(detail_image)
	detail_label = Label.new(); detail_label.name = "DetailText"; detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL; detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; detail_label.add_theme_font_size_override("font_size", 23); column.add_child(detail_label)
	detail_close = Button.new(); detail_close.name = "CloseDetails"; detail_close.text = tr("BACK"); detail_close.custom_minimum_size.y = 64; column.add_child(detail_close); detail_close.pressed.connect(func(): detail.visible = false)

func _show_detail(index: int) -> void:
	var data := load("res://resources/animals/%s.tres" % IDS[index]) as AnimalData
	var entry: Dictionary = progress.animals[IDS[index]]
	var unlocked := int(entry.count) > 0
	detail_image.texture = data.sprite
	detail_image.modulate = Color.WHITE if unlocked else Color(0.12, 0.16, 0.13, 0.92)
	detail_label.text = "%s\n%s %d · %s\n%s: %d\n%s: %s\n\n%s" % [tr(data.translation_key), tr("LEVEL"), index + 1, tr("UNLOCKED") if unlocked else tr("LOCKED"), tr("CREATED"), int(entry.count), tr("FIRST_FOUND"), entry.date if unlocked else "—", tr("ANIMAL_DESC_" + IDS[index].to_upper()) if unlocked else _unlock_hint(index)]
	detail.visible = true

func _unlock_hint(index: int) -> String:
	if index == 0: return tr("UNLOCK_DROP_ONLY")
	return tr("UNLOCK_HINT") if index < 5 else tr("UNLOCK_MERGE_ONLY")
