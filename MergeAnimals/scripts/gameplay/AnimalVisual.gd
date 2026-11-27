extends Node2D
# Cosmetic animation only. Physics body and collision shape never change size.
static var warned_missing: Dictionary = {}
enum AnimalExpression { NORMAL, HAPPY, SURPRISE }
var expression: AnimalExpression = AnimalExpression.NORMAL:
	set(value):
		expression = value
		queue_redraw()
var data: AnimalData:
	set(value):
		data = value
		queue_redraw()
var idle_phase := 0.0
var blink_left := 0.0
var blink_duration := 0.15
var next_blink := 0.0
var action_tween: Tween
var reduced := false
var audio_manager: Node

func _ready() -> void:
	idle_phase = randf_range(0.0, TAU)
	next_blink = randf_range(3.0, 8.0)
	blink_duration = randf_range(0.12, 0.18)
	audio_manager = get_node_or_null("/root/AudioManager")
	if audio_manager: reduced = audio_manager.reduced_effects
	# Previews stay static. Bodies subscribe once, instead of polling the
	# global setting on every rendered frame when Reduced Effects is enabled.
	if get_parent() is Animal and audio_manager:
		audio_manager.reduced_effects_changed.connect(_on_reduced_effects_changed)
	set_process(get_parent() is Animal and not reduced)

func _process(delta: float) -> void:
	idle_phase += delta * 1.5
	next_blink -= delta
	if next_blink <= 0.0:
		blink_duration = randf_range(0.12, 0.18)
		blink_left = blink_duration
		next_blink = randf_range(3.0, 8.0)
	if blink_left > 0.0: blink_left = maxf(0.0, blink_left - delta)
	if not action_tween or not action_tween.is_running():
		# Without per-sprite eye layers this is a gentle whole-sprite blink cue,
		# not a fabricated or occluding eyelid texture.
		var blink := sin(PI * (1.0 - blink_left / blink_duration)) * 0.045 if blink_left > 0.0 else 0.0
		var breathe := sin(idle_phase) * 0.012
		scale = Vector2(1.0 + breathe + blink, 1.0 - breathe - blink)

func _on_reduced_effects_changed(value: bool) -> void:
	reduced = value
	if reduced:
		if action_tween and action_tween.is_running(): action_tween.kill()
		scale = Vector2.ONE
		expression = AnimalExpression.NORMAL
	set_process(not reduced and get_parent() is Animal)

func animate_action(kind: String) -> void:
	if reduced: return
	if action_tween and action_tween.is_running(): action_tween.kill()
	var target := Vector2(1.1, 0.88) if kind == "landing" else Vector2(0.88, 1.12) if kind == "drop" else Vector2(0.72, 0.72) if kind == "merge" else Vector2(1.05, 0.95)
	expression = AnimalExpression.HAPPY if kind in ["merge", "happy"] else AnimalExpression.SURPRISE if kind in ["drop", "surprise"] else AnimalExpression.NORMAL
	scale = target
	action_tween = create_tween()
	action_tween.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	action_tween.tween_callback(_end_action)

func _end_action() -> void:
	expression = AnimalExpression.NORMAL

func _exit_tree() -> void:
	if action_tween and action_tween.is_running(): action_tween.kill()
	action_tween = null

func _draw() -> void:
	if data == null: return
	var r := data.radius
	var texture: Texture2D = data.sprite
	if expression == AnimalExpression.HAPPY and data.happy_sprite: texture = data.happy_sprite
	elif expression == AnimalExpression.SURPRISE and data.surprise_sprite: texture = data.surprise_sprite
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
