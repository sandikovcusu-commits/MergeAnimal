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
@export_range(1, 100, 1) var rescue_max_remove: int = 10
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
var effect_camera: Camera2D
var floating_scores := 0
var danger_sound_active := false
var autosave_elapsed := 0.0
var save_scheduled := false
var save_status: Error = OK
var progression: Dictionary = {}
var session_tainted := false
# Legacy/debug fixture bodies have unknown provenance; their score cannot become a lifetime record.
var score_untrusted := false
var discovery_notifier: Control
# Events wait here while storage is unavailable; physics and navigation pause.
var achievement_pending: Array[Dictionary] = []
var achievement_blocked := false
var achievement_retry_elapsed := 0.0
var remove_remaining := 1
var remove_selecting := false
var remove_touch := -1
var remove_touch_start := Vector2.ZERO
var remove_committing := false
var remove_button: Button
var remove_hint: Label
var undo_remaining := 1
var undo_snapshot: Dictionary = {}
var undo_processing := false
var undo_button: Button
var next_body_uid := 1
var rescue_remaining := 1
var rescue_processing := false
var rescue_finalized := false
var gameover_checkpoint_pending := false
var rescue_verifying := false
var rescue_button: Button
var rescue_message: Label
var rescued_label: Label
var rescue_selected: Array[Animal] = []
# Adapter is present for a future verified platform integration only. It is
# not connected to inventory or an ad SDK and never grants a reward here.
var reward_gateway := RewardRequestGateway.new()

func _ready() -> void:
	_install_web_touch_cancel_guard()
	get_tree().root.size_changed.connect(_on_window_size_changed)
	get_tree().auto_accept_quit = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var saved_settings := SettingsStore.load_values()
	SettingsStore.apply(saved_settings)
	effect_camera = Camera2D.new(); effect_camera.position = Vector2(360, 640); add_child(effect_camera)
	visual_theme = ThemeStore.current_index()
	$HUD.theme = ThemeStore.ui_theme()
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
	# Keep long localized Restart labels clear of the centered title.
	$HUD/RestartButton.expand_icon = true
	$HUD/RestartButton.add_theme_constant_override("icon_max_width", 24)
	$HUD/RestartButton.add_theme_font_size_override("font_size", 14)
	$HUD/RestartButton.size = Vector2(155, 52)
	resume_button.icon = load("res://assets/ui/icons/play.svg")
	$HUD/Overlay/RestartButton.icon = load("res://assets/ui/icons/restart.svg")
	$HUD/Overlay/SettingsButton.icon = load("res://assets/ui/icons/settings.svg")
	$HUD/Overlay/MainMenuButton.icon = load("res://assets/ui/icons/home.svg")
	_setup_remove_ui()
	_setup_undo_ui()
	_setup_rescue_ui()
	_refresh_ui_text()
	discovery_notifier = preload("res://scripts/ui/DiscoveryNotification.gd").new()
	$HUD.add_child(discovery_notifier)
	discovery_notifier.reduced_effects = reduced_effects
	best_score = _load_best()
	best_at_start = best_score
	progression = SessionSave.load_progression(best_score) if persist_best else Progression.empty()
	# Migrate only from persisted evidence, never from Challenge starter boards.
	if persist_best: AchievementManager.migrate()
	current_data = _pick_animal()
	next_data = _pick_animal()
	var continuing := bool(get_tree().get_meta("continue_requested", false))
	if continuing:
		get_tree().remove_meta("continue_requested")
		var loaded := SessionSave.load_session()
		if loaded.status in ["ok", "recovered"]:
			_restore_session(loaded.data)
			if bool(loaded.data.get("game_over_pending", false)):
				_show_game_over()
		else:
			push_warning("Continue unavailable: %s" % loaded.status)
			set_physics_process(false)
			get_tree().set_meta("continue_error", true)
			call_deferred("_return_to_menu_after_load_failure")
	if not continuing and persist_best:
		progression.total_games = int(progression.total_games) + 1
	if not continuing and bool(get_tree().get_meta("tutorial_requested", false)):
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

func _return_to_menu_after_load_failure() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func is_playing() -> bool:
	return game_state == GameState.PLAYING and not undo_processing

func _physics_process(delta: float) -> void:
	if achievement_blocked:
		achievement_retry_elapsed += delta
		if achievement_retry_elapsed >= 1.0:
			achievement_retry_elapsed = 0.0
			_flush_achievement_queue()
		if achievement_blocked: return
	if not is_playing() or get_tree().paused:
		return
	cooldown_left = maxf(0.0, cooldown_left - delta)
	combo_left = maxf(0.0, combo_left - delta)
	if combo_left <= 0.0 and combo_count > 0:
		combo_count = 0
		score_label.text = "%s  %d" % [tr("SCORE"), score]
	if rescue_verifying:
		if _spawn_clear(current_data, aim_x):
			rescue_verifying = false
			_update_hud()
		# Input remains locked until the real physics-space query is clear.
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
	if persist_best:
		progression.play_seconds = float(progression.play_seconds) + delta
		autosave_elapsed += delta
		if autosave_elapsed >= 1.0 and not save_scheduled:
			save_scheduled = true
			call_deferred("_autosave_safe")
	if is_instance_valid(undo_button): _update_undo_ui()
	if debug_panel.visible:
		_update_debug()
	if debug_outlines or remove_selecting:
		queue_redraw()

