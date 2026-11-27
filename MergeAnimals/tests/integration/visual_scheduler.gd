extends SceneTree
# Shared cosmetic ticker lifecycle, pause and reduced-mode checks; physics is
# validated separately in expression_frames.gd and the gameplay suite.
const ANIMAL := preload("res://scenes/animals/Animal.tscn")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", message])
	if not ok: failures += 1
func run() -> void:
	var original := AnimalVisualScheduler.visuals.size()
	var body: Animal = ANIMAL.instantiate()
	body.data = load("res://resources/animals/mouse.tres")
	root.add_child(body)
	await process_frame
	body.visual._on_reduced_effects_changed(false)
	body.visual.next_blink = 99.0
	check(AnimalVisualScheduler.visuals.size() == original + 1 and AnimalVisualScheduler.visuals.has(body.visual), "animal registered exactly once")
	check(not body.visual.is_processing() and AnimalVisualScheduler.is_processing(), "one shared ticker; individual callback disabled")
	var phase: float = body.visual.idle_phase
	for i in range(3): await process_frame
	check(body.visual.idle_phase > phase, "shared ticker advances cosmetic phase")
	paused = true
	phase = body.visual.idle_phase
	for i in range(3): await process_frame
	check(is_equal_approx(body.visual.idle_phase, phase), "pause freezes cosmetics")
	paused = false
	body.visual._on_reduced_effects_changed(true)
	check(not AnimalVisualScheduler.visuals.has(body.visual) and body.visual.scale == Vector2.ONE, "reduced mode unregisters and resets")
	body.visual._on_reduced_effects_changed(false)
	check(AnimalVisualScheduler.visuals.has(body.visual), "restoring normal effects re-registers")
	body.queue_free()
	await process_frame
	check(AnimalVisualScheduler.visuals.size() == original, "freeing body unregisters scheduler reference")
	print("VISUAL_SCHEDULER checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
