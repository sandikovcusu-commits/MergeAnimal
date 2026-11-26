extends SceneTree
# Forced previews for five legal spawn tiers. Attempts to force higher tiers
# were rejected by snapshot validation; no achievement state was fabricated.
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, msg: String) -> void:
	checks += 1; print("%s: %s" % ["PASS" if ok else "FAIL", msg])
	if not ok: failures += 1
func run() -> void:
	for path in [AchievementManager.PATH, AchievementManager.CHECKPOINT_PATH, ChallengeStore.PATH, SessionSave.PATH, SessionSave.POWERUP_PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	for tier in range(5):
		var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
		game.test_seed = 42; root.add_child(game); current_scene = game
		await process_frame; await process_frame
		game.current_data = game.animals[tier]; game._set_aim(360)
		var requested: bool = game.drop_animal()
		for frame in range(15): await physics_frame
		var state := AchievementManager.load_state()
		check(requested and game.spawn_count == 1 and Progression.discovered(game.progression) == tier + 1, "eligible physical drop %d discovers %s" % [tier + 1, Progression.IDS[tier]])
		check(not state.data.entries.A15.unlocked, "A15 remains locked after %d distinct drops" % (tier + 1))
		check(SessionSave.clear_session(game.progression) == OK, "preserve progression and clear board after drop %d" % (tier + 1))
		game.queue_free(); current_scene = null; await process_frame
	var final := AchievementManager.load_state()
	check(not final.data.entries.A15.unlocked, "A15 remains locked without twelve real discoveries")
	check(AchievementManager.migrate().new.is_empty(), "restart reconciliation does not repeat A15")
	print("A15_FIVE_FORCED_DROPS checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
