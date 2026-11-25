extends Node2D

enum SpawnState { READY, AIMING, DROPPING, COOLDOWN }
enum GameState { PLAYING, PAUSED, GAME_OVER }

# Bounds must agree with the wall shapes in Game.tscn.
@export var left_bound: float = 91.0
@export var right_bound: float = 629.0
@export var floor_height: float = 1094.0
@export var spawn_height: float = 350.0
@export var danger_height: float = 465.0
@export_range(1.0, 20.0) var spawn_margin: float = 2.0
@export_range(0.1, 2.0) var drop_cooldown: float = 0.5
@export var test_seed: int = 0
@export var animals: Array[AnimalData] = []
@export var animal_scene: PackedScene
@export var golden_config: GoldenConfig
@export var combo_enabled: bool = true
@export_range(0.1, 5.0) var combo_window: float = 1.0
@export var debug_enabled: bool = false
@export var persist_best: bool = true
@export_enum("Forest Garden", "Sunset Safari", "Snowy Valley") var visual_theme: int = 0
const THEME_BACKGROUNDS = [preload("res://assets/backgrounds/forest_garden.svg"), preload("res://assets/backgrounds/sunset_safari.svg"), preload("res://assets/backgrounds/snowy_valley.svg")]
const THEME_BOARDS = [Color("a67850"), Color("b3825e"), Color("78999d")]
const THEME_INSIDE = [Color("f7ebcf"), Color("f9ead5"), Color("ebf1ea")]

@onready var pieces: Node2D = $Pieces
@onready var merge_manager: MergeManager = $MergeManager
@onready var danger_monitor: DangerMonitor = $DangerMonitor
@onready var current_preview = $CurrentPreview
@onready var next_preview = $NextPreview
@onready var next_label: Label = $HUD/NextLabel
@onready var score_label: Label = $HUD/ScoreLabel
@onready var best_label: Label = $HUD/BestLabel
@onready var pause_button: Button = $HUD/PauseButton
@onready var overlay: Control = $HUD/Overlay
@onready var overlay_title: Label = $HUD/Overlay/Title
@onready var resume_button: Button = $HUD/Overlay/ResumeButton
@onready var golden_label: Label = $HUD/GoldenLabel
@onready var debug_panel: Control = $HUD/DebugPanel
@onready var debug_label: Label = $HUD/DebugPanel/Info
var current_data: AnimalData
var next_data: AnimalData
var aim_x: float = 360.0
var cooldown_left: float = 0.0
var active_touch: int = -1
var mouse_down: bool = false
var rng := RandomNumberGenerator.new()
var spawn_state: SpawnState = SpawnState.READY
var game_state: GameState = GameState.PLAYING
var score: int = 0
var best_score: int = 0
var spawn_count: int = 0
var debug_outlines: bool = false
var drop_requested: bool = false
var combo_count: int = 0
var combo_left: float = 0.0
var combo_events: int = 0
var highest_level: int = 1
var golden_tween: Tween
var max_combo: int = 0
var best_at_start: int = 0
var settings_panel: Control
var tutorial_stage: int = -1
var tutorial_label: Label
var tutorial_skip: Button
const SETTINGS_SCENE := preload("res://scenes/ui/SettingsPanel.tscn")
const EFFECT_SCRIPT := preload("res://scripts/effects/MergeEffects.gd")
var reduced_effects := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var saved_settings := SettingsStore.load_values()
	SettingsStore.apply(saved_settings)
	reduced_effects = saved_settings.reduced_effects
	pieces.process_mode = Node.PROCESS_MODE_PAUSABLE
	merge_manager.process_mode = Node.PROCESS_MODE_PAUSABLE
	danger_monitor.process_mode = Node.PROCESS_MODE_PAUSABLE
	assert(animals.size() >= 2 and animal_scene != null, "Configure animal resources and scene")
	if test_seed == 0:
		rng.randomize()
	else:
		rng.seed = test_seed
	merge_manager.setup(self)
	merge_manager.merged.connect(_on_merged)
	merge_manager.golden_merged.connect(_on_golden_merged)
	danger_monitor.setup(self)
	danger_monitor.overflow.connect(_on_game_over)
	danger_monitor.danger_changed.connect(_on_danger_changed)
	pause_button.pressed.connect(_toggle_pause)
	resume_button.pressed.connect(_toggle_pause)
	$HUD/Overlay/RestartButton.pressed.connect(_restart)
	$HUD/RestartButton.pressed.connect(_restart)
	$HUD/Overlay/SettingsButton.pressed.connect(_open_settings)
	$HUD/Overlay/MainMenuButton.pressed.connect(_main_menu)
	pause_button.icon = load("res://assets/ui/icons/pause.svg")
	$HUD/RestartButton.icon = load("res://assets/ui/icons/restart.svg")
	resume_button.icon = load("res://assets/ui/icons/play.svg")
	$HUD/Overlay/RestartButton.icon = load("res://assets/ui/icons/restart.svg")
	$HUD/Overlay/SettingsButton.icon = load("res://assets/ui/icons/settings.svg")
	$HUD/Overlay/MainMenuButton.icon = load("res://assets/ui/icons/home.svg")
	_refresh_ui_text()
	best_score = _load_best()
	best_at_start = best_score
	current_data = _pick_animal()
	next_data = _pick_animal()
	if bool(get_tree().get_meta("tutorial_requested", false)):
		get_tree().remove_meta("tutorial_requested")
		current_data = animals[0]
		next_data = animals[0]
		_begin_tutorial()
	debug_panel.visible = debug_enabled and OS.is_debug_build()
	if debug_panel.visible:
		$HUD/DebugPanel/Pair.pressed.connect(_debug_pair)
		$HUD/DebugPanel/Chain.pressed.connect(_debug_chain)
		$HUD/DebugPanel/Fill.pressed.connect(_debug_fill)
		$HUD/DebugPanel/Overflow.pressed.connect(_debug_overflow)
		$HUD/DebugPanel/Outlines.pressed.connect(_toggle_debug_outlines)
		$HUD/DebugPanel/Spawn.pressed.connect(_debug_spawn_selected)
	_update_hud()
	_set_aim(aim_x)

