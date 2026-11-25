extends Node2D
# Six lightweight procedural, non-interactive effects. No collision or textures.
const KINDS := ["sparkle", "soft_burst", "golden_glow", "leaves", "score_star", "combo_shine"]
var effect_kind := "sparkle"
var elapsed := 0.0
var duration := 0.7
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 6
func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
	else:
		queue_redraw()
func _draw() -> void:
	var t := clampf(elapsed / duration, 0.0, 1.0)
	var alpha := 1.0 - t
	match effect_kind:
		"sparkle", "combo_shine":
			var color := Color(1.0, 0.88, 0.48, alpha)
			for i in range(8):
				var angle := TAU * i / 8.0 + t * 0.25
				var unit := Vector2.from_angle(angle)
				var distance := 16.0 + t * 35.0
				draw_line(unit * distance, unit * (distance + 10.0 * alpha), color, 3.0)
		"soft_burst":
			draw_arc(Vector2.ZERO, 12.0 + 35.0 * t, 0.0, TAU, 40, Color(1.0, 0.90, 0.65, alpha * 0.65), 4.0)
		"golden_glow":
			for i in range(3):
				draw_arc(Vector2.ZERO, 25.0 + 22.0 * i + 20.0 * t, 0.0, TAU, 48, Color(1.0, 0.74, 0.18, alpha * 0.5), 5.0)
		"leaves":
			for i in range(5):
				var a := TAU * i / 5.0 + t
				var center := Vector2.from_angle(a) * (14.0 + 42.0 * t) + Vector2(0, 16 * t * t)
				draw_circle(center, 4.5, Color(0.45, 0.7, 0.32, alpha))
		"score_star":
			var points := PackedVector2Array()
			for i in range(10):
				var radius := 12.0 if i % 2 == 0 else 5.5
				points.append(Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * radius + Vector2(0, -24 * t))
			draw_colored_polygon(points, Color(1.0, 0.82, 0.32, alpha))
