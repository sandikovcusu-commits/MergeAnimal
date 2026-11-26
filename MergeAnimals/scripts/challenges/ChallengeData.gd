class_name ChallengeData
extends Resource

@export_range(1, 5) var id: int = 1
@export var title_key: StringName
@export var objective_key: StringName
@export_enum("animal", "score") var objective_type: String = "animal"
@export var animal_id: StringName = &""
@export_range(1, 1000000) var target: int = 1
