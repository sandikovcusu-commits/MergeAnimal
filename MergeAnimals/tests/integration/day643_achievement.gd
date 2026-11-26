extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, what: String) -> void:
	checks += 1; print("%s: %s" % ["PASS" if value else "FAIL", what])
	if not value: failures += 1
func frames(n := 3) -> void:
	for i in range(n): await process_frame
func clear_files() -> void:
	for path in [AchievementManager.PATH, ChallengeStore.PATH, SessionSave.PATH, SessionSave.POWERUP_PATH]:
		for suffix in ["", ".bak", ".tmp", ".bak.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
func run() -> void:
	if OS.get_environment("ACH_PHASE") == "read": read_phase(); return
	clear_files()
	check(AchievementManager.definitions().size() == 15, "15 resource definitions loaded")
	change_scene_to_file("res://scenes/ui/MainMenu.tscn"); await frames()
	var menu = current_scene
	var btn := menu.find_child("Achievements", true, false) as Button
	check(btn != null and not btn.disabled, "main menu achievement button enabled")
	if btn != null: btn.pressed.emit(); await frames()
	var ui = current_scene
	check(ui.scene_file_path.ends_with("Achievements.tscn") and ui.cards.size() == 15, "achievement UI navigation and 15 cards")
	var heading := ui.find_child("Progress", true, false) as Label
	check(heading != null and heading.text.contains("0/15"), "initial achievement count 0/15")
	ui.find_child("Back", true, false).pressed.emit(); await frames()
	check(current_scene.scene_file_path.ends_with("MainMenu.tscn"), "achievement Back navigation")
	change_scene_to_file("res://scenes/game/Game.tscn"); await frames()
	var game = current_scene
	game.test_seed = 42
	game.current_data = game.animals[0]; game._set_aim(360)
	var first: bool = game.drop_animal()
	for i in range(260): await physics_frame
	game.current_data = game.animals[0]; game._set_aim(360)
	var second: bool = game.drop_animal()
	for i in range(500):
		await physics_frame
		if game.merge_manager.merge_count > 0: break
	var loaded := AchievementManager.load_state()
	check(first and second and game.merge_manager.merge_count > 0 and loaded.data.entries.A01.unlocked, "A01 unlocks from two actual drops and physical merge")
	var notified: int = game.discovery_notifier.queue.size()
	game._sync_achievements(); var again := AchievementManager.load_state()
	check(again.data.entries.A01.unlocked and game.discovery_notifier.queue.size() == notified, "duplicate unlock emits no extra notification")
	# Undo carries permanent unlock but rolls back the underlying merge statistic.
	for i in range(300): await physics_frame
	game._request_undo(); await frames(20)
	var after := AchievementManager.load_state()
	check(game.undo_remaining == 0 and int(game.progression.total_merges) == 0 and after.data.entries.A01.unlocked and int(after.data.entries.A01.progress) == 1, "Undo rolls back statistics, keeps permanent achievement")
	game.queue_free(); current_scene = null; await frames()
	# A tainted debug session and debug bodies cannot contribute evidence.
	change_scene_to_file("res://scenes/game/Game.tscn"); await frames(); game = current_scene
	game.debug_panel.visible = true; game._debug_pair()
	check(game.session_tainted, "debug spawn taints session")
	var before := FileAccess.get_sha256(AchievementManager.PATH)
	for i in range(300): await physics_frame
	check(FileAccess.get_sha256(AchievementManager.PATH) == before, "debug bodies do not unlock achievements")
	game.queue_free(); current_scene = null; await frames()
	# Historical fixture has 11 proven discoveries. The twelfth is an actual drop;
	# this checks the transition, not natural discovery of the first eleven.
	clear_files()
	var eleven := Progression.empty(); eleven.highest_animal = 12
	for id in Progression.IDS:
		if id != "mouse": eleven.animals[id] = {"count": 1, "date": "2024-01-01"}
	check(SessionSave.clear_session(eleven) == OK, "save 11-animal historical fixture")
	change_scene_to_file("res://scenes/game/Game.tscn"); await frames(); game = current_scene
	var pre_collection := AchievementManager.load_state()
	check(not pre_collection.data.entries.A15.unlocked and int(pre_collection.data.entries.A15.progress) == 11, "A15 remains locked at 11 discoveries")
	game.current_data = game.animals[0]; game._set_aim(360)
	var last_drop: bool = game.drop_animal()
	for i in range(120):
		await physics_frame
		if Progression.discovered(game.progression) == 12: break
	var collection_state := AchievementManager.load_state()
	check(last_drop and Progression.discovered(game.progression) == 12 and collection_state.data.entries.A15.unlocked and not str(collection_state.data.entries.A15.date).is_empty(), "A15 unlocks on actual twelfth discovery after historical fixture")
	game.queue_free(); current_scene = null; await frames()
	# Migration fixtures are intentionally synthetic old-save data, not gameplay evidence.
	clear_files()
	var historic := Progression.empty(2500)
	historic.total_merges = 100; historic.golden_merges = 1; historic.max_combo = 5; historic.highest_animal = 12
	for id in Progression.IDS: historic.animals[id] = {"count": 1, "date": "2024-01-01"}
	check(SessionSave.clear_session(historic) == OK, "create historical Classic migration fixture")
	var challenges := ChallengeStore.empty()
	for i in range(10): challenges.entries[i].completed = true
	check(SaveManager.save_progress(challenges, ChallengeStore.PATH) == OK, "create historical Challenge migration fixture")
	var migrated := AchievementManager.migrate()
	for def in AchievementManager.definitions():
		var entry: Dictionary = migrated.data.entries[def.id]
		check(entry.unlocked and entry.date.is_empty() and int(entry.progress) == def.target, "%s historical evidence migration (date unknown)" % def.id)
	check(migrated.new.is_empty(), "migration sends no retroactive notifications")
	var duplicate := AchievementManager.migrate()
	check(duplicate.new.is_empty(), "migration is idempotent")
	var file := FileAccess.open(AchievementManager.PATH, FileAccess.WRITE); file.store_string("broken"); file.close()
	var recovered := AchievementManager.load_state()
	check(recovered.status == "recovered" and recovered.data.entries.A15.unlocked, "achievement backup recovers corrupted primary")
	print("ACHIEVEMENT checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
func read_phase() -> void:
	var loaded := AchievementManager.load_state()
	check(loaded.status in ["ok", "recovered"], "separate process loads achievement backup")
	if loaded.status in ["ok", "recovered"]:
		for def in AchievementManager.definitions(): check(loaded.data.entries[def.id].unlocked, "%s restored in separate process" % def.id)
	print("ACHIEVEMENT_READ checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
