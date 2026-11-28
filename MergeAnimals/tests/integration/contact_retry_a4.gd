extends SceneTree
# A.4 MERGE-CONTACT-RETRY-004: a cancelled pair that stays in contact must be
# re-requested automatically once relevant geometry changes, with no explicit
# request_merge call. Frozen bodies; MergeManager physics stays enabled so the
# throttled scheduler runs; DangerMonitor physics is disabled except where a
# scenario drives it manually.
var scene := preload("res://scenes/game/Game.tscn")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1; print("%s %s" % ["PASS" if ok else "FAIL", text])
	if not ok: failures += 1
func fresh():
	var game = scene.instantiate(); game.test_seed = 414; game.combo_enabled = false
	root.add_child(game); await process_frame
	game.danger_monitor.set_physics_process(false)
	return game
func dispose(game) -> void:
	paused = false; game.queue_free(); await process_frame
func dense_board(game) -> Array:
	var a: Animal; var b: Animal
	for row in range(7):
		for col in range(7):
			var body: Animal = game.create_animal(game.animals[0], Vector2(252+col*36,800+row*36)); body.freeze = true
			if row == 3 and col == 3: a = body
			if row == 3 and col == 4: b = body
	return [a, b]
func clear_blockers(game, a: Animal, b: Animal) -> void:
	for body in game.pieces.get_children():
		if body != a and body != b and body.position.y >= 700:
			game.pieces.remove_child(body); body.queue_free()
func wait_merges(game, want: int, frames: int = 180) -> bool:
	for i in range(frames):
		if game.merge_manager.merge_count >= want: return true
		await physics_frame
	return game.merge_manager.merge_count >= want