func _session_snapshot(include_undo: bool = true) -> Dictionary:
	var bodies: Array = []
	for animal in pieces.get_children():
		if not animal is Animal or animal.is_queued_for_deletion() or animal.merge_locked:
			return {}
		bodies.append({"uid": animal.save_uid, "id": str(animal.data.id), "x": animal.position.x, "y": animal.position.y, "rotation": animal.rotation, "vx": animal.linear_velocity.x, "vy": animal.linear_velocity.y, "angular_velocity": animal.angular_velocity, "sleeping": animal.sleeping, "eligible": animal.progression_eligible, "danger": float(danger_monitor.timers.get(animal.instance_uid, 0.0))})
	return {"session_version": 3, "generation": 0, "undo_remaining": undo_remaining, "undo_snapshot": undo_snapshot.duplicate(true) if include_undo else {}, "next_body_uid": next_body_uid, "rescue_remaining": rescue_remaining, "game_over_pending": game_state == GameState.GAME_OVER and not rescue_finalized, "active": true, "score": score, "best_score": best_score, "best_at_start": best_at_start, "spawn_count": spawn_count, "merge_count": merge_manager.merge_count, "combo_count": combo_count, "combo_left": combo_left, "combo_events": combo_events, "max_combo": max_combo, "highest_level": highest_level, "current": str(current_data.id), "next": str(next_data.id), "rng_state": str(rng.state), "aim_x": aim_x, "cooldown_left": cooldown_left, "tutorial_stage": tutorial_stage, "bodies": bodies, "progression": progression.duplicate(true), "tainted": session_tainted, "score_untrusted": score_untrusted, "remove_remaining": remove_remaining}

func save_session() -> Error:
	# Recheck at execution time, after physics/contact callbacks and deferred merges.
	if not persist_best or game_state == GameState.GAME_OVER or drop_requested or not merge_manager.pending.is_empty() or merge_manager.commit_scheduled:
		return ERR_BUSY
	if not SessionSave.can_write(): return ERR_UNAVAILABLE
	var snapshot := _session_snapshot()
	if not SessionSave.valid(snapshot): return ERR_INVALID_DATA
	save_status = SessionSave.write_snapshot(snapshot)
	return save_status

func _autosave_safe() -> void:
	save_scheduled = false
	if not is_inside_tree() or not is_playing(): return
	var result := save_session()
	if result == OK:
		$HUD/SaveStatus.visible = false
	elif result != ERR_BUSY:
		$HUD/SaveStatus.text = tr("SAVE_FAILED")
		$HUD/SaveStatus.visible = true
	# Retry later rather than writing an incomplete merge or hammering the filesystem.
	autosave_elapsed = 0.0

func _restore_session(data: Dictionary) -> void:
	# SessionSave.valid ran before creating any body; a fresh scene has an empty board.
	if data.has("progression"): progression = data.progression.duplicate(true)
	remove_remaining = int(data.get("remove_remaining", 1))
	undo_remaining = int(data.get("undo_remaining", 1))
	rescue_remaining = int(data.get("rescue_remaining", 1))
	undo_snapshot = data.get("undo_snapshot", {}).duplicate(true)
	next_body_uid = maxi(next_body_uid, int(data.get("next_body_uid", 1)))
	session_tainted = bool(data.get("tainted", false))
	score_untrusted = bool(data.get("score_untrusted", false))
	score = int(data.score)
	best_score = int(data.best_score) if int(data.session_version) >= 3 else maxi(best_score, int(data.best_score))
	best_at_start = int(data.best_at_start)
	progression.best_score = maxi(int(progression.best_score), best_score)
	spawn_count = int(data.spawn_count); merge_manager.merge_count = int(data.merge_count)
	combo_count = int(data.combo_count); combo_left = float(data.combo_left); combo_events = int(data.combo_events); max_combo = int(data.max_combo)
	highest_level = int(data.highest_level)
	current_data = find_animal(StringName(data.current)); next_data = find_animal(StringName(data.next))
	rng.state = int(data.rng_state)
	aim_x = float(data.aim_x); cooldown_left = float(data.cooldown_left)
	spawn_state = SpawnState.COOLDOWN if cooldown_left > 0.0 else SpawnState.READY
	for item in data.bodies:
		var body := create_animal(find_animal(StringName(item.id)), Vector2(float(item.x), float(item.y)))
		body.save_uid = int(item.uid)
		next_body_uid = maxi(next_body_uid, body.save_uid + 1)
		body.rotation = float(item.rotation)
		body.linear_velocity = Vector2(float(item.vx), float(item.vy))
		body.angular_velocity = float(item.angular_velocity)
		body.sleeping = item.sleeping
		body.progression_eligible = bool(item.get("eligible", false))
		if float(item.danger) > 0.0: danger_monitor.timers[body.instance_uid] = float(item.danger)
	if int(data.tutorial_stage) >= 0:
		_begin_tutorial()
		_tutorial_set_stage(int(data.tutorial_stage))

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

# Undo uses the same validated board snapshot as Continue. Physics is paused
# until the user:// checkpoint is written and all old bodies are detached.
# On Web this write is not an IndexedDB durability acknowledgement.
func _setup_undo_ui() -> void:
	undo_button = Button.new()
	undo_button.name = "UndoButton"
	undo_button.position = Vector2(285, 212)
	undo_button.size = Vector2(155, 54)
	undo_button.icon = load("res://assets/ui/icons/undo.svg")
	undo_button.expand_icon = true
	undo_button.add_theme_constant_override("icon_max_width", 29)
	undo_button.add_theme_font_size_override("font_size", 16)
	$HUD.add_child(undo_button)
	undo_button.pressed.connect(_request_undo)
	_update_undo_ui()

func _update_undo_ui() -> void:
	if not is_instance_valid(undo_button): return
	undo_button.disabled = undo_processing or undo_remaining <= 0 or undo_snapshot.is_empty() or not is_playing() or remove_selecting or remove_committing or drop_requested or not merge_manager.pending.is_empty() or merge_manager.commit_scheduled
	if undo_processing: undo_button.text = tr("UNDO_PROCESSING")
	elif undo_remaining <= 0: undo_button.text = tr("UNDO_USED")
	elif undo_snapshot.is_empty(): undo_button.text = tr("UNDO_EMPTY")
	else: undo_button.text = tr("UNDO_AVAILABLE")

func _request_undo() -> void:
	if not is_playing() or get_tree().paused or undo_remaining <= 0 or undo_snapshot.is_empty() or remove_selecting or remove_committing or drop_requested: return
	if not merge_manager.pending.is_empty() or merge_manager.commit_scheduled: return
	undo_processing = true
	active_touch = -1
	mouse_down = false
	get_tree().paused = true
	_update_undo_ui()
	_update_remove_ui()
	call_deferred("_commit_undo")

