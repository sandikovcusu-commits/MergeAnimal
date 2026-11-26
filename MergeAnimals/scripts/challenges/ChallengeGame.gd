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
var spawn_sequence_index := 0
var drop_settled_for := 0.0
var confirm_exit: ConfirmationDialog
var achievement_finish_waiting := false
var achievement_finish_success := false

func _ready() -> void:
	persist_best = false
	debug_enabled = false
	challenge_id = int(get_tree().get_meta("challenge_id", 0))
	var loaded := ChallengeStore.load_results()
	if loaded.status not in ["ok", "recovered", "missing"] or not ChallengeStore.is_unlocked(loaded.data, challenge_id):
		call_deferred("_selection")
		return
	AchievementManager.migrate()
	challenge = ChallengeManager.new(ChallengeManager.DEFINITIONS[challenge_id - 1])
	challenge.objective_reached.connect(_goal_reached)
	super._ready()
	get_tree().auto_accept_quit = false
	for i in range(challenge.definition.starting_animals.size()):
		var data := find_animal(StringName(challenge.definition.starting_animals[i]))
		if data == null: continue
		var body := create_animal(data, Vector2(360, floor_height - data.radius - 1.0))
		body.progression_eligible = true
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
		if challenge.definition.time_limit > 0.0 and challenge.elapsed >= challenge.definition.time_limit and not challenge.reached:
			call_deferred("_finish", false)
		_update_challenge_hud()
	super._physics_process(delta)
	if is_playing() and not get_tree().paused and challenge.definition.drop_limit > 0 and spawn_count >= challenge.definition.drop_limit and not challenge.reached:
		# A last drop (and every resulting chain) must have settled before failure.
		var stable: bool = merge_manager.pending.is_empty() and not merge_manager.commit_scheduled and not drop_requested
		for body in pieces.get_children():
			if not body is Animal or body.is_queued_for_deletion() or body.merge_locked: stable = false; break
			if not body.sleeping and (not body.supported or body.linear_velocity.length() > 20.0 or absf(body.angular_velocity) > 0.25): stable = false; break
		drop_settled_for = drop_settled_for + delta if stable else 0.0
		if drop_settled_for >= 0.75: call_deferred("_finish", false)

func _can_aim() -> bool:
	return (challenge == null or challenge.definition.drop_limit == 0 or spawn_count < challenge.definition.drop_limit) and super._can_aim()
func _can_begin_input() -> bool:
	return (challenge == null or challenge.definition.drop_limit == 0 or spawn_count < challenge.definition.drop_limit) and super._can_begin_input()

func _pick_animal() -> AnimalData:
	if challenge != null and not challenge.definition.spawn_sequence.is_empty():
		var sequence := challenge.definition.spawn_sequence
		var data := find_animal(StringName(sequence[spawn_sequence_index % sequence.size()]))
		spawn_sequence_index += 1
		if data != null: return data
	return super._pick_animal()

func _attempt_drop() -> void:
	# Classic snapshots forbid high-tier queued animals. Challenge has no Undo or
	# Classic session save, so it uses the same physical spawn without snapshotting.
	if not merge_manager.pending.is_empty() or merge_manager.commit_scheduled or not _spawn_clear(current_data, aim_x):
		spawn_state = SpawnState.COOLDOWN
		cooldown_left = 0.0
		_update_preview()
		return
	var data := current_data
	var body := create_animal(data, Vector2(aim_x, spawn_height))
	body.progression_eligible = true
	body.visual.animate_action("drop")
	FeelAudio.play_event("animal_drop")
	spawn_count += 1
	current_data = next_data
	next_data = _pick_animal()
	_set_aim(aim_x)
	cooldown_left = drop_cooldown
	spawn_state = SpawnState.COOLDOWN
	challenge.record_creation(data, true, score)
	_challenge_achievement_event({"animal": str(data.id)})
	_update_challenge_hud()
	_update_hud()

func _on_merged(data: AnimalData, point: Vector2) -> void:
	super._on_merged(data, point)
	challenge.record_creation(data, merge_manager.last_merge_eligible, score)
	challenge.record_score(score, merge_manager.last_merge_eligible)
	challenge.record_merge(merge_manager.merge_count, combo_count, merge_manager.last_merge_eligible)
	if merge_manager.last_merge_eligible: _challenge_achievement_event({"animal": str(data.id), "merge": true, "combo": combo_count})
	_update_challenge_hud()

func _on_golden_merged(point: Vector2) -> void:
	super._on_golden_merged(point)
	challenge.record_score(score, merge_manager.last_merge_eligible)
	challenge.record_merge(merge_manager.merge_count, combo_count, merge_manager.last_merge_eligible, true)
	if merge_manager.last_merge_eligible: _challenge_achievement_event({"merge": true, "golden": true})
	_update_challenge_hud()

func _challenge_achievement_event(event: Dictionary) -> void:
	var inputs := AchievementManager.saved_inputs()
	_queue_achievement(inputs.progress, {}, true, event)

func _achievement_recovered() -> void:
	if achievement_finish_waiting:
		achievement_finish_waiting = false
		call_deferred("_finish", achievement_finish_success)
	elif result_finished:
		next_button.visible = result_saved and result_success and challenge_id < ChallengeManager.DEFINITIONS.size()
		$HUD/Overlay/RestartButton.disabled = not result_saved
		$HUD/Overlay/MainMenuButton.disabled = not result_saved
		rescue_message.text = tr("CH_RESULT_SAVED") if result_saved else tr("CH_SAVE_FAILED")

