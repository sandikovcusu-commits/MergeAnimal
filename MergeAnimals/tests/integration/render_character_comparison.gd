extends SceneTree
## Native Godot software-rendered test fixture: actual imported current sprites
## beside e034511's project-authored PNGs. Not gameplay or a quality score.
const NAMES = ["mouse", "hamster", "rabbit", "cat", "dog", "fox", "raccoon", "koala", "panda", "bear", "lion", "elephant"]
var stage: Control
func _initialize() -> void: call_deferred("run")
func label(text: String, pos: Vector2, size: int = 24) -> void:
	var item := Label.new()
	item.position = pos
	item.text = text
	item.add_theme_color_override("font_color", Color("342b24"))
	item.add_theme_font_size_override("font_size", size)
	stage.add_child(item)
func picture(texture: Texture2D, pos: Vector2, size: Vector2) -> void:
	var item := TextureRect.new()
	item.texture = texture
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.position = pos
	item.size = size
	stage.add_child(item)
func run() -> void:
	stage = Control.new()
	stage.size = Vector2(720, 1280)
	root.add_child(stage)
	var ids := []
	var code := OS.execute("xdotool", ["search", "--onlyvisible", "--pid", str(OS.get_process_id())], ids, true)
	var windows := str(ids[0]).strip_edges().split("\n", false) if not ids.is_empty() else PackedStringArray()
	if code != 0 or windows.is_empty(): printerr("FAIL no X11 window"); quit(1); return
	for id in NAMES:
		for old in stage.get_children(): old.queue_free()
		await process_frame
		var bg := ColorRect.new()
		bg.color = Color("f4ead5")
		bg.size = Vector2(720, 1280)
		stage.add_child(bg)
		var image := Image.load_from_file(OS.get_environment("BASELINE_DIR") + "/" + id + ".png")
		var data: AnimalData = load("res://resources/animals/%s.tres" % id)
		if image == null or data == null or data.sprite == null: printerr("FAIL missing artwork ", id); quit(1); return
		label(id.to_upper() + "  /  NATIVE GODOT FIXTURE", Vector2(30, 38), 28)
		label("BEFORE e034511", Vector2(48, 115))
		label("AFTER", Vector2(400, 115))
		picture(ImageTexture.create_from_image(image), Vector2(32, 160), Vector2(300, 300))
		picture(data.sprite, Vector2(388, 160), Vector2(300, 300))
		label("Expression frames — current", Vector2(40, 540), 25)
		var textures := [data.sprite, data.blink_sprite, data.happy_sprite, data.surprise_sprite]
		for i in range(4):
			if textures[i] == null: printerr("FAIL missing expression ", id); quit(1); return
			picture(textures[i], Vector2(15 + 176 * i, 595), Vector2(160, 160))
			label(["NORMAL", "BLINK", "HAPPY", "SURPRISE"][i], Vector2(26 + 176 * i, 770), 17)
		label("Static test fixture. Not gameplay or physical collision proof.", Vector2(30, 1050), 19)
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		var destination := OS.get_environment("CAPTURE_DIR") + "/" + id + "-before-after.png"
		code = OS.execute("import", ["-window", windows[0], destination])
		var capture := Image.new()
		if code != 0 or capture.load(destination) != OK or capture.get_size() != Vector2i(720, 1280):
			printerr("FAIL capture ", id); quit(1); return
		print("CHARACTER_COMPARISON_CAPTURE ", destination)
	quit()
