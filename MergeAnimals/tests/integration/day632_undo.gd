extends SceneTree
var checks := 0
var failures := 0
var shown: Array[StringName] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", message])
	if not ok: failures += 1
func frames(n: int = 3) -> void:
	for i in range(n): await process_frame
func clear_save() -> void:
	for path in [SessionSave.PATH, SessionSave.POWERUP_PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
func new_game(persist := true):
	var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.test_seed = 187; game.persist_best = persist
	root.add_child(game); current_scene = game
	return game
func dispose(game) -> void:
	game.queue_free(); await frames()
func real_drop(game, x: float = 360.0) -> bool:
	for i in range(120):
		if game._can_aim(): break
		await physics_frame
	var before: int = game.spawn_count
	game._set_aim(x)
	if not game.drop_animal(): return false
	for i in range(120):
		await physics_frame
		if game.spawn_count > before: return true
	return false
func undo(game) -> void:
	game.undo_button.pressed.emit()
	await frames(3)
func run() -> void:
	var phase := OS.get_environment("UNDO_PHASE")
	if phase == "read": await read_phase(); return
	if phase == "verify": await verify_phase(); return
	clear_save()
	var game = new_game(); await frames()
	check(game.undo_remaining == 1 and game.undo_button.disabled, "fresh game has no snapshot")
	game.current_data = game.animals[0]; game.next_data = game.animals[1]
	var rng_before: String = str(game.rng.state)
	game.discovery_notifier.shown.connect(func(id: StringName): shown.append(id))
	check(await real_drop(game, 360), "normal real drop succeeds")
	var original: Animal = game.pieces.get_child(0)
	check(not game.undo_button.disabled and not game.undo_snapshot.is_empty(), "successful drop creates usable snapshot")
	check(int(game.progression.total_drops) == 1 and int(game.progression.animals.mouse.count) == 1 and shown.size() == 1, "drop awards one discovery")
	check(game.save_session() == OK, "save drop and undo snapshot")
	if phase == "write":
		print("UNDO_WRITE checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0); return
	# A busy/corrupt journal makes the transaction fail without touching live state.
	var invalid := FileAccess.open(SessionSave.POWERUP_PATH, FileAccess.WRITE)
	invalid.store_string("broken"); invalid.close()
	await undo(game)
	check(is_instance_valid(original) and game.pieces.get_child_count() == 1 and game.undo_remaining == 1 and game.spawn_count == 1, "failed save leaves live board and allowance unchanged")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SessionSave.POWERUP_PATH))
	var tmp_obstruction: String = ProjectSettings.globalize_path(SessionSave.POWERUP_PATH + ".tmp")
	check(DirAccess.make_dir_absolute(tmp_obstruction) == OK, "create checkpoint write obstruction")
	var primary_hash := FileAccess.get_sha256(SessionSave.PATH)
	await undo(game)
	check(is_instance_valid(original) and game.undo_remaining == 1 and FileAccess.get_sha256(SessionSave.PATH) == primary_hash, "checkpoint write failure leaves board and primary unchanged")
	DirAccess.remove_absolute(tmp_obstruction)
	await undo(game)
	check(not is_instance_valid(original) and game.pieces.get_child_count() == 0 and game.spawn_count == 0, "normal Undo restores board and drop count")
	check(game.undo_remaining == 0 and game.undo_button.disabled, "Undo consumes one use")
	check(str(game.current_data.id) == "mouse" and str(game.next_data.id) == "hamster" and str(game.rng.state) == rng_before, "queue and RNG restored exactly")
	check(int(game.progression.total_drops) == 0 and int(game.progression.animals.mouse.count) == 0 and not str(game.progression.animals.mouse.date).is_empty(), "creation count rolls back; discovery stays unlocked")
	check(await real_drop(game, 360), "can replay after Undo")
	check(int(game.progression.animals.mouse.count) == 1 and shown.size() == 1 and int(game.progression.total_drops) == 1, "replay counts once without duplicate discovery")
	var count: int = game.pieces.get_child_count(); await undo(game)
	check(game.undo_remaining == 0 and game.pieces.get_child_count() == count, "second Undo blocked")
	await dispose(game); clear_save()
	await chain_test()
	clear_save(); await pending_test()
	clear_save(); await latest_snapshot_test()
	clear_save(); await state_test()
	clear_save(); await golden_test()
	clear_save(); await tutorial_test()
	clear_save(); await remove_test()
	clear_save(); await backup_failure_test()
	clear_save(); await stress_test()
	print("UNDO checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
func chain_test() -> void:
	var game = new_game(); await frames()
	game.current_data = game.animals[0]; game.next_data = game.animals[1]
	var m: Animal = game.create_animal(game.animals[0], Vector2(360, 1075)); m.progression_eligible = true
	var h: Animal = game.create_animal(game.animals[1], Vector2(410, 1070)); h.progression_eligible = true
	for i in range(30): await physics_frame
	check(await real_drop(game, 360), "chain fixture drops mouse")
	for i in range(600):
		await physics_frame
		if game.merge_manager.merge_count >= 1: break
	check(game.merge_manager.merge_count >= 1, "first chain merge from real contact")
	if game.merge_manager.merge_count == 1:
		# Fixture pushes matching hamsters together; the second merge itself is
		# still produced by the physics contact callback, not request_merge.
		var hs: Array = []
		for b in game.pieces.get_children():
			if b is Animal and b.data.level == 2: hs.append(b)
		if hs.size() == 2:
			# Position and velocities are test controls; the merge must still be
			# triggered by a real Godot physics contact.
			hs[0].global_position = Vector2(270, 900)
			hs[1].global_position = Vector2(450, 900)
			hs[0].linear_velocity = Vector2(200, 0)
			hs[1].linear_velocity = Vector2(-200, 0)
	for i in range(360):
		await physics_frame
		if game.merge_manager.merge_count >= 2: break
	check(game.merge_manager.merge_count >= 2 and game.score > 0, "two real-contact merges and score")
	var previous: Dictionary = game.undo_snapshot.duplicate(true)
	check(int(game.progression.total_merges) >= 2 and int(game.progression.best_score) > 0, "chain awarded eligible statistics and best")
	# Blocked spawn must not overwrite the valid snapshot.
	game._set_aim(360)
	var held: Dictionary = game.undo_snapshot.duplicate(true)
	game.current_data = game.animals[0]
	var block: Animal = game.create_animal(game.animals[4], Vector2(360, game.spawn_height)); block.freeze = true
	await physics_frame
	game.spawn_state = game.SpawnState.READY; game._set_aim(360); game.drop_animal()
	await physics_frame; await frames()
	check(game.undo_snapshot == held, "blocked drop preserves previous snapshot")
	game.pieces.remove_child(block); block.queue_free(); await frames()
	# A stale separate legacy record must not resurrect an undone v3 best.
	var stale := ConfigFile.new(); stale.set_value("scores", "best", 9999); stale.save("user://wild_garden.cfg")
	await undo(game)
	check(game.merge_manager.merge_count == int(previous.merge_count) and game.score == int(previous.score) and game.combo_count == int(previous.combo_count), "Undo rolls back chain, score and combo")
	check(game.best_score == int(previous.best_score) and int(game.progression.best_score) == int(previous.progression.best_score), "Undo rolls back session best and lifetime best")
	check(int(SessionSave.load_progression().best_score) == int(previous.progression.best_score) and game._load_best() == int(previous.best_score), "v3 canonical best ignores stale separate legacy record")
	stale.set_value("scores", "best", 0); stale.save("user://wild_garden.cfg")
	check(int(game.progression.total_merges) == int(previous.progression.total_merges), "Undo rolls back merge statistics")
	check(game.pieces.get_child_count() == 2, "Undo restores both original chain bodies without duplicates")
	await dispose(game)
func pending_test() -> void:
	var game = new_game(false); await frames()
	check(await real_drop(game, 360), "pending fixture takes a drop")
	var body: Animal = game.pieces.get_child(0); body.freeze = true
	var other: Animal = game.create_animal(body.data, Vector2(500, 700)); other.freeze = true
	game.merge_manager.set_physics_process(false)
	check(game.merge_manager.request_merge(body, other), "pending fixture reserves a real merge pair")
	game._request_undo(); await frames()
	check(game.undo_remaining == 1 and not game.undo_processing and game.pieces.get_child_count() == 2, "Undo refuses pending merge without consuming use")
	game.merge_manager.pending.clear(); body.merge_locked = false; other.merge_locked = false
	game.pieces.remove_child(other); other.queue_free(); game.merge_manager.set_physics_process(true)
	await undo(game)
	check(game.undo_remaining == 0 and game.pieces.get_child_count() == 0, "Undo succeeds once merge queue is safe")
	await dispose(game)
func latest_snapshot_test() -> void:
	var game = new_game(false); await frames()
	check(await real_drop(game, 170), "first drop for latest snapshot")
	var first: Animal = game.pieces.get_child(0)
	var first_uid: int = first.save_uid
	check(await real_drop(game, 500), "second drop for latest snapshot")
	check(game.undo_snapshot.bodies.size() == 1 and int(game.undo_snapshot.bodies[0].uid) == first_uid, "second successful drop replaces Undo boundary")
	await undo(game)
	check(game.spawn_count == 1 and game.pieces.get_child_count() == 1 and game.pieces.get_child(0).save_uid == first_uid, "Undo reverses only last successful drop")
	await dispose(game)
func state_test() -> void:
	var game = new_game(); await frames()
	game.pieces.process_mode = Node.PROCESS_MODE_DISABLED
	game.danger_monitor.set_physics_process(false)
	game.current_data = game.animals[1]; game.next_data = game.animals[0]
	var body: Animal = game.create_animal(game.animals[2], Vector2(180, 700))
	body.rotation = 0.41
	body.linear_velocity = Vector2(28, -17)
	body.angular_velocity = 0.75
	game.danger_monitor.timers[body.instance_uid] = 1.25
	game.score = 12; game.best_score = 22; game.progression.best_score = 22
	game.combo_count = 2; game.combo_events = 1; game.max_combo = 2; game.combo_left = 1.5
	game.cooldown_left = 0.3 # Explicit state fixture; real input normally waits for ready.
	check(await real_drop(game, 500), "state fixture takes real drop")
	var saved: Dictionary = game.undo_snapshot.duplicate(true)
	check(saved.bodies.size() == 1 and float(saved.bodies[0].danger) == 1.25, "snapshot captures danger timer")
	await undo(game)
	var restored: Animal = game.pieces.get_child(0) if game.pieces.get_child_count() == 1 else null
	check(restored != null and restored.save_uid == int(saved.bodies[0].uid), "stable body identity restored without duplicates")
	if restored != null:
		check(restored.position.distance_to(Vector2(saved.bodies[0].x, saved.bodies[0].y)) < 0.1 and absf(restored.rotation - float(saved.bodies[0].rotation)) < 0.01, "position and rotation restored")
		check(restored.linear_velocity.distance_to(Vector2(saved.bodies[0].vx, saved.bodies[0].vy)) < 0.1 and absf(restored.angular_velocity - float(saved.bodies[0].angular_velocity)) < 0.01, "linear and angular velocities restored")
		check(absf(float(game.danger_monitor.timers.get(restored.instance_uid, 0.0)) - 1.25) < 0.001, "danger timer restored to replacement instance")
	check(game.score == 12 and game.combo_count == 2 and game.combo_events == 1 and absf(game.combo_left - float(saved.combo_left)) < 0.15, "score and combo restored")
	check(game.cooldown_left > 0.0 and absf(game.cooldown_left - float(saved.cooldown_left)) < 0.15, "spawn cooldown restored")
	check(str(game.current_data.id) == saved.current and str(game.next_data.id) == saved.next and str(game.rng.state) == saved.rng_state, "current next and RNG match snapshot")
	await dispose(game)
func golden_test() -> void:
	var game = new_game(); await frames()
	game.current_data = game.animals[0]; game.next_data = game.animals[1]
	var a: Animal = game.create_animal(game.animals[11], Vector2(205, 900)); a.progression_eligible = true
	var b: Animal = game.create_animal(game.animals[11], Vector2(515, 900)); b.progression_eligible = true
	check(await real_drop(game, 360), "Golden fixture takes real drop")
	a.linear_velocity = Vector2(220, 0); b.linear_velocity = Vector2(-220, 0)
	for i in range(300):
		await physics_frame
		if game.merge_manager.merge_count > 0: break
	check(game.merge_manager.merge_count == 1 and game.score == 1000 and int(game.progression.golden_merges) == 1, "real elephant contact awards Golden once")
	await undo(game)
	check(game.score == 0 and game.merge_manager.merge_count == 0 and int(game.progression.golden_merges) == 0 and game.pieces.get_child_count() == 2, "Undo restores both elephants and reverses Golden award")
	check(not game.golden_label.visible, "Undo clears Golden presentation")
	await dispose(game)
func tutorial_test() -> void:
	var game = new_game(false); await frames()
	game._begin_tutorial()
	check(game.tutorial_stage == 0 and await real_drop(game, 360), "tutorial fixture drops from stage zero")
	check(game.tutorial_stage == 2, "tutorial advanced after drop")
	await undo(game)
	check(game.tutorial_stage == 0 and game.get_node_or_null("HUD/Tutorial") != null, "Undo restores tutorial stage without duplicate overlay")
	await dispose(game)
func remove_test() -> void:
	var game = new_game(); await frames()
	check(await real_drop(game, 360), "Remove interaction has prior drop")
	var body: Animal = game.pieces.get_child(0)
	game._toggle_remove(); game._select_remove_at(body.global_position); await frames(4)
	check(game.remove_remaining == 0 and game.undo_snapshot.is_empty() and game.undo_button.disabled, "Remove invalidates pre-existing Undo snapshot")
	check(await real_drop(game, 500), "new drop after Remove creates new snapshot")
	await undo(game)
	check(game.remove_remaining == 0 and game.undo_remaining == 0 and game.pieces.get_child_count() == 0, "Undo never refunds Remove")
	await dispose(game)
func backup_failure_test() -> void:
	var game = new_game(); await frames()
	check(await real_drop(game, 360), "backup failure fixture takes a drop")
	check(game.save_session() == OK and game.save_session() == OK, "backup fixture has prior durable copies")
	var dir: String = ProjectSettings.globalize_path(SessionSave.PATH + ".bak.tmp")
	check(DirAccess.make_dir_absolute(dir) == OK, "backup write obstruction created")
	await undo(game)
	check(game.undo_remaining == 0 and game.pieces.get_child_count() == 0, "journal commits Undo despite ordinary mirror failure")
	DirAccess.remove_absolute(dir)
	var broken := FileAccess.open(SessionSave.PATH, FileAccess.WRITE); broken.store_string("corrupt primary"); broken.close()
	var recovered := SessionSave.load_session()
	check(recovered.status == "recovered" and recovered.data.undo_remaining == 0 and recovered.data.bodies.is_empty(), "journal prevents old backup refund after failed mirror and corrupt primary")
	check(DirAccess.make_dir_absolute(dir) == OK, "tombstone mirror obstruction created")
	check(SessionSave.clear_session(game.progression) == OK, "tombstone commits despite backup failure")
	DirAccess.remove_absolute(dir)
	broken = FileAccess.open(SessionSave.PATH, FileAccess.WRITE); broken.store_string("corrupt tombstone"); broken.close()
	check(SessionSave.load_session().status == "missing", "tombstone journal prevents resurrection after corrupt primary")
	await dispose(game)
	clear_save()
	game = new_game(); await frames()
	check(await real_drop(game, 360) and game.save_session() == OK and game.save_session() == OK, "Remove backup fixture prepared")
	check(DirAccess.make_dir_absolute(dir) == OK, "Remove mirror obstruction created")
	var body: Animal = game.pieces.get_child(0)
	game._toggle_remove(); game._select_remove_at(body.global_position); await frames(4)
	check(game.remove_remaining == 0 and game.pieces.get_child_count() == 0, "Remove checkpoint commits despite mirror failure")
	DirAccess.remove_absolute(dir)
	broken = FileAccess.open(SessionSave.PATH, FileAccess.WRITE); broken.store_string("corrupt primary"); broken.close()
	recovered = SessionSave.load_session()
	check(recovered.status == "recovered" and recovered.data.remove_remaining == 0 and recovered.data.bodies.is_empty(), "Remove checkpoint prevents backup refund")
	await dispose(game)
func stress_test() -> void:
	var game = new_game(false); await frames()
	for i in range(100):
		game.undo_remaining = 1 # Isolated fixture only.
		var ok := await real_drop(game, 360)
		if ok: await undo(game)
		check(ok and game.undo_remaining == 0 and game.pieces.get_child_count() == 0 and game.merge_manager.pending.is_empty(), "stress Undo %d" % (i + 1))
	await dispose(game)
func read_phase() -> void:
	var menu = (load("res://scenes/ui/MainMenu.tscn") as PackedScene).instantiate()
	root.add_child(menu); current_scene = menu; await frames(3)
	check(not menu.continue_button.disabled, "new process enables Continue")
	menu.continue_button.pressed.emit(); await frames(5)
	var game = current_scene
	check(game != menu and game.has_method("_request_undo"), "Continue opens gameplay")
	if game == menu or not game.has_method("_request_undo"):
		print("UNDO_READ checks=%d failures=%d" % [checks, failures]); quit(1); return
	check(game.undo_remaining == 1 and not game.undo_snapshot.is_empty() and not game.undo_button.disabled, "Continue restores undo snapshot and use")
	game._toggle_pause(); game._toggle_pause()
	check(game.undo_remaining == 1 and not game.undo_snapshot.is_empty(), "Pause and Resume preserve Undo snapshot and allowance")
	await undo(game)
	check(game.undo_remaining == 0 and game.pieces.get_child_count() == 0, "Continued snapshot can be undone")
	var doc := SessionSave.load_session()
	check(doc.status in ["ok", "recovered"] and doc.data.undo_remaining == 0, "used Undo is durable")
	await dispose(game)
	set_meta("continue_requested", true)
	game = new_game(); await frames(4)
	check(game.undo_remaining == 0 and game.undo_button.disabled, "Continue never replenishes Undo")
	print("UNDO_READ checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)

func verify_phase() -> void:
	var menu = (load("res://scenes/ui/MainMenu.tscn") as PackedScene).instantiate()
	root.add_child(menu); current_scene = menu; await frames(3)
	check(not menu.continue_button.disabled, "third process offers Continue")
	menu.continue_button.pressed.emit(); await frames(5)
	var game = current_scene
	check(game != menu and game.has_method("_request_undo"), "third process opens gameplay")
	if game != menu and game.has_method("_request_undo"):
		check(game.undo_remaining == 0 and game.undo_button.disabled and game.pieces.get_child_count() == 0, "spent Undo and restored board survive another process")
	print("UNDO_VERIFY checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
