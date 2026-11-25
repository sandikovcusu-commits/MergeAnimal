class_name AnimalData
extends Resource

@export var id: StringName = &"mouse"
@export var display_name: String = "Mouse"
@export_range(1, 100) var level: int = 1
@export_range(5.0, 200.0) var radius: float = 18.0
@export_range(0.01, 50.0) var body_mass: float = 1.0
@export_range(0.0, 1.0) var friction: float = 0.5
@export_range(0.0, 1.0) var bounce: float = 0.1
@export var merge_score: int = 2
@export var placeholder_color: Color = Color("d9b5a5")
@export var sprite: Texture2D
@export var merge_effect: PackedScene
@export var merge_sound: AudioStream
@export var unlock_id: StringName = &"mouse"
