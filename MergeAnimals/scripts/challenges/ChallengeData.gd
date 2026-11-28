class_name ChallengeData
extends Resource

@export_range(1, 20) var id: int = 1
@export var title_key: StringName
@export var objective_key: StringName
@export_enum("animal", "score", "merges", "combo", "golden") var objective_type: String = "animal"
@export var animal_id: StringName = &""
@export_range(1, 1000000) var target: int = 1
@export_range(0.0, 3600.0) var time_limit: float = 0.0
@export_range(0, 1000) var drop_limit: int = 0
# Setup bodies are a part of the level, never objective creations.
@export var starting_animals: PackedStringArray = []
@export var spawn_sequence: PackedStringArray = []
