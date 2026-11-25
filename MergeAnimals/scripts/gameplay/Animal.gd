class_name Animal
extends RigidBody2D

@export var data: AnimalData
@onready var circle: CollisionShape2D = $CollisionShape2D
@onready var visual: Node2D = $Visual

func _ready() -> void:
	assert(data != null, "Animal requires AnimalData")
	var shape := CircleShape2D.new()
	shape.radius = data.radius
	circle.shape = shape
	mass = data.body_mass
	var material := PhysicsMaterial.new()
	material.friction = data.friction
	material.bounce = data.bounce
	physics_material_override = material
	visual.queue_redraw()