func is_playing() -> bool:
	return game_state == GameState.PLAYING

func _physics_process(delta: float) -> void:
	if not is_playing():
		return
	cooldown_left = maxf(0.0, cooldown_left - delta)
	combo_left = maxf(0.0, combo_left - delta)
	if combo_left <= 0.0 and combo_count > 0:
		combo_count = 0
		score_label.text = "SCORE  %d" % score
	if drop_requested:
		drop_requested = false
		_attempt_drop()
	elif spawn_state == SpawnState.COOLDOWN and cooldown_left <= 0.0:
		# Only show the preview once its own spawn circle is free.
		if _spawn_clear(current_data, aim_x):
			spawn_state = SpawnState.AIMING if active_touch != -1 or mouse_down else SpawnState.READY
			_update_preview()
	elif _can_aim():
		current_preview.visible = _spawn_clear(current_data, aim_x)
	if debug_panel.visible:
		_update_debug()
	if debug_outlines:
		queue_redraw()

func _pick_animal() -> AnimalData:
	var total := 0.0
	var fallback: AnimalData = null
	for data in animals:
		if data.level <= 5:
			if fallback == null:
				fallback = data
			total += maxf(0.0, data.spawn_weight)
	assert(fallback != null, "At least one spawn-eligible animal is required")
	if total <= 0.0:
		return fallback
	var choice := rng.randf() * total
	for data in animals:
		if data.level <= 5:
			choice -= maxf(0.0, data.spawn_weight)
			if choice < 0.0:
				return data
	return fallback

func find_animal(id: StringName) -> AnimalData:
	for data in animals:
		if data.id == id:
			return data
	return null

func find_next_level(level: int) -> AnimalData:
	for data in animals:
		if data.level == level:
			return find_animal(data.next_evolution_id)
	return null