func _commit_undo() -> void:
	if not undo_processing: return
	var candidate := undo_snapshot.duplicate(true)
	var result: Error = ERR_INVALID_DATA
	if game_state == GameState.PLAYING and merge_manager.pending.is_empty() and not merge_manager.commit_scheduled and SessionSave.valid(candidate, false):
		candidate.undo_snapshot = {}
		candidate.undo_remaining = undo_remaining - 1
		candidate.remove_remaining = remove_remaining
		candidate.rescue_remaining = rescue_remaining
		candidate.next_body_uid = next_body_uid
		candidate.tainted = session_tainted or bool(candidate.get("tainted", false))
		# Discovery dates are durable; counts/merge totals/score are rolled back.
		var old_progress: Dictionary = candidate.progression
		for id in Progression.IDS:
			if str(old_progress.animals[id].date).is_empty() and not str(progression.animals[id].date).is_empty():
				old_progress.animals[id].date = progression.animals[id].date
		old_progress.highest_animal = maxi(int(old_progress.highest_animal), int(progression.highest_animal))
		old_progress.play_seconds = progression.play_seconds
		result = OK if not persist_best else SessionSave.write_snapshot(candidate, true)
	if result != OK:
		save_status = result
		$HUD/SaveStatus.text = tr("SAVE_FAILED")
		$HUD/SaveStatus.visible = true
		undo_processing = false
		get_tree().paused = false
		_update_undo_ui(); _update_remove_ui()
		return
	# No pending merges exist; detach old signal sources while physics is paused.
	for node in pieces.get_children():
		if node is Animal:
			node.merge_locked = true
			if node.body_entered.is_connected(merge_manager._on_body_entered.bind(node)):
				node.body_entered.disconnect(merge_manager._on_body_entered.bind(node))
		pieces.remove_child(node)
		node.queue_free()
	danger_monitor.timers.clear()
	danger_monitor.peak_time = 0.0
	var tutorial := $HUD.get_node_or_null("Tutorial")
	if tutorial: $HUD.remove_child(tutorial); tutorial.queue_free()
	tutorial_stage = -1
	tutorial_label = null
	tutorial_skip = null
	if golden_tween and golden_tween.is_running(): golden_tween.kill()
	golden_label.visible = false
	_restore_session(candidate)
	FeelAudio.play_event("undo")
	if persist_best: AchievementManager.synchronize(progression, {}, false)
	for timer in danger_monitor.timers.values(): danger_monitor.peak_time = maxf(danger_monitor.peak_time, float(timer))
	undo_processing = false
	get_tree().paused = false
	save_status = OK
	$HUD/SaveStatus.visible = false
	_update_hud()
	queue_redraw()

# Remove is committed outside physics callbacks. The candidate snapshot is
# written before mutating the live board, so a rejected write costs nothing.
func _setup_remove_ui() -> void:
	remove_button = Button.new()
	remove_button.name = "RemoveButton"
	remove_button.position = Vector2(80, 212)
	remove_button.size = Vector2(200, 54)
	remove_button.icon = load("res://assets/ui/icons/remove.svg")
	remove_button.expand_icon = true
	remove_button.add_theme_constant_override("icon_max_width", 32)
	remove_button.add_theme_font_size_override("font_size", 19)
	$HUD.add_child(remove_button)
	remove_button.pressed.connect(_toggle_remove)
	remove_hint = Label.new()
	remove_hint.name = "RemoveHint"
	remove_hint.position = Vector2(80, 265)
	remove_hint.size = Vector2(560, 30)
	remove_hint.add_theme_font_size_override("font_size", 18)
	remove_hint.add_theme_color_override("font_color", Color("263e2b"))
	remove_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(remove_hint)
	_update_remove_ui()

func _update_remove_ui() -> void:
	if not is_instance_valid(remove_button): return
	remove_button.disabled = remove_committing or (not remove_selecting and (remove_remaining <= 0 or not is_playing()))
	remove_button.text = tr("REMOVE_CANCEL") if remove_selecting else (tr("REMOVE_USED") if remove_remaining == 0 else tr("REMOVE_AVAILABLE"))
	remove_hint.visible = remove_selecting
	remove_hint.text = tr("REMOVE_SELECT")

func _toggle_remove() -> void:
	if remove_selecting:
		_cancel_remove()
		return
	if not is_playing() or remove_remaining <= 0 or remove_committing or drop_requested: return
	remove_selecting = true
	active_touch = -1
	mouse_down = false
	if spawn_state == SpawnState.AIMING: spawn_state = SpawnState.READY
	current_preview.visible = false
	_update_remove_ui()
	_update_undo_ui()
	queue_redraw()

func _cancel_remove() -> void:
	if remove_committing: return
	remove_touch = -1
	remove_selecting = false
	_update_remove_ui()
	_update_undo_ui()
	queue_redraw()

func _remove_eligible(node: Node) -> bool:
	return node is Animal and is_instance_valid(node) and node.get_parent() == pieces and not node.is_queued_for_deletion() and not node.merge_locked

func _select_remove_at(point: Vector2) -> void:
	if not remove_selecting or remove_committing: return
	var chosen: Animal = null
	var nearest := INF
	for node in pieces.get_children():
		if not _remove_eligible(node): continue
		var distance: float = node.global_position.distance_squared_to(point)
		if distance <= node.data.radius * node.data.radius and distance < nearest:
			chosen = node
			nearest = distance
	if chosen == null: return
	remove_committing = true
	_update_remove_ui()
	call_deferred("_commit_remove", chosen)

