extends Node2D

# Shared by bodies and previews. Experimental art is not cleared for commercial use.
static var warned_missing: Dictionary = {}
enum Expression { NORMAL, HAPPY, SURPRISE }
var expression: Expression = Expression.NORMAL:
	set(value):
		expression = value
		queue_redraw()
var data: AnimalData:
	set(value):
		data = value
		queue_redraw()

func _draw() -> void:
	if data == null:
		return
	var r := data.radius
	var texture: Texture2D = data.sprite
	if expression == Expression.HAPPY and data.happy_sprite:
		texture = data.happy_sprite
	elif expression == Expression.SURPRISE and data.surprise_sprite:
		texture = data.surprise_sprite
	if texture:
		draw_texture_rect(texture, Rect2(-r, -r, r * 2.0, r * 2.0), false)
		return
	if OS.is_debug_build() and not warned_missing.has(data.id):
		warned_missing[data.id] = true
		push_warning("Missing experimental sprite for %s: using diagnostic fallback" % data.id)
	draw_circle(Vector2.ZERO, r, Color("60483e"))
	draw_circle(Vector2.ZERO, r - 2.0, data.placeholder_color)
	draw_circle(Vector2(-r * 0.30, -r * 0.08), maxf(r * 0.10, 2.0), Color("40342f"))
	draw_circle(Vector2(r * 0.30, -r * 0.08), maxf(r * 0.10, 2.0), Color("40342f"))
	draw_arc(Vector2(0, r * 0.12), r * 0.16, 0.1, PI - 0.1, 12, Color("60483e"), 2.0)
