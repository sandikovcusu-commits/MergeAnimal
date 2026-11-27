extends SceneTree
# Deterministic QA fixture: a dense, frozen 7x7 mouse lattice. Its members
# touch without pair overlap. Two touching mice are reserved; all eight rings
# in the old 96px local search are blocked, while a distant safe area exists.
# Not a human/natural-gameplay simulation. The same fixture runs before/after.
var checks := 0
var failures := 0
var scene := preload("res://scenes/game/Game.tscn")
func check(value: bool, label: String) -> void:
	checks += 1
	print("%s %s" % ["PASS" if value else "FAIL", label])
	if not value: failures += 1
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = scene.instantiate()
	game.test_seed = 121
	game.combo_enabled = false
	root.add_child(game)
	await process_frame
	game.danger_monitor.set_physics_process(false)
	game.merge_manager.set_physics_process(false)
	var a: Animal
	var b: Animal
	for row in range(7):
		for col in range(7):
			var piece: Animal = game.create_animal(game.animals[0], Vector2(252 + col * 36, 800 + row * 36))
			piece.freeze = true
			if row == 3 and col == 3: a = piece
			if row == 3 and col == 4: b = piece
	var center: Vector2 = (a.position + b.position) * 0.5
	var free_far := true
	var far := Vector2(360, 500)
	for body in game.pieces.get_children():
		if body != a and body != b and far.distance_to(body.position) < game.animals[1].radius + body.data.radius + 1.0:
			free_far = false
	check(free_far and far.distance_to(center) > 96.0, "safe distant slot exists beyond old search")
	check(game.merge_manager.request_merge(a,b), "touching pair reserves")
	check(not game.merge_manager.request_merge(a,b), "duplicate pair cannot reserve")
	var found: Variant = game.find_merge_position(center, game.animals[1].radius, a, b)
	var mode := OS.get_environment("MERGE_EXPECT")
	if mode == "baseline":
		check(found == null, "baseline local search misses available distant slot")
		for i in range(120): game.merge_manager._commit_pending()
		check(game.merge_manager.pending.size() == 1 and a.merge_locked and b.merge_locked and game.score == 0, "120 deferred commits preserve stuck reservation without score")
		check(game._session_snapshot().is_empty() and game.save_session() == ERR_BUSY, "stuck reservation blocks safe save")
		game._attempt_drop()
		check(game.spawn_count == 0, "stuck reservation blocks drop")
	else:
		check(found is Vector2 and found.distance_to(center) > 96.0, "fallback finds safe slot beyond old search")
		game.merge_manager._commit_pending()
		check(game.merge_manager.pending.is_empty() and game.merge_manager.merge_count == 1 and game.score == 4, "single pending merge committed with one score")
		check(game.pieces.get_child_count() == 48, "49 original bodies become 48 without extra loss")
		var result: Animal
		for body in game.pieces.get_children():
			if body.data.id == &"hamster": result = body
		var clear := result != null
		if result:
			for body in game.pieces.get_children():
				if body != result and result.position.distance_to(body.position) < result.data.radius + body.data.radius + 0.99: clear = false
		check(clear, "replacement has no overlap with other body")
		check(not game._session_snapshot().is_empty() and game.save_session() == OK, "post-merge snapshot is valid and saves")
		game._set_aim(360)
		game._attempt_drop()
		check(game.spawn_count == 1, "new drop works after resolved reservation")
	if mode == "fixed":
		game.queue_free()
		await process_frame
		game = scene.instantiate(); game.test_seed = 122; game.combo_enabled = false
		root.add_child(game); await process_frame
		game.danger_monitor.set_physics_process(false); game.merge_manager.set_physics_process(false)
		a = game.create_animal(game.animals[0], Vector2(342, 820)); a.freeze = true
		b = game.create_animal(game.animals[0], Vector2(378, 820)); b.freeze = true
		# Deliberately overlapping frozen blockers: tests safe cancellation, not natural physics.
		for y in [680, 820, 960]:
			for x in [220, 360, 500]:
				var blocker: Animal = game.create_animal(game.animals[11], Vector2(x, y)); blocker.freeze = true
		check(game.find_merge_position(Vector2(360, 820), game.animals[1].radius, a, b) == null, "full bounded search proves no candidate in synthetic blocker fixture")
		check(game.merge_manager.request_merge(a,b), "no-space pair reserved")
		game.merge_manager._commit_pending()
		check(game.merge_manager.pending.is_empty() and not a.merge_locked and not b.merge_locked, "only failed no-space reservation cancelled")
		check(game.pieces.get_child_count() == 11 and game.score == 0 and game.merge_manager.merge_count == 0, "cancellation preserves both animals and grants no score")
		check(game.save_session() == OK, "cancelled pair leaves a valid safe snapshot")
		check(game.merge_manager.request_merge(a,b), "pair can reserve again on a new request")
		a.queue_free(); await process_frame
		game.merge_manager._commit_pending()
		check(game.merge_manager.pending.is_empty() and not b.merge_locked and game.score == 0, "freed reference cancels reservation and unlocks survivor")
	print("MERGE_DEADLOCK_FIXTURE mode=%s checks=%d failures=%d" % [mode, checks, failures])
	game.queue_free()
	quit(0 if failures == 0 else 1)
