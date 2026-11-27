extends Node
# QA-only temporary export: setup deterministic state and inspect geometry.
# Production export is not modified. Screenshots are not human play.
var last_id := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(_delta: float) -> void:
	var raw: Variant = JavaScriptBridge.eval("JSON.stringify(window.__qualityCommand || null)")
	if typeof(raw) != TYPE_STRING: return
	var cmd: Variant = JSON.parse_string(raw)
	if not cmd is Dictionary or int(cmd.get("id", 0)) == last_id: return
	last_id = int(cmd.id)
	if cmd.get("op") == "setup": call_deferred("setup", cmd)
	elif cmd.get("op") in ["gameover", "gameover-invalid"]: call_deferred("gameover", cmd)
	elif cmd.get("op") == "inspect": call_deferred("inspect", cmd)
	elif str(cmd.get("op", "")).begins_with("deadlock_"): call_deferred("deadlock", cmd)
func finish(id: int, data: Dictionary) -> void:
	data["id"] = id
	JavaScriptBridge.eval("window.__qualityReply=" + JSON.stringify(data))
func setup(cmd: Dictionary) -> void:
	get_tree().paused = false
	var locale := str(cmd.get("locale", "")); var theme := str(cmd.get("theme", ""))
	if locale not in ["az", "en", "tr", "ru"] or theme not in ThemeStore.IDS:
		finish(int(cmd.id), {"error":"invalid setup"}); return
	var settings := SettingsStore.DEFAULTS.duplicate(); settings.language = locale
	if SettingsStore.save_values(settings) != OK or ThemeStore._save({"version":1, "selected":theme, "unlocked":["forest", "sunset", "snow"]}) != OK:
		finish(int(cmd.id), {"error":"cannot save isolated settings"}); return
	if get_tree().change_scene_to_file("res://scenes/game/Game.tscn") != OK:
		finish(int(cmd.id), {"error":"game scene unavailable"}); return
	for i in range(6): await get_tree().process_frame
	var game = get_tree().current_scene
	if not game or not game.has_method("create_animal"):
		finish(int(cmd.id), {"error":"game scene not ready"}); return
	# Preserve normal Web status/overlay behavior in the isolated browser profile.
	# Only fixture bodies and danger monitoring are synthetic.
	game.danger_monitor.set_physics_process(false)
	var positions := [Vector2(373,1064), Vector2(606,798), Vector2(143,535), Vector2(421,1017), Vector2(136,796), Vector2(579,1026), Vector2(552,715), Vector2(382,786), Vector2(502,901), Vector2(453,587), Vector2(251,647), Vector2(237,949)]
	for index in range(12):
		var piece = game.create_animal(game.animals[index], positions[index]); piece.freeze = true
	game.highest_level = 12; game._update_hud()
	finish(int(cmd.id), {"locale":TranslationServer.get_locale(), "theme":game.visual_theme, "bodies":game.pieces.get_child_count(), "pause_width":game.pause_button.size.x, "pause_height":game.pause_button.size.y})
func gameover(cmd: Dictionary) -> void:
	var game = get_tree().current_scene
	if not game or not game.has_method("_on_game_over"):
		finish(int(cmd.id), {"error":"game not ready"}); return
	game.score = 124; game.best_at_start = 0; game.max_combo = 3
	# The normal eligible merge path updates both best_score and progression.
	# Preserve the old invalid setup only for the explicit regression scenario.
	if cmd.get("op") != "gameover-invalid":
		game.best_score = maxi(game.best_score, game.score)
		game.progression.best_score = maxi(int(game.progression.best_score), game.score)
	game._update_hud()
	game._on_game_over()
	for i in range(4): await get_tree().process_frame
	var title: Label = game.overlay_title
	var button: Control = game.get_node("HUD/Overlay/RestartButton")
	var font := title.get_theme_font("font"); var glyphs_ok := true
	for character in title.text:
		if character != "\n" and not font.has_char(character.unicode_at(0)): glyphs_ok = false
	var text_bottom: float = title.position.y + title.get_line_count() * title.get_line_height()
	var fits: bool = text_bottom + 10 <= button.position.y and game.rescue_message.position.y + game.rescue_message.size.y <= game.overlay.size.y
	var snap: Dictionary = game._session_snapshot()
	var repaired := snap.duplicate(true)
	if not repaired.is_empty(): repaired.best_score = maxi(int(repaired.best_score), int(repaired.score))
	finish(int(cmd.id), {"locale":TranslationServer.get_locale(), "theme":game.visual_theme, "game_over":game.overlay.visible, "title_bottom":text_bottom, "action_y":button.position.y, "fits":fits, "glyphs":glyphs_ok, "action_width":button.size.x, "action_height":button.size.y, "save_status":game.save_status, "message":game.rescue_message.text, "valid":SessionSave.valid(snap), "valid_with_best_fixed":SessionSave.valid(repaired), "score":game.score, "best":game.best_score, "session_id":game.session_id, "can_write":SessionSave.can_write(), "document":SessionSave.load_document()})