func _set_aim(x: float) -> void:
	if current_data == null:
		return
	aim_x = clampf(x, left_bound + current_data.radius + spawn_margin, right_bound - current_data.radius - spawn_margin)
	current_preview.position = Vector2(aim_x, spawn_height)
	current_preview.visible = false # Rechecked safely on the next physics tick.
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not is_playing():
		return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventScreenTouch:
		if event.pressed and active_touch == -1 and not mouse_down and _can_begin_input() and _inside_input_area(event.position):
			active_touch = event.index
			spawn_state = SpawnState.AIMING
			_set_aim(event.position.x)
		elif not event.pressed and event.index == active_touch:
			active_touch = -1
			if event.canceled:
				if spawn_state == SpawnState.AIMING:
					spawn_state = SpawnState.READY
			else:
				_set_aim(event.position.x)
				if _can_aim():
					drop_animal()
	elif event is InputEventScreenDrag and event.index == active_touch:
		_set_aim(event.position.x)
		if tutorial_stage == 0: _tutorial_set_stage(1)
	elif event is InputEventMouseMotion and active_touch == -1 and (_can_aim() or (spawn_state == SpawnState.COOLDOWN and cooldown_left <= 0.0)):
		_set_aim(event.position.x)
		if mouse_down and tutorial_stage == 0: _tutorial_set_stage(1)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and active_touch == -1:
		if event.pressed and _can_begin_input() and _inside_input_area(event.position):
			mouse_down = true
			spawn_state = SpawnState.AIMING
			_set_aim(event.position.x)
		elif not event.pressed and mouse_down:
			mouse_down = false
			_set_aim(event.position.x)
			drop_animal()

func _can_aim() -> bool:
	return spawn_state == SpawnState.READY or spawn_state == SpawnState.AIMING

func _can_begin_input() -> bool:
	# A blocked spawn must not swallow a new tap at a different x-coordinate.
	return _can_aim() or (spawn_state == SpawnState.COOLDOWN and cooldown_left <= 0.0)

func _inside_input_area(point: Vector2) -> bool:
	return point.x >= left_bound and point.x <= right_bound and point.y >= 260.0 and point.y <= floor_height

# Requests are committed at the next physics tick so the space query is safe.
func drop_animal() -> bool:
	if not is_playing() or not _can_aim() or drop_requested:
		return false
	spawn_state = SpawnState.DROPPING
	current_preview.visible = false
	drop_requested = true
	queue_redraw()
	return true

func _spawn_clear(data: AnimalData, x: float) -> bool:
	var circle := CircleShape2D.new()
	circle.radius = data.radius + 1.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, Vector2(x, spawn_height))
	query.collision_mask = 1
	query.collide_with_bodies = true
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _attempt_drop() -> void:
	if not _spawn_clear(current_data, aim_x):
		# No queue advancement and no body created on a blocked attempt.
		spawn_state = SpawnState.COOLDOWN
		cooldown_left = 0.0
		_update_preview()
		return
	var dropped := current_data
	create_animal(dropped, Vector2(aim_x, spawn_height))
	spawn_count += 1
	if tutorial_stage >= 0 and tutorial_stage < 3:
		_tutorial_set_stage(2 if spawn_count == 1 else 3)
	current_data = next_data
	next_data = _pick_animal()
	_set_aim(aim_x)
	cooldown_left = drop_cooldown
	spawn_state = SpawnState.COOLDOWN
	_update_hud()

func create_animal(data: AnimalData, point: Vector2) -> Animal:
	var animal := animal_scene.instantiate() as Animal
	animal.data = data
	highest_level = maxi(highest_level, data.level)
	queue_redraw()
	animal.position = point
	pieces.add_child(animal)
	merge_manager.observe(animal)
	return animal

func find_merge_position(midpoint: Vector2, radius: float, a: Animal, b: Animal) -> Variant:
	# Avoid inserting a larger circle into another body. If no nearby slot is
	# safe, the locked pair remains pending and is retried, not deleted.
	for ring in range(0, 9):
		var samples := 1 if ring == 0 else 16
		for index in range(samples):
			var offset := Vector2.ZERO if ring == 0 else Vector2.from_angle(TAU * index / samples) * (ring * 12.0)
			var point := midpoint + offset
			point.x = clampf(point.x, left_bound + radius, right_bound - radius)
			point.y = clampf(point.y, 300.0 + radius, floor_height - radius)
			var clear := true
			for node in pieces.get_children():
				var other := node as Animal
				if other == null or other == a or other == b or other.is_queued_for_deletion():
					continue
				if point.distance_squared_to(other.global_position) < pow(radius + other.data.radius + 1.0, 2.0):
					clear = false
					break
			if clear:
				return point
	return null

