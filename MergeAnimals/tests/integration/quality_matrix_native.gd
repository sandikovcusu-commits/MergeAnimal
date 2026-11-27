extends SceneTree
# Private QA fixture; actual Godot rendering, deterministic test-created bodies.
# Never a human playtest, and geometry checks are not a visual approval.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var locale := OS.get_environment("QA_LOCALE")
	var theme := OS.get_environment("QA_THEME")
	var dims := OS.get_environment("QA_SIZE").split("x")
	if locale not in ["az", "en", "tr", "ru"] or theme not in ThemeStore.IDS or dims.size() != 2:
		printerr("FAIL invalid matrix input"); quit(1); return
	var dimensions := Vector2i(int(dims[0]), int(dims[1]))
	var settings := SettingsStore.DEFAULTS.duplicate(); settings.language = locale
	if SettingsStore.save_values(settings) != OK or ThemeStore._save({"version": 1, "selected": theme, "unlocked": ["forest", "sunset", "snow"]}) != OK:
		printerr("FAIL matrix fixture save"); quit(1); return
	var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.test_seed = 42; game.persist_best = false
	root.add_child(game); current_scene = game
	for i in range(5): await process_frame
	game.danger_monitor.set_physics_process(false)
	var positions := [Vector2(373,1064), Vector2(606,798), Vector2(143,535), Vector2(421,1017), Vector2(136,796), Vector2(579,1026), Vector2(552,715), Vector2(382,786), Vector2(502,901), Vector2(453,587), Vector2(251,647), Vector2(237,949)]
	for index in range(12):
		var piece = game.create_animal(game.animals[index], positions[index]); piece.freeze = true
	game.highest_level = 12; game._update_hud()
	if game.visual_theme != ThemeStore.IDS.find(theme) or TranslationServer.get_locale() != locale:
		printerr("FAIL incorrect locale or theme fixture"); quit(1); return
	await create_timer(0.5, true).timeout
	if not await capture("gameplay", locale, theme, dimensions): quit(1); return
	game.score = 124; game.best_at_start = 0; game.max_combo = 3
	game._on_game_over()
	await create_timer(0.5, true).timeout
	var title: Label = game.overlay_title
	var action: Control = game.get_node("HUD/Overlay/RestartButton")
	var text_bottom: float = title.position.y + title.get_line_count() * title.get_line_height()
	var font := title.get_theme_font("font")
	var glyphs_ok := true
	for character in title.text:
		if character != "\n" and not font.has_char(character): glyphs_ok = false
	var fits := text_bottom + 10 <= action.position.y and game.rescue_message.position.y + game.rescue_message.size.y <= game.overlay.size.y
	var scale_factor := minf(float(dimensions.x) / 720.0, float(dimensions.y) / 1280.0)
	print("MATRIX_GEOMETRY ", JSON.stringify({"locale":locale,"theme":theme,"size":str(dimensions),"title_bottom":text_bottom,"action_y":action.position.y,"fits":fits,"glyphs":glyphs_ok,"pause_target_px":game.pause_button.size * scale_factor,"restart_target_px":action.size * scale_factor}))
	if not fits or not glyphs_ok: printerr("FAIL result geometry or font glyph"); quit(1); return
	if not await capture("gameover", locale, theme, dimensions): quit(1); return
	paused = false; quit()
func capture(screen: String, locale: String, theme: String, dimensions: Vector2i) -> bool:
	await RenderingServer.frame_post_draw
	var output := []
	if OS.execute("xdotool", ["search", "--onlyvisible", "--pid", str(OS.get_process_id())], output, true) != 0 or output.is_empty():
		printerr("FAIL X11 window search"); return false
	var ids := str(output[0]).strip_edges().split("\n", false)
	if ids.is_empty(): printerr("FAIL X11 no window"); return false
	var filename := "%s/native-%s-%s-%s-%dx%d.png" % [OS.get_environment("CAPTURE_DIR"), screen, locale, theme, dimensions.x, dimensions.y]
	if OS.execute("import", ["-window", ids[0], filename]) != 0: printerr("FAIL image capture"); return false
	var image := Image.new()
	if image.load(filename) != OK or image.get_size() != dimensions:
		printerr("FAIL native capture size: ", filename, " actual=", image.get_size()); return false
	print("MATRIX_CAPTURE ", filename, " test-fixture, not human review")
	return true
