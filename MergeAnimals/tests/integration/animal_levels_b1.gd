extends SceneTree
# B.1 §07 — all 12 animal levels and all 11 normal merge transitions.
# Contract data is read from resources/animals/*.tres through the loaded
# AnimalData resources (not hardcoded), and every transition is driven by a
# real physical collision of two landing bodies, not by a direct API call.
var scene := preload("res://scenes/game/Game.tscn")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1; print("%s: %s" % ["PASS" if ok else "FAIL", text])
	if not ok: failures += 1
func fresh() -> Node:
	paused = false
	var game = scene.instantiate()
	game.test_seed = 6102
	game.combo_enabled = false
	game.persist_best = false
	root.add_child(game)
	await process_frame
	game.danger_monitor.set_physics_process(false)
	return game
func run() -> void:
	var game = await fresh()
	# --- Contract table for all 12 levels -------------------------------
	var expect_names: Array = ["mouse", "hamster", "rabbit", "cat", "dog", "fox", "raccoon", "koala", "panda", "bear", "lion", "elephant"]
	check(game.animals.size() == 12, "12 animal resources are loaded")
	var rows: Array = []
	for i in range(12):
		var d: AnimalData = game.animals[i]
		rows.append(d)
		check(d.level == i + 1, "level %d is %s" % [i + 1, d.id])
		check(str(d.id) == expect_names[i], "id mapping for level %d is %s" % [i + 1, d.id])
		check(d.radius > 0.0 and d.body_mass > 0.0, "%s has positive radius and mass" % d.id)
		check(d.sprite != null and d.sprite.get_size().x > 0.0, "%s has a loadable sprite" % d.id)
		# Visual/physical agreement: AnimalVisual draws the texture into
		# Rect2(-r,-r,2r,2r), so the drawn box equals the collision diameter
		# regardless of the source texture resolution. A non-square texture
		# would stretch, so require square source art as well.
		var size: Vector2 = d.sprite.get_size()
		check(is_equal_approx(size.x, size.y) and size.x >= d.radius * 2.0,
			"%s sprite %dx%d is square and at least the %d px drawn box" % [d.id, int(size.x), int(size.y), int(d.radius * 2.0)])
		if i < 11:
			check(str(d.next_evolution_id) == expect_names[i + 1] and not d.golden_terminal, "%s evolves into %s" % [d.id, expect_names[i + 1]])
		else:
			check(d.golden_terminal and str(d.next_evolution_id) == "", "elephant is the golden terminal")
		check(d.merge_score > 0, "%s has a positive merge score" % d.id)
	# Monotonic physical growth: radius and mass must increase with level so
	# the stacking physics matches the visual progression.
	var monotonic := true
	for i in range(11):
		if rows[i + 1].radius <= rows[i].radius or rows[i + 1].body_mass <= rows[i].body_mass:
			monotonic = false
	check(monotonic, "radius and mass increase strictly across all 12 levels")
	var golden_bonus: int = int(game.golden_config.bonus_score)
	check(golden_bonus > 0, "golden merge score is configured (%d)" % golden_bonus)
	# Each Animal node must derive its physics from the resource.
	var probe: Animal = game.create_animal(game.animals[3], Vector2(360, 900))
	probe.freeze = true
	check(is_equal_approx(probe.mass, game.animals[3].body_mass), "Animal mass comes from AnimalData")
	check(is_equal_approx(probe.circle.shape.radius, game.animals[3].radius), "collision radius comes from AnimalData")
	check(probe.collision_layer == 1 and probe.collision_mask == 1, "animals share collision layer/mask 1 with walls")
	check(probe.continuous_cd and probe.contact_monitor and probe.max_contacts_reported >= 8, "CCD and contact monitoring are enabled on animals")
	probe.queue_free()
	await process_frame
	game.queue_free()
	await process_frame
	# --- All 11 transitions through real physical contact ----------------
	for i in range(11):
		game = await fresh()
		var data: AnimalData = game.animals[i]
		var expected: AnimalData = game.animals[i + 1]
		# Score contract: MergeManager emits `merged` with the EVOLVED data,
		# so the award is the target merge_score, not the source value.
		var award: int = expected.merge_score
		# Two identical animals resting side by side on the floor, pushed into
		# contact by gravity and their own velocity: a real narrowphase pair.
		var left: Animal = game.create_animal(data, Vector2(360 - data.radius * 0.9, 900))
		var right: Animal = game.create_animal(data, Vector2(360 + data.radius * 0.9, 900))
		left.progression_eligible = false
		var merged := false
		for frame in range(90):
			if game.merge_manager.merge_count >= 1:
				merged = true
				break
			await physics_frame
		var result: Animal = null
		for body in game.pieces.get_children():
			if body is Animal and body.data.id == expected.id:
				result = body
		check(merged, "level %d %s -> %s merges from real physical contact" % [i + 1, data.id, expected.id])
		check(result != null, "level %d produced exactly one %s body" % [i + 1, expected.id])
		var count_after: int = game.pieces.get_child_count()
		check(count_after == 1, "level %d originals were consumed (1 body left, got %d)" % [i + 1, count_after])
		check(game.score == award, "level %d scored exactly %d once (combo disabled, got %d)" % [i + 1, award, game.score])
		check(game.merge_manager.merge_count == 1, "level %d counted exactly one merge" % [i + 1])
		# No orphan reservation or lock may survive a successful commit.
		var locked := 0
		for body in game.pieces.get_children():
			if body.merge_locked: locked += 1
		check(locked == 0 and game.merge_manager.pending.is_empty(), "level %d released reservation and locks" % [i + 1])
		game.queue_free()
		await process_frame
	print("ANIMAL_LEVELS_B1 checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