func inspect(cmd: Dictionary) -> void:
	var doc := SessionSave.load_document()
	var result := {"document":doc, "observer":get_node("/root/SaveDurability").state(), "can_write":SessionSave.can_write()}
	var game = get_tree().current_scene
	if game and game.has_method("save_session"):
		var snapshot: Dictionary = game._session_snapshot()
		var pairs := []
		for pair in game.merge_manager.pending:
			if is_instance_valid(pair.a) and is_instance_valid(pair.b):
				pairs.append({"a":str(pair.a.data.id), "b":str(pair.b.data.id), "target":str(pair.target.id) if pair.target else "golden", "a_x":pair.a.position.x, "a_y":pair.a.position.y, "b_x":pair.b.position.x, "b_y":pair.b.position.y})
		result["checkpoint_details"] = game._checkpoint_details()
		result["live"] = {"game_state":game.game_state, "spawn_state":game.spawn_state, "score":game.score, "spawn_count":game.spawn_count, "merges":game.merge_manager.merge_count, "paused":get_tree().paused, "achievement_blocked":game.achievement_blocked, "achievement_pending":game.achievement_pending.size(), "cooldown":game.cooldown_left, "drop_requested":game.drop_requested, "save_status":game.save_status, "save_message":game.get_node("HUD/SaveStatus").text, "save_visible":game.get_node("HUD/SaveStatus").visible, "play_seconds":game.progression.play_seconds, "pending_merges":pairs, "commit_scheduled":game.merge_manager.commit_scheduled, "snapshot_empty":snapshot.is_empty(), "snapshot_valid":SessionSave.valid(snapshot)}
	finish(int(cmd.id), result)

# Separate QA export only: synthetic, frozen board; normal production merge,
# save and status implementations execute unmodified.
func deadlock(cmd: Dictionary) -> void:
	var op := str(cmd.op)
	if op == "deadlock_setup":
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/game/Game.tscn")
		for i in range(6): await get_tree().process_frame
		var game = get_tree().current_scene
		game.danger_monitor.set_physics_process(false)
		game.merge_manager.set_physics_process(false)
		for row in range(7):
			for col in range(7):
				var animal: Animal = game.create_animal(game.animals[0], Vector2(252 + col * 36, 800 + row * 36))
				animal.freeze = true
		get_tree().paused = true
		var status: Error = game.save_session()
		finish(int(cmd.id), {"saved":status, "bodies":game.pieces.get_child_count(), "details":game._checkpoint_details()})
		return
	var game = get_tree().current_scene
	if not game or not game.has_method("save_session"):
		finish(int(cmd.id), {"error":"game unavailable"}); return
	var result: Variant = null
	if op == "deadlock_mutate_powerup": game.remove_remaining = 0
	elif op == "deadlock_save": result = game.save_session()
	elif op == "deadlock_reserve":
		var a: Animal = game.pieces.get_child(24); var b: Animal = game.pieces.get_child(25)
		result = game.merge_manager.request_merge(a, b)
	elif op == "deadlock_commit": game.merge_manager._commit_pending()
	elif op == "deadlock_drop":
		game._set_aim(360); game._attempt_drop()
	elif op != "deadlock_details":
		finish(int(cmd.id), {"error":"unknown operation"}); return
	var positions := []
	for body in game.pieces.get_children():
		if body is Animal: positions.append({"id":str(body.data.id), "x":body.position.x, "y":body.position.y, "radius":body.data.radius, "locked":body.merge_locked})
	finish(int(cmd.id), {"result":result, "details":game._checkpoint_details(), "pending":game.merge_manager.pending.size(), "score":game.score, "merges":game.merge_manager.merge_count, "spawns":game.spawn_count, "body_count":game.pieces.get_child_count(), "bodies":positions})
