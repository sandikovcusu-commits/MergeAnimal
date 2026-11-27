extends SceneTree
# Scripted software-render animation exercise. It does not claim artistic or
# human/device acceptance; fake static setup, then a physical golden collision.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.test_seed = 42; game.persist_best = false
	root.add_child(game); current_scene = game
	for i in range(6): await process_frame
	game.danger_monitor.set_physics_process(false)
	var positions := [Vector2(373,1064), Vector2(606,798), Vector2(143,535), Vector2(421,1017), Vector2(136,796), Vector2(579,1026), Vector2(552,715), Vector2(382,786), Vector2(502,901), Vector2(453,587), Vector2(251,647), Vector2(237,949)]
	var bodies: Array[Animal] = []
	for index in range(12):
		var animal: Animal = game.create_animal(game.animals[index], positions[index])
		animal.freeze = true; animal.merge_locked = true; bodies.append(animal)
	var phase := Label.new(); phase.position = Vector2(55, 290); phase.size = Vector2(610, 42)
	phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase.add_theme_font_size_override("font_size", 24); phase.add_theme_color_override("font_color", Color("203f2c"))
	game.get_node("HUD").add_child(phase)
	await create_timer(0.6).timeout
	var out := []
	if OS.execute("xdotool", ["search", "--onlyvisible", "--pid", str(OS.get_process_id())], out, true) != 0 or out.is_empty():
		printerr("FAIL animation X11 window"); quit(1); return
	var windows := str(out[0]).strip_edges().split("\n", false)
	if windows.is_empty(): printerr("FAIL animation window ID"); quit(1); return
	OS.execute("xdotool", ["windowmove", windows[0], "0", "0"])
	var recording := OS.create_process("ffmpeg", ["-y", "-loglevel", "error", "-f", "x11grab", "-framerate", "20", "-video_size", "720x1280", "-i", OS.get_environment("DISPLAY") + "+0,0", "-t", "18", "-an", "-vf", "scale=540:960", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-preset", "ultrafast", "-crf", "27", OS.get_environment("CAPTURE_DIR") + "/animation-motion.mp4"])
	if recording <= 0: printerr("FAIL start video"); quit(1); return
	phase.text = "IDLE — 12 test bodies"; var before: float = bodies[0].visual.idle_phase
	await create_timer(1.0).timeout
	if is_equal_approx(before, bodies[0].visual.idle_phase): printerr("FAIL idle scheduler"); quit(1); return
	phase.text = "BLINK — forced test timing"
	for animal in bodies: animal.visual.next_blink = 0.0
	await create_timer(0.05).timeout
	for animal in bodies:
		if animal.visual.blink_left <= 0.0 or animal.visual._texture_for_expression() != animal.data.blink_sprite:
			printerr("FAIL blink ", animal.data.id); quit(1); return
	await create_timer(0.7).timeout
	for action in ["happy", "surprise", "drop", "landing", "merge"]:
		phase.text = action.to_upper() + " — 12 test bodies"
		for animal in bodies: animal.visual.animate_action(action)
		await create_timer(0.08).timeout
		for animal in bodies:
			if action in ["happy", "merge"] and animal.visual._texture_for_expression() != animal.data.happy_sprite:
				printerr("FAIL happy frame ", animal.data.id, " ", action); quit(1); return
			if action in ["surprise", "drop"] and animal.visual._texture_for_expression() != animal.data.surprise_sprite:
				printerr("FAIL surprise frame ", animal.data.id, " ", action); quit(1); return
			if not is_equal_approx(animal.circle.shape.radius, animal.data.radius) or not is_equal_approx(animal.mass, animal.data.body_mass) or animal.scale != Vector2.ONE or animal.circle.scale != Vector2.ONE:
				printerr("FAIL physics invariance ", animal.data.id, " ", action); quit(1); return
		print("PASS motion phase ", action, " 12/12 frames and shape/mass invariant")
		await create_timer(0.85).timeout
	if game.score != 0 or game.merge_manager.merge_count != 0:
		printerr("FAIL cosmetic action changed score/merge"); quit(1); return
	for animal in bodies: animal.queue_free()
	for i in range(3): await process_frame
	phase.text = "GOLDEN MERGE — physical elephant collision"
	var a: Animal = game.create_animal(game.animals[11], Vector2(225, 700))
	var b: Animal = game.create_animal(game.animals[11], Vector2(495, 700))
	a.linear_velocity = Vector2(200, 0); b.linear_velocity = Vector2(-200, 0)
	for i in range(240):
		await physics_frame
		if game.merge_manager.merge_count > 0: break
	if game.merge_manager.merge_count != 1 or game.score != (game.golden_config.bonus_score if game.golden_config else 1000):
		printerr("FAIL golden count/score ", game.merge_manager.merge_count, " ", game.score); quit(1); return
	await create_timer(2.0).timeout
	if game.merge_manager.merge_count != 1:
		printerr("FAIL duplicate golden merge"); quit(1); return
	print("PASS golden actual collision score=", game.score, " count=1; elephant only")
	while OS.is_process_running(recording): await create_timer(0.2).timeout
	var video := OS.get_environment("CAPTURE_DIR") + "/animation-motion.mp4"
	if not FileAccess.file_exists(video) or FileAccess.get_file_as_bytes(video).is_empty(): printerr("FAIL missing video"); quit(1); return
	print("PASS animated Godot software fixture video: idle/blink/happy/surprise/drop/landing/merge 12 animals; golden elephant; no human approval")
	quit()
