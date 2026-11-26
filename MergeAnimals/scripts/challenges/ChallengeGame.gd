## Inherited Classic physics/merge board; separate mode and results, never writes Classic.
extends "res://scripts/gameplay/Game.gd"
const SELECTION := "res://scenes/ui/ChallengeSelection.tscn"
var challenge: ChallengeManager
var challenge_id := 0
var goal_label: Label
var next_button: Button
var save_retry_button: Button
var result_success := false
var result_saved := false
var result_finished := false

func _ready() -> void:
	persist_best = false
	debug_enabled = false
	challenge_id = int(get_tree().get_meta("challenge_id", 0))
	var loaded := ChallengeStore.load_results()
	if loaded.status not in ["ok", "recovered", "missing"] or not ChallengeStore.is_unlocked(loaded.data, challenge_id):
		call_deferred("_selection")
		return
	challenge = ChallengeManager.new(ChallengeManager.DEFINITIONS[challenge_id - 1])
	challenge.objective_reached.connect(_goal_reached)
	super._ready()
	# This mode never exposes or activates the Classic power-ups.
	remove_button.visible = false; remove_button.disabled = true
	undo_button.visible = false; undo_button.disabled = true
	rescue_button.visible = false; rescue_button.disabled = true
	best_score = int(loaded.data.entries[challenge_id - 1].best)
	goal_label = Label.new(); goal_label.name = "ChallengeGoal"
	goal_label.position = Vector2(85, 205); goal_label.size = Vector2(365, 65)
	goal_label.add_theme_font_size_override("font_size", 18); goal_label.add_theme_color_override("font_color", Color("263e2b"))
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; goal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$HUD.add_child(goal_label)
	next_button = Button.new(); next_button.name = "NextChallenge"; next_button.position = Vector2(70, 255); next_button.size = Vector2(340, 55)
	next_button.text = tr("CH_NEXT"); next_button.visible = false; overlay.add_child(next_button); next_button.pressed.connect(_next_challenge)
	save_retry_button = Button.new(); save_retry_button.name = "RetryResultSave"; save_retry_button.position = Vector2(70, 255); save_retry_button.size = Vector2(340, 55)
	save_retry_button.text = tr("CH_RETRY_SAVE"); save_retry_button.visible = false; overlay.add_child(save_retry_button); save_retry_button.pressed.connect(_persist_result)
	_update_challenge_hud()
	_update_hud()

func _physics_process(delta: float) -> void:
	if challenge == null: return
	if is_playing() and not get_tree().paused:
		challenge.tick(delta)
		_update_challenge_hud()
	super._physics_process(delta)

func _attempt_drop() -> void:
	var before_count := spawn_count
	var data := current_data
	super._attempt_drop()
	if spawn_count > before_count:
		challenge.record_creation(data, true, score)
		_update_challenge_hud()

func _on_merged(data: AnimalData, point: Vector2) -> void:
	super._on_merged(data, point)
	challenge.record_creation(data, merge_manager.last_merge_eligible, score)
	challenge.record_score(score, merge_manager.last_merge_eligible)
	_update_challenge_hud()

func _on_golden_merged(point: Vector2) -> void:
	super._on_golden_merged(point)
	challenge.record_score(score, merge_manager.last_merge_eligible)
	_update_challenge_hud()

func _update_challenge_hud() -> void:
	if not is_instance_valid(goal_label) or challenge == null: return
	goal_label.text = "%s  %d/%d\n%s  %d:%02d" % [tr(challenge.definition.objective_key), mini(challenge.count, challenge.definition.target), challenge.definition.target, tr("CH_TIME"), int(challenge.elapsed) / 60, int(challenge.elapsed) % 60]

func _goal_reached() -> void:
	call_deferred("_finish", true)

func _on_game_over() -> void:
	if not is_playing() or challenge == null or challenge.reached: return
	call_deferred("_finish", false)

func _finish(success: bool) -> void:
	if result_finished: return
	result_finished = true; result_success = success
	game_state = GameState.GAME_OVER
	drop_requested = false; active_touch = -1; mouse_down = false
	current_preview.visible = false
	get_tree().paused = true
	resume_button.visible = false; $HUD/Overlay/SettingsButton.visible = false
	rescue_button.visible = false; rescue_message.visible = true
	$HUD/Overlay/RestartButton.position.y = 180
	$HUD/Overlay/RestartButton.text = tr("CH_REPLAY")
	$HUD/Overlay/MainMenuButton.position.y = 330
	$HUD/Overlay/MainMenuButton.text = tr("CH_SELECT_BUTTON")
	overlay_title.text = "%s\n%s\n%s: %d\n%s: %d:%02d" % [tr("CH_SUCCESS") if success else tr("CH_FAILED"), tr(challenge.definition.title_key), tr("FINAL_SCORE"), score, tr("CH_TIME"), int(challenge.elapsed) / 60, int(challenge.elapsed) % 60]
	overlay.visible = true
	_persist_result()
	queue_redraw()

func _persist_result() -> void:
	if not result_finished or result_saved: return
	var result := ChallengeStore.record_result(challenge_id, result_success, score)
	result_saved = result == OK
	save_retry_button.visible = not result_saved
	next_button.visible = result_saved and result_success and challenge_id < 5
	$HUD/Overlay/RestartButton.disabled = not result_saved
	$HUD/Overlay/MainMenuButton.disabled = not result_saved
	rescue_message.text = tr("CH_RESULT_SAVED") if result_saved else tr("CH_SAVE_FAILED")

func _next_challenge() -> void:
	if not result_saved or not result_success or challenge_id >= 5: return
	get_tree().set_meta("challenge_id", challenge_id + 1)
	get_tree().paused = false
	get_tree().reload_current_scene()
func _selection() -> void:
	get_tree().paused = false
	if get_tree().has_meta("challenge_id"): get_tree().remove_meta("challenge_id")
	get_tree().change_scene_to_file(SELECTION)
func _main_menu() -> void:
	if result_finished and not result_saved: return
	_selection()
func _restart() -> void:
	if result_finished and not result_saved: return
	get_tree().paused = false
	get_tree().reload_current_scene()
func _toggle_pause() -> void:
	super._toggle_pause()
	if game_state == GameState.PAUSED:
		$HUD/Overlay/SettingsButton.visible = false
		$HUD/Overlay/MainMenuButton.text = tr("CH_SELECT_BUTTON")
func _update_remove_ui() -> void:
	if is_instance_valid(remove_button): remove_button.visible = false; remove_button.disabled = true
	if is_instance_valid(remove_hint): remove_hint.visible = false
func _update_undo_ui() -> void:
	if is_instance_valid(undo_button): undo_button.visible = false; undo_button.disabled = true
func _toggle_remove() -> void: pass
func _request_undo() -> void: pass
func _request_rescue() -> void: pass
func _open_settings() -> void: pass
