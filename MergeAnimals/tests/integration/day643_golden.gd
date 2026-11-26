extends SceneTree
# Challenge access is seeded. Cat, Elephant and Golden achievement evidence
# comes only from actual configured/random queue drops and physical contacts.
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", text])
	if not ok: failures += 1
func new_level(id: int, seed: int):
	set_meta("challenge_id", id)
	var game = (load("res://scenes/game/ChallengeGame.tscn") as PackedScene).instantiate()
	game.test_seed = seed; root.add_child(game); current_scene = game
	await process_frame; await process_frame
	return game
func dispose(game) -> void:
	paused = false; game.queue_free(); current_scene = null; await process_frame; await process_frame
func run() -> void:
	for path in [AchievementManager.PATH, ChallengeStore.PATH, SessionSave.PATH, SessionSave.POWERUP_PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	var access := ChallengeStore.empty()
	for i in range(19): access.entries[i].completed = true
	check(SaveManager.save_progress(access, ChallengeStore.PATH) == OK, "seed Challenge access only")
	var cat_game = null
	for seed in range(1, 300):
		var candidate = await new_level(1, seed)
		if candidate.current_data.id == &"cat": cat_game = candidate; break
		await dispose(candidate)
	if cat_game != null:
		var state := AchievementManager.load_state()
		check(not state.data.entries.A02.unlocked, "actual Cat not yet discovered")
		var dropped: bool = cat_game.drop_animal()
		for i in range(120):
			await physics_frame
			if cat_game.spawn_count > 0: break
		state = AchievementManager.load_state()
		check(dropped and cat_game.spawn_count == 1 and state.data.entries.A02.unlocked, "A02 from actual random Cat drop")
		await dispose(cat_game)
	else: check(false, "find deterministic random Cat seed")
	var elephant = await new_level(19, 88)
	var before := AchievementManager.load_state()
	check(not before.data.entries.A05.unlocked, "starter lion does not unlock Elephant")
	for i in range(120): await physics_frame
	elephant._set_aim(360); elephant.drop_animal()
	for i in range(500):
		await process_frame
		if elephant.result_finished: break
	var state := AchievementManager.load_state()
	check(elephant.result_success and elephant.merge_manager.merge_count > 0 and state.data.entries.A05.unlocked, "A05 from real configured Lion collision")
	await dispose(elephant)
	var golden = await new_level(20, 88)
	state = AchievementManager.load_state()
	check(not state.data.entries.A06.unlocked, "starter bear does not unlock Golden")
	for attempt in range(10):
		for i in range(220):
			await physics_frame
			if golden.result_finished: break
		if golden.result_finished: break
		golden._set_aim(360); golden.drop_animal()
	for i in range(500):
		await process_frame
		if golden.result_finished: break
	state = AchievementManager.load_state()
	check(golden.result_success and golden.challenge.count == 1 and state.data.entries.A06.unlocked, "A06 from real Golden Merge")
	check(not state.data.entries.A07.unlocked and not state.data.entries.A08.unlocked and not state.data.entries.A09.unlocked, "Challenge score cannot unlock Classic score achievements")
	print("ACHIEVEMENT_GOLDEN failures=%d" % failures); quit(1 if failures else 0)
