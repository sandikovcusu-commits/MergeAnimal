extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, name: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", name])
	if not ok: failures += 1
func touch_event(game: Node, down: bool, x: float) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0; event.pressed = down; event.position = Vector2(x, 350)
	game._unhandled_input(event)
func run() -> void:
	set_meta("tutorial_requested", true)
	var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.persist_best = false; game.test_seed = 99
	root.add_child(game)
	await process_frame
	check(game.tutorial_stage == 0 and game.current_data.id == game.next_data.id, "tutorial starts with matching pair")
	touch_event(game, true, 350)
	var drag := InputEventScreenDrag.new(); drag.index = 0; drag.position = Vector2(360, 350)
	game._unhandled_input(drag)
	check(game.tutorial_stage == 1, "real screen drag advances aim instruction")
	touch_event(game, false, 360)
	for i in range(120): await physics_frame
	check(game.spawn_count == 1 and game.tutorial_stage == 2, "release actually drops first piece and advances tutorial")
	touch_event(game, true, 360); touch_event(game, false, 360)
	for i in range(600):
		await physics_frame
		if game.tutorial_stage == 4: break
	check(game.spawn_count >= 2, "second matching animal was actually dropped")
	check(game.merge_manager.merge_count > 0 and game.tutorial_stage == 4, "real physics collision advances merge and danger instruction")
	paused = false
	game.queue_free()
	print("Day5 tutorial checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
