extends Node
# Injected into a temporary CI project only. This creates deterministic board
# fixtures and inspects state; ad requests themselves come from the actual UI.
var last_id := -1
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(_delta: float) -> void:
	var raw = JavaScriptBridge.eval("JSON.stringify(window.__rewardQACommand || null)")
	if typeof(raw) != TYPE_STRING: return
	var command = JSON.parse_string(raw)
	if not command is Dictionary or int(command.get("id", -1)) == last_id: return
	last_id = int(command.id)
	var game = get_tree().current_scene
	var manager = get_node("/root/AdManager")
	var audio = get_node("/root/AudioManager")
	var op := str(command.get("op", "state"))
	var result: Variant = null
	if op == "fixture" and game and game.has_method("_on_game_over") and game.game_state == game.GameState.PLAYING:
		game.danger_monitor.set_physics_process(false)
		for node in game.pieces.get_children(): game.pieces.remove_child(node); node.queue_free()
		game.current_data = game.animals[0]; game.next_data = game.animals[1]
		var a = game.create_animal(game.animals[0], Vector2(360,430)); a.freeze = true
		var b = game.create_animal(game.animals[8], Vector2(220,800)); b.freeze = true
		game._on_game_over()
		result = true
	elif op == "block_save":
		result = DirAccess.make_dir_absolute(ProjectSettings.globalize_path(SessionSave.POWERUP_PATH + ".tmp")) == OK
	elif op == "unblock_save":
		result = DirAccess.remove_absolute(ProjectSettings.globalize_path(SessionSave.POWERUP_PATH + ".tmp")) == OK
	elif op == "corrupt_primary":
		var f := FileAccess.open(SessionSave.PATH, FileAccess.WRITE)
		if f: f.store_string("broken"); f.close(); result = true
	elif op == "mute":
		var values := SettingsStore.load_values(); values.mute = bool(command.get("mute", true)); SettingsStore.apply(values); result = SettingsStore.save_values(values) == OK
	elif op == "state": result = true
	var doc := SessionSave.load_session()
	var state := {"id": last_id, "result": result, "sdk": manager.sdk_state, "environment": manager.sdk_environment, "available": manager.rewarded_available(), "provider": manager.provider, "ad_state": manager.ad_state, "tx": manager.transaction_id, "tx_session": manager.transaction_session, "paused": get_tree().paused, "ad_audio": audio.ad_audio_paused, "music_paused": audio.music.stream_paused, "master_mute": AudioServer.is_bus_mute(0), "doc_status": doc.status, "doc": doc.get("data", {}), "scene": game.name if game else ""}
	if game and game.has_method("_on_game_over"):
		state.merge({"session":game.session_id, "game_state":game.game_state, "rescue":game.rescue_remaining, "earned":game.ad_rescue_earned, "pending_save":game.reward_commit_pending, "processing":game.rescue_processing, "button_visible":game.rescue_button.visible, "button_disabled":game.rescue_button.disabled, "button_text":game.rescue_button.text, "message":game.rescue_message.text, "bodies":game.pieces.get_child_count(), "request_id":game.reward_request_id}, true)
	JavaScriptBridge.eval("window.__rewardQAResult=" + JSON.stringify(state))
