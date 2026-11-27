extends Node
# Temporary QA export only. Production scripts are not changed. Frozen synthetic
# cases and explicit requests are reported separately from physical contacts.
var last_id := 0
var first: Animal
var second: Animal
func _ready() -> void: process_mode = Node.PROCESS_MODE_ALWAYS
func _process(_delta: float) -> void:
	var raw: Variant = JavaScriptBridge.eval("JSON.stringify(window.__verifyCommand || null)")
	if typeof(raw) != TYPE_STRING: return
	var cmd: Variant = JSON.parse_string(raw)
	if not cmd is Dictionary or int(cmd.get("id",0)) == last_id: return
	last_id = int(cmd.id)
	call_deferred("dispatch", cmd)
func finish(id: int, value: Dictionary) -> void:
	value.id = id
	JavaScriptBridge.eval("window.__verifyReply=" + JSON.stringify(value))
func fresh(persist: bool = true):
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")
	for i in range(6): await get_tree().process_frame
	var game = get_tree().current_scene
	game.persist_best = persist
	game.combo_enabled = false
	game.danger_monitor.set_physics_process(false)
	return game
func pair(game, y: float = 800.0) -> void:
	first = game.create_animal(game.animals[0], Vector2(342,y)); first.freeze = true
	second = game.create_animal(game.animals[0], Vector2(378,y)); second.freeze = true
func metrics(game) -> Dictionary:
	var locks := 0
	for b in game.pieces.get_children():
		if b is Animal and b.merge_locked: locks += 1
	return {"state":game.game_state, "paused":get_tree().paused, "pending":game.merge_manager.pending.size(), "locks":locks, "count":game.pieces.get_child_count(), "score":game.score, "merges":game.merge_manager.merge_count, "spawns":game.spawn_count, "undo":game.undo_remaining, "remove":game.remove_remaining, "snapshot_empty":game._session_snapshot().is_empty(), "details":game._checkpoint_details()}
