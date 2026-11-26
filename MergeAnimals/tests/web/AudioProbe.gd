extends Node
# Test-only autoload. The workflow injects this into a temporary copy of the
# project for a separate instrumented Web export; it is not in production.
var last_id := -1
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(_delta: float) -> void:
	if not OS.has_feature("web"): return
	var raw = JavaScriptBridge.eval("JSON.stringify(window.__audioQACommand || null)")
	if typeof(raw) != TYPE_STRING: return
	var command = JSON.parse_string(raw)
	if not command is Dictionary or int(command.get("id", -1)) == last_id: return
	last_id = int(command.id)
	var manager = get_node("/root/AudioManager")
	var result: Variant = null
	match str(command.get("op", "state")):
		"event": result = manager.play_event(str(command.get("name", "")))
		"impact": result = manager.impact(float(command.get("speed", 0)), bool(command.get("landing", false)))
		"impact_test":
			manager.impact_elapsed = 1.0
			result = [manager.impact(99.0, false), manager.impact(300.0, false), manager.impact(300.0, false)]
		"theme": manager.set_music(str(command.get("name", ""))); result = true
		"ad": manager.set_ad_audio_paused(bool(command.get("paused", false))); result = true
		"stop_sfx":
			for player in manager.players: player.stop()
			result = true
		"settings":
			var values: Dictionary = SettingsStore.load_values()
			for key in ["master", "music", "sfx", "mute"]:
				if command.has(key): values[key] = command[key]
			SettingsStore.apply(values); result = SettingsStore.save_values(values) == OK
		"state": result = true
	var active := 0
	for player in manager.players:
		if player.playing: active += 1
	var stream = manager.music.stream
	var buses := {}
	for name in ["Master", "Music", "SFX", "UI"]:
		var idx := AudioServer.get_bus_index(name)
		buses[name] = {"linear": db_to_linear(AudioServer.get_bus_volume_db(idx)), "mute": AudioServer.is_bus_mute(idx), "send": AudioServer.get_bus_send(idx)}
	var scene := get_tree().current_scene
	var snapshot := {"id": last_id, "result": result, "unlocked": manager.unlocked_audio, "music_theme": manager.music_theme, "music_playing": manager.music.playing, "music_paused": manager.music.stream_paused, "music_position": manager.music.get_playback_position(), "music_instance": manager.music.get_instance_id(), "music_length": stream.get_length() if stream else 0.0, "music_loop": stream.loop_mode if stream is AudioStreamWAV else -1, "pool_size": manager.players.size(), "pool_active": active, "ad_paused": manager.ad_audio_paused, "accepted": manager.accepted_events.duplicate(), "buses": buses, "settings": SettingsStore.load_values(), "scene": scene.name if scene else "", "tree_paused": get_tree().paused, "memory_static": Performance.get_monitor(Performance.MEMORY_STATIC)}
	JavaScriptBridge.eval("window.__audioQAResult=" + JSON.stringify(snapshot))
