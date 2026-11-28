extends SceneTree
# Storage fault injection only. Achievement events come from real physical drops.
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1; print("%s: %s" % ["PASS" if ok else "FAIL", text])
	if not ok: failures += 1
func frames(n := 3) -> void:
	for i in range(n): await process_frame
func clear_files() -> void:
	for path in [AchievementManager.PATH, AchievementManager.CHECKPOINT_PATH, SessionSave.PATH, SessionSave.POWERUP_PATH, ChallengeStore.PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
func run() -> void:
	if OS.get_environment("INTEGRITY_PHASE") == "read":
		var saved := AchievementManager.load_state()
		check(saved.status in ["ok", "recovered"] and saved.data.entries.A01.unlocked and saved.data.entries.A02.unlocked, "separate process restores committed unlocks")
		var migrated := AchievementManager.migrate()
		check(migrated.status == "ok" and migrated.new.is_empty(), "separate-process reconciliation emits no duplicate")
		print("INTEGRITY_READ checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0); return
	clear_files()
	var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.test_seed = 42; root.add_child(game); current_scene = game; await frames()
	game.current_data = game.animals[0]; game._set_aim(360); game.drop_animal()
	for i in range(260): await physics_frame
	var obstruction := ProjectSettings.globalize_path(AchievementManager.CHECKPOINT_PATH + ".tmp")
	check(DirAccess.make_dir_absolute(obstruction) == OK, "obstruct achievement checkpoint")
	game.current_data = game.animals[0]; game._set_aim(360); game.drop_animal()
	for i in range(600):
		await process_frame
		if game.achievement_blocked: break
	var before := AchievementManager.load_state()
	check(game.merge_manager.merge_count == 1 and game.achievement_blocked and paused and not before.data.entries.A01.unlocked, "real merge pauses with unsaved achievement rather than losing it")
	game._restart(); await frames()
	check(current_scene == game and game.achievement_blocked, "restart blocked while achievement write fails")
	DirAccess.remove_absolute(obstruction)
	for i in range(240):
		await process_frame
		if not game.achievement_blocked: break
	var after := AchievementManager.load_state()
	check(not game.achievement_blocked and not paused and after.data.entries.A01.unlocked, "automatic retry commits and resumes")
	var date: String = after.data.entries.A01.date
	var queued: int = game.discovery_notifier.queue.size()
	game._sync_achievements()
	check(game.discovery_notifier.queue.size() == queued and AchievementManager.load_state().data.entries.A01.date == date, "retry and duplicate event do not notify twice")
	# A mirror write fails but the newer checkpoint commits first.
	for i in range(120): await physics_frame
	var mirror_block := ProjectSettings.globalize_path(AchievementManager.PATH + ".bak.tmp")
	check(DirAccess.make_dir_absolute(mirror_block) == OK, "obstruct ordinary mirror")
	game.current_data = game.animals[3]; game._set_aim(360); game.drop_animal()
	for i in range(180):
		await process_frame
		var current := AchievementManager.load_state()
		if current.status in ["ok", "recovered"] and current.data.entries.A02.unlocked: break
	var committed := AchievementManager.load_state()
	check(committed.status == "recovered" and committed.data.entries.A02.unlocked and not game.achievement_blocked, "checkpoint commits real Cat despite mirror failure")
	DirAccess.remove_absolute(mirror_block)
	for path in [AchievementManager.PATH, AchievementManager.PATH + ".bak"]:
		var file := FileAccess.open(path, FileAccess.WRITE); file.store_string("corrupt"); file.close()
	var recovered := AchievementManager.load_state()
	check(recovered.status == "recovered" and recovered.data.entries.A01.unlocked and recovered.data.entries.A02.unlocked, "checkpoint recovers after both ordinary copies corrupt")
	var sync := AchievementManager.synchronize(game.progression, {}, true)
	check(sync.status == "ok" and sync.new.is_empty(), "reconciliation does not repeat unlock")
	# Damaged checkpoint cannot silently fall back to an older mirror.
	var raw := FileAccess.get_file_as_bytes(AchievementManager.CHECKPOINT_PATH)
	var corrupt := FileAccess.open(AchievementManager.CHECKPOINT_PATH, FileAccess.WRITE); corrupt.store_string("bad"); corrupt.close()
	check(AchievementManager.load_state().status == "unavailable", "corrupt checkpoint fails closed")
	var repair := FileAccess.open(AchievementManager.CHECKPOINT_PATH, FileAccess.WRITE); repair.store_buffer(raw); repair.close()
	game.queue_free(); current_scene = null; await frames()
	# Challenge access is seeded, not an achievement unlock fixture.
	var ch := ChallengeStore.empty()
	for i in range(19): ch.entries[i].completed = true
	check(SaveManager.save_progress(ch, ChallengeStore.PATH) == OK, "seed Challenge access")
	set_meta("challenge_id", 19)
	game = (load("res://scenes/game/ChallengeGame.tscn") as PackedScene).instantiate()
	game.test_seed = 88; root.add_child(game); current_scene = game; await frames()
	for i in range(120): await physics_frame
	check(DirAccess.make_dir_absolute(obstruction) == OK, "obstruct Challenge achievement write")
	game._set_aim(360); game.drop_animal()
	for i in range(300):
		await process_frame
		if game.achievement_blocked: break
	check(game.achievement_blocked and paused, "Challenge stops and retains pending event on write failure")
	DirAccess.remove_absolute(obstruction)
	for i in range(500):
		await process_frame
		if not game.achievement_blocked: break
	check(not game.achievement_blocked and game.achievement_pending.is_empty(), "Challenge event retries in order")
	paused = false
	print("INTEGRITY checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