func dispatch(cmd: Dictionary) -> void:
	var op := str(cmd.op)
	if op == "setup":
		var game = await fresh(true)
		game.merge_manager.set_physics_process(false)
		pair(game)
		var result: Error = game.save_session()
		var out := metrics(game); out.result = result; finish(int(cmd.id), out); return
	if op == "matrix":
		var game = await fresh(false)
		game.merge_manager.set_physics_process(false)
		get_tree().paused = true
		var rows := []
		for count in [10,20,40]:
			for seed_value in range(10):
				for child in game.pieces.get_children(): game.pieces.remove_child(child); child.queue_free()
				game.score = 0; game.merge_manager.merge_count = 0
				var rng := RandomNumberGenerator.new(); rng.seed = 51000 + seed_value
				var bodies: Array[Animal] = []
				for i in range(count):
					var body: Animal = game.create_animal(game.animals[0], Vector2(216 + (i % 8) * 36, 820 + (i / 8) * 36))
					body.freeze = true; bodies.append(body)
				var index: int = rng.randi_range(0, count / 2 - 2) * 2
				var center: Vector2 = (bodies[index].position + bodies[index+1].position) / 2.0
				var found: Variant = game.find_merge_position(center, game.animals[1].radius, bodies[index], bodies[index+1])
				var start := Time.get_ticks_usec()
				var r1: bool = game.merge_manager.request_merge(bodies[index], bodies[index+1])
				var duplicate: bool = game.merge_manager.request_merge(bodies[index], bodies[index+2])
				var r2: bool = game.merge_manager.request_merge(bodies[index+2], bodies[index+3])
				var queue: int = game.merge_manager.pending.size(); var locks := 0
				for b in bodies:
					if b.merge_locked: locks += 1
				var blocked: bool = game.save_session() == ERR_BUSY and game._session_snapshot().is_empty()
				game._attempt_drop(); blocked = blocked and game.spawn_count == 0
				game.merge_manager._commit_pending()
				var elapsed := (Time.get_ticks_usec() - start) / 1000.0
				var valid: bool = r1 and r2 and not duplicate and blocked and game.merge_manager.pending.is_empty() and game.merge_manager.merge_count == 2 and game.score == 8 and game.pieces.get_child_count() == count - 2
				var clear := true; var bounds := true
				for b in game.pieces.get_children():
					if b.merge_locked: valid = false
					if b.data.id == &"hamster":
						bounds = bounds and b.position.x-b.data.radius >= game.left_bound-0.01 and b.position.x+b.data.radius <= game.right_bound+0.01 and b.position.y+b.data.radius <= game.floor_height+0.01
						for other in game.pieces.get_children():
							if other != b and b.position.distance_to(other.position) < b.data.radius+other.data.radius+0.99: clear = false
				valid = valid and clear and bounds
				rows.append({"seed":51000+seed_value,"bodies":count,"queue_max":queue,"locks_max":locks,"pending_ms":elapsed,"distance":found.distance_to(center) if found is Vector2 else -1.0,"merges":game.merge_manager.merge_count,"score":game.score,"lost":count-game.merge_manager.merge_count-game.pieces.get_child_count(),"duplicate":int(duplicate),"clear":clear,"bounds":bounds,"ok":valid})
		finish(int(cmd.id), {"rows":rows}); return
	if op == "document":
		finish(int(cmd.id), {"document":SessionSave.load_document()}); return
	if op == "placement":
		var game = await fresh(false)
		game.merge_manager.set_physics_process(false); get_tree().paused = true
		var rows := []
		for base_y in [344.0, 800.0]:
			for child in game.pieces.get_children(): game.pieces.remove_child(child); child.queue_free()
			var a: Animal; var b: Animal
			for row in range(7):
				for col in range(7):
					var body: Animal = game.create_animal(game.animals[0], Vector2(252+col*36,base_y+row*36)); body.freeze = true
					if row == 3 and col == 3: a = body
					if row == 3 and col == 4: b = body
			var middle: Vector2 = (a.position+b.position)*0.5
			var point: Variant = game.find_merge_position(middle, game.animals[1].radius, a, b)
			rows.append({"scenario":"dense_danger" if base_y < 500.0 else "dense_bottom", "x":middle.x,"y":middle.y,"result_x":point.x if point is Vector2 else -1.0,"result_y":point.y if point is Vector2 else -1.0,"distance":point.distance_to(middle) if point is Vector2 else -1.0,"before_danger":middle.y-game.animals[0].radius < game.danger_height,"after_danger":point.y-game.animals[1].radius < game.danger_height if point is Vector2 else false})
		for child in game.pieces.get_children(): game.pieces.remove_child(child); child.queue_free()
		var a: Animal = game.create_animal(game.animals[0], Vector2(109,1076)); a.freeze = true
		var b: Animal = game.create_animal(game.animals[0], Vector2(145,1076)); b.freeze = true
		var center: Vector2 = (a.position+b.position)*0.5
		var point: Variant = game.find_merge_position(center,game.animals[1].radius,a,b)
		rows.append({"scenario":"wall_floor","x":center.x,"y":center.y,"result_x":point.x if point is Vector2 else -1.0,"result_y":point.y if point is Vector2 else -1.0,"distance":point.distance_to(center) if point is Vector2 else -1.0,"radius":game.animals[1].radius,"left":game.left_bound,"right":game.right_bound,"floor":game.floor_height})
		finish(int(cmd.id), {"rows":rows}); return
	if op == "cancel":
		var game = await fresh(true)
		game.merge_manager.set_physics_process(false); pair(game)
		var blockers := []
		for y in [680,820,960]:
			for x in [220,360,500]:
				var body: Animal = game.create_animal(game.animals[11],Vector2(x,y)); body.freeze = true; blockers.append(body)
		get_tree().paused = true
		var no_point: bool = game.find_merge_position(Vector2(360,800),game.animals[1].radius,first,second) == null
		var reserved: bool = game.merge_manager.request_merge(first,second)
		game.merge_manager._commit_pending()
		var after := metrics(game)
		var saved: Error = game.save_session()
		game._set_aim(360); game._attempt_drop()
		var dropped: int = game.spawn_count
		# No external callback is generated while paused; process the empty queue repeatedly.
		for i in range(120): game.merge_manager._physics_process(1.0/120.0)
		var loop_pending: int = game.merge_manager.pending.size()
		for body in blockers: game.pieces.remove_child(body); body.queue_free()
		var retry: bool = game.merge_manager.request_merge(first,second)
		game.merge_manager._commit_pending()
		finish(int(cmd.id), {"no_point":no_point,"reserved":reserved,"after":after,"saved":saved,"dropped":dropped,"loop_pending":loop_pending,"retry":retry,"final":metrics(game)}); return
	if op == "physical":
		var game = await fresh(false)
		game.create_animal(game.animals[1], Vector2(360,1071))
		game.create_animal(game.animals[0], Vector2(360,980))
		game.create_animal(game.animals[0], Vector2(360,880))
		for i in range(600):
			await get_tree().physics_frame
			if game.merge_manager.merge_count >= 2: break
		var chain := {"merges":game.merge_manager.merge_count,"score":game.score,"count":game.pieces.get_child_count(),"pending":game.merge_manager.pending.size()}
		game = await fresh(false)
		game.create_animal(game.animals[11], Vector2(360,969))
		game.create_animal(game.animals[11], Vector2(360,650))
		for i in range(600):
			await get_tree().physics_frame
			if game.merge_manager.merge_count >= 1: break
		finish(int(cmd.id), {"chain":chain,"golden":{"merges":game.merge_manager.merge_count,"score":game.score,"count":game.pieces.get_child_count(),"pending":game.merge_manager.pending.size()}}); return
	var game = get_tree().current_scene
	if not game or not game.has_method("save_session"):
		finish(int(cmd.id), {"error":"game unavailable"}); return
	var result: Variant = null
	if op == "reserve": result = game.merge_manager.request_merge(first,second)
	elif op == "save": result = game.save_session()
	elif op == "commit": game.merge_manager._commit_pending()
	elif op == "pause" or op == "resume": game._toggle_pause()
	elif op == "undo":
		game.undo_snapshot = game._session_snapshot(true,true)
		game._request_undo()
	elif op == "remove":
		game._toggle_remove(); game._commit_remove(first)
	elif op == "menu": game._main_menu()
	elif op == "restart":
		game.merge_manager.commit_scheduled = true
		game.merge_manager.call_deferred("_commit_pending")
		game._restart()
		for i in range(8): await get_tree().process_frame
		var current = get_tree().current_scene
		finish(int(cmd.id), {"scene":current.scene_file_path,"count":current.pieces.get_child_count(),"score":current.score,"pending":current.merge_manager.pending.size(),"merges":current.merge_manager.merge_count}); return
	elif op == "gameover":
		first.position = Vector2(342,450); first.supported = true
		game.danger_monitor._physics_process(game.danger_monitor.grace_period + 0.1)
		for i in range(5): await get_tree().process_frame
	elif op != "details":
		finish(int(cmd.id), {"error":"unknown operation"}); return
	var out := metrics(game); out.result = result; finish(int(cmd.id), out)
