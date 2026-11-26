class_name ChallengeManager
extends RefCounted
signal objective_reached
const DEFINITIONS: Array[ChallengeData] = [preload("res://resources/challenges/01.tres"), preload("res://resources/challenges/02.tres"), preload("res://resources/challenges/03.tres"), preload("res://resources/challenges/04.tres"), preload("res://resources/challenges/05.tres"), preload("res://resources/challenges/06.tres"), preload("res://resources/challenges/07.tres"), preload("res://resources/challenges/08.tres"), preload("res://resources/challenges/09.tres"), preload("res://resources/challenges/10.tres")]
var definition: ChallengeData
var count: int = 0
var elapsed: float = 0.0
var reached := false
func _init(data: ChallengeData) -> void: definition = data
func tick(delta: float) -> void:
	if not reached: elapsed += delta
func _evaluate() -> void:
	if not reached and count >= definition.target:
		reached = true
		objective_reached.emit()
func record_creation(data: AnimalData, eligible: bool, game_score: int) -> void:
	if reached or not eligible: return
	if definition.objective_type == "animal" and data.id == definition.animal_id: count += 1
	elif definition.objective_type == "score": count = game_score
	_evaluate()
func record_score(game_score: int, eligible: bool) -> void:
	if reached or not eligible or definition.objective_type != "score": return
	count = game_score
	_evaluate()
func record_merge(merge_count: int, combo: int, eligible: bool, golden: bool = false) -> void:
	if reached or not eligible: return
	match definition.objective_type:
		"merges": count += 1
		"combo": count = maxi(count, combo)
		"golden":
			if golden: count += 1
	_evaluate()
