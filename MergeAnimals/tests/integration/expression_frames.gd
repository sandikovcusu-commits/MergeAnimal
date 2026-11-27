extends SceneTree
# Frame selection and lifecycle regression; not a human visual assessment.
const ANIMAL = preload("res://scenes/animals/Animal.tscn")
const NAMES = ["mouse", "hamster", "rabbit", "cat", "dog", "fox", "raccoon", "koala", "panda", "bear", "lion", "elephant"]
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var failures := 0
	for id in NAMES:
		var data: AnimalData = load("res://resources/animals/%s.tres" % id)
		var body: Animal = ANIMAL.instantiate()
		body.data = data
		root.add_child(body)
		await process_frame
		body.visual._on_reduced_effects_changed(false)
		body.visual.set_process(false)
		var shape: CircleShape2D = body.circle.shape
		var radius := shape.radius
		var correct: bool = data.sprite != null and data.blink_sprite != null and data.happy_sprite != null and data.surprise_sprite != null
		body.visual.blink_left = 0.0
		correct = correct and body.visual._texture_for_expression() == data.sprite
		body.visual.next_blink = 0.0
		body.visual._process(0.01)
		correct = correct and body.visual.blink_left > 0 and body.visual._texture_for_expression() == data.blink_sprite
		body.visual.animate_action("merge")
		correct = correct and body.visual._texture_for_expression() == data.happy_sprite
		body.visual.animate_action("drop")
		correct = correct and body.visual._texture_for_expression() == data.surprise_sprite
		correct = correct and shape.radius == radius and body.mass == data.body_mass
		body.visual._on_reduced_effects_changed(true)
		correct = correct and body.visual.expression == 0 and body.visual.blink_left == 0.0 and body.visual.scale == Vector2.ONE and body.visual._texture_for_expression() == data.sprite
		if not correct: failures += 1
		print("%s expression frames, collision invariants and reduced reset: %s" % [id, "PASS" if correct else "FAIL"])
		body.queue_free()
		await process_frame
	print("EXPRESSION_FRAMES total=%d failures=%d" % [NAMES.size(), failures])
	quit(1 if failures else 0)
