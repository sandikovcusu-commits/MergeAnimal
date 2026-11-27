extends Control
signal closed
signal replay_requested
signal settings_changed(values: Dictionary)
var values: Dictionary
var sliders: Dictionary = {}
var mute_toggle: CheckBox
var reduced_toggle: CheckBox
var language_select: OptionButton
var slider_touch_id := -1
var slider_touch_key := ""
var slider_touch_original := 0.0
const DESIGN := preload("res://scripts/ui/GardenDesign.gd")
const LOCALES := ["en", "az", "tr", "ru"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# HUD may be a Control child of Node2D with zero layout size. Use the
	# project logical canvas explicitly and draw above the pause overlay.
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = Vector2(720, 1280)
	z_index = 20
	mouse_filter = Control.MOUSE_FILTER_STOP
	values = SettingsStore.load_values()
	SettingsStore.apply(values)
	_build()
	# Godot's Slider uses mouse emulation for touch, disabled for gameplay.
	# Track touch explicitly without changing global input emulation.
	var guard := get_node_or_null("/root/WebTouchGuard")
	if guard and guard.has_signal("touch_cancelled"): guard.touch_cancelled.connect(_cancel_slider_touch)
	get_tree().root.size_changed.connect(_cancel_slider_touch)

func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.10, 0.16, 0.12, 0.78)
	shade.position = Vector2.ZERO
	shade.size = Vector2(720, 1280)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var card := PanelContainer.new()
	card.name = "SettingsCard"
	card.position = Vector2(75, 170)
	card.size = Vector2(570, 940)
	card.add_theme_stylebox_override("panel", DESIGN.surface(ThemeStore.current_index()))
	add_child(card)
	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]: margin.add_theme_constant_override(side, 24)
	card.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	var title := Label.new(); title.text = "SETTINGS"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36); title.add_theme_color_override("font_color", DESIGN.INK); column.add_child(title)
	for entry in [["MASTER_VOLUME", "master"], ["MUSIC_VOLUME", "music"], ["SFX_VOLUME", "sfx"]]:
		var label := Label.new(); label.text = entry[0]; label.add_theme_font_size_override("font_size", 23); label.add_theme_color_override("font_color", DESIGN.INK); column.add_child(label)
		var slider := HSlider.new(); slider.name = entry[1]; slider.min_value = 0; slider.max_value = 1; slider.step = 0.05; slider.value = values[entry[1]]
		slider.custom_minimum_size = Vector2(0, 56); column.add_child(slider); sliders[entry[1]] = slider
		slider.value_changed.connect(_on_slider.bind(entry[1]))
	mute_toggle = CheckBox.new(); mute_toggle.name = "Mute"; mute_toggle.text = "MUTE"; mute_toggle.button_pressed = values.mute
	_style_check(mute_toggle); mute_toggle.add_theme_font_size_override("font_size", 24); mute_toggle.custom_minimum_size.y = 65; column.add_child(mute_toggle); mute_toggle.toggled.connect(_on_toggle.bind("mute"))
	reduced_toggle = CheckBox.new(); reduced_toggle.name = "ReducedEffects"; reduced_toggle.text = "REDUCED_EFFECTS"; reduced_toggle.button_pressed = values.reduced_effects
	_style_check(reduced_toggle); reduced_toggle.add_theme_font_size_override("font_size", 24); reduced_toggle.custom_minimum_size.y = 65; column.add_child(reduced_toggle); reduced_toggle.toggled.connect(_on_toggle.bind("reduced_effects"))
	var language_label := Label.new(); language_label.text = "LANGUAGE"; language_label.add_theme_font_size_override("font_size", 23); language_label.add_theme_color_override("font_color", DESIGN.INK); column.add_child(language_label)
	language_select = OptionButton.new(); language_select.name = "Language"; language_select.custom_minimum_size.y = 70; language_select.add_theme_font_size_override("font_size", 24)
	for option in ["English", "Azərbaycanca", "Türkçe", "Русский"]: language_select.add_item(option)
	DESIGN.menu_button(language_select, ThemeStore.current_index()); language_select.select(LOCALES.find(values.language)); column.add_child(language_select); language_select.item_selected.connect(_on_language)
	var popup := language_select.get_popup()
	popup.add_theme_stylebox_override("panel", DESIGN.surface(ThemeStore.current_index()))
	popup.add_theme_stylebox_override("hover", DESIGN.surface(ThemeStore.current_index(), true))
	popup.add_theme_color_override("font_color", DESIGN.INK)
	popup.add_theme_color_override("font_hover_color", DESIGN.INK)
	var replay := Button.new(); replay.name = "ReplayTutorial"; replay.text = "REPLAY_TUTORIAL"; replay.custom_minimum_size.y = 70; replay.add_theme_font_size_override("font_size", 24)
	replay.icon = load("res://assets/ui/icons/restart.svg"); DESIGN.menu_button(replay, ThemeStore.current_index()); column.add_child(replay); replay.pressed.connect(func(): replay_requested.emit())
	var back := Button.new(); back.name = "Back"; back.text = "BACK"; back.icon = load("res://assets/ui/icons/back.svg"); back.custom_minimum_size.y = 70; back.add_theme_font_size_override("font_size", 24)
	DESIGN.menu_button(back, ThemeStore.current_index()); column.add_child(back); back.pressed.connect(_close)

func _style_check(toggle: CheckBox) -> void:
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		toggle.add_theme_color_override(state, DESIGN.INK)

# Preview a single touch/drag, commit only on valid release. A browser
# touchcancel/focus/resize restores the old value and performs no save.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		if event.pressed and slider_touch_id == -1:
			for key in sliders:
				var slider: HSlider = sliders[key]
				if slider.get_global_rect().has_point(event.position):
					slider_touch_id = event.index
					slider_touch_key = key
					slider_touch_original = slider.value
					_preview_slider_touch(event.position)
					break
		elif not event.pressed and event.index == slider_touch_id:
			if event.canceled:
				_cancel_slider_touch()
			else:
				_preview_slider_touch(event.position)
				var key := slider_touch_key
				var value: float = sliders[key].value
				slider_touch_id = -1
				slider_touch_key = ""
				_on_slider(value, key)
	elif event is InputEventScreenDrag and event.index == slider_touch_id:
		_preview_slider_touch(event.position)

func _preview_slider_touch(point: Vector2) -> void:
	if slider_touch_key.is_empty(): return
	var slider: HSlider = sliders[slider_touch_key]
	var rect := slider.get_global_rect()
	if rect.size.x <= 0.0: return
	var ratio := clampf((point.x - rect.position.x) / rect.size.x, 0.0, 1.0)
	slider.set_value_no_signal(slider.min_value + ratio * (slider.max_value - slider.min_value))

func _cancel_slider_touch() -> void:
	if slider_touch_id != -1 and sliders.has(slider_touch_key):
		var slider: HSlider = sliders[slider_touch_key]
		slider.set_value_no_signal(slider_touch_original)
	slider_touch_id = -1
	slider_touch_key = ""

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: _cancel_slider_touch()

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
