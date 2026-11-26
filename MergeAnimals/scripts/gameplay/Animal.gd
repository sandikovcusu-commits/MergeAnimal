class_name Animal
extends RigidBody2D

@export var data: AnimalData
@onready var circle: CollisionShape2D = $CollisionShape2D
@onready var visual = $Visual
var merge_locked: bool = false
# False for debug/fixtures; genuine drops and their descendants are true.
var progression_eligible: bool = false
var supported: bool = false
var instance_uid: int = 0
# Stable identity within a saved board, independent of Godot instance IDs.
var save_uid: int = 0
var impact_speed := 0.0

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
	body_entered.connect(_on_visual_contact)

# Contact normals face away from the supporting surface. This is refreshed by
# the physics server and avoids treating a side-wall contact as support.
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	supported = false
	impact_speed = state.linear_velocity.length()
	for i in range(state.get_contact_count()):
		if state.get_contact_local_normal(i).y < -0.5:
			supported = true
			break

func _on_visual_contact(other: Node) -> void:
	if impact_speed < 100.0: return
	var landing := not other is Animal
	if landing: visual.animate_action("landing")
	FeelAudio.impact(impact_speed, landing)
