extends SceneTree
# Fixed dog queue only; all scoring/merges are from unmodified gameplay physics.
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, msg: String) -> void:
	checks += 1; print("%s: %s" % ["PASS" if ok else "FAIL", msg])
	if not ok: failures += 1
func run() -> void:
	for path in [AchievementManager.PATH, AchievementManager.CHECKPOINT_PATH, ChallengeStore.PATH, SessionSave.PATH, SessionSave.POWERUP_PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.test_seed = 99; root.add_child(game); current_scene = game; await process_frame; await process_frame
	var attempts := 0
	while game.is_playing() and int(game.progression.best_score) < 2500 and attempts < 80:
		for i in range(220):
			await physics_frame
			if not game.is_playing(): break
		if not game.is_playing(): break
		game.current_data = game.animals[4]; game._set_aim(360)
		if game.drop_animal(): attempts += 1
	for i in range(300): await physics_frame
	var state := AchievementManager.load_state()
	print("CLASSIC_REAL drops=%d merges=%d score=%d combo=%d" % [game.spawn_count, game.merge_manager.merge_count, game.score, game.max_combo])
	for id in ["A01", "A03", "A04", "A07", "A08", "A09", "A10", "A11", "A12"]:
		check(state.data.entries.get(id, {}).get("unlocked", false), "%s unlocked by actual Classic drops" % id)
	check(int(game.progression.best_score) >= 2500, "Classic score reaches 2500 through actual collisions")
	check(game.save_session() == OK, "save real Classic score for theme unlock")
	var theme := ThemeStore.refresh()
	check(theme.status == "ok" and "sunset" in theme.data.unlocked, "real Classic score unlocks sunset theme")
	# Two kinds of notices share one sequential queue.
	var notifier = preload("res://scripts/ui/DiscoveryNotification.gd").new()
	root.add_child(notifier); await process_frame
	var seen: Array[String] = []
	notifier.shown.connect(func(id): seen.append("animal:" + str(id)))
	notifier.achievement_shown.connect(func(id): seen.append("achievement:" + str(id)))
	notifier.enqueue(game.animals[0]); notifier.enqueue_achievement(AchievementManager.definitions()[0]); notifier.enqueue_achievement(AchievementManager.definitions()[1])
	await create_timer(8.0, true).timeout
	check(seen == ["animal:mouse", "achievement:A01", "achievement:A02"] and not notifier.displaying, "animal and achievement notifications display sequentially and close")
	print("ACHIEVEMENT_CLASSIC checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
