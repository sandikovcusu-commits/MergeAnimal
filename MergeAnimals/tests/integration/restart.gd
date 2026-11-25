extends SceneTree
var scene := preload("res://scenes/game/Game.tscn")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = scene.instantiate()
	game.persist_best = false
	root.add_child(game)
	current_scene = game
	await process_frame
	game.create_animal(game.animals[0], Vector2(360, 700))
	game.score = 42
	game._on_game_over()
	game._restart()
	for i in range(4):
		await process_frame
	var fresh = current_scene
	var ok: bool = is_instance_valid(fresh) and fresh != game and fresh.pieces.get_child_count() == 0 and fresh.score == 0 and fresh.is_playing() and not paused
	print("%s: scene restart clears bodies and score, resumes tree" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
