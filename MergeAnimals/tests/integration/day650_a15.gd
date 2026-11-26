extends SceneTree
# Forced preview selection, including normally unavailable high tiers: each
# discovery still occurs in _attempt_drop on a real physics board. Not organic.
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, msg: String) -> void:
	checks += 1; print("%s: %s" % ["PASS" if ok else "FAIL", msg])
	if not ok: failures += 1
func run() -> void:
	for path in [AchievementManager.PATH, AchievementManager.CHECKPOINT_PATH, ChallengeStore.PATH, SessionSave.PATH, SessionSave.POWERUP_PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	for tier in range(12):
		var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
		game.test_seed = 42; root.add_child(game); current_scene = game
		await process_frame; await process_frame
		game.current_data = game.animals[tier]; game._set_aim(360)
		var requested: bool = game.drop_animal()
		for frame in range(15): await physics_frame
		var state := AchievementManager.load_state()
		check(requested and game.spawn_count == 1 and Progression.discovered(game.progression) == tier + 1, "eligible physical drop %d discovers %s" % [tier + 1, Progression.IDS[tier]])
		check(state.data.entries.A15.unlocked == (tier == 11), "A15 state after %d distinct drops" % (tier + 1))
		check(SessionSave.clear_session(game.progression) == OK, "preserve progression and clear board after drop %d" % (tier + 1))
		game.queue_free(); current_scene = null; await process_frame
	var final := AchievementManager.load_state()
	check(final.data.entries.A15.unlocked and not final.data.entries.A15.date.is_empty(), "A15 has live date after 12 eligible drops")
	check(AchievementManager.migrate().new.is_empty(), "restart reconciliation does not repeat A15")
	print("A15_FORCED_DROPS checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