func _commit_remove(body: Animal) -> void:
	if not is_playing() or not remove_selecting or remove_remaining <= 0 or not _remove_eligible(body) or drop_requested or not merge_manager.pending.is_empty() or merge_manager.commit_scheduled:
		remove_committing = false
		_update_remove_ui()
		return
	var snapshot := _session_snapshot()
	if snapshot.is_empty():
		remove_committing = false
		_update_remove_ui()
		return
	var index := pieces.get_children().find(body)
	if index < 0 or index >= snapshot.bodies.size():
		remove_committing = false
		_update_remove_ui()
		return
	snapshot.bodies.remove_at(index)
	snapshot.remove_remaining = remove_remaining - 1
	snapshot.undo_snapshot = {} # Removing an animal invalidates the old drop boundary.
	var result: Error = OK
	if persist_best:
		result = SessionSave.write_snapshot(snapshot, true)
	if result != OK:
		save_status = result
		$HUD/SaveStatus.text = tr("SAVE_FAILED")
		$HUD/SaveStatus.visible = true
		remove_committing = false
		_update_remove_ui()
		return
	# Block stale contact callbacks before detaching. No merge or reward is emitted.
	body.merge_locked = true
	if body.body_entered.is_connected(merge_manager._on_body_entered.bind(body)):
		body.body_entered.disconnect(merge_manager._on_body_entered.bind(body))
	danger_monitor.timers.erase(body.instance_uid)
	pieces.remove_child(body)
	body.queue_free()
	remove_remaining -= 1
	FeelAudio.play_event("remove")
	undo_snapshot = {}
	remove_selecting = false
	remove_committing = false
	save_status = OK
	$HUD/SaveStatus.visible = false
	_update_hud()
	queue_redraw()

# Godot 4.7.2 Web maps DOM touchcancel to an ordinary touch release and
# does not set InputEventScreenTouch.canceled. Capture the cancelled DOM IDs
# before the engine's canvas listener and consume the marker on release.
# Native exports and ordinary touchend keep their original behavior.
func _install_web_touch_cancel_guard() -> void:
	if not OS.has_feature("web"): return
	JavaScriptBridge.eval("""
	if (!window.__wildGardenTouchCancel) {
	  const cancelled = new Set();
	  const held = new Set();
	  window.__wildGardenTouchCancel = cancelled;
	  window.addEventListener('touchstart', e => {
	    for (const t of e.changedTouches) { cancelled.delete(t.identifier); held.add(t.identifier); }
	  }, true);
	  window.addEventListener('touchend', e => {
	    for (const t of e.changedTouches) held.delete(t.identifier);
	  }, true);
	  const invalidateHeld = () => { for (const id of held) cancelled.add(id); };
	  window.addEventListener('blur', invalidateHeld, true);
	  document.addEventListener('visibilitychange', () => {
	    if (document.hidden) invalidateHeld();
	  }, true);
	  window.addEventListener('touchcancel', e => {
	    const ids = Array.from(e.changedTouches, t => t.identifier);
	    for (const id of ids) { cancelled.add(id); held.delete(id); }
	    setTimeout(() => { for (const id of ids) cancelled.delete(id); }, 0);
	  }, true);
	}
	""", true)

func _web_touch_was_cancelled(index: int) -> bool:
	if not OS.has_feature("web"): return false
	return bool(JavaScriptBridge.eval("Boolean(window.__wildGardenTouchCancel && window.__wildGardenTouchCancel.delete(%d))" % index, true))

func _unhandled_input(event: InputEvent) -> void:
	if not is_playing():
		return
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if remove_selecting or remove_committing:
		if remove_selecting and not remove_committing:
			if event is InputEventScreenTouch:
				if event.pressed and remove_touch == -1:
					remove_touch = event.index
					remove_touch_start = event.position
				elif not event.pressed and event.index == remove_touch:
					remove_touch = -1
					if not event.canceled and not _web_touch_was_cancelled(event.index) and event.position.distance_to(remove_touch_start) <= 24.0:
						_select_remove_at(event.position)
			elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_select_remove_at(event.position)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed and active_touch == -1 and not mouse_down and _can_begin_input() and _inside_input_area(event.position):
			active_touch = event.index
			spawn_state = SpawnState.AIMING
			_set_aim(event.position.x)
		elif not event.pressed and event.index == active_touch:
			active_touch = -1
			if event.canceled or _web_touch_was_cancelled(event.index):
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
	return not remove_selecting and not remove_committing and not rescue_verifying and (spawn_state == SpawnState.READY or spawn_state == SpawnState.AIMING)

func _can_begin_input() -> bool:
	# A blocked spawn must not swallow a new tap at a different x-coordinate.
	return not remove_selecting and not remove_committing and not rescue_verifying and (_can_aim() or (spawn_state == SpawnState.COOLDOWN and cooldown_left <= 0.0))

func _inside_input_area(point: Vector2) -> bool:
	return point.x >= left_bound and point.x <= right_bound and point.y >= 260.0 and point.y <= floor_height

# Requests are committed at the next physics tick so the space query is safe.
func drop_animal() -> bool:
	if not is_playing() or remove_selecting or remove_committing or not _can_aim() or drop_requested:
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
	if not merge_manager.pending.is_empty() or merge_manager.commit_scheduled or not _spawn_clear(current_data, aim_x):
		# No queue advancement and no body created on a blocked attempt.
		spawn_state = SpawnState.COOLDOWN
		cooldown_left = 0.0
		_update_preview()
		return
	# A successful drop is only allowed when a complete, stable pre-drop board
	# can be captured. A blocked attempt leaves the previous undo untouched.
	var before := _session_snapshot(false)
	if not SessionSave.valid(before):
		spawn_state = SpawnState.COOLDOWN
		cooldown_left = 0.0
		_update_preview()
		return
	undo_snapshot = before
	var dropped := current_data
	var dropped_body := create_animal(dropped, Vector2(aim_x, spawn_height))
	dropped_body.progression_eligible = true
	dropped_body.visual.animate_action("drop")
	FeelAudio.play_event("animal_drop")
	spawn_count += 1
	if persist_best and not session_tainted:
		progression.total_drops = int(progression.total_drops) + 1
		_record_discovery(dropped)
		_sync_achievements()
	if tutorial_stage >= 0 and tutorial_stage < 3:
		_tutorial_set_stage(2 if spawn_count == 1 else 3)
	current_data = next_data
	next_data = _pick_animal()
	_set_aim(aim_x)
	cooldown_left = drop_cooldown
	spawn_state = SpawnState.COOLDOWN
	_update_hud()
	# Persist the new undo boundary promptly at the next safe idle point.
	if persist_best and not save_scheduled:
		save_scheduled = true
		call_deferred("_autosave_safe")

