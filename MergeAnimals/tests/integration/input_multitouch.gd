extends SceneTree
var scene := preload("res://scenes/game/Game.tscn")
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		failures += 1
func run() -> void:
	var game = scene.instantiate()
	game.test_seed = 42
	game.persist_best = false
	root.add_child(game)
	await process_frame
	var first := InputEventScreenTouch.new()
	first.index = 1
	first.position = Vector2(200, 600)
	first.pressed = true
	game._unhandled_input(first)
	var second := InputEventScreenTouch.new()
	second.index = 2
	second.position = Vector2(500, 600)
	second.pressed = true
	game._unhandled_input(second)
	second.pressed = false
	game._unhandled_input(second)
	check(game.active_touch == 1 and not game.drop_requested, "second finger cannot drop or steal the active touch")
	first.pressed = false
	first.position = Vector2(1000, 600)
	game._unhandled_input(first)
	check(game.drop_requested and game.active_touch == -1, "first finger release queues one drop")
	check(game.aim_x <= game.right_bound - game.current_data.radius - game.spawn_margin, "release beyond right edge is clamped")
	await physics_frame
	await physics_frame
	check(game.spawn_count == 1 and game.pieces.get_child_count() == 1, "multi-touch sequence creates exactly one body")
	print("Multi-touch failures: ", failures)
	quit(1 if failures else 0)