func _award_merge(base_score: int) -> void:
	if combo_enabled:
		combo_count = combo_count + 1 if combo_left > 0.0 else 1
		combo_left = combo_window
		if combo_count > 1:
			combo_events += 1
	else:
		combo_count = 1
	max_combo = maxi(max_combo, combo_count)
	var multiplier := minf(2.0, 1.0 + maxf(0, combo_count - 1) * 0.25)
	score += roundi(base_score * multiplier)
	if score > best_score:
		best_score = score
		_save_best()
	_update_hud()

func _on_merged(data: AnimalData, point: Vector2) -> void:
	_award_merge(data.merge_score)
	_spawn_effect("soft_burst", point)
	if not reduced_effects:
		_spawn_effect("sparkle", point)
		_spawn_effect("leaves", point)
		_spawn_effect("score_star", point)
		if combo_count > 1: _spawn_effect("combo_shine", point)
	if tutorial_stage == 3: _tutorial_set_stage(4)

func _spawn_effect(kind: String, point: Vector2) -> void:
	var effect := EFFECT_SCRIPT.new()
	effect.effect_kind = kind
	effect.position = to_local(point)
	add_child(effect)

func _on_golden_merged(point: Vector2) -> void:
	_spawn_effect("soft_burst", point)
	if not reduced_effects: _spawn_effect("golden_glow", point)
	# Golden award is exactly the configured bonus; it does not receive combo multiplication.
	score += golden_config.bonus_score if golden_config else 1000
	if score > best_score:
		best_score = score
		_save_best()
	_update_hud()
	golden_label.visible = true
	golden_label.modulate.a = 1.0
	if golden_tween and golden_tween.is_running():
		golden_tween.kill()
	golden_tween = create_tween()
	golden_tween.tween_interval(0.7)
	golden_tween.tween_property(golden_label, "modulate:a", 0.0, 0.5)
	golden_tween.tween_callback(func(): golden_label.visible = false)

func _load_best() -> int:
	if not persist_best:
		return 0
	var config := ConfigFile.new()
	if config.load("user://wild_garden.cfg") != OK:
		return 0
	var saved: Variant = config.get_value("scores", "best", 0)
	if typeof(saved) != TYPE_INT:
		return 0
	return maxi(0, saved)

func _save_best() -> void:
	if not persist_best:
		return
	var config := ConfigFile.new()
	config.set_value("scores", "best", best_score)
	var result := config.save("user://wild_garden.cfg")
	if result != OK:
		push_warning("Best score could not be saved: %s" % result)

func _on_danger_changed(_seconds: float) -> void:
	queue_redraw()

func _on_game_over() -> void:
	if not is_playing():
		return
	game_state = GameState.GAME_OVER
	combo_count = 0
	combo_left = 0.0
	drop_requested = false
	active_touch = -1
	mouse_down = false
	current_preview.visible = false
	var record := "\n" + tr("NEW_RECORD") if score > best_at_start and score > 0 else ""
	overlay_title.text = "%s\n%s: %d   %s: %d\n%s: %s\n%s: %d   %s: %d%s" % [tr("GAME_OVER"), tr("FINAL_SCORE"), score, tr("BEST"), best_score, tr("LARGEST"), animals[clampi(highest_level - 1, 0, animals.size() - 1)].display_name, tr("MERGES"), merge_manager.merge_count, tr("MAX_COMBO"), max_combo, record]
	resume_button.visible = false
	$HUD/Overlay/SettingsButton.visible = false
	overlay.visible = true
	get_tree().paused = true
	queue_redraw()

func _toggle_pause() -> void:
	if game_state == GameState.GAME_OVER:
		return
	if game_state == GameState.PLAYING:
		game_state = GameState.PAUSED
		active_touch = -1
		mouse_down = false
		if spawn_state == SpawnState.AIMING:
			spawn_state = SpawnState.READY
		overlay_title.text = tr("PAUSE")
		resume_button.visible = true
		$HUD/Overlay/SettingsButton.visible = true
		overlay.visible = true
		get_tree().paused = true
	else:
		game_state = GameState.PLAYING
		overlay.visible = false
		get_tree().paused = false

func _refresh_ui_text() -> void:
	pause_button.text = tr("PAUSE")
	$HUD/RestartButton.text = tr("RESTART")
	resume_button.text = tr("RESUME")
	$HUD/Overlay/RestartButton.text = tr("RESTART")
	$HUD/Overlay/SettingsButton.text = tr("SETTINGS")
	$HUD/Overlay/MainMenuButton.text = tr("MAIN_MENU")
	$HUD/Hint.text = tr("GUIDE")

