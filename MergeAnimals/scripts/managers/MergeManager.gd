class_name MergeManager
extends Node

signal merged(result: AnimalData, point: Vector2)
signal golden_merged(point: Vector2)

var game
var pending: Array[Dictionary] = []
var merge_count: int = 0
var commit_scheduled: bool = false
var last_merge_eligible: bool = false
# Failed placement is suppressed until relevant collision geometry changes by
# the 1px clearance used by the placement test. Weak refs avoid retaining bodies.
var failed_placements: Dictionary = {}
const PLACEMENT_CHANGE := 1.0

func _pair_key(a: Animal, b: Animal) -> String:
	var x := a.get_instance_id(); var y := b.get_instance_id()
	return "%d:%d" % [mini(x, y), maxi(x, y)]

func _placement_geometry(a: Animal, b: Animal, radius: float) -> Dictionary:
	var middle := (a.global_position + b.global_position) * 0.5
	var limit: float = game.merge_placement_limit(radius, a, b)
	var positions := {}
	for node in game.pieces.get_children():
		if not node is Animal or node.is_queued_for_deletion(): continue
		# A one-pixel margin also detects blockers entering the relevant region.
		if node == a or node == b or node.global_position.distance_to(middle) <= limit + radius + node.data.radius + 2.0:
			positions[node.get_instance_id()] = node.global_position
	return positions

func _same_geometry(previous: Dictionary, current: Dictionary) -> bool:
	if previous.size() != current.size(): return false
	for id in previous:
		if not current.has(id) or previous[id].distance_squared_to(current[id]) >= PLACEMENT_CHANGE * PLACEMENT_CHANGE: return false
	return true

func _prune_failures() -> void:
	for key in failed_placements.keys():
		var record: Dictionary = failed_placements[key]
		var a: Variant = record.a.get_ref(); var b: Variant = record.b.get_ref()
		if not is_instance_valid(a) or not is_instance_valid(b) or a.is_queued_for_deletion() or b.is_queued_for_deletion() or a.get_parent() != game.pieces or b.get_parent() != game.pieces:
			failed_placements.erase(key)

func setup(owner_game: Node2D) -> void:
	game = owner_game

func observe(animal: Animal) -> void:
	animal.body_entered.connect(_on_body_entered.bind(animal))

func _on_body_entered(other: Node, animal: Animal) -> void:
	if not other is Animal or not game.is_playing():
		return
	if not is_instance_valid(animal) or animal.get_parent() != game.pieces or other.get_parent() != game.pieces:
		return
	request_merge(animal, other as Animal)

func request_merge(a: Animal, b: Animal) -> bool:
	if not is_instance_valid(a) or not is_instance_valid(b) or a == b:
		return false
	if a.merge_locked or b.merge_locked or a.is_queued_for_deletion() or b.is_queued_for_deletion():
		return false
	if a.data.level != b.data.level or a.data.id != b.data.id:
		return false
	var target: AnimalData = game.find_animal(a.data.next_evolution_id)
	var golden: bool = a.data.golden_terminal
	if target == null and not golden:
		return false
	_prune_failures()
	var key := _pair_key(a, b)
	if failed_placements.has(key) and not golden:
		if _same_geometry(failed_placements[key].geometry, _placement_geometry(a, b, target.radius)):
			return false
		failed_placements.erase(key)
	# Reserve both synchronously inside the callback. No scene/physics mutation here.
	a.merge_locked = true
	b.merge_locked = true
	pending.append({"a": a, "b": b, "target": target, "golden": golden})
	return true

func _physics_process(_delta: float) -> void:
	if pending.is_empty() or commit_scheduled:
		return
	commit_scheduled = true
	call_deferred("_commit_pending")

# Release only this reservation; never unlock a body owned by another pair.
# A failed transaction preserves all still-live bodies and does not award score.
func _cancel_pair(pair: Dictionary) -> void:
	pending.erase(pair)
	for key in ["a", "b"]:
		var body: Variant = pair.get(key)
		if not is_instance_valid(body) or not body is Animal: continue
		var reserved_elsewhere := false
		for remaining in pending:
			if remaining.get("a") == body or remaining.get("b") == body:
				reserved_elsewhere = true
				break
		if not reserved_elsewhere: body.merge_locked = false

func _commit_pending() -> void:
	commit_scheduled = false
	if not game.is_playing():
		return
	for pair in pending.duplicate():
		var a: Variant = pair.get("a")
		var b: Variant = pair.get("b")
		if not is_instance_valid(a) or not is_instance_valid(b) or not a is Animal or not b is Animal:
			_cancel_pair(pair)
			continue
		if a == b or a.is_queued_for_deletion() or b.is_queued_for_deletion() or a.get_parent() != game.pieces or b.get_parent() != game.pieces or not a.merge_locked or not b.merge_locked:
			_cancel_pair(pair)
			continue
		var target: AnimalData = pair.get("target")
		if a.data.id != b.data.id or a.data.level != b.data.level or (target == null and not pair.get("golden", false)):
			_cancel_pair(pair)
			continue
		var midpoint: Vector2 = (a.global_position + b.global_position) * 0.5
		var safe_point: Variant = midpoint
		if not pair["golden"]:
			safe_point = game.find_merge_position(midpoint, target.radius, a, b)
			if safe_point == null:
				# Cancel only this transaction and suppress the same unchanged
				# geometry; bodies, score and all other pairs are preserved.
				failed_placements[_pair_key(a, b)] = {"a":weakref(a), "b":weakref(b), "geometry":_placement_geometry(a, b, target.radius)}
				_cancel_pair(pair)
				continue
		failed_placements.erase(_pair_key(a, b))
		var inherited_danger: float = maxf(float(game.danger_monitor.timers.get(a.instance_uid, 0.0)), float(game.danger_monitor.timers.get(b.instance_uid, 0.0)))
		pending.erase(pair)
		# Remove from the tree outside physics callbacks before creating the replacement.
		game.pieces.remove_child(a)
		game.pieces.remove_child(b)
		a.queue_free()
		b.queue_free()
		merge_count += 1
		last_merge_eligible = a.progression_eligible and b.progression_eligible
		if pair["golden"]:
			golden_merged.emit(midpoint)
		else:
			var result: Animal = game.create_animal(target, safe_point)
			result.progression_eligible = last_merge_eligible
			# Only an offset placement inherits a running danger timer. A normal
			# midpoint merge retains the existing natural gameplay rules.
			if inherited_danger > 0.0 and result.global_position.distance_squared_to(midpoint) > 0.0001 and result.global_position.y - target.radius < game.danger_height:
				game.danger_monitor.inherit_merge_timer(result, inherited_danger)
			result.visual.animate_action("merge")
			merged.emit(target, safe_point)
	# Capture only after the queue has drained, never a locked partial board.
	if pending.is_empty() and game.persist_best and game.is_playing() and not game.save_scheduled:
		game.save_scheduled = true
		game.call_deferred("_autosave_safe")
