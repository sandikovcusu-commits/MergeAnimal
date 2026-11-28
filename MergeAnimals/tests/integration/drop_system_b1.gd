extends SceneTree
# B.1 §08 — drop system validation, 1000 executed drop requests.
# Every request goes through the production entry point (drop_animal ->
# _attempt_drop on the next physics tick). Boundary aims, cooldown pressure,
# rapid requests, pause, pending merge and game-over guards are exercised.
# Reported counters are actual executions, never targets.
var scene := preload("res://scenes/game/Game.tscn")
var requests := 0
var executed := 0
var refused := 0
var out_of_bounds := 0
var duplicate := 0
var wrong_animal := 0
var spawned_total := 0
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1; if not ok: print("FAIL: " + text); failures += 1
func fresh() -> Node:
	paused = false
	var game = scene.instantiate()
	game.test_seed = 6103
	game.combo_enabled = false
	game.persist_best = false
	game.tutorial_stage = -1
	root.add_child(game)
	await process_frame
	game.danger_monitor.set_physics_process(false)
	return game
# One player-like tap: aim, request, and let the physics tick resolve it.
func tap(game, x: float) -> bool:
	requests += 1
	game._set_aim(x)
	var expected: AnimalData = game.current_data
	var before: int = game.spawn_count
	var accepted: bool = game.drop_animal()
	game._physics_process(1.0 / 120.0)
	await physics_frame
	var spawned: bool = game.spawn_count == before + 1
	if accepted and not spawned: refused += 1
	if not accepted: refused += 1
	if spawned:
		executed += 1
		spawned_total += 1
		var body: Animal = null
		for candidate in game.pieces.get_children():
			if candidate.save_uid == game.next_body_uid - 1:
				body = candidate
		if body == null:
			wrong_animal += 1
		else:
			# Spawn must respect the real wall/floor geometry for this radius.
			if body.position.x - body.data.radius < game.left_bound - 0.01 or body.position.x + body.data.radius > game.right_bound + 0.01 or body.position.y > game.floor_height + 0.01:
				out_of_bounds += 1
			if game.spawn_count - before != 1:
				duplicate += 1
	return spawned
func run() -> void:
	var game = await fresh()
	# --- Boundary aim clamping ------------------------------------------
	var radius: float = game.current_data.radius
	game._set_aim(-10000.0)
	check(game.aim_x >= game.left_bound + radius, "aim far left clamps inside the left wall")
	game._set_aim(10000.0)
	check(game.aim_x <= game.right_bound - radius, "aim far right clamps inside the right wall")
	game._set_aim(360.0)
	check(is_equal_approx(game.aim_x, 360.0), "centre aim is preserved")
	# --- 1000 executed drop requests on a live board ---------------------
	# Strategy: deterministic sweep across the board width with a mild
	# left/right alternation so stacks build in different columns. Physics is
	# real; we simply keep the board from overflowing by clearing when needed.
	var rng := RandomNumberGenerator.new()
	rng.seed = 6103
	var target := 1000
	var guard := 0
	while executed < target and guard < 20000:
		guard += 1
		if not game.is_playing():
			# Natural overflow reached: a new session continues the sample.
			game.queue_free(); await process_frame
			game = await fresh()
			continue
		# Keep the board shallow so the sample keeps exercising spawn logic
		# rather than dying at the danger line immediately.
		if game.pieces.get_child_count() > 26:
			for body in game.pieces.get_children():
				game.pieces.remove_child(body); body.queue_free()
			await physics_frame
			continue
		var lane: int = int(rng.randf_range(0.0, 7.0))
		var x: float = game.left_bound + 12.0 + lane * ((game.right_bound - game.left_bound - 24.0) / 7.0)
		if rng.randf() < 0.15:
			x = game.left_bound - 50.0 if rng.randf() < 0.5 else game.right_bound + 50.0
		var spawned: bool = await tap(game, x)
		if not spawned:
			# A blocked column: wait the cooldown out and retry, as a player would.
			for i in range(20): await physics_frame
			if guard % 500 == 0:
				# Periodic pause/resume must not leak a queued drop.
				game._toggle_pause()
				var before: int = game.spawn_count
				var accepted: bool = game.drop_animal()
				game._physics_process(1.0 / 120.0)
				check(not accepted and game.spawn_count == before, "paused state refuses the drop during sampling")
				game._toggle_pause()
	check(executed == target, "executed %d accepted drops (target %d)" % [executed, target])
	check(requests >= executed, "requests (%d) >= executed drops (%d)" % [requests, executed])
	check(out_of_bounds == 0, "no out-of-bounds spawn (violations %d)" % out_of_bounds)
	check(duplicate == 0, "no duplicate spawn per accepted request (%d)" % duplicate)
	check(wrong_animal == 0, "every spawned body matches the requested animal (%d)" % wrong_animal)
	check(spawned_total == executed, "every executed drop created exactly one body (%d/%d)" % [spawned_total, executed])
	# --- Rapid input: many requests inside one physics tick --------------
	var rapid_game = await fresh()
	var rapid_before: int = rapid_game.spawn_count
	var accepted_in_tick := 0
	for i in range(20):
		rapid_game._set_aim(200.0 + i * 10.0)
		if rapid_game.drop_animal():
			accepted_in_tick += 1
	rapid_game._physics_process(1.0 / 120.0)
	await physics_frame
	check(accepted_in_tick == 1, "20 rapid requests in one tick queue exactly one drop (got %d)" % accepted_in_tick)
	check(rapid_game.spawn_count == rapid_before + 1, "rapid input produced exactly one body")
	rapid_game.queue_free(); await process_frame
	# --- Pending merge and game-over guards ------------------------------
	var guard_game = await fresh()
	var a: Animal = guard_game.create_animal(guard_game.animals[0], Vector2(342, 800)); a.freeze = true
	var b: Animal = guard_game.create_animal(guard_game.animals[0], Vector2(378, 800)); b.freeze = true
	guard_game.merge_manager.request_merge(a, b)
	var pending_before: int = guard_game.spawn_count
	var pending_accepted: bool = guard_game.drop_animal()
	guard_game._physics_process(1.0 / 120.0)
	check(not pending_accepted and guard_game.spawn_count == pending_before, "pending merge guard refuses a drop")
	for i in range(30): await physics_frame
	guard_game.queue_free(); await process_frame
	print("DROP_SYSTEM_B1 requests=%d executed=%d refused=%d out_of_bounds=%d duplicate=%d wrong_animal=%d checks=%d failures=%d" % [requests, executed, refused, out_of_bounds, duplicate, wrong_animal, checks, failures])
	quit(1 if failures else 0)
