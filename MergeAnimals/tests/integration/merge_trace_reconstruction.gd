extends SceneTree
# Approximation only: old IDB checkpoint geometry plus the logged cat pair's
# later coordinates. Non-pair bodies were not captured at contact time.
var scene := preload("res://scenes/game/Game.tscn")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/v091_trace_firefox_approx.json"))
	var game = scene.instantiate(); game.persist_best = false; game.combo_enabled = false; game.test_seed = 202
	root.add_child(game); await process_frame
	game.danger_monitor.set_physics_process(false); game.merge_manager.set_physics_process(false)
	var a: Animal; var b: Animal
	for item in doc.bodies:
		var data: AnimalData = game.find_animal(StringName(item.id))
		var body: Animal = game.create_animal(data, Vector2(item.x,item.y)); body.freeze = true
		if int(item.uid) == int(doc.pair_uids[0]): a = body
		if int(item.uid) == int(doc.pair_uids[1]): b = body
	var pair: Dictionary = doc.pair
	var distance_a := a.position.distance_to(Vector2(pair.a_x,pair.a_y))
	var distance_b := b.position.distance_to(Vector2(pair.b_x,pair.b_y))
	a.position = Vector2(pair.a_x,pair.a_y); b.position = Vector2(pair.b_x,pair.b_y)
	var midpoint := (a.position+b.position)*0.5
	var found: Variant = game.find_merge_position(midpoint,game.animals[4].radius,a,b)
	var reserved: bool = game.merge_manager.request_merge(a,b)
	for i in range(120): game.merge_manager._commit_pending()
	var mode := OS.get_environment("TRACE_EXPECT")
	var old_ok: bool = found == null and game.merge_manager.pending.size() == 1 and a.merge_locked and b.merge_locked and game.score == 0
	var new_ok: bool = found is Vector2 and found.distance_to(midpoint) > 96.0 and game.merge_manager.pending.is_empty() and game.merge_manager.merge_count == 1 and game.score > 0 and game.pieces.get_child_count() == doc.bodies.size()-1
	var ok: bool = reserved and distance_a < 2.0 and distance_b < 2.0 and (old_ok if mode == "baseline" else new_ok)
	print("TRACE_RECONSTRUCTION mode=%s result=%s pair_offsets=%.3f,%.3f point=%s distance=%.3f pending=%d merges=%d score=%d bodies=%d" % [mode,"PASS" if ok else "FAIL",distance_a,distance_b,str(found),found.distance_to(midpoint) if found is Vector2 else -1.0,game.merge_manager.pending.size(),game.merge_manager.merge_count,game.score,game.pieces.get_child_count()])
	game.queue_free(); quit(0 if ok else 1)
