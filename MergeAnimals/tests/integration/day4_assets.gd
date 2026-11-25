extends SceneTree
# DEV integration checks; release acceptance is tested separately.
var scene := preload("res://scenes/game/Game.tscn")
var checks := 0
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, name: String) -> void:
	checks += 1
	print("%s %d: %s" % ["PASS" if ok else "FAIL", checks, name])
	if not ok:
		failures += 1
func run() -> void:
	var game = scene.instantiate()
	game.persist_best = false
	game.test_seed = 42
	root.add_child(game)
	await process_frame
	var present := [&"mouse", &"hamster", &"rabbit", &"cat", &"dog", &"fox", &"raccoon", &"koala", &"panda", &"bear", &"lion", &"elephant"]
	for d in game.animals:
		var available: bool = d.id in present
		check((d.sprite != null) == available, "%s expected present/missing status" % d.id)
		if not available:
			continue
		var img: Image = d.sprite.get_image()
		check(img != null and img.get_size() == Vector2i(512, 512) and img.detect_alpha() != Image.ALPHA_NONE, "%s PNG dimensions and alpha" % d.id)
		check(img.get_pixel(0, 0).a == 0.0 and img.get_pixel(511, 0).a == 0.0 and img.get_pixel(0, 511).a == 0.0 and img.get_pixel(511, 511).a == 0.0, "%s transparent corners" % d.id)
		game.current_data = d
		game.next_data = d
		game._update_hud()
		check(game.current_preview.data.sprite == d.sprite and game.next_preview.data.sprite == d.sprite, "%s preview and next use same texture" % d.id)
		var body = game.create_animal(d, Vector2(360, 700))
		check(body.visual.data.sprite == d.sprite and is_equal_approx(body.circle.shape.radius, d.radius), "%s body texture and collision radius" % d.id)
		body.queue_free()
		await process_frame
	check(game.THEME_BACKGROUNDS.size() == 3, "three theme backgrounds are configured")
	for theme in range(3):
		game.visual_theme = theme
		game.queue_redraw()
		check(game.visual_theme == theme and game.THEME_BACKGROUNDS[theme] != null, "theme %d can be selected" % theme)
	print("Day4 DEV asset checks: %d; failures: %d; normal sprites=12; happy/surprise=not supplied" % [checks, failures])
	quit(1 if failures else 0)
