extends SceneTree
# Explicit seeded fixture for real Godot/X11 visual inspection, not gameplay evidence.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var screen := OS.get_environment("CAPTURE_SCREEN")
	var dims := OS.get_environment("CAPTURE_SIZE").split("x")
	if dims.size() != 2 or screen not in ["menu", "collection", "locked", "unlocked", "details", "statistics", "notification"]:
		printerr("FAIL: bad visual parameters"); quit(1); return
	var progress := Progression.empty(432)
	progress.total_games = 2; progress.completed_games = 1; progress.total_drops = 7; progress.total_merges = 3; progress.max_combo = 2; progress.play_seconds = 63.0
	var mouse := load("res://resources/animals/mouse.tres") as AnimalData
	var hamster := load("res://resources/animals/hamster.tres") as AnimalData
	Progression.record_animal(progress, mouse); Progression.record_animal(progress, mouse); Progression.record_animal(progress, hamster)
	if SessionSave.clear_session(progress) != OK:
		printerr("FAIL: cannot write visual fixture"); quit(1); return
	var path := "res://scenes/ui/MainMenu.tscn"
	if screen in ["collection", "locked", "unlocked", "details"]: path = "res://scenes/ui/Collection.tscn"
	if screen == "statistics": path = "res://scenes/ui/Statistics.tscn"
	if screen == "notification": path = "res://scenes/game/Game.tscn"
	var node = (load(path) as PackedScene).instantiate()
	if screen == "notification": node.persist_best = false
	root.add_child(node); current_scene = node
	await process_frame
	if screen == "locked": node.cards[11].pressed.emit()
	if screen == "unlocked": node.cards[0].pressed.emit()
	if screen == "details": node.cards[1].pressed.emit()
	if screen == "notification": node.discovery_notifier.enqueue(mouse)
	await create_timer(0.6, true).timeout
	await RenderingServer.frame_post_draw
	var output := []
	var code := OS.execute("xdotool", ["search", "--onlyvisible", "--pid", str(OS.get_process_id())], output, true)
	var ids := str(output[0]).strip_edges().split("\n", false) if not output.is_empty() else PackedStringArray()
	if code != 0 or ids.is_empty(): printerr("FAIL: X11 window unavailable"); quit(1); return
	var path_out := "%s/%s_%s.png" % [OS.get_environment("CAPTURE_DIR"), screen, OS.get_environment("CAPTURE_SIZE")]
	code = OS.execute("import", ["-window", ids[0], path_out])
	var image := Image.new()
	var loaded := image.load(path_out) if code == 0 else ERR_CANT_OPEN
	var size := Vector2i(int(dims[0]), int(dims[1]))
	print("DAY62_RENDER fixture=%s expected=%s actual=%s" % [screen, size, image.get_size()])
	if code != 0 or loaded != OK or image.get_size() != size:
		printerr("FAIL: capture size or file"); quit(1); return
	quit()
