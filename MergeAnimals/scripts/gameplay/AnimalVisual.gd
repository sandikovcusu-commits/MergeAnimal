extends Node2D

# Shared by bodies, current preview and next preview. Temporary diagnostic art.
var data: AnimalData:
	set(value):
		data = value
		queue_redraw()

func _draw() -> void:
	if data == null:
		return
	var r := data.radius
	if data.sprite:
		draw_texture_rect(data.sprite, Rect2(-r, -r, r * 2.0, r * 2.0), false)
		return
	draw_circle(Vector2.ZERO, r, Color("60483e"))
	draw_circle(Vector2.ZERO, r - 2.0, data.placeholder_color)
	draw_circle(Vector2(-r * 0.30, -r * 0.08), maxf(r * 0.10, 2.0), Color("40342f"))
	draw_circle(Vector2(r * 0.30, -r * 0.08), maxf(r * 0.10, 2.0), Color("40342f"))
	draw_arc(Vector2(0, r * 0.12), r * 0.16, 0.1, PI - 0.1, 12, Color("60483e"), 2.0)