func create_animal(data: AnimalData, point: Vector2) -> Animal:
	var animal := animal_scene.instantiate() as Animal
	animal.data = data
	animal.save_uid = next_body_uid
	next_body_uid += 1
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
	if score > best_score and (not persist_best or (not session_tainted and not score_untrusted and merge_manager.last_merge_eligible)):
		best_score = score
		_save_best()
	_update_hud()

func _on_merged(data: AnimalData, point: Vector2) -> void:
	var previous_score := score
	if persist_best and not merge_manager.last_merge_eligible: score_untrusted = true
	_award_merge(data.merge_score)
	FeelAudio.play_event("small_merge" if data.level <= 4 else "medium_merge" if data.level <= 8 else "large_merge")
	if combo_count > 1: FeelAudio.play_event("combo", minf(1.15, 1.0 + combo_count * 0.025), -7.0)
	_show_score_effect(point, score - previous_score)
	if persist_best and not session_tainted and merge_manager.last_merge_eligible:
		progression.total_merges = int(progression.total_merges) + 1
		if not score_untrusted:
			progression.best_score = maxi(int(progression.best_score), score)
			progression.max_combo = maxi(int(progression.max_combo), combo_count)
		_record_discovery(data)
		_sync_achievements()
	_spawn_effect("soft_burst", point)
	if not reduced_effects:
		_spawn_effect("sparkle", point)
		_spawn_effect("leaves", point)
		_spawn_effect("score_star", point)
		if combo_count > 1: _spawn_effect("combo_shine", point)
	if tutorial_stage == 3: _tutorial_set_stage(4)

func _record_discovery(data: AnimalData) -> void:
	if Progression.record_animal(progression, data) and is_instance_valid(discovery_notifier):
		discovery_notifier.enqueue(data)

func _sync_achievements() -> void:
	if not persist_best or session_tainted: return
	_queue_achievement(progression, {}, true)

func _queue_achievement(progress: Dictionary, challenges: Dictionary, live: bool, event: Dictionary = {}) -> void:
	achievement_pending.append({"progress": progress.duplicate(true), "challenges": challenges.duplicate(true), "live": live, "event": event.duplicate(true)})
	_flush_achievement_queue()

func _flush_achievement_queue() -> void:
	while not achievement_pending.is_empty():
		var job: Dictionary = achievement_pending[0]
		var result := AchievementManager.synchronize(job.progress, job.challenges, job.live, job.event)
		if result.status != "ok":
			achievement_blocked = true
			get_tree().paused = true
			if is_node_ready():
				$HUD/SaveStatus.text = tr("ACH_SAVE_WAIT")
				$HUD/SaveStatus.visible = true
			return
		achievement_pending.pop_front()
		if is_instance_valid(discovery_notifier):
			for achievement in result.new: discovery_notifier.enqueue_achievement(achievement)
	if achievement_blocked:
		achievement_blocked = false
		if is_node_ready(): $HUD/SaveStatus.visible = false
		if game_state == GameState.PLAYING: get_tree().paused = false
		_achievement_recovered()

func _achievement_recovered() -> void: pass

func _spawn_effect(kind: String, point: Vector2) -> void:
	if get_tree().get_nodes_in_group("visual_effects").size() >= 40: return
	var effect := EFFECT_SCRIPT.new()
	effect.effect_kind = kind
	effect.position = to_local(point)
	effect.add_to_group("visual_effects")
	add_child(effect)

func _show_score_effect(point: Vector2, amount: int) -> void:
	if floating_scores >= 8: return
	floating_scores += 1
	var label := Label.new(); label.text = "+%d" % amount; label.position = to_local(point) + Vector2(-35, -50)
	label.size = Vector2(130, 50); label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color("4a3424"))
	label.add_theme_color_override("font_outline_color", Color("fff4ce"))
	label.add_theme_constant_override("outline_size", 3); label.z_index = 8
	$HUD.add_child(label)
	var tween := label.create_tween(); tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - (12.0 if reduced_effects else 45.0), 0.7)
	tween.tween_property(label, "modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(_finish_score_effect.bind(label))

func _finish_score_effect(label: Label) -> void:
	floating_scores -= 1
	if is_instance_valid(label): label.queue_free()

func _on_golden_merged(point: Vector2) -> void:
	FeelAudio.play_event("golden_merge")
	_show_score_effect(point, golden_config.bonus_score if golden_config else 1000)
	if not reduced_effects and is_instance_valid(effect_camera):
		effect_camera.offset = Vector2(5, -3)
		var shake := effect_camera.create_tween(); shake.tween_property(effect_camera, "offset", Vector2(-3, 2), 0.06); shake.tween_property(effect_camera, "offset", Vector2.ZERO, 0.12)
	if persist_best and not merge_manager.last_merge_eligible: score_untrusted = true
	_spawn_effect("soft_burst", point)
	if not reduced_effects:
		_spawn_effect("golden_glow", point)
		_spawn_effect("sparkle", point)
		_spawn_effect("score_star", point)
	# Golden award is exactly the configured bonus; it does not receive combo multiplication.
	score += golden_config.bonus_score if golden_config else 1000
	if persist_best and not session_tainted and merge_manager.last_merge_eligible:
		progression.total_merges = int(progression.total_merges) + 1
		progression.golden_merges = int(progression.golden_merges) + 1
		if not score_untrusted: progression.best_score = maxi(int(progression.best_score), score)
		_sync_achievements()
	if score > best_score and (not persist_best or (not session_tainted and not score_untrusted and merge_manager.last_merge_eligible)):
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
	return int(SessionSave.load_progression().best_score) if persist_best else 0

func _save_best() -> void:
	# Lifetime best travels with progression at the next session checkpoint.
	# Writing a separate legacy file would resurrect a record after Undo.
	pass

func _on_danger_changed(seconds: float) -> void:
	if seconds > 0.0 and not danger_sound_active:
		danger_sound_active = true; FeelAudio.play_event("danger_warning")
	elif seconds <= 0.0: danger_sound_active = false
	queue_redraw()

func _on_game_over() -> void:
	if not is_playing(): return
	FeelAudio.play_event("game_over")
	_cancel_remove()
	# Cancel reservations, not body/score mutations, before checkpointing. A
	# previously deferred commit sees GAME_OVER and cannot touch this board.
	for pair in merge_manager.pending:
		for key in ["a", "b"]:
			var body: Variant = pair.get(key)
			if is_instance_valid(body): body.merge_locked = false
	merge_manager.pending.clear()
	merge_manager.commit_scheduled = false
	combo_count = 0
	combo_left = 0.0
	drop_requested = false
	active_touch = -1
	mouse_down = false
	if spawn_state == SpawnState.DROPPING or spawn_state == SpawnState.AIMING: spawn_state = SpawnState.READY
	_show_game_over()
	if persist_best:
		gameover_checkpoint_pending = true
		_update_rescue_ui()
		call_deferred("_checkpoint_game_over")

func _show_game_over() -> void:
	game_state = GameState.GAME_OVER
	rescue_finalized = false
	current_preview.visible = false
	_update_remove_ui()
	_update_undo_ui()
	var record := "\n" + tr("NEW_RECORD") if score > best_at_start and score > 0 and not session_tainted and not score_untrusted else ""
	overlay_title.text = "%s\n%s: %d   %s: %d\n%s: %s\n%s: %d   %s: %d%s" % [tr("GAME_OVER"), tr("FINAL_SCORE"), score, tr("BEST"), best_score, tr("LARGEST"), tr(animals[clampi(highest_level - 1, 0, animals.size() - 1)].translation_key), tr("MERGES"), merge_manager.merge_count, tr("MAX_COMBO"), max_combo, record]
	resume_button.visible = false
	$HUD/Overlay/SettingsButton.visible = false
	$HUD/Overlay/RestartButton.position.y = 180
	$HUD/Overlay/RestartButton.text = tr("PLAY_AGAIN")
	$HUD/Overlay/MainMenuButton.position.y = 330
	rescue_button.visible = true
	rescue_message.text = ""
	rescue_message.visible = true
	overlay.visible = true
	_animate_overlay()
	get_tree().paused = true
	_update_rescue_ui()
	if not record.is_empty() and not reduced_effects:
		overlay_title.modulate = Color("ffd96c")
		create_tween().tween_property(overlay_title, "modulate", Color.WHITE, 0.8)
	queue_redraw()

func _animate_overlay() -> void:
	if reduced_effects:
		overlay.modulate.a = 1.0
		return
	overlay.modulate.a = 0.0
	var tween := overlay.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.18)

