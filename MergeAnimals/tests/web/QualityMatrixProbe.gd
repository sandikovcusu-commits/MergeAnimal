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
	elif cmd.get("op") == "gameover": call_deferred("gameover", cmd)
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
	game.persist_best = false
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
	game._on_game_over()
	for i in range(4): await get_tree().process_frame
	var title: Label = game.overlay_title
	var button: Control = game.get_node("HUD/Overlay/RestartButton")
	var font := title.get_theme_font("font"); var glyphs_ok := true
	for character in title.text:
		if character != "\n" and not font.has_char(character.unicode_at(0)): glyphs_ok = false
	var text_bottom: float = title.position.y + title.get_line_count() * title.get_line_height()
	var fits: bool = text_bottom + 10 <= button.position.y and game.rescue_message.position.y + game.rescue_message.size.y <= game.overlay.size.y
	finish(int(cmd.id), {"locale":TranslationServer.get_locale(), "theme":game.visual_theme, "game_over":game.overlay.visible, "title_bottom":text_bottom, "action_y":button.position.y, "fits":fits, "glyphs":glyphs_ok, "action_width":button.size.x, "action_height":button.size.y})