func _open_settings() -> void:
	if game_state != GameState.PAUSED or is_instance_valid(settings_panel):
		return
	settings_panel = SETTINGS_SCENE.instantiate()
	$HUD.add_child(settings_panel)
	settings_panel.replay_requested.connect(func():
		get_tree().set_meta("tutorial_requested", true)
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	settings_panel.settings_changed.connect(func(values: Dictionary):
		reduced_effects = values.reduced_effects
		_refresh_ui_text()
		overlay_title.text = tr("PAUSE")
		_update_hud()
	)
	settings_panel.closed.connect(func(): settings_panel = null; $HUD/Overlay/SettingsButton.grab_focus())

func _begin_tutorial() -> void:
	var hint := Control.new(); hint.name = "Tutorial"; hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(hint)
	var panel := ColorRect.new(); panel.color = Color(0.12, 0.2, 0.15, 0.88); panel.position = Vector2(92, 245); panel.size = Vector2(536, 62); panel.mouse_filter = Control.MOUSE_FILTER_IGNORE; hint.add_child(panel)
	tutorial_label = Label.new(); tutorial_label.position = Vector2(105, 253); tutorial_label.size = Vector2(400, 46); tutorial_label.add_theme_font_size_override("font_size", 19); tutorial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE; hint.add_child(tutorial_label)
	tutorial_skip = Button.new(); tutorial_skip.name = "Skip"; tutorial_skip.position = Vector2(512, 251); tutorial_skip.size = Vector2(108, 48); hint.add_child(tutorial_skip); tutorial_skip.pressed.connect(_finish_tutorial)
	_tutorial_set_stage(0)

func _tutorial_set_stage(stage: int) -> void:
	tutorial_stage = stage
	if is_instance_valid(tutorial_label):
		var keys := ["TUTORIAL_MOVE", "TUTORIAL_DROP", "TUTORIAL_MATCH", "TUTORIAL_MERGE", "TUTORIAL_DANGER"]
		tutorial_label.text = tr(keys[clampi(stage, 0, 4)])
		tutorial_skip.text = tr("DONE" if stage == 4 else "SKIP")

func _finish_tutorial() -> void:
	tutorial_stage = -1
	var config := ConfigFile.new(); config.set_value("tutorial", "completed", true)
	if config.save("user://wild_garden_tutorial.cfg") != OK: push_warning("Tutorial state could not be saved")
	var tutorial := $HUD.get_node_or_null("Tutorial")
	if tutorial: tutorial.queue_free()

func _main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and is_playing():
		_toggle_pause()

func _update_preview() -> void:
	current_preview.data = current_data
	current_preview.visible = is_playing() and _can_aim()
	current_preview.position = Vector2(aim_x, spawn_height)
	queue_redraw()

func _update_hud() -> void:
	current_preview.data = current_data
	next_preview.data = next_data
	next_label.text = tr("NEXT") + "  ·  " + next_data.display_name.to_upper()
	score_label.text = tr("SCORE") + "  %d" % score
	if combo_count > 1:
		score_label.text += "  " + tr("COMBO") + " %d" % combo_count
	best_label.text = tr("BEST").to_upper() + "  %d" % best_score
	_update_preview()

func _draw() -> void:
	var theme_index := clampi(visual_theme, 0, 2)
	draw_texture_rect(THEME_BACKGROUNDS[theme_index], Rect2(0, 0, 720, 1280), false)
	# Visible walls and floor follow the inner faces of the collision shapes.
	var board: Color = THEME_BOARDS[theme_index]
	draw_rect(Rect2(left_bound, 280, right_bound - left_bound, floor_height - 280), THEME_INSIDE[theme_index])
	draw_rect(Rect2(left_bound - 32, 280, 32, 830), board.darkened(0.20))
	draw_rect(Rect2(right_bound, 280, 32, 830), board.darkened(0.20))
	draw_rect(Rect2(left_bound - 16, floor_height, right_bound - left_bound + 32, 32), board.darkened(0.20))
	draw_rect(Rect2(left_bound - 26, 280, 22, 814), board)
	draw_rect(Rect2(right_bound + 4, 280, 22, 814), board)
	draw_rect(Rect2(left_bound - 10, floor_height + 4, right_bound - left_bound + 20, 22), board)
	draw_rect(Rect2(left_bound, 280, 7, floor_height - 280), Color(0.25, 0.16, 0.1, 0.10))
	draw_rect(Rect2(right_bound - 7, 280, 7, floor_height - 280), Color(0.25, 0.16, 0.1, 0.10))
	var line_color := Color("d86053") if danger_monitor and danger_monitor.peak_time > 0.0 else Color("d68a77")
	draw_line(Vector2(left_bound, danger_height), Vector2(right_bound, danger_height), line_color, 3.0)
	if current_data and is_playing() and _can_aim():
		draw_dashed_line(Vector2(aim_x, spawn_height + current_data.radius + 12), Vector2(aim_x, floor_height - 8), Color(0.38, 0.48, 0.37, 0.35), 2.0, 8.0)
	# Two rows keep all twelve tiers in the bottom margin without shrinking the board.
	var font := ThemeDB.fallback_font
	for i in range(animals.size()):
		var item := animals[i]
		var x := 75.0 + (i % 6) * 114.0
		var y := 1159.0 + floori(float(i) / 6.0) * 55.0
		if item.sprite:
			var tint := Color.WHITE if item.level <= highest_level else Color(0.45, 0.45, 0.45, 0.55)
			draw_texture_rect(item.sprite, Rect2(x - 23, y, 46, 46), false, tint)
		else:
			draw_circle(Vector2(x, y + 23), 21, item.placeholder_color)
		if item.level == highest_level:
			draw_arc(Vector2(x, y + 23), 25, 0, TAU, 32, Color("d29b31"), 3.0)
		draw_string(font, Vector2(x - 25, y + 56), "%d %s" % [item.level, item.display_name.substr(0, 3).to_upper()], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("394f39"))
		if i % 6 < 5:
			draw_line(Vector2(x + 31, y + 23), Vector2(x + 78, y + 23), Color(0.35, 0.45, 0.33, 0.5), 1.5)

	if debug_outlines and is_instance_valid(pieces):
		for body in pieces.get_children():
			if body is Animal:
				draw_arc(body.position, body.data.radius, 0, TAU, 40, Color.RED, 1.5)

func _update_debug() -> void:
	debug_label.text = "FPS %d   Bodies %d\nCurrent %s  Next %s\nSpawn %d  Merge %d  Pending %d\nScore %d  SpawnState %s\nGameState %s  Danger %.2f" % [Engine.get_frames_per_second(), pieces.get_child_count(), current_data.id, next_data.id, spawn_count, merge_manager.merge_count, merge_manager.pending.size(), score, SpawnState.keys()[spawn_state], GameState.keys()[game_state], danger_monitor.peak_time]

func _debug_spawn_selected() -> void:
	if is_playing() and debug_panel.visible:
		var level: int = int($HUD/DebugPanel/Level.value)
		create_animal(animals[clampi(level - 1, 0, animals.size() - 1)], Vector2(360, 600))

func _debug_pair() -> void:
	if is_playing() and debug_panel.visible:
		var data: AnimalData = animals[clampi(int($HUD/DebugPanel/Level.value) - 1, 0, animals.size() - 1)]
		create_animal(data, Vector2(300, 700))
		create_animal(data, Vector2(300 + data.radius * 2.0 + 1.0, 700))

func _debug_chain() -> void:
	if is_playing() and debug_panel.visible:
		create_animal(animals[1], Vector2(360, 1000))
		create_animal(animals[0], Vector2(340, 880))
		create_animal(animals[0], Vector2(380, 880))

func _debug_fill() -> void:
	if is_playing() and debug_panel.visible:
		for y in range(4):
			for x in range(8):
				create_animal(animals[(x + y) % 3], Vector2(120 + x * 65, 660 + y * 75))

func _debug_overflow() -> void:
	if is_playing() and debug_panel.visible:
		# Fill a supported pile using the temporary max level, which cannot merge.
		# The regular danger monitor still decides whether overflow occurs.
		for row in range(8):
			for column in range(6):
				var body := create_animal(animals[4], Vector2(140 + column * 84, 1052 - row * 84))
				body.merge_locked = true # Debug fixture only, to retain a stable overflow pile.

func _toggle_debug_outlines() -> void:
	debug_outlines = not debug_outlines
	queue_redraw()