func _update_hud() -> void:
	super._update_hud()
	# High-tier challenge spawns need a compact HUD preview; physics radius is unchanged.
	if is_instance_valid(next_preview) and next_data != null:
		next_preview.scale = Vector2.ONE * minf(1.0, 34.0 / next_data.radius)

func _update_challenge_hud() -> void:
	if not is_instance_valid(goal_label) or challenge == null: return
	var shown_time: float = maxf(0.0, challenge.definition.time_limit - challenge.elapsed) if challenge.definition.time_limit > 0 else challenge.elapsed
	goal_label.text = "%s  %d/%d\n%s  %d:%02d" % [tr(challenge.definition.objective_key), mini(challenge.count, challenge.definition.target), challenge.definition.target, tr("CH_TIME"), int(shown_time) / 60, int(shown_time) % 60]
	if challenge.definition.drop_limit > 0: goal_label.text += "    %s %d/%d" % [tr("CH_DROPS"), spawn_count, challenge.definition.drop_limit]

func _goal_reached() -> void:
	call_deferred("_finish", true)

func _on_game_over() -> void:
	if not is_playing() or challenge == null or challenge.reached: return
	call_deferred("_finish", false)

func _finish(success: bool) -> void:
	if result_finished: return
	if achievement_blocked:
		achievement_finish_waiting = true
		achievement_finish_success = achievement_finish_success or success
		return
	# A goal reached before the deferred failure resolves always wins.
	success = success or challenge.reached
	result_finished = true; result_success = success
	AdManager.set_gameplay_active(false)
	FeelAudio.play_event("challenge_success" if success else "challenge_failed")
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
	_animate_overlay()
	_persist_result()
	queue_redraw()

func _persist_result() -> void:
	if not result_finished or result_saved: return
	var result := ChallengeStore.record_result(challenge_id, result_success, score, challenge.elapsed)
	result_saved = result == OK
	if result_saved and result_success:
		var inputs := AchievementManager.saved_inputs()
		_queue_achievement(inputs.progress, inputs.challenges, true)
	save_retry_button.visible = not result_saved
	next_button.visible = result_saved and result_success and not achievement_blocked and challenge_id < ChallengeManager.DEFINITIONS.size()
	$HUD/Overlay/RestartButton.disabled = not result_saved or achievement_blocked
	$HUD/Overlay/MainMenuButton.disabled = not result_saved or achievement_blocked
	rescue_message.text = tr("ACH_SAVE_WAIT") if achievement_blocked else (tr("CH_RESULT_SAVED") if result_saved else tr("CH_SAVE_FAILED"))

func _next_challenge() -> void:
	if achievement_blocked: return
	if not result_saved or not result_success or challenge_id >= ChallengeManager.DEFINITIONS.size(): return
	get_tree().set_meta("challenge_id", challenge_id + 1)
	get_tree().paused = false
	get_tree().reload_current_scene()
func _selection() -> void:
	get_tree().paused = false
	if get_tree().has_meta("challenge_id"): get_tree().remove_meta("challenge_id")
	get_tree().change_scene_to_file(SELECTION)
func _main_menu() -> void:
	if achievement_blocked: return
	if result_finished and not result_saved: return
	if not result_finished: _confirm_abandon("selection"); return
	_selection()
func _restart() -> void:
	if achievement_blocked: return
	if result_finished and not result_saved: return
	if not result_finished: _confirm_abandon("restart"); return
	get_tree().paused = false
	get_tree().reload_current_scene()
func _confirm_abandon(action: String) -> void:
	if is_instance_valid(confirm_exit): return
	var resume_on_cancel := is_playing() and not get_tree().paused
	if resume_on_cancel: _toggle_pause()
	confirm_exit = ConfirmationDialog.new()
	confirm_exit.title = tr("CH_LEAVE_TITLE")
	confirm_exit.dialog_text = tr("CH_LEAVE_WARNING")
	confirm_exit.ok_button_text = tr("CH_LEAVE")
	confirm_exit.cancel_button_text = tr("BACK")
	$HUD.add_child(confirm_exit)
	confirm_exit.confirmed.connect(func():
		confirm_exit.queue_free(); confirm_exit = null
		if action == "selection": _selection()
		elif action == "restart": get_tree().paused = false; get_tree().reload_current_scene()
		else: get_tree().quit()
	)
	confirm_exit.canceled.connect(func():
		confirm_exit.queue_free(); confirm_exit = null
		if resume_on_cancel and game_state == GameState.PAUSED: _toggle_pause()
	)
	confirm_exit.close_requested.connect(func():
		if is_instance_valid(confirm_exit): confirm_exit.queue_free(); confirm_exit = null
		if resume_on_cancel and game_state == GameState.PAUSED: _toggle_pause()
	)
	confirm_exit.popup_centered(Vector2i(510, 240))
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and challenge != null:
		if achievement_blocked: return
		if result_finished and result_saved: get_tree().quit()
		else: _confirm_abandon("quit")
	else: super._notification(what)
func _exit_tree() -> void:
	get_tree().auto_accept_quit = true

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
