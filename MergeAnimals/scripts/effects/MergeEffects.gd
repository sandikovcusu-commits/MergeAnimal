extends Node2D
# Six lightweight procedural, non-interactive effects. No collision or textures.
const KINDS := ["sparkle", "soft_burst", "golden_glow", "leaves", "score_star", "combo_shine"]
var effect_kind := "sparkle"
var reduced_visual := false
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
		"sparkle":
			var color := Color(1.0, 0.88, 0.48, alpha)
			for i in range(8):
				var angle := TAU * i / 8.0 + t * 0.25
				var unit := Vector2.from_angle(angle)
				var distance := 16.0 + t * 35.0
				draw_line(unit * distance, unit * (distance + 10.0 * alpha), color, 3.0)
		"combo_shine":
			var shine := Color(1.0, 0.76, 0.20, alpha)
			for i in range(3):
				var offset := Vector2((i - 1) * 18.0, -20.0 - 14.0 * t)
				draw_line(offset + Vector2(-9, 12), offset + Vector2(9, -12), shine, 4.0)
		"soft_burst":
			# Ease out the ring so the contact feels soft, not like an expanding
			# rigid marker. Reduced mode retains only the essential first ring.
			var eased: float = 1.0 - pow(1.0 - t, 3.0)
			var radius := 12.0 + 35.0 * eased
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1.0, 0.90, 0.65, alpha * 0.65), 4.0)
			if not reduced_visual:
				draw_arc(Vector2.ZERO, radius * 0.72, 0.0, TAU, 32, Color(1.0, 0.98, 0.81, alpha * 0.42), 2.0)
		"golden_glow":
			# Bounded procedural halo and rays; no textures, physics, or particles.
			var eased: float = 1.0 - pow(1.0 - t, 2.0)
			draw_circle(Vector2.ZERO, 48.0 + 12.0 * eased, Color(1.0, 0.76, 0.24, alpha * 0.10))
			for i in range(3):
				draw_arc(Vector2.ZERO, 25.0 + 22.0 * i + 20.0 * eased, 0.0, TAU, 48, Color(1.0, 0.74, 0.18, alpha * 0.5), 5.0)
			for i in range(8):
				var unit := Vector2.from_angle(TAU * i / 8.0)
				var distance := 58.0 + 34.0 * eased
				draw_circle(unit * distance, 3.0 * alpha + 1.0, Color(1.0, 0.87, 0.46, alpha * 0.8))
		"leaves":
			for i in range(5):
				var a := TAU * i / 5.0 + t
				var center := Vector2.from_angle(a) * (14.0 + 42.0 * t) + Vector2(0, 16 * t * t)
				var axis := Vector2.from_angle(a + t * 2.0) * 7.0
				var side := axis.rotated(PI / 2.0) * 0.55
				var leaf := PackedVector2Array([center - axis, center + side, center + axis, center - side])
				draw_colored_polygon(leaf, Color(0.45, 0.7, 0.32, alpha))
		"score_star":
			var points := PackedVector2Array()
			for i in range(10):
				var radius := 12.0 if i % 2 == 0 else 5.5
				points.append(Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * radius + Vector2(0, -24 * t))
			draw_colored_polygon(points, Color(1.0, 0.82, 0.32, alpha))
