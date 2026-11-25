class_name Animal
extends RigidBody2D

@export var data: AnimalData
@onready var circle: CollisionShape2D = $CollisionShape2D
@onready var visual = $Visual
var merge_locked: bool = false
var supported: bool = false
var instance_uid: int = 0

func _ready() -> void:
	assert(data != null, "Animal requires AnimalData")
	instance_uid = get_instance_id()
	var shape := CircleShape2D.new()
	shape.radius = data.radius
	circle.shape = shape
	mass = data.body_mass
	linear_damp = data.linear_damping
	angular_damp = data.angular_damping
	var material := PhysicsMaterial.new()
	material.friction = data.friction
	material.bounce = data.bounce
	physics_material_override = material
	visual.data = data

# Contact normals face away from the supporting surface. This is refreshed by
# the physics server and avoids treating a side-wall contact as support.
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	supported = false
	for i in range(state.get_contact_count()):
		if state.get_contact_local_normal(i).y < -0.5:
			supported = true
			break
