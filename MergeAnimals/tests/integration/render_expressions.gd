extends SceneTree
# X11 software-rendered fixture of actual AnimalVisual nodes, not gameplay.
const NAMES = ["mouse", "hamster", "rabbit", "cat", "dog", "fox", "raccoon", "koala", "panda", "bear", "lion", "elephant"]
const VISUAL = preload("res://scripts/gameplay/AnimalVisual.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var background := ColorRect.new()
	background.color = Color("f4ead5")
	background.size = Vector2(720, 1280)
	stage.add_child(background)
	for col in range(4):
		var label := Label.new()
		label.text = ["NORMAL", "BLINK", "HAPPY", "SURPRISE"][col]
		label.position = Vector2(165 + 140 * col, 10)
		label.add_theme_color_override("font_color", Color("342b24"))
		label.add_theme_font_size_override("font_size", 17)
		stage.add_child(label)
	for row in range(NAMES.size()):
		var data: AnimalData = load("res://resources/animals/%s.tres" % NAMES[row])
		var label := Label.new()
		label.text = NAMES[row]
		label.position = Vector2(8, 66 + row * 100)
		label.add_theme_color_override("font_color", Color("342b24"))
		label.add_theme_font_size_override("font_size", 16)
		stage.add_child(label)
		for col in range(4):
			var visual = VISUAL.new()
			visual.data = data
			visual.position = Vector2(205 + col * 140, 72 + row * 100)
			visual.scale = Vector2.ONE * (40.0 / data.radius)
			stage.add_child(visual)
			if col == 1: visual.blink_left = 1.0
			elif col == 2: visual.expression = VISUAL.AnimalExpression.HAPPY
			elif col == 3: visual.expression = VISUAL.AnimalExpression.SURPRISE
			visual.queue_redraw()
	await create_timer(2.0).timeout
	await RenderingServer.frame_post_draw
	var ids := []
	var code := OS.execute("xdotool", ["search", "--onlyvisible", "--pid", str(OS.get_process_id())], ids, true)
	var windows := str(ids[0]).strip_edges().split("\n", false) if not ids.is_empty() else PackedStringArray()
	if code != 0 or windows.is_empty(): printerr("FAIL no X11 window"); quit(1); return
	var destination := OS.get_environment("CAPTURE_DIR") + "/character_expressions_720x1280.png"
	code = OS.execute("import", ["-window", windows[0], destination])
	var image := Image.new()
	if code != 0 or image.load(destination) != OK or image.get_size() != Vector2i(720, 1280):
		printerr("FAIL expression capture"); quit(1); return
	print("EXPRESSION_CAPTURE %s %s" % [destination, image.get_size()])
	quit()
