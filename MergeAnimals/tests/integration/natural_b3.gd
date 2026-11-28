extends SceneTree
# B.3 §05/§06/§08/§09/§12/§13/§16/§17 — NATIVE NATURAL GAMEPLAY, DANGER LINE,
# TERMINAL SAVE, CONTINUE, REFRESH-EQUIVALENT RESTORE, RESTART and FREE RESCUE.
#
# Rules enforced by this file:
#  * Every board state is produced by real input events (InputEventMouseButton /
#    InputEventScreenTouch pushed through the viewport) entering the production
#    _input path. No body is created, moved, frozen or freed by the test.
#  * No score is written, no Game Over is triggered, no merge is forced, no
#    rescue is forced: the suite only *observes* and *clicks*.
#  * The only writes are read-only reads of the save document and of the
#    production `_checkpoint_details()` diagnostics.
#
# This is automated gameplay, never presented as human play.
var scene := preload("res://scenes/game/Game.tscn")
var menu_scene := preload("res://scenes/ui/MainMenu.tscn")
var checks := 0
var failures := 0
var seed_base := 93000
var session_index := 0
var sessions_started := 0
var game = null
var hero := ""
var events := 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("seed="): seed_base = int(arg.split("=")[1])
		if arg.begins_with("actor="): hero = arg.split("=")[1]
	call_deferred("run")

