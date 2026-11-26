class_name FeelAudio
extends RefCounted
# Test main loops may not create autoloads; gameplay remains silent and safe.
static func manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("AudioManager") if tree and tree.root else null
static func play_event(id: String, pitch: float = 1.0, volume_db: float = -3.0) -> bool:
	var instance := manager()
	return instance.play_event(id, pitch, volume_db) if instance else false
static func impact(speed: float, landing: bool) -> bool:
	var instance := manager()
	return instance.impact(speed, landing) if instance else false

static func set_music(id: String) -> void:
	var instance := manager()
	if instance: instance.set_music(id)
