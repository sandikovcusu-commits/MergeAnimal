extends SceneTree
# A.3 fixture: manual reservations/frozen bodies except explicit danger scan.
# 53f7407 pre-fix evidence exists in docs/qa/v091-a2; this checks new rules.
var scene := preload("res://scenes/game/Game.tscn")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1; print("%s %s" % ["PASS" if ok else "FAIL", text])
	if not ok: failures += 1
func fresh():
	var game = scene.instantiate(); game.test_seed = 314; game.combo_enabled = false
	root.add_child(game); await process_frame
	game.danger_monitor.set_physics_process(false); game.merge_manager.set_physics_process(false)
	return game
func dispose(game) -> void:
	paused = false; game.queue_free(); await process_frame
func run() -> void:
	var game = await fresh()
	var a: Animal; var b: Animal
	for row in range(7):
		for col in range(7):
			var body: Animal = game.create_animal(game.animals[0], Vector2(252+col*36,800+row*36)); body.freeze = true
			if row == 3 and col == 3: a = body
			if row == 3 and col == 4: b = body
	var middle: Vector2 = (a.position+b.position)*0.5
	var limit: float = game.merge_placement_limit(game.animals[1].radius,a,b)
	check(is_equal_approx(limit,42.0), "mouse cap derived from result plus source radii and clearance")
	check(game.find_merge_position(middle,game.animals[1].radius,a,b) == null, "old 132px distant fixture rejects out-of-cap placement")
	check(game.merge_manager.request_merge(a,b), "dense pair reserves")
	game.merge_manager._commit_pending()
	check(game.merge_manager.pending.is_empty() and not a.merge_locked and not b.merge_locked and game.pieces.get_child_count()==49 and game.score==0, "dense cancellation preserves bodies and score")
	var denied := true
	for i in range(120): denied = denied and not game.merge_manager.request_merge(a,b)
	check(denied and game.merge_manager.pending.is_empty(), "unchanged failed pair cannot continuously requeue")
	check(game.save_session()==OK and not game._session_snapshot().is_empty(), "safe save after cancellation")
	game._set_aim(360); game._attempt_drop()
	check(game.spawn_count==1, "drop after cancellation")
	# Remove fixture blockers; physical board geometry now differs.
	for body in game.pieces.get_children():
		if body != a and body != b and body.position.y >= 700:
			game.pieces.remove_child(body); body.queue_free()
	check(game.merge_manager.request_merge(a,b), "changed relevant board permits retry")
	game.merge_manager._commit_pending()
	check(game.merge_manager.merge_count==1 and game.score==4 and game.merge_manager.pending.is_empty(), "retry commits exactly once")
	await dispose(game)
	# Old dangerous 120px downward fixture: no candidate or no escape.
	game = await fresh(); a = null; b = null
	for row in range(4):
		for col in range(7):
			var body: Animal = game.create_animal(game.animals[0],Vector2(252+col*36,344+row*36)); body.freeze = true
			if row==1 and col==2: a=body
			if row==1 and col==3: b=body
	middle=(a.position+b.position)*0.5
	var candidate: Variant = game.find_merge_position(middle,game.animals[1].radius,a,b)
	check(candidate == null or (candidate.distance_to(middle)<=42.01 and candidate.y-game.animals[1].radius < game.danger_height), "old 120px danger crossing cannot occur")
	check(game.merge_manager.request_merge(a,b), "danger pair reserves")
	game.danger_monitor.timers[a.instance_uid] = 1.95
	game.danger_monitor.timers[b.instance_uid] = 1.6
	game.merge_manager._commit_pending()
	check(game.merge_manager.pending.is_empty() and game.score==0 and game.pieces.get_child_count()==28 and float(game.danger_monitor.timers.get(a.instance_uid,0))==1.95, "no-safe danger cancellation preserves bodies score and timer")
	await dispose(game)
	# A local offset under the line keeps a running timer and can overflow.
	game = await fresh(); a=game.create_animal(game.animals[0],Vector2(342,420)); a.freeze=true
	b=game.create_animal(game.animals[0],Vector2(378,420)); b.freeze=true
	var obstacle: Animal=game.create_animal(game.animals[0],Vector2(370,420)); obstacle.freeze=true
	middle=(a.position+b.position)*0.5
	candidate=game.find_merge_position(middle,game.animals[1].radius,a,b)
	check(candidate is Vector2 and candidate.distance_to(middle)>0.01 and candidate.distance_to(middle)<=42.01 and candidate.y-game.animals[1].radius<game.danger_height, "local offset found within geometric bound and danger region")
	game.danger_monitor.timers[a.instance_uid]=1.95
	game.danger_monitor.timers[b.instance_uid]=1.4
	check(game.merge_manager.request_merge(a,b), "timed offset pair reserved")
	game.merge_manager._commit_pending()
	var result: Animal
	for body in game.pieces.get_children():
		if body.data.id==&"hamster": result=body
	check(result != null and is_equal_approx(float(game.danger_monitor.timers.get(result.instance_uid,0)),1.95), "local offset inherits active danger timer")
	if result:
		result.supported=false; game.danger_monitor._physics_process(1.0/120.0)
		check(is_equal_approx(float(game.danger_monitor.timers.get(result.instance_uid,0)),1.95), "one integration grace retains inherited timer")
		result.supported=true; game.danger_monitor._physics_process(0.06)
		check(game.game_state==game.GameState.GAME_OVER, "supported near-expiry timer triggers game over")
	await dispose(game)
	# Clear midpoint normal case retains original natural merge rule.
	game=await fresh(); a=game.create_animal(game.animals[0],Vector2(342,420)); a.freeze=true
	b=game.create_animal(game.animals[0],Vector2(378,420)); b.freeze=true
	game.danger_monitor.timers[a.instance_uid]=1.5
	check(game.merge_manager.request_merge(a,b), "normal midpoint pair reserves")
	game.merge_manager._commit_pending(); result=null
	for body in game.pieces.get_children():
		if body.data.id==&"hamster": result=body
	check(result!=null and is_equal_approx(result.position.x,360.0) and not game.danger_monitor.timers.has(result.instance_uid), "normal midpoint merge retains prior timer behavior")
	print("PLACEMENT_A3 checks=%d failures=%d" % [checks,failures])
	await dispose(game); quit(1 if failures else 0)
