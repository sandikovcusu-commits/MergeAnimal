extends SceneTree
# Two independent Godot processes, shared isolated user:// directory. Automated, not human play.
var checks := 0
var failures := 0
const EXPECTED := "user://day61_expected.json"
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, description: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", description])
	if not ok: failures += 1
func capture(name: String) -> void:
	if OS.get_environment("CAPTURE_DIR").is_empty(): return
	await process_frame
	await RenderingServer.frame_post_draw
	var output := []
	var code := OS.execute("xdotool", ["search", "--onlyvisible", "--pid", str(OS.get_process_id())], output, true)
	if code != 0 or output.is_empty():
		check(false, "locate X11 window for " + name); return
	var ids := str(output[0]).strip_edges().split("\n", false)
	if ids.is_empty():
		check(false, "X11 window exists for " + name); return
	var file := OS.get_environment("CAPTURE_DIR") + "/" + name + ".png"
	code = OS.execute("import", ["-window", ids[0], file])
	check(code == 0 and FileAccess.file_exists(file), "X11 capture " + name)
func choose_x(game) -> float:
	var left: float = game.left_bound + game.current_data.radius + game.spawn_margin
	var right: float = game.right_bound - game.current_data.radius - game.spawn_margin
	var target: Animal = null
	for body in game.pieces.get_children():
		if body.data.id == game.current_data.id and not body.merge_locked:
			if target == null or body.position.y > target.position.y: target = body
	if target != null: return clampf(target.position.x, left, right)
	var best_x := left
	var best_height := -INF
	for i in range(9):
		var x: float = lerpf(left, right, i / 8.0)
		var top: float = game.floor_height
		for body in game.pieces.get_children():
			if absf(body.position.x - x) < body.data.radius + game.current_data.radius:
				top = minf(top, body.position.y - body.data.radius)
		if top > best_height:
			best_height = top
			best_x = x
	return best_x
func run() -> void:
	var phase := OS.get_environment("SESSION_PHASE")
	if phase == "write": await write_phase()
	elif phase == "read": await read_phase()
	else: check(false, "invalid test phase")
	print("DAY61 phase=%s checks=%d failures=%d" % [phase, checks, failures])
	quit(1 if failures else 0)
func write_phase() -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SessionSave.PATH + suffix))
	var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.test_seed = 30000
	root.add_child(game)
	current_scene = game
	await process_frame
	check(game.is_playing() and game.spawn_count == 0, "new game started")
	var ticks := 0
	var next_drop := 0
	while game.is_playing() and game.spawn_count < 20 and ticks < 12000:
		await physics_frame
		ticks += 1
		if ticks >= next_drop:
			game._set_aim(choose_x(game))
			if game.drop_animal(): next_drop = ticks + 144
			else: next_drop = ticks + 24
	check(game.spawn_count == 20, "20 animals dropped via gameplay")
	check(game.merge_manager.merge_count > 0 and game.score > 0, "real contact merge awards score")
	if failures > 0: return
	for i in range(1000):
		await physics_frame
		if game.merge_manager.pending.is_empty() and not game.merge_manager.commit_scheduled and not game.drop_requested: break
	await process_frame
	game.pause_button.pressed.emit()
	check(paused and game.game_state == game.GameState.PAUSED, "game paused before process exit")
	check(game.save_session() == OK, "persist first snapshot")
	check(game.save_session() == OK, "persist matching backup snapshot")
	var loaded := SessionSave.load_session()
	check(loaded.status == "ok", "saved session readable")
	if loaded.status != "ok": return
	var probe := RandomNumberGenerator.new()
	probe.state = game.rng.state
	var sequence := []
	for i in range(8): sequence.append(probe.randi())
	var file := FileAccess.open(EXPECTED, FileAccess.WRITE)
	file.store_string(JSON.stringify({"session": loaded.data, "rng_sequence": sequence})); file.close()
	print("DAY61_SAVED drops=%d merges=%d score=%d bodies=%d rng=%s" % [game.spawn_count, game.merge_manager.merge_count, game.score, game.pieces.get_child_count(), str(game.rng.state)])
	await capture("day61_saved_game")

