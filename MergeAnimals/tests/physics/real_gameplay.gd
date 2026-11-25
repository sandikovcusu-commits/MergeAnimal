extends SceneTree
# Real Godot physics tests of stable overflow, support normals and pause.
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
	game.danger_monitor.set_physics_process(false)
	var body = game.create_animal(game.animals[0], Vector2(360, 500))
	for i in range(20):
		await physics_frame
	var before: float = body.position.y
	game._toggle_pause()
	for i in range(30):
		await physics_frame
	check(is_equal_approx(body.position.y, before), "pause stops actual rigid body movement")
	game._toggle_pause()
	for i in range(30):
		await physics_frame
	check(body.position.y > before + 5.0, "resume continues actual rigid body movement")
	game.queue_free()
	await process_frame

	game = scene.instantiate()
	game.test_seed = 42
	game.persist_best = false
	root.add_child(game)
	await process_frame
	# Non-merging maximum level: broad supported grid extends above danger line.
	for row in range(8):
		for column in range(6):
			game.create_animal(game.animals[4], Vector2(140 + column * 84, 1052 - row * 84))
	for i in range(360):
		await physics_frame
		if not game.is_playing():
			break
	var supported := 0
	for piece in game.pieces.get_children():
		if piece.supported:
			supported += 1
	print("Real overflow: bodies=%d supported=%d peak_time=%.3f game_state=%s" % [game.pieces.get_child_count(), supported, game.danger_monitor.peak_time, game.GameState.keys()[game.game_state]])
	check(game.game_state == game.GameState.GAME_OVER, "stable physical pile triggers game over")
	check(not game.drop_animal(), "real game over blocks spawn")
	paused = false
	game.queue_free()
	await process_frame
	print("Real gameplay failures: ", failures)
	quit(1 if failures else 0)
