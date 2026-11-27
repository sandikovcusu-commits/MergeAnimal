class_name GardenDesign
extends RefCounted
# Lightweight shared visual tokens. Geometry and input remain the owner's job.
const PANEL_COLORS := [Color("f8f0d9"), Color("fff0d8"), Color("eaf4f3")]
const BORDER_COLORS := [Color("b29b71"), Color("c08d65"), Color("92b1b1")]
const PRIMARY := [Color("416c4c"), Color("9a5a38"), Color("426c7a")]
const SECONDARY := [Color("e9f0da"), Color("f8e3cc"), Color("d9eaeb")]
const INK := Color("283a2c")

static func _box(fill: Color, border: Color, radius: int, shadow: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(10)
	if shadow:
		box.shadow_color = Color(0.18, 0.24, 0.16, 0.18)
		box.shadow_size = shadow
		box.shadow_offset = Vector2(0, 4)
	return box

static func surface(index: int, translucent: bool = false) -> StyleBoxFlat:
	var i := clampi(index, 0, 2)
	var color: Color = PANEL_COLORS[i]
	if translucent: color.a = 0.82
	return _box(color, BORDER_COLORS[i], 18, 0 if translucent else 8)

static func menu_button(button: Button, index: int, primary: bool = false) -> void:
	var i := clampi(index, 0, 2)
	var base: Color = PRIMARY[i] if primary else SECONDARY[i]
	var border: Color = PRIMARY[i] if primary else BORDER_COLORS[i]
	button.add_theme_stylebox_override("normal", _box(base, border, 14, 2))
	button.add_theme_stylebox_override("hover", _box(base.lightened(0.10), border, 14, 2))
	button.add_theme_stylebox_override("pressed", _box(base.darkened(0.12), border, 14))
	button.add_theme_stylebox_override("disabled", _box(Color("e1e0d5"), Color("b3b7a5"), 14))
	var text_color := Color("fff9e9") if primary else INK
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, text_color)
	button.add_theme_color_override("font_disabled_color", Color("747a70"))
