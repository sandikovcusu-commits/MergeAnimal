class_name DangerMonitor
extends Node

signal danger_changed(seconds: float)
signal overflow
@export_range(0.1, 10.0) var grace_period: float = 2.0
@export_range(0.0, 200.0) var max_settled_speed: float = 35.0
var game
var timers: Dictionary = {}
var peak_time: float = 0.0

func setup(owner_game: Node2D) -> void:
	game = owner_game

func _physics_process(delta: float) -> void:
	if game == null or not game.is_playing():
		return
	var updated: Dictionary = {}
	peak_time = 0.0
	for node in game.pieces.get_children():
		var body := node as Animal
		if body == null or body.is_queued_for_deletion():
			continue
		var above: bool = body.global_position.y - body.data.radius < game.danger_height
		var settled: bool = (body.sleeping or body.linear_velocity.length() <= max_settled_speed)
		if above and settled and body.supported:
			var elapsed: float = float(timers.get(body.instance_uid, 0.0)) + delta
			updated[body.instance_uid] = elapsed
			peak_time = maxf(peak_time, elapsed)
	timers = updated
	danger_changed.emit(peak_time)
	if peak_time >= grace_period:
		overflow.emit()
