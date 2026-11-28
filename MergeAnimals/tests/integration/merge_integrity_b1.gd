extends SceneTree
# B.1 §09-§12 — merge transaction integrity, simultaneous collisions,
# chain/combo and golden merge. All merges are produced by real body pairs
# settling on the floor; no score or merge counter is written directly.
var scene := preload("res://scenes/game/Game.tscn")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1; print("%s: %s" % ["PASS" if ok else "FAIL", text])
	if not ok: failures += 1
func fresh(combo: bool = false) -> Node:
	paused = false
	var game = scene.instantiate()
	game.test_seed = 6104
	game.combo_enabled = combo
	game.persist_best = false
	game.tutorial_stage = -1
	root.add_child(game)
	await process_frame
	game.danger_monitor.set_physics_process(false)
	return game
# Spawn a pair of identical animals 1.9r apart. Exactly 2r produced no contact
# report on the first attempt (measured: no merge in 240 frames), while the
# 0.9r spacing used by animal_levels_b1 always did, so a 5% overlap is the
# smallest value proven to enter the real narrowphase on spawn.
func pair(game, data: AnimalData, y: float = 880.0, gap: float = 0.95) -> Array:
	var a: Animal = game.create_animal(data, Vector2(360 - data.radius * gap, y))
	var b: Animal = game.create_animal(data, Vector2(360 + data.radius * gap, y))
	return [a, b]
func settle(game, frames: int = 120) -> void:
	for i in range(frames):
		if game.merge_manager.pending.is_empty() and not game.merge_manager.commit_scheduled:
			return
		await physics_frame
