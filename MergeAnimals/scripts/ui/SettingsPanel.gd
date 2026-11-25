extends Control
signal closed
signal settings_changed(values: Dictionary)
var values: Dictionary
var sliders: Dictionary = {}
var mute_toggle: CheckBox
var reduced_toggle: CheckBox
var language_select: OptionButton
const LOCALES := ["en", "az", "tr", "ru"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	values = SettingsStore.load_values()
	SettingsStore.apply(values)
	_build()

func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.10, 0.16, 0.12, 0.78)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var card := PanelContainer.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.offset_left = -285; card.offset_right = 285; card.offset_top = -420; card.offset_bottom = 420
	add_child(card)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]: margin.add_theme_constant_override(side, 24)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	var title := Label.new(); title.text = "SETTINGS"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36); column.add_child(title)
	for entry in [["MASTER_VOLUME", "master"], ["MUSIC_VOLUME", "music"], ["SFX_VOLUME", "sfx"]]:
		var label := Label.new(); label.text = entry[0]; label.add_theme_font_size_override("font_size", 23); column.add_child(label)
		var slider := HSlider.new(); slider.name = entry[1]; slider.min_value = 0; slider.max_value = 1; slider.step = 0.05; slider.value = values[entry[1]]
		slider.custom_minimum_size = Vector2(0, 40); column.add_child(slider); sliders[entry[1]] = slider
		slider.value_changed.connect(_on_slider.bind(entry[1]))
	mute_toggle = CheckBox.new(); mute_toggle.name = "Mute"; mute_toggle.text = "MUTE"; mute_toggle.button_pressed = values.mute
	mute_toggle.custom_minimum_size.y = 55; column.add_child(mute_toggle); mute_toggle.toggled.connect(_on_toggle.bind("mute"))
	reduced_toggle = CheckBox.new(); reduced_toggle.name = "ReducedEffects"; reduced_toggle.text = "REDUCED_EFFECTS"; reduced_toggle.button_pressed = values.reduced_effects
	reduced_toggle.custom_minimum_size.y = 55; column.add_child(reduced_toggle); reduced_toggle.toggled.connect(_on_toggle.bind("reduced_effects"))
	var language_label := Label.new(); language_label.text = "LANGUAGE"; language_label.add_theme_font_size_override("font_size", 23); column.add_child(language_label)
	language_select = OptionButton.new(); language_select.name = "Language"; language_select.custom_minimum_size.y = 55
	for option in ["English", "Azərbaycanca", "Türkçe", "Русский"]: language_select.add_item(option)
	language_select.select(LOCALES.find(values.language)); column.add_child(language_select); language_select.item_selected.connect(_on_language)
	var back := Button.new(); back.name = "Back"; back.text = "BACK"; back.icon = load("res://assets/ui/icons/back.svg"); back.custom_minimum_size.y = 66
	column.add_child(back); back.pressed.connect(_close)

func _on_slider(value: float, key: String) -> void:
	values[key] = value
	_commit()
func _on_toggle(value: bool, key: String) -> void:
	values[key] = value
	_commit()
func _on_language(index: int) -> void:
	values.language = LOCALES[index]
	_commit()
func _commit() -> void:
	SettingsStore.apply(values)
	if SettingsStore.save_values(values) != OK:
		push_warning("Settings could not be saved")
	settings_changed.emit(values)
func _close() -> void:
	closed.emit()
	queue_free()
