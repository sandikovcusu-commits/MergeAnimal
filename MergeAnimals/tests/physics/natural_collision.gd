extends SceneTree

# Real body_entered integration path. This script has not been run in the
# current environment; see QA_REPORT.md for status.
var scene := preload("res://scenes/game/Game.tscn")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = scene.instantiate()
	game.test_seed = 42
	game.persist_best = false
	root.add_child(game)
	await process_frame
	game.danger_monitor.set_physics_process(false)
	game.create_animal(game.animals[0], Vector2(360, 1076))
	game.create_animal(game.animals[0], Vector2(360, 650))
	for tick in range(240):
		await physics_frame
	var count: int = game.pieces.get_child_count()
	var ok: bool = count == 1 and game.pieces.get_child(0).data.id == &"hamster" and game.score == 4 and game.merge_manager.merge_count == 1
	print("Natural collision: bodies=%d score=%d merges=%d result=%s" % [count, game.score, game.merge_manager.merge_count, "PASS" if ok else "FAIL"])
	quit(0 if ok else 1)