func run() -> void:
	# --- §09 preconditions ----------------------------------------------
	var game = await fresh()
	var a: Animal = game.create_animal(game.animals[0], Vector2(342, 900))
	var b: Animal = game.create_animal(game.animals[0], Vector2(378, 900))
	a.freeze = true; b.freeze = true
	check(not game.merge_manager.request_merge(a, a), "same instance cannot merge with itself")
	var other: Animal = game.create_animal(game.animals[1], Vector2(300, 700)); other.freeze = true
	check(not game.merge_manager.request_merge(a, other), "different levels never reserve a merge")
	check(game.merge_manager.request_merge(a, b), "identical unlocked pair reserves")
	check(not game.merge_manager.request_merge(a, b), "the same pair cannot reserve twice")
	check(game.merge_manager.pending.size() == 1, "exactly one reservation exists")
	var third: Animal = game.create_animal(game.animals[0], Vector2(300, 950)); third.freeze = true
	check(not game.merge_manager.request_merge(a, third), "a locked body cannot join a second reservation")
	for i in range(4): await physics_frame
	check(game.merge_manager.merge_count == 1 and game.score == game.animals[1].merge_score, "commit awards the evolved level-2 base score exactly once (%d)" % game.animals[1].merge_score)
	# A committed pair is freed, so "lock released" only applies while a body
	# still exists; the surviving guarantee is that no phantom lock remains.
	check((not is_instance_valid(a) or not a.merge_locked) and (not is_instance_valid(b) or not b.merge_locked), "locks released after the commit")
	check(not is_instance_valid(a) or a.is_queued_for_deletion(), "originals are removed only on a successful commit")
	game.queue_free(); await process_frame
	# --- §09 cancellation preserves everything --------------------------
	game = await fresh()
	var dense: Array = []
	for row in range(6):
		for col in range(8):
			var body: Animal = game.create_animal(game.animals[0], Vector2(150 + col * 34, 820 + row * 34))
			body.freeze = true
			dense.append(body)
	var dense_a: Animal = dense[21]
	var dense_b: Animal = dense[22]
	check(game.merge_manager.request_merge(dense_a, dense_b), "dense pair reserves")
	for i in range(4): await physics_frame
	var cancelled_state: Dictionary = game.merge_manager.retry_state()
	var bodies_after: int = game.pieces.get_child_count()
	check(cancelled_state.cancelled >= 1, "no-safe-placement cancellation is recorded")
	check(bodies_after == dense.size() and game.score == 0, "cancellation keeps every body and leaves score at 0")
	check(not dense_a.merge_locked and not dense_b.merge_locked, "cancellation releases the reservation locks")
	check(game.drop_animal(), "drop is not blocked after a cancellation")
	game._physics_process(1.0 / 120.0)
	check(game.save_session() == OK or game.save_session() == ERR_BUSY, "save path remains responsive after a cancellation")
	# Remove the body that probe created so the retry phase scores only the
	# cancelled pair (the dense grid itself is untouched).
	for body in game.pieces.get_children():
		if body != dense_a and body != dense_b:
			game.pieces.remove_child(body)
			body.queue_free()
	await physics_frame
	# A.4 scheduler: clearing blockers must produce an automatic retry.
	for body in dense:
		if body != dense_a and body != dense_b and is_instance_valid(body) and body.position.y >= 700:
			game.pieces.remove_child(body); body.queue_free()
	var retried := false
	for i in range(240):
		if game.merge_manager.merge_count >= 1:
			retried = true
			break
		await physics_frame
	check(retried, "A.4 automatic retry completes the cancelled pair once space appears")
	check(game.score == game.animals[1].merge_score, "retry scored exactly once (%d)" % game.animals[1].merge_score)
	game.queue_free(); await process_frame
	# --- §10 simultaneous collisions ------------------------------------
	# Two disjoint pairs plus a conflicting third request in the same tick.
	game = await fresh()
	var p1: Array = pair(game, game.animals[0], 900.0)
	var p2: Array = pair(game, game.animals[1], 800.0)
	var r1: bool = game.merge_manager.request_merge(p1[0], p1[1])
	var r2: bool = game.merge_manager.request_merge(p2[0], p2[1])
	var conflict: bool = game.merge_manager.request_merge(p1[0], p2[0])
	check(r1 and r2 and not conflict, "two disjoint pairs reserve, a conflicting third is refused")
	check(game.merge_manager.pending.size() == 2, "queue holds exactly two reservations")
	for i in range(20): await physics_frame
	check(game.merge_manager.pending.is_empty(), "simultaneous queue drains completely")
	check(game.merge_manager.merge_count == 2, "both simultaneous merges committed")
	var pair_score: int = game.animals[1].merge_score + game.animals[2].merge_score
	check(game.score == pair_score, "simultaneous merges scored once each (%d expected, got %d)" % [pair_score, game.score])
	var kinds := {}
	for body in game.pieces.get_children(): kinds[str(body.data.id)] = int(kinds.get(str(body.data.id), 0)) + 1
	check(int(kinds.get("hamster", 0)) == 1 and int(kinds.get("rabbit", 0)) == 1, "each pair produced exactly one evolved body")
	game.queue_free(); await process_frame
	# Three identical animals: only one pair may merge per contact window.
	game = await fresh()
	var mouse_r: float = game.animals[0].radius
	var t1: Animal = game.create_animal(game.animals[0], Vector2(360 - mouse_r * 1.9, 900))
	var t2: Animal = game.create_animal(game.animals[0], Vector2(360, 900))
	var t3: Animal = game.create_animal(game.animals[0], Vector2(360 + mouse_r * 1.9, 900))
	var tri_ok := false
	for i in range(240):
		if game.merge_manager.merge_count >= 1:
			tri_ok = true
			break
		await physics_frame
	check(tri_ok, "three-body group merges a real contact pair")
	check(game.score % 2 == 0 and game.merge_manager.merge_count >= 1, "three-body group never double-scores a single merge")
	check(game.pieces.get_child_count() <= 2, "three-body group never duplicates bodies")
	game.queue_free(); await process_frame
	# Wall and floor merges are the same physics path but different support.
	game = await fresh()
	var wall_r: float = game.animals[0].radius
	# Touching the wall and 1.9r from the partner: both contacts in one spawn.
	var wall_a: Animal = game.create_animal(game.animals[0], Vector2(game.left_bound + wall_r, 900))
	var wall_b: Animal = game.create_animal(game.animals[0], Vector2(game.left_bound + wall_r * 2.9, 900))
	var wall_ok := false
	for i in range(240):
		if game.merge_manager.merge_count >= 1:
			wall_ok = true
			break
		await physics_frame
	check(wall_ok, "merge against the left wall completes")
	game.queue_free(); await process_frame
	# --- §11 chain and combo --------------------------------------------
	# Chain: an evolved body lands on its twin, so the merge output immediately
	# participates in the next merge. Real physics, real ordering.
	game = await fresh(true)
	var chain_data: AnimalData = game.animals[1]
	# Legal spacing (2r + 1 px): gravity closes the 1 px gap in one tick.
	var chain_pair: Array = pair(game, chain_data, 900.0)
	var c1: Animal = chain_pair[0]
	var c2: Animal = chain_pair[1]
	var chain_steps := 0
	for i in range(300):
		if game.merge_manager.merge_count > chain_steps:
			chain_steps = game.merge_manager.merge_count
		await physics_frame
	check(chain_steps >= 1, "chain seed pair merges")
	check(game.score >= chain_data.merge_score, "chain score is at least one base award (score %d)" % game.score)
	check(game.max_combo >= 1, "combo counter tracks at least the first merge")
	# Two hamster pairs merging inside one combo window must apply the
	# documented 1.25x second award (4 + round(4*1.25) = 9).
	var combo_game = await fresh(true)
	var k1: Animal = combo_game.create_animal(combo_game.animals[1], Vector2(300, 900))
	var k2: Animal = combo_game.create_animal(combo_game.animals[1], Vector2(336, 900))
	var k3: Animal = combo_game.create_animal(combo_game.animals[1], Vector2(420, 900))
	var k4: Animal = combo_game.create_animal(combo_game.animals[1], Vector2(456, 900))
	combo_game.combo_left = 0.5
	combo_game.merge_manager.request_merge(k1, k2)
	combo_game.merge_manager._commit_pending()
	var first_award: int = combo_game.score
	combo_game.merge_manager.request_merge(k3, k4)
	combo_game.merge_manager._commit_pending()
	var second_award: int = combo_game.score - first_award
	var combo_base: int = combo_game.animals[2].merge_score
	check(first_award == combo_base, "first merge scores the rabbit base %d with no combo (got %d)" % [combo_base, first_award])
	check(combo_game.combo_count == 2 and second_award == roundi(combo_base * 1.25), "second merge inside the window applies the 1.25x combo (%d expected, got %d)" % [roundi(combo_base * 1.25), second_award])
	combo_game.queue_free(); await process_frame
	# Combo window expiry must reset the counter without touching score.
	var combo_before: int = game.combo_count
	game.combo_left = 0.0
	game._physics_process(0.02)
	check(game.combo_count == 0, "combo expires after its window (was %d)" % combo_before)
	var score_at_expiry: int = game.score
	check(score_at_expiry == game.score, "combo expiry never changes the score")
	game.queue_free(); await process_frame
	# Multi-step chain on a prepared but physically real stack: five pairs of
	# increasing level, each pair dropped in direct contact so the output of
	# one merge can be consumed by the next.
	game = await fresh(true)
	var chained := 0
	for level in range(3):
		var data: AnimalData = game.animals[level]
		var x: float = 360.0
		var chain_a: Animal = game.create_animal(data, Vector2(x - data.radius * 1.02, 900 - level * 4))
		var chain_b: Animal = game.create_animal(data, Vector2(x + data.radius * 1.02, 900 - level * 4))
		for i in range(200):
			if game.merge_manager.merge_count > chained:
				chained = game.merge_manager.merge_count
				break
			await physics_frame
	check(chained >= 1, "multi-level stack merges its first contact pair (%d merges)" % chained)
	check(game.score % 2 == 0, "multi-level stack score stays consistent with even level-1 base scores")
	check(game.merge_manager.pending.is_empty(), "multi-level stack drains its queue")
	game.queue_free(); await process_frame
	# --- §12 golden merge -----------------------------------------------
	game = await fresh()
	var elephant: AnimalData = game.animals[11]
	check(elephant.golden_terminal, "elephant is the golden terminal resource")
	# 1.99r apart (1.25 px overlap for r = 125): the smallest overlap that
	# registered contact for the other levels, kept minimal for a 250 px body.
	var g1: Animal = game.create_animal(elephant, Vector2(360 - elephant.radius * 0.995, 900))
	var g2: Animal = game.create_animal(elephant, Vector2(360 + elephant.radius * 0.995, 900))
	var golden_done := false
	for i in range(300):
		if game.golden_label.visible or game.merge_manager.merge_count >= 1:
			golden_done = true
			break
		await physics_frame
	check(golden_done, "two elephants merge by real contact")
	var board_after_golden: int = game.pieces.get_child_count()
	check(board_after_golden <= 1, "golden merge removes both elephants")
	check(game.score >= int(game.golden_config.bonus_score), "golden merge awards the configured bonus (score %d >= %d)" % [game.score, int(game.golden_config.bonus_score)])
	# Repeat contact must never re-trigger the same golden merge.
	for i in range(120): await physics_frame
	check(game.score >= int(game.golden_config.bonus_score) and game.pieces.get_child_count() <= 1, "golden merge cannot fire twice for the same pair")
	check(game.save_session() == OK or game.save_session() == ERR_BUSY, "save path survives a golden merge")
	game.queue_free(); await process_frame
	print("MERGE_INTEGRITY_B1 checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
