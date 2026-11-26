extends Node
## Single bounded audio pool and one persistent music player across scenes.
const EVENTS := ["button_click", "menu_back", "animal_drop", "soft_landing", "animal_collision", "small_merge", "medium_merge", "large_merge", "combo", "golden_merge", "animal_discovered", "achievement_unlocked", "challenge_success", "challenge_failed", "undo", "remove", "rescue", "game_over", "danger_warning", "theme_unlocked"]
const MAX_PLAYERS := 8
const IMPACT_MIN := 100.0
const IMPACT_COOLDOWN := 0.18
var streams := {}
var players: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var music_theme := ""
var unlocked_audio := false
var reduced_effects := false
var impact_elapsed := 1.0
var theme_check := 0.0
var last_scene: Node
var accepted_events: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SettingsStore.apply(SettingsStore.load_values())
	for id in EVENTS: streams[id] = load("res://assets/audio/sfx/%s.wav" % id)
	for i in range(MAX_PLAYERS):
		var player := AudioStreamPlayer.new(); player.name = "Sound%d" % i; add_child(player); players.append(player)
	music = AudioStreamPlayer.new(); music.name = "Music"; music.bus = "Music"; add_child(music)
	get_tree().node_added.connect(_node_added)
	# Web audio is gated until an actual input gesture; this also avoids
	# surprising audio at startup on desktop.

func _input(event: InputEvent) -> void:
	if not unlocked_audio and ((event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventKey and event.pressed and not event.echo)):
		unlocked_audio = true
		set_music(ThemeStore.IDS[ThemeStore.current_index()])

func _process(delta: float) -> void:
	impact_elapsed += delta
	theme_check += delta
	if unlocked_audio and theme_check >= 1.0:
		theme_check = 0.0
		set_music(ThemeStore.IDS[ThemeStore.current_index()])
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
	if unlocked_audio: music.play()

func play_event(id: String, pitch: float = 1.0, volume_db: float = -3.0) -> bool:
	if not unlocked_audio or not streams.has(id) or streams[id] == null: return false
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
	# Native button pressed state is instantaneous and does not enqueue actions.
