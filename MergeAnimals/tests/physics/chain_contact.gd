extends SceneTree
var scene := preload("res://scenes/game/Game.tscn")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = scene.instantiate()
	game.combo_enabled = false
	game.test_seed = 42
	game.persist_best = false
	root.add_child(game)
	await process_frame
	game.danger_monitor.set_physics_process(false)
	game.create_animal(game.animals[1], Vector2(360, 1071))
	game.create_animal(game.animals[0], Vector2(360, 980))
	game.create_animal(game.animals[0], Vector2(360, 880))
	for i in range(600):
		await physics_frame
		if game.merge_manager.merge_count >= 2:
			break
	var ok: bool = game.pieces.get_child_count() == 1 and game.pieces.get_child(0).data.id == &"rabbit" and game.score == 12 and game.merge_manager.merge_count == 2
	print("%s: actual contact chain mouse->hamster->rabbit; bodies=%d score=%d merges=%d pending=%d" % ["PASS" if ok else "FAIL", game.pieces.get_child_count(), game.score, game.merge_manager.merge_count, game.merge_manager.pending.size()])
	quit(0 if ok else 1)
