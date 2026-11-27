extends Node
## Single bounded audio pool and one persistent music player across scenes.
const EVENTS := ["button_click", "menu_back", "animal_drop", "soft_landing", "animal_collision", "small_merge", "medium_merge", "large_merge", "combo", "golden_merge", "animal_discovered", "achievement_unlocked", "challenge_success", "challenge_failed", "undo", "remove", "rescue", "game_over", "danger_warning", "theme_unlocked"]
const THEME_IDS := ["forest", "sunset", "snow"]
const MAX_PLAYERS := 8
const IMPACT_MIN := 100.0
const IMPACT_COOLDOWN := 0.18
var streams := {}
var players: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var music_theme := ""
var unlocked_audio := false
signal reduced_effects_changed(value: bool)
var reduced_effects := false:
	set(value):
		if reduced_effects == value: return
		reduced_effects = value
		reduced_effects_changed.emit(value)
var impact_elapsed := 1.0
var last_scene: Node
var accepted_events: Dictionary = {}
# External integrations can temporarily suspend game audio without changing
# the user's saved settings or starting a second player.
var ad_audio_paused := false
var _music_paused_before_ad := false
var _sfx_paused_before_ad: Array[bool] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var settings = load("res://scripts/ui/SettingsStore.gd")
	settings.apply(settings.load_values())
	for id in EVENTS: streams[id] = load("res://assets/audio/sfx/%s.wav" % id)
	for i in range(MAX_PLAYERS):
		var player := AudioStreamPlayer.new(); player.name = "Sound%d" % i
		# Godot 4.7 Web's default sample path produced no output in both
		# browsers despite accepting play(); stream playback reaches WebAudio.
		if OS.has_feature("web"): player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		add_child(player); players.append(player)
	music = AudioStreamPlayer.new(); music.name = "Music"; music.bus = "Music"
	if OS.has_feature("web"): music.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(music)
	get_tree().node_added.connect(_node_added)
	# Web audio is gated until an actual input gesture; this also avoids
	# surprising audio at startup on desktop.

func _input(event: InputEvent) -> void:
	if not unlocked_audio and ((event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventKey and event.pressed and not event.echo)):
		unlocked_audio = true
		set_music(THEME_IDS[load("res://scripts/themes/ThemeStore.gd").current_index()])

func _process(delta: float) -> void:
	impact_elapsed += delta
	var scene := get_tree().current_scene
	if scene != last_scene and is_instance_valid(scene):
		last_scene = scene
		# Quick fade affects only root canvas visuals, never input or physics.
		if scene is CanvasItem and not reduced_effects:
			scene.modulate.a = 0.0
			var tween := scene.create_tween(); tween.tween_property(scene, "modulate:a", 1.0, 0.16)

func set_music(id: String) -> void:
	if id not in ["forest", "sunset", "snow"] or (id == music_theme and music.playing): return
	var stream := load("res://assets/audio/music/%s.wav" % id) as AudioStreamWAV
	if stream == null: return
	stream = stream.duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	music.stop(); music.stream = stream; music_theme = id
	if unlocked_audio:
		music.play()
		if ad_audio_paused: music.stream_paused = true

func play_event(id: String, pitch: float = 1.0, volume_db: float = -3.0) -> bool:
	if ad_audio_paused or not unlocked_audio or not streams.has(id) or streams[id] == null: return false
	for player in players:
		if not player.playing:
			player.stream = streams[id]
			player.bus = "UI" if id in ["button_click", "menu_back"] else "SFX"
			player.pitch_scale = clampf(pitch, 0.8, 1.2)
			player.volume_db = volume_db
			player.play()
			accepted_events[id] = int(accepted_events.get(id, 0)) + 1
			return true
	return false

# Idempotent ad lifecycle hook; no SDK and no persistent settings mutations.
# Existing streams resume at their old positions; newly requested one-shots
# are dropped while suspended rather than unexpectedly replayed afterward.
func set_ad_audio_paused(paused: bool) -> void:
	if paused == ad_audio_paused: return
	ad_audio_paused = paused
	if paused:
		_music_paused_before_ad = music.stream_paused
		_sfx_paused_before_ad.clear()
		for player in players:
			_sfx_paused_before_ad.append(player.stream_paused)
			player.stream_paused = true
		music.stream_paused = true
	else:
		music.stream_paused = _music_paused_before_ad
		for i in range(players.size()):
			players[i].stream_paused = _sfx_paused_before_ad[i] if i < _sfx_paused_before_ad.size() else false
		_sfx_paused_before_ad.clear()

func impact(speed: float, landing: bool) -> bool:
	if speed < IMPACT_MIN or impact_elapsed < IMPACT_COOLDOWN: return false
	if play_event("soft_landing" if landing else "animal_collision", randf_range(0.94, 1.06), lerpf(-12.0, -5.0, clampf((speed - IMPACT_MIN) / 700.0, 0.0, 1.0))):
		impact_elapsed = 0.0
		return true
	return false

func _node_added(node: Node) -> void:
	if node is BaseButton:
		var button := node as BaseButton
		button.button_down.connect(_button_down.bind(button))
func _button_down(button: BaseButton) -> void:
	if not is_instance_valid(button) or button.disabled: return
	play_event("menu_back" if button.name in ["Back", "MainMenuButton"] else "button_click")
	if reduced_effects or not button is Button or button is OptionButton: return
	if button.has_meta("feel_tween"):
		var previous: Variant = button.get_meta("feel_tween")
		if previous is Tween and previous.is_running(): previous.kill()
	button.pivot_offset = button.size * 0.5
	button.scale = Vector2(0.97, 0.97)
	var tween := button.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	button.set_meta("feel_tween", tween)
	tween.tween_property(button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE)
	# This never invokes pressed and cannot repeat an action.

func _exit_tree() -> void:
	# Release streams when the single manager is destroyed (not on scene change).
	for player in players:
		if is_instance_valid(player): player.stop(); player.stream = null
	if is_instance_valid(music): music.stop(); music.stream = null
	streams.clear()