func _checkpoint_game_over() -> void:
	gameover_checkpoint_pending = false
	if game_state != GameState.GAME_OVER or rescue_finalized: return
	var snapshot := _session_snapshot()
	save_status = SessionSave.write_snapshot(snapshot, true) if not snapshot.is_empty() else ERR_BUSY
	if save_status != OK:
		rescue_message.text = tr("SAVE_FAILED")
	_update_rescue_ui()

# Exactly one completed-game increment, committed together with tombstone.
func _finalize_game() -> Error:
	if game_state != GameState.GAME_OVER or rescue_finalized: return OK
	var final_progress := progression.duplicate(true)
	if persist_best: final_progress.completed_games = int(final_progress.completed_games) + 1
	var result: Error = SessionSave.clear_session(final_progress) if persist_best else OK
	if result == OK:
		progression = final_progress
		rescue_finalized = true
	return result

func _setup_rescue_ui() -> void:
	rescue_button = Button.new()
	rescue_button.name = "RescueButton"
	rescue_button.position = Vector2(70, 255)
	rescue_button.size = Vector2(340, 55)
	rescue_button.icon = load("res://assets/ui/icons/rescue.svg")
	rescue_button.expand_icon = true
	rescue_button.add_theme_constant_override("icon_max_width", 38)
	rescue_button.add_theme_font_size_override("font_size", 23)
	rescue_button.visible = false
	overlay.add_child(rescue_button)
	rescue_button.pressed.connect(_request_rescue)
	rescue_message = Label.new()
	rescue_message.name = "RescueMessage"
	rescue_message.position = Vector2(20, 395)
	rescue_message.size = Vector2(440, 85)
	rescue_message.add_theme_font_size_override("font_size", 18)
	rescue_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rescue_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rescue_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rescue_message.visible = false
	overlay.add_child(rescue_message)
	rescued_label = Label.new()
	rescued_label.name = "RescuedLabel"
	rescued_label.position = Vector2(150, 410)
	rescued_label.size = Vector2(420, 70)
	rescued_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rescued_label.add_theme_font_size_override("font_size", 38)
	rescued_label.add_theme_color_override("font_color", Color("e59a23"))
	rescued_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rescued_label.visible = false
	$HUD.add_child(rescued_label)

func _update_rescue_ui() -> void:
	if not is_instance_valid(rescue_button): return
	rescue_button.disabled = game_state != GameState.GAME_OVER or rescue_remaining <= 0 or rescue_finalized or rescue_processing or gameover_checkpoint_pending
	rescue_button.text = tr("RESCUE_PROCESSING") if rescue_processing or gameover_checkpoint_pending else (tr("RESCUE_USED") if rescue_remaining <= 0 else tr("RESCUE_AVAILABLE"))

func _request_rescue() -> void:
	if game_state != GameState.GAME_OVER or rescue_finalized or rescue_processing or gameover_checkpoint_pending or rescue_remaining <= 0: return
	rescue_processing = true
	rescue_message.text = ""
	_update_rescue_ui()
	call_deferred("_commit_rescue")

func _rescue_failed(key: String) -> void:
	rescue_processing = false
	rescue_selected.clear()
	rescue_message.text = tr(key)
	_update_rescue_ui()
	queue_redraw()

