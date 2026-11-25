extends SceneTree
var checks := 0
var failures := 0
var shown: Array[StringName] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", message])
	if not ok: failures += 1
func frames(n: int = 3) -> void:
	for i in range(n): await process_frame
func touch(game: Node, down: bool, x: float) -> void:
	var event := InputEventScreenTouch.new(); event.index = 0; event.pressed = down; event.position = Vector2(x, 350); game._unhandled_input(event)
func run() -> void:
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SessionSave.PATH + suffix))
	var score_cfg := ConfigFile.new(); score_cfg.set_value("scores", "best", 432); score_cfg.save("user://wild_garden.cfg")
	var settings := SettingsStore.load_values(); settings.language = "az"; SettingsStore.save_values(settings)
	# A V0.6.1 snapshot is read without inventing past discoveries.
	var legacy_game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	legacy_game.test_seed = 99; root.add_child(legacy_game); await process_frame
	legacy_game.score = 432
	var legacy_a: Animal = legacy_game.create_animal(legacy_game.animals[0], Vector2(330, 700))
	var legacy_b: Animal = legacy_game.create_animal(legacy_game.animals[0], Vector2(390, 700))
	legacy_a.linear_velocity = Vector2(200, 0); legacy_b.linear_velocity = Vector2(-200, 0)
	var legacy: Dictionary = legacy_game._session_snapshot()
	legacy.session_version = 1
	legacy.erase("progression"); legacy.erase("tainted"); legacy.erase("score_untrusted")
	for body in legacy.bodies: body.erase("eligible")
	check(SaveManager.save_progress(legacy, SessionSave.PATH) == OK, "write legacy session fixture")
	check(SessionSave.load_session().status == "ok", "V0.6.1 session remains readable")
	var migrated := SessionSave.load_progression()
	check(migrated.best_score == 432 and migrated.total_games == 1 and Progression.discovered(migrated) == 0, "legacy migration preserves best without invented animals")
	check(SettingsStore.load_values().language == "az", "legacy settings preserved")
	legacy_game.queue_free(); await process_frame
	paused = true
	var legacy_menu = (load("res://scenes/ui/MainMenu.tscn") as PackedScene).instantiate()
	root.add_child(legacy_menu); current_scene = legacy_menu; await process_frame
	legacy_menu.continue_button.pressed.emit(); await frames(5)
	var restored_legacy = current_scene
	check(restored_legacy.has_method("save_session") and str(restored_legacy.rng.state) == legacy.rng_state and str(restored_legacy.current_data.id) == legacy.current and restored_legacy.best_score == 432, "legacy Continue restores session and best")
	check(restored_legacy.save_session() == OK and int(SessionSave.load_session().data.session_version) == 2 and SessionSave.load_session().data.has("progression") and Progression.discovered(restored_legacy.progression) == 0, "legacy session migrates without fake discovery")
	paused = false
	for i in range(180):
		await physics_frame
		if restored_legacy.merge_manager.merge_count > 0: break
	check(restored_legacy.merge_manager.merge_count == 1 and restored_legacy.score > restored_legacy.best_score and restored_legacy.score_untrusted and Progression.discovered(restored_legacy.progression) == 0, "legacy unknown-provenance collision cannot fake discovery or record")
	check(restored_legacy.save_session() == OK, "legacy game remains saveable when uncertain merge score exceeds best")
	for i in range(300):
		await physics_frame
		if i % 24 == 0:
			restored_legacy._set_aim(500); restored_legacy.drop_animal()
		if int(restored_legacy.progression.total_drops) > 0: break
	check(int(restored_legacy.progression.total_drops) == 1 and Progression.discovered(restored_legacy.progression) == 1, "new genuine drops still progress after uncertain legacy merge")
	restored_legacy.queue_free(); await process_frame
	current_scene = null
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SessionSave.PATH + suffix))
	set_meta("tutorial_requested", true)
	var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.test_seed = 99; root.add_child(game); current_scene = game; await process_frame
	game.discovery_notifier.shown.connect(func(id: StringName): shown.append(id))
	check(int(game.progression.total_games) == 1 and Progression.discovered(game.progression) == 0, "new game counted once, collection starts empty")
	var seconds: float = float(game.progression.play_seconds)
	for i in range(20): await physics_frame
	check(float(game.progression.play_seconds) > seconds, "active gameplay time increases")
	touch(game, true, 360); touch(game, false, 360)
	for i in range(120): await physics_frame
	check(game.spawn_count == 1 and int(game.progression.total_drops) == 1, "first real drop counted")
	check(int(game.progression.animals.mouse.count) == 1 and Progression.discovered(game.progression) == 1, "first mouse unlocked once")
	var first_date: String = game.progression.animals.mouse.date
	check(not first_date.is_empty() and shown.size() == 1 and shown[0] == &"mouse", "discovery date and nonblocking notification")
	touch(game, true, 360); touch(game, false, 360)
	for i in range(600):
		await physics_frame
		if game.tutorial_stage == 4: break
	check(game.spawn_count == 2 and int(game.progression.total_drops) == 2 and int(game.progression.animals.mouse.count) == 2, "repeat drop increments count, not discovery")
	check(game.merge_manager.merge_count == 1 and int(game.progression.total_merges) == 1 and int(game.progression.animals.hamster.count) == 1, "real collision unlocks hamster and counts merge")
	check(Progression.discovered(game.progression) == 2 and game.progression.animals.mouse.date == first_date, "duplicate discovery prevented, date stable")
	check(int(game.progression.best_score) == 432 and int(game.progression.max_combo) == 1, "legacy best retained and actual max combo recorded")
	for i in range(400):
		await process_frame
		if shown.size() >= 2: break
	check(shown.size() == 2 and shown[1] == &"hamster" and game.discovery_notifier.mouse_filter == Control.MOUSE_FILTER_IGNORE, "notifications queued and input-transparent")
	# Debug-created pieces, even when merged, must not count or unlock.
	game.debug_panel.visible = true
	var before_count: int = int(game.progression.animals.rabbit.count)
	game._debug_pair()
	game.score = 500 # Isolated debug-tainted fixture: it must not become a record.
	var merges_before_debug: int = int(game.progression.total_merges)
	for i in range(250): await physics_frame
	check(game.session_tainted and int(game.progression.animals.rabbit.count) == before_count and int(game.progression.total_merges) == merges_before_debug, "debug spawn and subsequent collisions cannot progress collection or merge stats")
	check(game.best_score == 432 and int(game.progression.best_score) == 432, "debug score cannot become lifetime best")
	check(game.save_session() == OK, "tainted session remains saveable without altering best")
	# New untainted session retains prior progress. Restart itself does not complete a game.
	game._restart(); await frames(5); game = current_scene
	check(int(game.progression.total_games) == 2 and int(game.progression.completed_games) == 0, "restart starts another game without completion")
	check(int(game.progression.animals.mouse.count) == 2 and int(game.progression.animals.hamster.count) == 1, "restart preserves collection")
	game.pause_button.pressed.emit(); await frames()
	var frozen: float = float(game.progression.play_seconds)
	await frames(80)
	check(is_equal_approx(float(game.progression.play_seconds), frozen), "paused gameplay time stops")
	check(game.save_session() == OK and game.save_session() == OK, "collection and statistics saved with session")
	var saved := SessionSave.load_session()
	check(saved.status == "ok" and int(saved.data.progression.animals.mouse.count) == 2, "save/load includes collection")
	game._main_menu(); await frames(5)
	var menu = current_scene
	check(menu.has_method("_play"), "pause navigates to main menu")
	var before_menu_time: float = float(SessionSave.load_progression().play_seconds)
	await frames(80)
	check(is_equal_approx(float(SessionSave.load_progression().play_seconds), before_menu_time), "main menu time not counted")
	menu.find_child("Collection", true, false).pressed.emit(); await frames(5)
	var collection = current_scene
	check(collection.cards.size() == 12 and collection.get_node_or_null("CollectionScroll/AnimalGrid") != null, "collection has 12 cards in three-column grid")
	check(collection.cards[0].find_child("Lock", true, false) == null and collection.cards[11].find_child("Lock", true, false) != null, "unlocked and locked cards render appropriate state")
	var previous_settings := SettingsStore.load_values()
	for locale in ["en", "az", "tr", "ru"]:
		var localized := previous_settings.duplicate(); localized.language = locale; SettingsStore.save_values(localized)
		var localized_collection = (load("res://scenes/ui/Collection.tscn") as PackedScene).instantiate()
		root.add_child(localized_collection); await frames(6)
		var fits := true
		for card in localized_collection.cards:
			var column: Control = card.get_child(0)
			for child in column.get_children():
				if child is Control and child.position.y + child.size.y > card.size.y - 5.0: fits = false
		check(fits and TranslationServer.translate("ANIMAL_DESC_MOUSE") != "ANIMAL_DESC_MOUSE", "card text fits and descriptions translate for " + locale)
		localized_collection.queue_free(); await process_frame
	SettingsStore.save_values(previous_settings); SettingsStore.apply(previous_settings)
	collection.scroll.scroll_vertical = int(collection.scroll.get_v_scroll_bar().max_value)
	await frames()
	check(collection.scroll.scroll_vertical > 0, "collection grid scrolls to later animals")
	collection.cards[0].pressed.emit(); await frames()
	check(collection.detail.visible and collection.detail_label.text.contains("2"), "animal detail opens with persisted count")
	collection.detail_close.pressed.emit(); await frames()
	check(not collection.detail.visible, "detail closes")
	collection.find_child("Back", true, false).pressed.emit(); await frames(5)
	menu = current_scene
	menu.find_child("Statistics", true, false).pressed.emit(); await frames(5)
	var statistics = current_scene
	check(statistics.progress.total_games == 2 and statistics.progress.total_drops == 2 and statistics.progress.total_merges == 1, "statistics screen reads actual saved values")
	statistics.find_child("Back", true, false).pressed.emit(); await frames(5)
	menu = current_scene
	paused = true
	menu.continue_button.pressed.emit(); await frames(5)
	game = current_scene
	check(game.has_method("save_session") and int(game.progression.total_games) == 2 and int(game.progression.total_drops) == 2 and int(game.progression.total_merges) == 1, "Continue does not double-count game or events")
	check(game.save_session() == OK and game.save_session() == OK, "create matching backup for recovery")
	var file := FileAccess.open(SessionSave.PATH, FileAccess.WRITE); file.store_string("damaged"); file.close()
	var recovery := SessionSave.load_session()
	check(recovery.status == "recovered" and int(recovery.data.progression.animals.mouse.count) == 2 and int(recovery.data.progression.total_drops) == 2, "corrupt session recovers collection and statistics")
	paused = false
	# Simulated bodies with legitimate eligibility exercise real physics golden contact in this isolated test.
	game.danger_monitor.set_physics_process(false)
	# A pre-existing Elephant discovery is a test fixture, not an awarded discovery.
	game.progression.animals.elephant = {"count": 3, "date": "2026-01-01 12:00:00"}
	game.progression.highest_animal = 12
	var a: Animal = game.create_animal(game.animals[11], Vector2(225, 700))
	var b: Animal = game.create_animal(game.animals[11], Vector2(495, 700))
	a.progression_eligible = true; b.progression_eligible = true
	a.linear_velocity = Vector2(200, 0); b.linear_velocity = Vector2(-200, 0)
	for i in range(180):
		await physics_frame
		if int(game.progression.golden_merges) > 0: break
	check(int(game.progression.golden_merges) == 1 and int(game.progression.total_merges) == 2, "real golden collision counted once")
	check(int(game.progression.best_score) == 1000 and game.best_score == 1000 and int(game.progression.max_combo) == 1, "golden gameplay updates best and preserves maximum combo")
	check(int(game.progression.animals.mouse.count) == 2 and int(game.progression.animals.hamster.count) == 1 and int(game.progression.animals.elephant.count) == 3 and game.progression.animals.elephant.date == "2026-01-01 12:00:00", "golden merge preserves existing Elephant discovery")
	game._on_game_over()
	check(int(game.progression.completed_games) == 1 and SessionSave.load_session().status == "missing", "completion counted once, no continue after game over")
	game._on_game_over()
	check(int(game.progression.completed_games) == 1, "game-over reentry does not duplicate completion")
	check(int(SessionSave.load_progression().animals.elephant.count) == 3, "golden collection persists after game over")
	file = FileAccess.open(SessionSave.PATH, FileAccess.WRITE); file.store_string("broken primary"); file.close()
	file = FileAccess.open(SessionSave.PATH + ".bak", FileAccess.WRITE); file.store_string("broken backup"); file.close()
	check(SessionSave.load_document().status == "corrupt" and SessionSave.clear_session() == ERR_UNAVAILABLE, "two corrupt copies are not overwritten")
	paused = false
	var unavailable = (load("res://scenes/ui/Collection.tscn") as PackedScene).instantiate()
	root.add_child(unavailable); await process_frame
	check(unavailable.cards.is_empty(), "unrecoverable data is not presented as empty collection")
	unavailable.queue_free()
	for suffix in ["", ".bak", ".tmp", ".bak.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SessionSave.PATH + suffix))
	var future_progress := Progression.empty()
	future_progress.version = 2
	check(SaveManager.save_progress({"session_version": 1, "active": false, "progression": future_progress}, SessionSave.PATH) == OK, "future progression fixture written")
	var future_hash := FileAccess.get_sha256(SessionSave.PATH)
	check(SessionSave.load_document().status == "future" and SessionSave.clear_session() == ERR_UNAVAILABLE and FileAccess.get_sha256(SessionSave.PATH) == future_hash, "future progression schema is protected")
	print("DAY62 collection and statistics checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
