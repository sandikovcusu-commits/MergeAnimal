class_name MergeManager
extends Node

signal merged(result: AnimalData, point: Vector2)
signal golden_merged(point: Vector2)

var game
var pending: Array[Dictionary] = []
var merge_count: int = 0
var commit_scheduled: bool = false
var last_merge_eligible: bool = false

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

func _commit_pending() -> void:
	commit_scheduled = false
	if not game.is_playing():
		return
	# Work on a snapshot; pending pairs without room are retried on later ticks.
	for pair in pending.duplicate():
		var a: Animal = pair["a"]
		var b: Animal = pair["b"]
		if not is_instance_valid(a) or not is_instance_valid(b):
			if is_instance_valid(a):
				a.merge_locked = false
			if is_instance_valid(b):
				b.merge_locked = false
			pending.erase(pair)
			continue
		var target: AnimalData = pair["target"]
		var midpoint: Vector2 = (a.global_position + b.global_position) * 0.5
		var safe_point: Variant = midpoint
		if not pair["golden"]:
			safe_point = game.find_merge_position(midpoint, target.radius, a, b)
			if safe_point == null:
				continue
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
			result.visual.animate_action("merge")
			merged.emit(target, safe_point)
