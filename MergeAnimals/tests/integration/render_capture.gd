extends SceneTree
# Render capture from the Godot viewport, not generated art.
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
	for index in range(5):
		var piece = game.create_animal(game.animals[index], Vector2(150 + index * 100, 1030 - game.animals[index].radius))
		piece.freeze = true
	game.highest_level = 5
	game.queue_redraw()
	print("RENDER_STATE pieces=%d current=%s preview_visible=%s score=%s next=%s" % [game.pieces.get_child_count(), game.current_data.id if game.current_data else "NULL", game.current_preview.visible, game.score_label.text, game.next_label.text])
	var out_dir := OS.get_environment("CAPTURE_DIR")
	if out_dir.is_empty():
		printerr("FAIL: CAPTURE_DIR is required")
		quit(1)
		return
	var dimensions := [Vector2i(360,640), Vector2i(360,800), Vector2i(720,1280), Vector2i(1080,1920), Vector2i(1366,768), Vector2i(1920,1080)]
	for size in dimensions:
		root.size = size
		DisplayServer.window_set_size(size)
		for i in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := "%s/game_%dx%d.png" % [out_dir, size.x, size.y]
		var result := image.save_png(path)
		print("RENDER requested=%s window=%s image=%s saved=%s path=%s" % [size, root.size, image.get_size(), result == OK, path])
		if result != OK:
			quit(1)
			return
	quit()