func check(ok: bool, text: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", text])
	if not ok: failures += 1

func frames(count: int = 2) -> void:
	for i in range(count): await process_frame

func ticks(count: int = 1) -> void:
	for i in range(count): await physics_frame

# ---------------------------------------------------------------- real input
# A pointer down/up at a screen position, pushed through the root viewport so
# the production Game._input handler receives it exactly like a player click.
func click(point: Vector2, touch: bool = false) -> void:
	events += 1
	if touch:
		for pressed in [true, false]:
			var event := InputEventScreenTouch.new()
			event.index = 0
			event.pressed = pressed
			event.position = point
			root.push_input(event, true)
			await frames(1)
		return
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		event.global_position = point
		root.push_input(event, true)
		await frames(1)

# ---------------------------------------------------------------- window
# The explicit test seed is only used for a fresh session; Continue must
# restore the real stored session, so no seed is injected there.
func start_new_session(seed_value: int) -> void:
	paused = false
	remove_meta("continue_requested")
	# A previous path may have left a live scene (for example after Restart), so
	# the new session starts from an empty tree instead of two live boards.
	game = null
	for node in root.get_children():
		if node.has_method("_attempt_drop"):
			node.queue_free()
		elif is_instance_valid(current_scene) and node == current_scene and not node.has_method("_attempt_drop"):
			node.queue_free()
	current_scene = null
	await frames(4)
	game = scene.instantiate()
	game.test_seed = seed_value
	game.persist_best = true   # real save path: production checkpoints run
	root.add_child(game)
	current_scene = game
	await frames(3)
	await ticks(2)
	sessions_started += 1

# A browser refresh returns to the Main Menu; Continue is then a real button
# press, so the suite drives exactly that path instead of injecting the flag.
func go_to_menu() -> void:
	paused = false
	remove_meta("continue_requested")
	var menu = menu_scene.instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(3)

func press_continue() -> bool:
	var menu = current_scene
	if not is_instance_valid(menu) or not ("continue_button" in menu):
		check(false, "main menu exposes a Continue button")
		return false
	var button: Button = menu.continue_button
	check(not button.disabled, "Continue is enabled for a valid checkpoint")
	await click(button.get_global_transform_with_canvas() * (button.size / 2.0))
	for i in range(30): await frames(1)
	var loaded = current_scene
	if not is_instance_valid(loaded) or not loaded.has_method("_attempt_drop"):
		check(false, "Continue opens the gameplay scene")
		return false
	game = loaded
	# The production scene keeps its own runtime seed; the test seed is not
	# injected here because Continue must restore, not reroll.
	paused = false
	await frames(3)
	await ticks(2)
	return true

func dispose() -> void:
	paused = false
	var old = game
	game = null
	if is_instance_valid(old):
		old.queue_free()
	await frames(4)

# ---------------------------------------------------------------- observation
func ensure_live() -> bool:
	return is_instance_valid(game) and not game.is_queued_for_deletion()

func empty_live() -> Dictionary:
	return {
		"valid": false, "game_state": -1, "spawn_state": -1, "score": 0, "best": 0,
		"spawns": 0, "merges": 0, "bodies": 0, "highest": 0, "combo": 0, "pending": 0,
		"locked": 0, "rescue_remaining": 0, "undo_remaining": 0, "remove_remaining": 0,
		"session_id": "", "paused": false, "rescue_ready": false, "rescue_text": "",
		"overlay_visible": false, "overlay_text": "", "highest_body_y": 0.0,
		"spawn_count_delta_locked": 0, "instance_id": 0,
	}

func live() -> Dictionary:
	if not ensure_live(): return empty_live()
	var pending := 0
	var locked := 0
	for pair in game.merge_manager.pending: pending += 1
	for body in game.pieces.get_children():
		if body is Animal and body.merge_locked: locked += 1
	return {
		"valid": true,
		"game_state": int(game.game_state),
		"spawn_state": int(game.spawn_state),
		"score": int(game.score),
		"best": int(game.best_score),
		"spawns": int(game.spawn_count),
		"merges": int(game.merge_manager.merge_count),
		"bodies": int(game.pieces.get_child_count()),
		"highest": int(game.highest_level),
		"combo": int(game.combo_count),
		"pending": pending,
		"locked": locked,
		"rescue_remaining": int(game.rescue_remaining),
		"undo_remaining": int(game.undo_remaining),
		"remove_remaining": int(game.remove_remaining),
		"session_id": str(game.session_id),
		"paused": paused,
		"rescue_ready": is_instance_valid(game.rescue_button) and game.rescue_button.visible and not game.rescue_button.disabled,
		"rescue_text": str(game.rescue_button.text) if is_instance_valid(game.rescue_button) else "",
		"overlay_visible": game.overlay.visible,
		"overlay_text": str(game.overlay_title.text),
		"highest_body_y": _highest_body_y(),
		"spawn_count_delta_locked": int(game.spawn_count),
		"instance_id": int(game.get_instance_id()),
	}

func _highest_body_y() -> float:
	var top := 100000.0
	for body in game.pieces.get_children():
		if body is Animal:
			top = minf(top, body.position.y - body.data.radius)
	return top

func details() -> Dictionary:
	if not is_instance_valid(game): return {}
	return game._checkpoint_details()

# ---------------------------------------------------------------- policies
# The recorded input policy for every B.3 session: a fixed eight-lane cycle,
# rotated per session, so the sequence is reproducible and never looks at hidden
# state. It is a legal player pattern (the same one a beginner uses: drop in a
# column, come back later), and it is the policy that also reached a natural
# Game Over in the earlier A.3 natural run.
const LANES := [130.0, 245.0, 360.0, 475.0, 590.0, 245.0, 475.0, 360.0]

func aim_x(i: int) -> float:
	var left: float = game.left_bound + game.current_data.radius + game.spawn_margin
	var right: float = game.right_bound - game.current_data.radius - game.spawn_margin
	var lane: float = LANES[(i + session_index * 2) % LANES.size()]
	return clampf(lane, left, right)

# ---------------------------------------------------------------- geometry
# Result-overlay buttons cover part of the board. A click that lands on one of
# them is a legal navigation press, not an illegal board input, so illegal-input
# probes are placed from the live button rectangles instead of guessed pixels.
func visible_button_rects(node: Node) -> Array:
	var out: Array = []
	for child in node.get_children():
		if child is Button and child.is_visible_in_tree():
			var button: Button = child
			var rect: Rect2 = button.get_global_rect()
			if rect.has_area(): out.append(rect)
		out.append_array(visible_button_rects(child))
	return out

func safe_board_points(count: int) -> Array:
	var blocked: Array = visible_button_rects(root)
	var points: Array = []
	var y := 700.0
	var x := float(game.left_bound) + 20.0
	while points.size() < count and y > 300.0:
		var candidate := Vector2(x, y)
		var blocked_here := false
		for rect in blocked:
			if rect.grow(8.0).has_point(candidate):
				blocked_here = true
				break
		if not blocked_here: points.append(candidate)
		x += 60.0
		if x > float(game.right_bound) - 20.0:
			x = float(game.left_bound) + 20.0
			y -= 90.0
	return points

# ---------------------------------------------------------------- 1. session
# A body only counts as "in danger" when the production rules would count it:
# above the Danger Line AND settled AND physically supported. A falling body at
# spawn height is above the line by construction, so counting unfiltered
# positions would report a permanent false approach.
func danger_bodies() -> int:
	var count := 0
	for body in game.pieces.get_children():
		if not body is Animal: continue
		var above: bool = body.position.y - body.data.radius < game.danger_height
		var settled: bool = body.sleeping or body.linear_velocity.length() <= 35.0
		if above and settled and body.supported:
			count += 1
	return count

# Every body above the Danger Line, the same rule RescuePlanner applies when it
# decides which removals are mandatory.
func _bodies_above_line() -> int:
	var count := 0
	if not ensure_live(): return count
	for body in game.pieces.get_children():
		if body is Animal and body.position.y - body.data.radius < game.danger_height:
			count += 1
	return count

# Wait a number of physics ticks, stopping early if the session ends. Returns
# true when the session reached a terminal state while waiting.
func settle_ticks(count: int) -> bool:
	for i in range(count):
		await ticks(1)
		if not is_instance_valid(game): return true
		if int(game.game_state) == 2: return true
	return false

func session(seed_value: int, cap_inputs: int, cadence_ticks: int) -> Dictionary:
	print("NATURAL_SESSION_BEGIN seed=%d cap_inputs=%d cadence_ticks=%d" % [seed_value, cap_inputs, cadence_ticks])
	await start_new_session(seed_value)
	var start := live()
	var accepted := 0
	var rejected := 0
	var cancelled := 0
	var retries := 0
	var max_bodies := 0
	var max_combo := 0
	var max_danger := 0
	var danger_approaches := 0
	var danger_cleared := 0
	var was_in_danger := false
	var inputs := 0
	var over := false
	var terminal_at_input := 0
	var sim_seconds := 0.0
	var started_ms := Time.get_ticks_msec()
	var end_state_before := 0
	while inputs < cap_inputs:
		if not ensure_live(): break
		end_state_before = int(game.game_state)
		if int(game.game_state) == 2:
			over = true
			terminal_at_input = inputs
			break
		var bodies_before: int = game.pieces.get_child_count()
		var spawns_before: int = game.spawn_count
		await click(Vector2(aim_x(inputs), 700.0))
		inputs += 1
		# Let the queued drop be committed by the next physics tick.
		await ticks(2)
		if not ensure_live():
			over = int(end_state_before) == 2
			break
		if game.spawn_count > spawns_before:
			accepted += 1
		elif game.pieces.get_child_count() == bodies_before and game.is_playing():
			rejected += 1
		max_bodies = maxi(max_bodies, game.pieces.get_child_count())
		max_combo = maxi(max_combo, game.combo_count)
		# A player cadence: hold the position long enough for the drop to land
		# and the Danger Line to be evaluated against a settled board.
		if await settle_ticks(cadence_ticks):
			over = true
			terminal_at_input = inputs
			break
		var in_danger := danger_bodies()
		max_danger = maxi(max_danger, in_danger)
		if in_danger > 0:
			danger_approaches += 1
			was_in_danger = true
		elif was_in_danger:
			danger_cleared += 1
			was_in_danger = false
		cancelled = int(game.merge_manager.cancelled_count)
		retries = int(game.merge_manager.auto_retry_attempts)
		sim_seconds = float(inputs) * float(cadence_ticks) / float(Engine.physics_ticks_per_second)
	if not over and ensure_live() and int(game.game_state) == 2:
		over = true
		terminal_at_input = inputs
	if not over:
		print("NATURAL_NOT_REACHED seed=%d reason=%s inputs=%d cap=%d" % [
			seed_value, "input_cap" if inputs >= cap_inputs else "session_guard", inputs, cap_inputs])
	# Let a terminal checkpoint attempt settle before reading it.
	for i in range(40):
		if not ensure_live() or int(game.game_state) != 2: break
		await frames(2)
	var end_live := live()
	var end_details := details()
	var elapsed := (Time.get_ticks_msec() - started_ms) / 1000.0
	if over: sim_seconds = float(inputs) * float(cadence_ticks) / float(Engine.physics_ticks_per_second)
	var doc := SessionSave.load_document()
	print("NATURAL_SESSION seed=%d over=%s inputs=%d accepted=%d rejected=%d merges=%d cancelled=%d retries=%d score=%d best=%d highest=%d max_bodies=%d max_combo=%d max_danger=%d danger_approaches=%d danger_cleared=%d sim_seconds=%.2f wall_seconds=%.2f bodies_end=%d session=%s" % [
		seed_value, str(over), inputs, accepted, rejected, end_live.get("merges", 0), cancelled, retries,
		end_live.get("score", 0), end_live.get("best", 0), end_live.get("highest", 0), max_bodies,
		max_combo, max_danger, danger_approaches, danger_cleared, sim_seconds, elapsed,
		end_live.get("bodies", 0), end_live.get("session_id", "")])
	print("NATURAL_TERMINAL_STATE seed=%d game_state=%d overlay=%s rescue_ready=%s rescue_text=%s pending=%d locked=%d" % [
		seed_value, end_live.get("game_state", -1), str(end_live.get("overlay_visible", false)),
		str(end_live.get("rescue_ready", false)), end_live.get("rescue_text", ""),
		end_live.get("pending", 0), end_live.get("locked", 0)])
	print("NATURAL_SAVE_TRACE seed=%d doc_status=%s doc_score=%s doc_over=%s generation=%s details=%s" % [
		seed_value, str(doc.get("status", "")), str(doc.data.get("score", -1) if doc.has("data") else ""),
		str(doc.data.get("game_over_pending", false) if doc.has("data") else ""),
		str(doc.data.get("generation", -1) if doc.has("data") else ""), JSON.stringify(end_details)])
	return {
		"seed": seed_value, "over": over, "inputs": inputs, "accepted": accepted, "rejected": rejected,
		"merges": int(end_live.get("merges", 0)), "cancelled": cancelled, "retries": retries,
		"score": int(end_live.get("score", 0)), "best": int(end_live.get("best", 0)),
		"highest": int(end_live.get("highest", 0)), "max_bodies": max_bodies, "max_combo": max_combo,
		"max_danger": max_danger, "danger_approaches": danger_approaches, "danger_cleared": danger_cleared,
		"sim_seconds": sim_seconds, "wall_seconds": elapsed, "terminal_input": terminal_at_input,
		"session_id": str(end_live.get("session_id", "")),
		"start_score": int(start.get("score", 0)), "bodies_start": int(start.get("bodies", 0)),
		"details": end_details, "doc_status": str(doc.get("status", "")),
		"doc_game_over": bool(doc.data.get("game_over_pending", false)) if doc.has("data") else false,
		"doc_score": int(doc.data.get("score", -1)) if doc.has("data") else -1,
	}

# ---------------------------------------------------------------- 2. terminal contract
func terminal_contract(result: Dictionary) -> void:
	if not bool(result.get("over", false)):
		print("NATURAL_TERMINAL_CONTRACT seed=%d SKIPPED reason=not_reached" % int(result.get("seed", -1)))
		return
	var before := live()
	check(int(before.game_state) == 2, "terminal state is GAME_OVER (%d)" % int(before.game_state))
	check(bool(before.overlay_visible) and str(before.overlay_text).length() > 0, "terminal overlay is visible with text")
	# Illegal input after Game Over: pointer presses on the board (never on an
	# action button) must not spawn, score or navigate.
	var probes := safe_board_points(6)
	print("NATURAL_PROBE seed=%d points=%s buttons=%s" % [int(result.get("seed", -1)), JSON.stringify(probes), JSON.stringify(visible_button_rects(root).map(func(r): return [r.position.x, r.position.y, r.size.x, r.size.y]))])
	for point in probes:
		await click(point)
		await ticks(2)
	var after := live()
	check(int(after.get("instance_id", 0)) == int(before.get("instance_id", -1)), "terminal board is still the same live scene after illegal input")
	check(int(after.spawns) == int(before.spawns), "GAME_OVER refuses new drops (%d -> %d spawns)" % [int(before.spawns), int(after.spawns)])
	check(int(after.score) == int(before.score), "GAME_OVER refuses new score (%d -> %d)" % [int(before.score), int(after.score)])
	check(int(after.bodies) == int(before.bodies), "GAME_OVER keeps the body count (%d -> %d)" % [int(before.bodies), int(after.bodies)])
	check(int(after.pending) == 0 and int(after.locked) == 0, "no reservation or lock survives Game Over (pending=%d locked=%d)" % [int(after.pending), int(after.locked)])
	# A deferred merge commit must not mutate the terminal board.
	if is_instance_valid(game):
		game.merge_manager._commit_pending()
		for i in range(4): await ticks(1)
	var after_commit := live()
	check(int(after_commit.score) == int(before.score) and int(after_commit.bodies) == int(before.bodies), "terminal board is immune to a deferred merge commit")
	check(int(after_commit.merges) == int(before.merges), "merge counter unchanged by a deferred commit")
	# Exactly one terminal event for this session.
	check(int(after.game_state) == 2, "repeated input never re-enters a second state")
	await frames(2)
	var d := details()
	var doc := SessionSave.load_document()
	print("NATURAL_CONTRACT seed=%d doc_status=%s doc_over=%s score=%d doc_score=%d details=%s" % [
		int(result.get("seed", -1)), str(doc.get("status", "")), str(doc.data.get("game_over_pending", false) if doc.has("data") else ""),
		int(after.score), int(doc.data.get("score", -1) if doc.has("data") else -1), JSON.stringify(d)])
	# Save invariants that must hold for a real terminal session.
	if doc.status in ["ok", "recovered"] and doc.has("data"):
		check(bool(doc.data.get("game_over_pending", false)), "terminal checkpoint marks game_over_pending")
		check(int(doc.data.get("score", -1)) == int(after.score), "checkpoint score equals the live terminal score (%d vs %d)" % [int(doc.data.get("score", -1)), int(after.score)])
		check(int(doc.data.get("best_score", -1)) >= int(after.score), "checkpoint best score is not below the final score")
		check(str(doc.data.get("session_id", "")) == str(after.session_id), "checkpoint belongs to this session")
		var current: String = str(d.get("current_revision", ""))
		var written: String = str(d.get("written_revision", ""))
		var verified: String = str(d.get("verified_revision", ""))
		print("NATURAL_REVISIONS seed=%d current=%s written=%s verified=%s readback=%s scoped=%s aggregate=%s status=%s" % [
			int(result.get("seed", -1)), current, written, verified, str(d.get("readback", "")), str(d.get("scoped", "")), str(d.get("aggregate", "")), str(d.get("status", ""))])
		check(not current.is_empty() and written == current, "written revision matches the terminal snapshot")
		check(str(d.get("status", "")) != "verified" or verified == written, "verified revision can only be the written one")
	else:
		check(false, "terminal checkpoint is readable (status %s)" % str(doc.get("status", "")))

# ---------------------------------------------------------------- 3. refresh-equivalent restore
func refresh_restore(result: Dictionary) -> void:
	if not bool(result.get("over", false)):
		return
	var before := live()
	var doc_before := SessionSave.load_document()
	var revision: String = str(details().get("written_revision", ""))
	await dispose()
	# A browser refresh re-enters the game at the Main Menu with the same
	# user:// storage; Continue is then a real UI press.
	await go_to_menu()
	check(await press_continue(), "refresh-equivalent reaches gameplay through Continue")
	var after := live()
	check(bool(after.valid), "refresh-equivalent: scene reloads from the terminal checkpoint")
	check(int(after.game_state) == 2, "refresh keeps the terminal Game Over state (got %d)" % int(after.game_state))
	check(str(after.session_id) == str(before.session_id), "refresh keeps the same session id")
	check(int(after.score) == int(before.score), "refresh keeps the score (%d vs %d)" % [int(after.score), int(before.score)])
	check(int(after.best) >= int(before.best), "refresh does not lower the best score")
	check(int(after.bodies) == int(before.bodies), "refresh keeps the terminal body set (%d vs %d)" % [int(after.bodies), int(before.bodies)])
	check(int(after.rescue_remaining) == int(before.rescue_remaining), "refresh keeps the rescue budget (%d)" % int(after.rescue_remaining))
	check(bool(after.overlay_visible), "refresh re-shows the Game Over overlay")
	var doc_after := SessionSave.load_document()
	check(str(doc_after.get("status", "")) == str(doc_before.get("status", "")), "refresh does not change the save status")
	check(bool(doc_after.data.get("game_over_pending", false)) if doc_after.has("data") else false, "refresh keeps game_over_pending")
	print("NATURAL_REFRESH seed=%d revision=%s score=%d best=%d bodies=%d rescue=%d session_match=%s" % [
		int(result.get("seed", -1)), revision, int(after.score), int(after.best), int(after.bodies), int(after.rescue_remaining),
		str(str(after.session_id) == str(before.session_id))])
	await dispose()

# ---------------------------------------------------------------- 4. restart isolation
func restart_isolation(result: Dictionary) -> void:
	if not bool(result.get("over", false)):
		return
	var old_session: String = str(result.get("session_id", ""))
	var old_score: int = int(result.get("score", 0))
	var old_best: int = int(result.get("best", 0))
	await go_to_menu()
	check(await press_continue(), "restart fixture restores the terminal session through Continue")
	var terminal := live()
	check(int(terminal.game_state) == 2, "restart fixture starts from the terminal state")
	# Restart is a real UI press on the overlay button.
	var button: Control = game.get_node("HUD/Overlay/RestartButton")
	var old: String = str(game.session_id)
	var previous_scene = current_scene
	await click(button.get_global_transform_with_canvas() * (button.size / 2.0))
	# reload_current_scene() replaces current_scene at the end of the frame; adopt
	# the replacement only once it exists, instead of reading a freed scene.
	var adopted = null
	for i in range(180):
		await frames(1)
		paused = false
		if is_instance_valid(current_scene) and current_scene != previous_scene and current_scene.has_method("_attempt_drop"):
			adopted = current_scene
			break
	if adopted != null:
		game = adopted
	for i in range(10): await frames(1)
	var fresh := live()
	check(bool(fresh.valid), "restart produced a live session")
	check(int(fresh.game_state) == 0, "restart returns to PLAYING (got %d)" % int(fresh.game_state))
	check(str(fresh.session_id) != old_session, "restart creates a new session id")
	check(int(fresh.score) == 0, "restart resets the score (got %d)" % int(fresh.score))
	check(int(fresh.spawns) == 0 and int(fresh.bodies) == 0, "restart clears the board (%d bodies)" % int(fresh.bodies))
	check(int(fresh.merges) == 0 and int(fresh.pending) == 0 and int(fresh.locked) == 0, "restart clears merges, reservations and locks")
	check(int(fresh.combo) == 0, "restart clears the combo counter")
	check(int(fresh.undo_remaining) == 1 and int(fresh.rescue_remaining) == 1, "restart restores the per-session power-up budgets")
	check(int(fresh.best) >= old_best, "restart preserves the legitimate best score (%d >= %d)" % [int(fresh.best), old_best])
	# A drop must be possible immediately in the new session.
	var spawns_before: int = int(fresh.spawns)
	var candidates := safe_board_points(1)
	var point: Vector2 = Vector2(360.0, 700.0) if candidates.is_empty() else candidates[0]
	print("NATURAL_RESTART_TRACE instance=%d state=%d spawn_state=%s paused=%s overlay=%s buttons=%s point=%s" % [
		int(fresh.get("instance_id", 0)), int(fresh.game_state), str(int(fresh.spawn_state)), str(paused),
		str(fresh.overlay_visible), JSON.stringify(visible_button_rects(root).map(func(r): return [r.position.x, r.position.y, r.size.x, r.size.y])), JSON.stringify(point)])
	await click(point)
	await ticks(3)
	var dropped := live()
	print("NATURAL_RESTART_TRACE after_drop instance=%d valid=%s spawns=%s state=%s spawn_state=%s" % [
		int(dropped.get("instance_id", 0)), str(dropped.valid), str(int(dropped.get("spawns", 0))),
		str(int(dropped.get("game_state", -1))), str(int(dropped.get("spawn_state", -1)))])
	check(int(dropped.spawns) == spawns_before + 1, "restart session accepts the first drop")
	check(int(dropped.score) == 0, "the previous session's score does not leak into the new one")
	# Old callbacks: the previous session id must never reappear.
	check(str(dropped.session_id) != old_session and str(dropped.session_id) == str(fresh.session_id), "no stale callback resurrects the old session")
	var doc := SessionSave.load_document()
	check(not (doc.has("data") and str(doc.data.get("session_id", "")) == old_session and int(doc.data.get("score", -1)) == old_score), "the checkpoint no longer describes the abandoned terminal session")
	print("NATURAL_RESTART old_session=%s new_session=%s old_score=%d live_score=%d best=%d overlays_pending=%s" % [
		old_session, str(dropped.session_id), old_score, int(dropped.score), int(dropped.best),
		str(doc.data.get("game_over_pending", false) if doc.has("data") else "")])
	await dispose()

# ---------------------------------------------------------------- 5. natural rescue
func natural_rescue(result: Dictionary) -> bool:
	if not bool(result.get("over", false)):
		return false
	await go_to_menu()
	check(await press_continue(), "rescue fixture restores the terminal session through Continue")
	var terminal := live()
	check(int(terminal.game_state) == 2, "rescue fixture starts from the terminal state")
	check(bool(terminal.rescue_ready), "free rescue button is available on Game Over (%s / %s)" % [str(terminal.rescue_ready), str(terminal.rescue_text)])
	var before := live()
	var bodies_before := _body_signature()
	var doc_before := SessionSave.load_document()
	var revision_before: String = str(details().get("written_revision", ""))
	var button: Control = game.rescue_button
	print("NATURAL_RESCUE_TRACE pre_click instance=%d text=%s disabled=%s pending=%s processing=%s processing_flag=%s checkpoint_pending=%s point=%s" % [
		int(game.get_instance_id()), str(button.text), str(button.disabled), str(int(terminal.pending)),
		str(bool(game.rescue_processing)), str(bool(game.gameover_checkpoint_pending)), str(bool(game.save_status == OK)),
		JSON.stringify(button.get_global_transform_with_canvas() * (button.size / 2.0))])
	await click(button.get_global_transform_with_canvas() * (button.size / 2.0))
	for i in range(6): await frames(2)
	var verdict: int = int(game.game_state)
	var message: String = str(game.rescue_message.text)
	print("NATURAL_RESCUE_TRACE post_click processing=%s message=%s text=%s state=%d above_line=%d bodies=%d" % [
		str(bool(game.rescue_processing)), message, str(game.rescue_button.text), verdict,
		_bodies_above_line(), int(game.pieces.get_child_count())])
	if verdict == 2:
		# The production rescue was offered and then refused. Record the refusal
		# with the state that caused it; nothing is retried inside the same board.
		print("NATURAL_RESCUE_REFUSED seed=%d score=%d bodies=%d above_line=%d supported_above=%d rescue=%d message=%s" % [
			int(result.get("seed", -1)), int(before.score), int(before.bodies), _bodies_above_line(),
			danger_bodies(), int(before.rescue_remaining), message])
		check(false, "natural rescue completes on the first attempt (refused: %s)" % message)
		return false
	# The commit is deferred and includes a 0.4 s highlight, so allow real time.
	for i in range(80):
		await frames(1)
		if is_instance_valid(game) and int(game.game_state) == 0: break
	var after := live()
	var bodies_after := _body_signature()
	check(int(after.game_state) == 0, "natural rescue returns to PLAYING (got %d)" % int(after.game_state))
	check(int(after.rescue_remaining) == int(before.rescue_remaining) - 1, "rescue budget decreases exactly once (%d -> %d)" % [int(before.rescue_remaining), int(after.rescue_remaining)])
	check(int(after.score) == int(before.score), "rescue does not change the score (%d -> %d)" % [int(before.score), int(after.score)])
	check(int(after.best) >= int(before.best), "rescue does not lower the best score")
	var removed: Array = []
	for entry in bodies_before:
		if not bodies_after.has(entry): removed.append(entry)
	check(removed.size() > 0, "rescue removed at least one real body (%d)" % removed.size())
	check(bodies_after.size() == bodies_before.size() - removed.size(), "rescue removed exactly the reported bodies")
	check(int(after.pending) == 0 and int(after.locked) == 0, "rescue leaves no reservation or lock")
	check(int(after.undo_remaining) == 0, "rescue consumes the undo snapshot by rule (%d)" % int(after.undo_remaining))
	# A new drop and, if the board allows it, a new merge must be possible.
	var spawns_before: int = int(after.spawns)
	await click(Vector2(360.0, 700.0))
	await ticks(4)
	var dropped := live()
	check(int(dropped.spawns) == spawns_before + 1, "a real drop works after rescue")
	var merges_before: int = int(dropped.merges)
	for i in range(12):
		await click(Vector2(aim_x(i), 700.0))
		await ticks(30)
	var merged := live()
	check(int(merged.merges) >= merges_before, "merge counter is monotonic after rescue (%d -> %d)" % [merges_before, int(merged.merges)])
	var doc_after := SessionSave.load_document()
	var revision_after: String = str(details().get("written_revision", ""))
	check(doc_after.get("status", "") in ["ok", "recovered"], "a checkpoint is readable after rescue (%s)" % str(doc_after.get("status", "")))
	check(not (doc_after.has("data") and bool(doc_after.data.get("game_over_pending", true))), "rescue clears game_over_pending in the checkpoint")
	check(revision_after != revision_before, "rescue writes a new revision")
	print("NATURAL_RESCUE seed=%d before(score=%d bodies=%d rescue=%d rev=%s) after(score=%d bodies=%d rescue=%d rev=%s removed=%d merges=%d)" % [
		int(result.get("seed", -1)), int(before.score), int(before.bodies), int(before.rescue_remaining), revision_before,
		int(after.score), int(after.bodies), int(after.rescue_remaining), revision_after, removed.size(), int(merged.merges)])
	# Post-rescue persistence: a fresh scene must not restore an active Game Over
	# and must not refund the used rescue.
	var used_rescue: int = int(after.rescue_remaining)
	var score_now: int = int(merged.score)
	await dispose()
	await go_to_menu()
	check(await press_continue(), "post-rescue restore reaches gameplay through Continue")
	var restored := live()
	check(bool(restored.valid), "post-rescue session restores from the checkpoint")
	check(int(restored.game_state) != 2, "post-rescue checkpoint is not a Game Over (got %d)" % int(restored.game_state))
	check(int(restored.rescue_remaining) == used_rescue, "used rescue is not refunded after restore (%d vs %d)" % [int(restored.rescue_remaining), used_rescue])
	check(int(restored.score) == score_now, "restored score equals the last committed score (%d vs %d)" % [int(restored.score), score_now])
	print("NATURAL_RESCUE_RESTORE score=%d rescue=%d state=%d" % [int(restored.score), int(restored.rescue_remaining), int(restored.game_state)])
	await dispose()
	return true

func _body_signature() -> Array:
	var out: Array = []
	if not is_instance_valid(game): return out
	for body in game.pieces.get_children():
		if body is Animal:
			out.append("%d:%s:%d:%d" % [int(body.save_uid), str(body.data.id), int(body.position.x), int(body.position.y)])
	out.sort()
	return out

# ---------------------------------------------------------------- driver
func run() -> void:
	print("NATURAL_CONFIG engine=%s physics=%d actor=%s" % [Engine.get_version_info().string, Engine.physics_ticks_per_second, hero if not hero.is_empty() else "none"])
	# A clean starting state: no Continue flag, no tutorial injection.
	remove_meta("continue_requested")
	# 260 inputs at a 150 tick (1.25 s at 120 Hz) cadence is at most ~325 s of
	# simulated play per session. The cap is a guard, never a target: when it is
	# why a session did not end, that is printed as NOT_REACHED with the reason.
	var sessions := [
		{"seed": seed_base + 1, "cap": 260, "cadence": 150},
		{"seed": seed_base + 2, "cap": 260, "cadence": 150},
		{"seed": seed_base + 3, "cap": 260, "cadence": 150},
	]
	var results: Array = []
	for config in sessions:
		session_index += 1
		var result: Dictionary = await session(int(config.seed), int(config.cap), int(config.cadence))
		results.append(result)
		await terminal_contract(result)
		await dispose()
	var reached := 0
	for result in results:
		if bool(result.get("over", false)): reached += 1
	print("NATURAL_SUMMARY sessions=%d game_over=%d not_reached=%d seeds=%s" % [
		results.size(), reached, results.size() - reached,
		",".join(results.map(func(r): return str(int(r.get("seed", -1)))))])
	# Each deep path legitimately rewrites the checkpoint, so each one is driven
	# by its own freshly played natural session instead of borrowing the state a
	# previous path left behind. Nothing is skipped and nothing is reused.
	var deep_paths := [
		{"name": "refresh", "seed": seed_base + 11, "cap": 260, "cadence": 150},
		{"name": "restart", "seed": seed_base + 12, "cap": 260, "cadence": 150},
	]
	for path in deep_paths:
		print("NATURAL_DEEP_BEGIN path=%s seed=%d" % [str(path.name), int(path.seed)])
		session_index += 1
		var played: Dictionary = await session(int(path.seed), int(path.cap), int(path.cadence))
		if not bool(played.get("over", false)):
			print("NATURAL_DEEP SKIPPED path=%s reason=no_terminal_session" % str(path.name))
			check(false, "deep path %s needs a natural Game Over" % str(path.name))
			await dispose()
			continue
		session_index += 1
		if str(path.name) == "refresh":
			await refresh_restore(played)
		else:
			await restart_isolation(played)
		await dispose()
	# Natural free rescue. The rescue can be refused by the production planner on
	# a real terminal board; each attempt is a separate freshly played session and
	# every refusal is printed, so the measured success rate is visible instead of
	# hidden behind a retry loop.
	var rescue_attempts := 0
	var rescue_refusals := 0
	var rescue_done := false
	for offset in [13, 23, 33]:
		if rescue_done: break
		rescue_attempts += 1
		print("NATURAL_RESCUE_ATTEMPT attempt=%d seed=%d" % [rescue_attempts, seed_base + offset])
		session_index += 1
		var played: Dictionary = await session(seed_base + offset, 260, 150)
		if not bool(played.get("over", false)):
			print("NATURAL_RESCUE_ATTEMPT attempt=%d outcome=no_terminal_session" % rescue_attempts)
			await dispose()
			continue
		session_index += 1
		if await natural_rescue(played):
			rescue_done = true
		else:
			rescue_refusals += 1
		await dispose()
	print("NATURAL_RESCUE_SUMMARY attempts=%d refusals=%d succeeded=%s" % [rescue_attempts, rescue_refusals, str(rescue_done)])
	print("NATURAL_B3 checks=%d failures=%d sessions=%d events=%d" % [checks, failures, sessions_started, events])
	quit(1 if failures else 0)
