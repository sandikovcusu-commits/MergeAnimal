extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if value else "FAIL", message])
	if not value: failures += 1
func frames(n: int = 3) -> void:
	for i in range(n): await process_frame
func mouse(game, position: Vector2) -> void:
	var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true; event.position = position
	game._unhandled_input(event)
func touch(game, position: Vector2) -> void:
	var event := InputEventScreenTouch.new(); event.index = 0; event.pressed = true; event.position = position
	game._unhandled_input(event)
func clear_save() -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SessionSave.PATH + suffix))
func make_game(persist := true):
	var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.test_seed = 7; game.persist_best = persist
	root.add_child(game); current_scene = game
	return game
func run() -> void:
	var phase := OS.get_environment("REMOVE_PHASE")
	if phase == "read":
		await read_phase(); return
	clear_save()
	var game = make_game()
	await frames()
	check(game.remove_remaining == 1 and not game.remove_button.disabled, "fresh session offers one Remove")
	var body: Animal = game.create_animal(game.animals[0], Vector2(200, 700))
	body.freeze = true
	await frames()
	var score: int = game.score; var merges: int = game.merge_manager.merge_count
	var progression: Dictionary = game.progression.duplicate(true)
	game.remove_button.pressed.emit()
	check(game.remove_selecting and game.remove_button.text == tr("REMOVE_CANCEL"), "button enters selection and displays Cancel")
	check(not game.drop_animal() and not game.drop_requested, "drop blocked in selection")
	mouse(game, Vector2(500, 400)); await frames()
	check(game.remove_selecting and game.remove_remaining == 1 and is_instance_valid(body), "invalid mouse selection consumes nothing")
	game.remove_button.pressed.emit()
	check(not game.remove_selecting and game.remove_remaining == 1, "Cancel consumes nothing")
	game.remove_button.pressed.emit(); body.merge_locked = true
	mouse(game, body.global_position); await frames()
	check(game.remove_selecting and game.remove_remaining == 1 and is_instance_valid(body), "merge-locked animal cannot be selected")
	body.merge_locked = false
	var preview_pos: Vector2 = game.current_preview.global_position
	mouse(game, preview_pos); await frames()
	check(game.remove_remaining == 1 and is_instance_valid(body), "preview cannot be selected")
	# A failed validation/write leaves board and allowance unchanged.
	var invalid_file := FileAccess.open(SessionSave.PATH, FileAccess.WRITE); invalid_file.store_string("bad"); invalid_file.close()
	invalid_file = FileAccess.open(SessionSave.PATH + ".bak", FileAccess.WRITE); invalid_file.store_string("bad"); invalid_file.close()
	mouse(game, body.global_position); await frames()
	check(is_instance_valid(body) and game.remove_remaining == 1 and game.remove_selecting, "save failure preserves body and allowance")
	clear_save()
	touch(game, body.global_position); await frames(5)
	check(not is_instance_valid(body) and game.pieces.get_child_count() == 0, "touch selects and safely removes body")
	check(game.remove_remaining == 0 and game.remove_button.disabled and not game.remove_selecting, "successful remove spends one and disables button")
	check(game.score == score and game.merge_manager.merge_count == merges, "remove changes neither score nor merge count")
	# Ignore clock, which advances normally while selecting.
	progression.play_seconds = game.progression.play_seconds
	check(game.progression == progression, "remove does not modify collection or statistics")
	game._toggle_remove(); check(not game.remove_selecting, "second Remove blocked")
	var saved := SessionSave.load_session()
	check(saved.status == "ok" and saved.data.remove_remaining == 0 and saved.data.bodies.is_empty(), "body and used allowance saved together")
	var backup := SaveManager._read_envelope(SessionSave.PATH + ".bak")
	check(backup.status == "ok" and backup.data.remove_remaining == 0 and backup.data.bodies.is_empty(), "backup contains committed removal")
	var bad := saved.data.duplicate(true); bad.remove_remaining = 2
	check(not SessionSave.valid(bad), "invalid allowance rejected")
	var legacy := saved.data.duplicate(true); legacy.erase("remove_remaining")
	check(SessionSave.valid(legacy), "legacy v2 session accepted")
	if phase == "write":
		print("REMOVE_WRITE checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0); return
	# Non-persistent fixture resets allowances only for stress; production cannot.
	game.queue_free(); await frames()
	game = make_game(false); await frames()
	for i in range(50):
		game.remove_remaining = 1
		var animal: Animal = game.create_animal(game.animals[i % 5], Vector2(360, 700))
		animal.freeze = true
		game._toggle_remove(); mouse(game, animal.global_position); await frames(2)
		check(not is_instance_valid(animal) and game.remove_remaining == 0 and game.pieces.get_child_count() == 0 and game.merge_manager.pending.is_empty(), "stress removal %d" % (i + 1))
	print("REMOVE checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
func read_phase() -> void:
	var loaded := SessionSave.load_session()
	check(loaded.status == "ok" and loaded.data.remove_remaining == 0, "second process sees used allowance")
	set_meta("continue_requested", true)
	var game = make_game(); await frames(4)
	check(game.remove_remaining == 0 and game.remove_button.disabled and game.pieces.get_child_count() == 0, "Continue restores removed board and disabled button")
	game._toggle_remove(); check(not game.remove_selecting, "Continue cannot reuse Remove")
	game._restart(); await frames(6)
	game = current_scene
	check(game.remove_remaining == 1 and not game.remove_button.disabled, "restart creates new allowance")
	print("REMOVE_READ checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