func _commit_rescue() -> void:
	if game_state != GameState.GAME_OVER or rescue_finalized or not rescue_processing or not merge_manager.pending.is_empty() or merge_manager.commit_scheduled:
		_rescue_failed("RESCUE_FAILED"); return
	var snapshot := _session_snapshot()
	if snapshot.is_empty():
		_rescue_failed("RESCUE_FAILED"); return
	var items: Array = []
	var by_uid := {}
	for body in pieces.get_children():
		if not body is Animal or body.merge_locked or body.is_queued_for_deletion():
			_rescue_failed("RESCUE_FAILED"); return
		items.append({"uid": body.save_uid, "x": body.position.x, "y": body.position.y, "radius": body.data.radius, "level": body.data.level})
		by_uid[body.save_uid] = body
	var xmin := left_bound + current_data.radius + spawn_margin
	var xmax := right_bound - current_data.radius - spawn_margin
	var plan := RescuePlanner.plan(items, danger_height, spawn_height, current_data.radius, xmin, xmax, aim_x, rescue_max_remove)
	if plan.is_empty():
		_rescue_failed("RESCUE_FAILED"); return
	var ids: Array = plan.remove_uids
	# Check the actual collision world too, excluding only the planned removals.
	# Geometric planning alone cannot account for additional static fixtures.
	var circle := CircleShape2D.new()
	circle.radius = current_data.radius + 1.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, Vector2(float(plan.spawn_x), spawn_height))
	query.collision_mask = 1
	var excluded: Array[RID] = []
	for uid in ids: excluded.append(by_uid[uid].get_rid())
	query.exclude = excluded
	if not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
		_rescue_failed("RESCUE_FAILED"); return
	var kept: Array = []
	for item in snapshot.bodies:
		if int(item.uid) not in ids:
			item.danger = 0.0
			kept.append(item)
	snapshot.bodies = kept
	snapshot.aim_x = plan.spawn_x
	snapshot.rescue_remaining = rescue_remaining - 1
	snapshot.game_over_pending = false
	snapshot.undo_snapshot = {}
	# A short cooldown also prevents held or synthetic input from dropping
	# before the physics space has confirmed a free spawn circle.
	snapshot.cooldown_left = maxf(0.25, float(snapshot.cooldown_left))
	if not SessionSave.valid(snapshot):
		_rescue_failed("RESCUE_FAILED"); return
	var result: Error = SessionSave.write_snapshot(snapshot, true) if persist_best else OK
	if result != OK:
		save_status = result
		_rescue_failed("SAVE_FAILED"); return
	# The checkpoint is the commit point. Highlight while paused, then detach.
	FeelAudio.play_event("rescue")
	for uid in ids:
		var body: Animal = by_uid[uid]
		rescue_selected.append(body)
		body.visual.modulate = Color(1.0, 0.75, 0.35, 1.0)
	overlay.visible = false
	queue_redraw()
	await get_tree().create_timer(0.4, true).timeout
	for body in rescue_selected:
		if not is_instance_valid(body): continue
		var point: Vector2 = body.global_position
		body.merge_locked = true
		if body.body_entered.is_connected(merge_manager._on_body_entered.bind(body)):
			body.body_entered.disconnect(merge_manager._on_body_entered.bind(body))
		pieces.remove_child(body)
		body.queue_free()
		if not reduced_effects: _spawn_effect("soft_burst", point)
	rescue_selected.clear()
	danger_monitor.timers.clear()
	danger_monitor.peak_time = 0.0
	rescue_remaining -= 1
	undo_snapshot = {}
	aim_x = float(plan.spawn_x)
	cooldown_left = float(snapshot.cooldown_left)
	spawn_state = SpawnState.COOLDOWN
	rescue_processing = false
	rescue_verifying = true
	game_state = GameState.PLAYING
	save_status = OK
	get_tree().paused = false
	rescued_label.text = tr("RESCUED")
	rescued_label.visible = true
	rescued_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(0.7)
	tween.tween_property(rescued_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): rescued_label.visible = false)
	_update_hud()
	queue_redraw()

func _toggle_pause() -> void:
	if achievement_blocked: return
	if game_state == GameState.GAME_OVER:
		return
	if game_state == GameState.PLAYING:
		_cancel_remove()
		game_state = GameState.PAUSED
		rescue_button.visible = false
		rescue_message.visible = false
		$HUD/Overlay/RestartButton.position.y = 245
		$HUD/Overlay/RestartButton.text = tr("RESTART")
		$HUD/Overlay/MainMenuButton.position.y = 385
		_update_remove_ui()
		_update_undo_ui()
		active_touch = -1
		mouse_down = false
		# Cancel uncommitted input when pausing; it must not drop on resume.
		drop_requested = false
		if spawn_state == SpawnState.AIMING or spawn_state == SpawnState.DROPPING:
			spawn_state = SpawnState.READY
		var pause_save := save_session() if persist_best else OK
		overlay_title.text = tr("PAUSE") if pause_save == OK else tr("SAVE_WAIT")
		resume_button.visible = true
		$HUD/Overlay/SettingsButton.visible = true
		overlay.visible = true
		get_tree().paused = true
	else:
		game_state = GameState.PLAYING
		_update_remove_ui()
		_update_undo_ui()
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
	_update_remove_ui()
	_update_undo_ui()

