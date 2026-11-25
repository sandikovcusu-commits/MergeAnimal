extends SceneTree

# These are integration checks, not a substitute for real touch/mobile testing.
# Run after editor import: godot --headless --path . --script res://tests/integration/day2_suite.gd
var failures := 0
var checks := 0
var game
var scene := preload("res://scenes/game/Game.tscn")

func check(condition: bool, name: String) -> void:
	checks += 1
	if condition:
		print("PASS ", checks, ": ", name)
	else:
		failures += 1
		printerr("FAIL ", checks, ": ", name)

func _initialize() -> void:
	call_deferred("run")

func fixture() -> void:
	paused = false
	game = scene.instantiate()
	game.test_seed = 42
	game.persist_best = false
	root.add_child(game)
	await process_frame

func clear_fixture() -> void:
	paused = false
	game.queue_free()
	await process_frame

func run() -> void:
	# Merge transitions, score accounting, pair locks, and mixed IDs.
	for level in range(4):
		await fixture()
		var a = game.create_animal(game.animals[level], Vector2(270, 850))
		var b = game.create_animal(game.animals[level], Vector2(320, 850))
		var accepted: bool = game.merge_manager.request_merge(a, b)
		check(accepted, "%s pair accepted" % game.animals[level].id)
		check(not game.merge_manager.request_merge(a, b), "duplicate contact locked level %d" % (level + 1))
		game.merge_manager._commit_pending()
		check(game.pieces.get_child_count() == 1 and game.pieces.get_child(0).data.level == level + 2, "level %d produces next level" % (level + 1))
		check(game.score == game.animals[level + 1].merge_score, "level %d score counted once" % (level + 1))
		await clear_fixture()
	await fixture()
	var mouse = game.create_animal(game.animals[0], Vector2(180, 900))
	var hamster = game.create_animal(game.animals[1], Vector2(280, 900))
	check(not game.merge_manager.request_merge(mouse, hamster), "different levels do not merge")
	var b = game.create_animal(game.animals[0], Vector2(225, 900))
	var c = game.create_animal(game.animals[0], Vector2(370, 900))
	check(game.merge_manager.request_merge(mouse, b), "first of three reserves")
	check(not game.merge_manager.request_merge(mouse, c), "three-way contact cannot reuse animal")
	game.merge_manager._commit_pending()
	check(game.pieces.get_child_count() == 3, "three-way result keeps third and other-level body")
	await clear_fixture()

	await fixture()
	var group: Array = []
	for x in [160, 205, 425, 470]:
		group.append(game.create_animal(game.animals[0], Vector2(x, 900)))
	check(game.merge_manager.request_merge(group[0], group[1]) and game.merge_manager.request_merge(group[2], group[3]), "four bodies reserve two legal pairs")
	game.merge_manager._commit_pending()
	check(game.pieces.get_child_count() == 2 and game.score == 8, "four bodies produce two hamsters and two scores")
	var first = game.pieces.get_child(0)
	var second = game.pieces.get_child(1)
	check(game.merge_manager.request_merge(first, second), "result bodies can chain")
	game.merge_manager._commit_pending()
	check(game.pieces.get_child_count() == 1 and game.pieces.get_child(0).data.level == 3 and game.score == 16, "chain creates rabbit and correct score")
	await clear_fixture()

	await fixture()
	var wall_a = game.create_animal(game.animals[0], Vector2(109, 1060))
	var wall_b = game.create_animal(game.animals[0], Vector2(145, 1060))
	check(game.merge_manager.request_merge(wall_a, wall_b), "wall/floor pair accepted")
	game.merge_manager._commit_pending()
	var merged = game.pieces.get_child(0)
	check(merged.position.x - merged.data.radius >= game.left_bound, "merge corrected away from left wall")
	check(merged.position.y + merged.data.radius <= game.floor_height, "merge corrected above floor")
	await clear_fixture()

	# Spawn, queue, input and cooldown. Query after the physics server has advanced.
	await fixture()
	game._set_aim(-1000)
	check(is_equal_approx(game.aim_x, game.left_bound + game.current_data.radius + game.spawn_margin), "left aim clamp")
	game._set_aim(1000)
	check(is_equal_approx(game.aim_x, game.right_bound - game.current_data.radius - game.spawn_margin), "right aim clamp")
	game._set_aim(360)
	var old_next: AnimalData = game.next_data
	check(game.drop_animal(), "drop request accepted")
	check(not game.drop_animal(), "duplicate request rejected")
	await physics_frame
	await physics_frame
	check(game.spawn_count == 1, "one physical body spawned")
	check(game.current_data == old_next, "queue advances exactly once")
	check(game.spawn_state == game.SpawnState.COOLDOWN, "cooldown active")
	check(not game.drop_animal(), "cooldown rejects another request")
	check(not game.current_preview.visible, "preview hidden in cooldown")
	check(game.next_preview.data == game.next_data and game.current_preview.data == game.current_data, "preview data matches queue")
	await clear_fixture()

	await fixture()
	var cancelled := InputEventScreenTouch.new()
	cancelled.index = 1
	cancelled.position = Vector2(360, 600)
	cancelled.pressed = true
	game._unhandled_input(cancelled)
	cancelled.pressed = false
	cancelled.canceled = true
	game._unhandled_input(cancelled)
	check(not game.drop_requested and game.spawn_count == 0, "canceled touch does not drop")
	var emulated := InputEventMouseButton.new()
	emulated.button_index = MOUSE_BUTTON_LEFT
	emulated.device = InputEvent.DEVICE_ID_EMULATION
	emulated.position = Vector2(360, 600)
	emulated.pressed = true
	game._unhandled_input(emulated)
	emulated.pressed = false
	game._unhandled_input(emulated)
	check(not game.drop_requested, "emulated mouse ignored")
	var obstruction = game.create_animal(game.current_data, Vector2(360, game.spawn_height))
	await physics_frame
	await physics_frame
	game._set_aim(360)
	var old_current = game.current_data
	var old_queue = game.next_data
	game.drop_animal()
	await physics_frame
	await physics_frame
	check(game.spawn_count == 0 and game.current_data == old_current and game.next_data == old_queue, "blocked spawn does not change queue or add a body")
	check(is_instance_valid(obstruction), "blocking body not deleted")
	await clear_fixture()

	# Monitor logic with support and speed explicitly controlled: this is not a
	# replacement for real collision integration testing.
	await fixture()
	game.danger_monitor.set_physics_process(false)
	var hazard = game.create_animal(game.animals[0], Vector2(360, game.danger_height - 20))
	hazard.supported = false
	hazard.linear_velocity = Vector2(0, 150)
	game.danger_monitor._physics_process(2.1)
	check(game.danger_monitor.peak_time == 0.0 and game.is_playing(), "falling unsupported body ignored")
	hazard.supported = true
	hazard.linear_velocity = Vector2.ZERO
	game.danger_monitor._physics_process(1.0)
	check(game.danger_monitor.peak_time > 0.0 and game.is_playing(), "supported danger starts grace period")
	hazard.supported = false
	game.danger_monitor._physics_process(0.1)
	check(game.danger_monitor.peak_time == 0.0, "danger timer resets on loss of support")
	hazard.supported = true
	game.danger_monitor._physics_process(2.1)
	check(game.game_state == game.GameState.GAME_OVER and paused, "persistent danger ends and pauses game")
	check(not game.drop_animal(), "game over blocks drop")
	await clear_fixture()

	await fixture()
	game._toggle_pause()
	check(game.game_state == game.GameState.PAUSED and paused, "pause stops tree")
	check(not game.drop_animal(), "pause blocks drop")
	game._toggle_pause()
	check(game.is_playing() and not paused, "resume unpauses tree")
	await clear_fixture()

	print("Checks: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