func read_phase() -> void:
	var file := FileAccess.open(EXPECTED, FileAccess.READ)
	check(file != null, "prior process fixture present")
	if file == null: return
	var fixture: Variant = JSON.parse_string(file.get_as_text())
	if typeof(fixture) != TYPE_DICTIONARY:
		check(false, "prior fixture parses"); return
	var expected: Variant = fixture.get("session")
	check(SessionSave.valid(expected), "prior saved snapshot valid")
	if not SessionSave.valid(expected): return
	paused = true # Compare before a physics tick changes positions or triggers contacts.
	var menu = (load("res://scenes/ui/MainMenu.tscn") as PackedScene).instantiate()
	root.add_child(menu); current_scene = menu
	await process_frame
	check(not menu.continue_button.disabled, "Continue enabled in new process")
	var before_prompt := FileAccess.get_sha256(SessionSave.PATH)
	menu.play_button.pressed.emit()
	await process_frame
	check(is_instance_valid(menu.new_game_dialog) and menu.new_game_dialog.visible, "new game requests confirmation before replacing save")
	check(FileAccess.get_sha256(SessionSave.PATH) == before_prompt, "prompt alone does not overwrite save")
	if is_instance_valid(menu.new_game_dialog): menu.new_game_dialog.canceled.emit()
	await process_frame
	await create_timer(0.5, true).timeout
	await capture("day61_continue_menu")
	menu.continue_button.pressed.emit()
	await process_frame
	await process_frame
	var game = current_scene
	check(game != menu and game.has_method("save_session"), "Continue button opens gameplay")
	if game == menu or not game.has_method("save_session"): return
	check(game.spawn_count == int(expected.spawn_count) and game.merge_manager.merge_count == int(expected.merge_count), "drop and merge counters restored without duplicates")
	check(game.score == int(expected.score) and game.best_score >= int(expected.best_score), "score and best restored without duplicate award")
	check(game.combo_count == int(expected.combo_count) and is_equal_approx(game.combo_left, float(expected.combo_left)), "combo restored")
	check(str(game.current_data.id) == expected.current and str(game.next_data.id) == expected.next and str(game.rng.state) == expected.rng_state, "current next and exact RNG state restored")
	var saved_rng_state: int = game.rng.state
	var matches_rng := true
	for value in fixture.rng_sequence:
		if game.rng.randi() != int(value): matches_rng = false
	game.rng.state = saved_rng_state
	check(matches_rng, "future RNG sequence matches previous process")
	check(game.pieces.get_child_count() == expected.bodies.size(), "exact body count restored")
	var actual: Array = game.pieces.get_children()
	if actual.size() == expected.bodies.size():
		for i in range(actual.size()):
			var body: Animal = actual[i]
			var saved: Dictionary = expected.bodies[i]
			check(str(body.data.id) == saved.id and body.position.distance_to(Vector2(saved.x, saved.y)) < 0.01 and absf(body.rotation - float(saved.rotation)) < 0.001, "body %d id, position and rotation" % i)
			check(body.linear_velocity.distance_to(Vector2(saved.vx, saved.vy)) < 0.01 and absf(body.angular_velocity - float(saved.angular_velocity)) < 0.01, "body %d linear and angular velocity" % i)
	await capture("day61_restored_game")
	# Corrupt the primary and ensure the matching previous copy can be read.
	file = FileAccess.open(SessionSave.PATH, FileAccess.WRITE)
	file.store_string("bad save"); file.close()
	var recovered := SessionSave.load_session()
	check(recovered.status == "recovered" and int(recovered.data.score) == int(expected.score) and recovered.data.bodies.size() == expected.bodies.size(), "corrupt primary recovers backup")
	var invalid: Dictionary = expected.duplicate(true)
	invalid.bodies.append(invalid.bodies[0].duplicate(true))
	check(not SessionSave.valid(invalid), "duplicate body identity rejected")
	invalid = expected.duplicate(true); invalid.bodies[0].id = "not_an_animal"
	check(not SessionSave.valid(invalid), "unknown animal rejected")
	change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	await process_frame
	await process_frame
	menu = current_scene
	check(not menu.continue_button.disabled, "Continue enabled for recovered backup")
	menu.continue_button.pressed.emit()
	await process_frame
	await process_frame
	game = current_scene
	check(game.has_method("save_session") and game.score == int(expected.score) and game.pieces.get_child_count() == expected.bodies.size(), "Continue actually restores corrupted primary from backup")
	check(game.save_session() == OK, "continue after recovery writes valid primary")
	paused = false
	var before: int = game.spawn_count
	for i in range(2000):
		await physics_frame
		if not game.is_playing(): break
		if i % 24 == 0:
			game._set_aim(choose_x(game)); game.drop_animal()
		if game.spawn_count > before: break
	check(game.spawn_count == before + 1, "continued gameplay accepts a further real drop")
	# A pending pair must leave durable data untouched even if a caller explicitly requests a save.
	if game.is_playing():
		var a: Animal = game.create_animal(game.animals[0], Vector2(250, 350))
		var b: Animal = game.create_animal(game.animals[0], Vector2(500, 350))
		var hash_before := FileAccess.get_sha256(SessionSave.PATH)
		check(game.merge_manager.request_merge(a, b), "pending merge fixture reserved")
		check(game.save_session() == ERR_BUSY, "save refused during pending merge")
		check(FileAccess.get_sha256(SessionSave.PATH) == hash_before, "pending save did not change durable data")
		game._on_game_over()
		check(SessionSave.load_session().status == "missing", "game over invalidates continue")
		file = FileAccess.open(SessionSave.PATH, FileAccess.WRITE)
		file.store_string("damaged tombstone"); file.close()
		check(SessionSave.load_session().status == "missing", "corrupt tombstone cannot resurrect old game")
	print("DAY61_RESTORED score=%d bodies=%d drops=%d" % [game.score, game.pieces.get_child_count(), game.spawn_count])