func _open_settings() -> void:
	if game_state != GameState.PAUSED or is_instance_valid(settings_panel):
		return
	settings_panel = SETTINGS_SCENE.instantiate()
	$HUD.add_child(settings_panel)
	settings_panel.replay_requested.connect(func():
		if persist_best and SessionSave.clear_session(progression) != OK:
			overlay_title.text = tr("SAVE_WAIT")
			return
		get_tree().set_meta("tutorial_requested", true)
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	settings_panel.settings_changed.connect(func(values: Dictionary):
		reduced_effects = values.reduced_effects
		if is_instance_valid(discovery_notifier): discovery_notifier.reduced_effects = reduced_effects
		_refresh_ui_text()
		overlay_title.text = tr("PAUSE")
		_update_hud()
		if tutorial_stage >= 0: _tutorial_set_stage(tutorial_stage)
		queue_redraw()
	)
	settings_panel.closed.connect(func(): settings_panel = null; $HUD/Overlay/SettingsButton.grab_focus())

func _begin_tutorial() -> void:
	var hint := Control.new(); hint.name = "Tutorial"; hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(hint)
	# The banner starts below the power-up buttons; wrap longer translations
	# rather than drawing through Skip or over the HUD controls.
	var panel := ColorRect.new(); panel.name = "Panel"; panel.color = Color(0.12, 0.2, 0.15, 0.88); panel.position = Vector2(92, 280); panel.size = Vector2(536, 82); panel.mouse_filter = Control.MOUSE_FILTER_IGNORE; hint.add_child(panel)
	tutorial_label = Label.new(); tutorial_label.position = Vector2(105, 285); tutorial_label.size = Vector2(400, 72); tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; tutorial_label.add_theme_font_size_override("font_size", 19); tutorial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE; hint.add_child(tutorial_label)
	tutorial_skip = Button.new(); tutorial_skip.name = "Skip"; tutorial_skip.position = Vector2(512, 297); tutorial_skip.size = Vector2(108, 48); tutorial_skip.add_theme_font_size_override("font_size", 14); hint.add_child(tutorial_skip); tutorial_skip.pressed.connect(_finish_tutorial)
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
	if achievement_blocked: return
	if game_state == GameState.GAME_OVER:
		if rescue_processing or _finalize_game() != OK:
			rescue_message.text = tr("SAVE_WAIT")
			return
	if game_state == GameState.PAUSED and persist_best:
		if save_session() != OK:
			overlay_title.text = tr("SAVE_WAIT")
			return
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _restart() -> void:
	if achievement_blocked: return
	if game_state == GameState.GAME_OVER:
		if rescue_processing or _finalize_game() != OK:
			rescue_message.text = tr("SAVE_WAIT")
			return
	elif persist_best and SessionSave.clear_session(progression) != OK:
		overlay_title.text = tr("SAVE_WAIT")
		return
	get_tree().paused = false
	get_tree().reload_current_scene()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not achievement_blocked: get_tree().quit()
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and is_playing():
		_toggle_pause()

# A held input belongs to the old screen-to-world transform. Never commit it
# after resize/orientation changes; the player can begin a fresh gesture.
func _on_window_size_changed() -> void:
	remove_touch = -1
	active_touch = -1
	mouse_down = false
	if spawn_state == SpawnState.AIMING:
		spawn_state = SpawnState.READY

func _exit_tree() -> void:
	if get_tree().root.size_changed.is_connected(_on_window_size_changed):
		get_tree().root.size_changed.disconnect(_on_window_size_changed)
	get_tree().auto_accept_quit = true

func _update_preview() -> void:
	current_preview.data = current_data
	current_preview.visible = is_playing() and _can_aim()
	current_preview.position = Vector2(aim_x, spawn_height)
	queue_redraw()

func _update_hud() -> void:
	current_preview.data = current_data
	next_preview.data = next_data
	next_label.text = tr("NEXT") + "  ·  " + tr(next_data.translation_key).to_upper()
	score_label.text = tr("SCORE") + "  %d" % score
	if combo_count > 1:
		score_label.text += "  " + tr("COMBO") + " %d" % combo_count
	best_label.text = tr("BEST").to_upper() + "  %d" % best_score
	_update_preview()
	_update_remove_ui()
	_update_undo_ui()

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
	var font := preload("res://assets/fonts/DejaVuSans.ttf")
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
		draw_string(font, Vector2(x - 25, y + 56), "%d %s" % [item.level, tr(item.translation_key).substr(0, 3).to_upper()], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("394f39"))
		if i % 6 < 5:
			draw_line(Vector2(x + 31, y + 23), Vector2(x + 78, y + 23), Color(0.35, 0.45, 0.33, 0.5), 1.5)

	if rescue_processing:
		for body in rescue_selected:
			if is_instance_valid(body): draw_arc(body.position, body.data.radius + 10.0, 0, TAU, 48, Color("ffd96c"), 6.0)

	if remove_selecting and is_instance_valid(pieces):
		for body in pieces.get_children():
			if _remove_eligible(body):
				draw_arc(body.position, body.data.radius + 8.0, 0, TAU, 48, Color("f4bb38"), 4.0)

	if debug_outlines and is_instance_valid(pieces):
		for body in pieces.get_children():
			if body is Animal:
				draw_arc(body.position, body.data.radius, 0, TAU, 40, Color.RED, 1.5)

func _update_debug() -> void:
	debug_label.text = "FPS %d   Bodies %d\nCurrent %s  Next %s\nSpawn %d  Merge %d  Pending %d\nScore %d  SpawnState %s\nGameState %s  Danger %.2f" % [Engine.get_frames_per_second(), pieces.get_child_count(), current_data.id, next_data.id, spawn_count, merge_manager.merge_count, merge_manager.pending.size(), score, SpawnState.keys()[spawn_state], GameState.keys()[game_state], danger_monitor.peak_time]

func _debug_spawn_selected() -> void:
	if is_playing() and debug_panel.visible:
		session_tainted = true
		var level: int = int($HUD/DebugPanel/Level.value)
		create_animal(animals[clampi(level - 1, 0, animals.size() - 1)], Vector2(360, 600))

func _debug_pair() -> void:
	if is_playing() and debug_panel.visible:
		session_tainted = true
		var data: AnimalData = animals[clampi(int($HUD/DebugPanel/Level.value) - 1, 0, animals.size() - 1)]
		create_animal(data, Vector2(300, 700))
		create_animal(data, Vector2(300 + data.radius * 2.0 + 1.0, 700))

func _debug_chain() -> void:
	if is_playing() and debug_panel.visible:
		session_tainted = true
		create_animal(animals[1], Vector2(360, 1000))
		create_animal(animals[0], Vector2(340, 880))
		create_animal(animals[0], Vector2(380, 880))

func _debug_fill() -> void:
	if is_playing() and debug_panel.visible:
		session_tainted = true
		for y in range(4):
			for x in range(8):
				create_animal(animals[(x + y) % 3], Vector2(120 + x * 65, 660 + y * 75))

func _debug_overflow() -> void:
	if is_playing() and debug_panel.visible:
		session_tainted = true
		# Fill a supported pile using the temporary max level, which cannot merge.
		# The regular danger monitor still decides whether overflow occurs.
		for row in range(8):
			for column in range(6):
				var body := create_animal(animals[4], Vector2(140 + column * 84, 1052 - row * 84))
				body.merge_locked = true # Debug fixture only, to retain a stable overflow pile.

func _toggle_debug_outlines() -> void:
	debug_outlines = not debug_outlines
	queue_redraw()
