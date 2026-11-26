class_name ChallengeManager
extends RefCounted

signal objective_reached
const DEFINITIONS: Array[ChallengeData] = [preload("res://resources/challenges/01.tres"), preload("res://resources/challenges/02.tres"), preload("res://resources/challenges/03.tres"), preload("res://resources/challenges/04.tres"), preload("res://resources/challenges/05.tres")]
var definition: ChallengeData
var count: int = 0
var elapsed: float = 0.0
var reached := false
func _init(data: ChallengeData) -> void: definition = data
func tick(delta: float) -> void:
	if not reached: elapsed += delta
func record_creation(data: AnimalData, eligible: bool, game_score: int) -> void:
	if reached or not eligible: return
	if definition.objective_type == "animal" and data.id == definition.animal_id:
		count += 1
	elif definition.objective_type == "score":
		count = game_score
	if count >= definition.target:
		reached = true
		objective_reached.emit()
func record_score(game_score: int, eligible: bool) -> void:
	if reached or not eligible or definition.objective_type != "score": return
	count = game_score
	if count >= definition.target:
		reached = true
		objective_reached.emit()