func run() -> void:
	# Main scenario: cancel, static blocker (no retry), blocker moves, auto retry.
	var game = await fresh()
	var pair: Array = dense_board(game)
	var a: Animal = pair[0]; var b: Animal = pair[1]
	check(game.merge_manager.request_merge(a, b), "dense pair reserves")
	for i in range(4): await physics_frame
	check(game.merge_manager.pending.is_empty() and game.pieces.get_child_count() == 49 and game.score == 0, "no-safe cancellation preserves bodies and score")
	var state: Dictionary = game.merge_manager.retry_state()
	check(state.failed == 1 and state.cancelled == 1 and state.attempts == 0, "cancellation tracked without retry while geometry unchanged")
	for i in range(45): await physics_frame
	state = game.merge_manager.retry_state()
	check(game.merge_manager.merge_count == 0 and state.attempts == 0 and state.failed == 1, "static blocker produces no automatic retry")
	check(game.save_session() == OK and not game._session_snapshot().is_empty(), "save not blocked after cancellation")
	clear_blockers(game, a, b)
	check(await wait_merges(game, 1), "blocker movement triggers automatic retry without explicit re-request")
	state = game.merge_manager.retry_state()
	check(state.successes == 1 and state.attempts >= 1 and state.failed == 0, "automatic retry reserved exactly once")
	check(game.score == 4 and game.merge_manager.pending.is_empty(), "retry merge awards score exactly once")
	for i in range(45): await physics_frame
	check(game.merge_manager.merge_count == 1 and game.score == 4, "no duplicate merge after automatic retry")
	game._set_aim(360); game._attempt_drop()
	check(game.spawn_count == 1, "drop not blocked after cancellation and retry")
	check(game.save_session() == OK and not game._session_snapshot().is_empty(), "save snapshot valid after automatic retry")
	await dispose(game)
	# Contact broken: tracked pair must be dropped, never merged.
	game = await fresh()
	pair = dense_board(game); a = pair[0]; b = pair[1]
	check(game.merge_manager.request_merge(a, b), "contact-break pair reserves")
	for i in range(4): await physics_frame
	b.position = Vector2(600, 1000)
	for i in range(45): await physics_frame
	state = game.merge_manager.retry_state()
	check(state.failed == 0 and state.contact_broken >= 1 and game.merge_manager.merge_count == 0, "broken contact drops retry tracking without merge")
	await dispose(game)
	# One body deleted: entry pruned, no crash, no merge.
	game = await fresh()
	pair = dense_board(game); a = pair[0]; b = pair[1]
	check(game.merge_manager.request_merge(a, b), "deletion pair reserves")
	for i in range(4): await physics_frame
	game.pieces.remove_child(a); a.queue_free()
	for i in range(45): await physics_frame
	state = game.merge_manager.retry_state()
	check(state.failed == 0 and game.merge_manager.merge_count == 0, "deleted body prunes retry tracking")
	await dispose(game)
	# Pause gate: no retry while not playing; retry resumes after resume.
	game = await fresh()
	pair = dense_board(game); a = pair[0]; b = pair[1]
	check(game.merge_manager.request_merge(a, b), "pause pair reserves")
	for i in range(4): await physics_frame
	clear_blockers(game, a, b)
	game.game_state = game.GameState.PAUSED
	for i in range(45): await physics_frame
	check(game.merge_manager.merge_count == 0, "no automatic retry while paused")
	game.game_state = game.GameState.PLAYING
	check(await wait_merges(game, 1), "automatic retry resumes after resume")
	await dispose(game)
	# Game Over gate: scheduler inactive in terminal state. The board must be
	# built above the Danger Line, otherwise the monitor clears the timers and
	# no overflow can occur (the A.4 first attempt made exactly that mistake).
	game = await fresh()
	for row in range(7):
		for col in range(7):
			var body: Animal = game.create_animal(game.animals[0], Vector2(252+col*36, 236+row*36)); body.freeze = true
			if row == 4 and col == 3: a = body
			if row == 4 and col == 4: b = body
	check(game.merge_manager.request_merge(a, b), "game-over pair reserves above danger line")
	for i in range(4): await physics_frame
	check(game.merge_manager.pending.is_empty() and game.score == 0 and game.merge_manager.retry_state().failed == 1, "above-line danger cancel tracked without merge")
	game.danger_monitor.timers[a.instance_uid] = 1.95
	game.danger_monitor.timers[b.instance_uid] = 1.95
	a.supported = true; b.supported = true
	game.danger_monitor._physics_process(game.danger_monitor.grace_period + 0.1)
	for i in range(5): await process_frame
	check(game.game_state == game.GameState.GAME_OVER, "danger overflow reaches game over")
	paused = false
	for i in range(45): await physics_frame
	check(game.merge_manager.merge_count == 0 and game.score == 0, "no automatic retry after game over")
	await dispose(game)
	# Golden terminal merge is unaffected and never enters retry tracking.
	game = await fresh()
	var g1: Animal = game.create_animal(game.animals[11], Vector2(342, 900)); g1.freeze = true
	var g2: Animal = game.create_animal(game.animals[11], Vector2(378, 900)); g2.freeze = true
	check(game.merge_manager.request_merge(g1, g2), "golden pair reserves")
	for i in range(4): await physics_frame
	state = game.merge_manager.retry_state()
	check(game.merge_manager.merge_count == 1 and state.failed == 0 and state.cancelled == 0, "golden merge commits without retry tracking")
	await dispose(game)
	# Explicit clear (undo restore path) drops stale tracking.
	game = await fresh()
	pair = dense_board(game); a = pair[0]; b = pair[1]
	check(game.merge_manager.request_merge(a, b), "clear pair reserves")
	for i in range(4): await physics_frame
	game.merge_manager.clear_retry_state()
	clear_blockers(game, a, b)
	for i in range(45): await physics_frame
	check(game.merge_manager.retry_state().failed == 0 and game.merge_manager.merge_count == 0, "cleared retry state produces no stale merge")
	await dispose(game)
	print("CONTACT_RETRY_A4 checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
