extends SceneTree
# Called after the real challenge integration tests in their own user data dir.
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, msg: String) -> void:
	checks += 1; print("%s: %s" % ["PASS" if ok else "FAIL", msg])
	if not ok: failures += 1
func run() -> void:
	var state := AchievementManager.load_state()
	check(state.status in ["ok", "recovered"], "live challenge events were saved")
	if state.status not in ["ok", "recovered"]: quit(1); return
	for id in ["A01", "A02", "A03", "A04", "A05", "A06", "A11", "A12", "A14"]:
		check(state.data.entries.has(id) and state.data.entries[id].unlocked and not str(state.data.entries[id].date).is_empty(), "%s unlocked by live challenge event" % id)
	for id in ["A08", "A09", "A10"]:
		check(not state.data.entries.get(id, {}).get("unlocked", false), "%s ignores Challenge score" % id)
	var ch := ChallengeStore.load_results()
	var count := 0
	for item in ch.data.entries:
		if item.completed: count += 1
	check(count == 20, "20 distinct real completed challenges")
	# Replays use normal level setup/queue and real physics. No artificial merge,
	# score, objective or body removal. Each success takes 32 drops in baseline.
	for replay in range(5):
		state = AchievementManager.load_state()
		if state.data.entries.get("A13", {}).get("unlocked", false): break
		set_meta("challenge_id", 17)
		var game = (load("res://scenes/game/ChallengeGame.tscn") as PackedScene).instantiate()
		game.test_seed = 88; root.add_child(game); current_scene = game; await process_frame; await process_frame
		var attempts := 0
		while not game.result_finished and attempts < 48:
			for i in range(220):
				await physics_frame
				if game.result_finished: break
			if game.result_finished: break
			game._set_aim(360)
			if game.drop_animal(): attempts += 1
		for i in range(500):
			await process_frame
			if game.result_finished: break
		check(game.result_success and game.merge_manager.merge_count >= 1, "replay %d real physical merges" % (replay + 1))
		paused = false; game.queue_free(); current_scene = null; await process_frame; await process_frame
	state = AchievementManager.load_state(); ch = ChallengeStore.load_results()
	check(state.data.entries.get("A13", {}).get("unlocked", false), "A13 from 100 real merges")
	count = 0
	for item in ch.data.entries:
		if item.completed: count += 1
	check(count == 20 and state.data.entries.A14.unlocked, "replays do not create new distinct challenge completions")
	print("ACHIEVEMENT_EVENTS checks=%d failures=%d challenge_merges=%d" % [checks, failures, int(state.data.events.total_merges)])
	quit(1 if failures else 0)
