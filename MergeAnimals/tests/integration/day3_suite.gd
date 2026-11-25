extends SceneTree
var scene := preload("res://scenes/game/Game.tscn")
var checks := 0
var failures := 0
var game
var ids := ["mouse", "hamster", "rabbit", "cat", "dog", "fox", "raccoon", "koala", "panda", "bear", "lion", "elephant"]
var radii := [18, 23, 29, 35, 42, 50, 59, 69, 80, 93, 108, 125]
var scores := [2, 4, 8, 12, 20, 32, 48, 70, 100, 150, 220, 500]
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, name: String) -> void:
	checks += 1
	print("%s %d: %s" % ["PASS" if ok else "FAIL", checks, name])
	if not ok:
		failures += 1
func fixture() -> void:
	paused = false
	game = scene.instantiate()
	game.test_seed = 42
	game.persist_best = false
	root.add_child(game)
	await process_frame
func cleanup() -> void:
	paused = false
	game.queue_free()
	await process_frame
func run() -> void:
	await fixture()
	check(game.animals.size() == 12, "12 configured AnimalData resources")
	for i in range(12):
		var d = game.animals[i]
		check(d.id == StringName(ids[i]) and d.level == i + 1 and d.radius == radii[i] and d.merge_score == scores[i], "animal %d identity radius score" % (i + 1))
	for i in range(11):
		check(game.find_animal(game.animals[i].next_evolution_id) == game.animals[i + 1], "evolution link %d" % (i + 1))
	check(game.animals[11].golden_terminal and game.animals[11].next_evolution_id == &"", "elephant golden terminal")
	check(game.right_bound - game.left_bound >= 4 * game.animals[11].radius, "two elephant diameters fit container")
	var counts := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	game.rng.seed = 13579
	for i in range(10000):
		var d = game._pick_animal()
		counts[d.level - 1] += 1
	print("Spawn distribution seed=13579 n=10000: ", counts)
	for i in range(5):
		check(absf(counts[i] / 10000.0 - [0.30, 0.25, 0.20, 0.15, 0.10][i]) < 0.02, "spawn weight %s within 2 percentage points" % ids[i])
	var high := 0
	for i in range(5, 12):
		high += counts[i]
	check(high == 0, "no high tier randomly spawns")
	game.rng.seed = 13579
	var first = game._pick_animal().id
	game.rng.seed = 13579
	check(game._pick_animal().id == first, "spawn seed reproducible")
	game.score = 0
	game._award_merge(100)
	check(game.combo_count == 1 and game.score == 100, "combo start 1x")
	game._award_merge(100)
	check(game.combo_count == 2 and game.score == 225, "combo x2 1.25")
	game._award_merge(100)
	check(game.combo_count == 3 and game.score == 375, "combo x3 1.5")
	game._award_merge(100)
	check(game.combo_count == 4 and game.score == 550, "combo x4 1.75")
	game._award_merge(100)
	game._award_merge(100)
	check(game.combo_count == 6 and game.score == 950, "combo x5+ capped 2x")
	game._toggle_pause()
	var held: float = game.combo_left
	await physics_frame
	check(game.combo_left == held, "combo timer pauses")
	game._toggle_pause()
	game.combo_left = 0.001
	game._physics_process(0.01)
	check(game.combo_count == 0, "combo timeout resets")
	game._award_merge(100)
	check(game.combo_count == 1 and game.score == 1050, "post timeout returns to 1x")
	game._on_game_over()
	check(game.combo_count == 0 and game.combo_left == 0.0, "game over resets combo")
	await cleanup()
	# Actual Godot contact, not direct request_merge, for every transition including gold.
	for i in range(12):
		await fixture()
		game.danger_monitor.set_physics_process(false)
		var d = game.animals[i]
		var left = game.create_animal(d, Vector2(360 - d.radius - 10, 700))
		var right = game.create_animal(d, Vector2(360 + d.radius + 10, 700))
		left.linear_velocity = Vector2(200, 0)
		right.linear_velocity = Vector2(-200, 0)
		for frame in range(180):
			await physics_frame
			if game.merge_manager.merge_count > 0:
				break
		var expected_score: int = 1000 if i == 11 else scores[i + 1]
		var count_expected := 0 if i == 11 else 1
		var correct: bool = game.merge_manager.merge_count == 1 and game.pieces.get_child_count() == count_expected and game.score == expected_score
		if i < 11 and game.pieces.get_child_count() == 1:
			correct = correct and game.pieces.get_child(0).data.id == StringName(ids[i + 1])
		check(correct, "real collision %s -> %s (score=%d, count=%d)" % [ids[i], "gold" if i == 11 else ids[i + 1], game.score, game.pieces.get_child_count()])
		if i == 11:
			await physics_frame
			await physics_frame
			check(game.score == 1000 and game.is_playing() and game.merge_manager.merge_count == 1, "golden duplicate protected; play continues")
		await cleanup()
	await fixture()
	check(game.combo_count == 0 and game.highest_level == 1 and game.score == 0, "new scene resets combo score guide")
	game.create_animal(game.animals[7], Vector2(360, 800))
	check(game.highest_level == 8, "guide records highest created animal")
	await cleanup()
	print("Day3 checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
