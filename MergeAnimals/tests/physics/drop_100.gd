extends SceneTree

# 100 actual spawn requests in an isolated empty-spawn fixture. Each spawned
# body is removed by the test after a tick; this is not a stacked-pile stress test.
var scene := preload("res://scenes/game/Game.tscn")
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = scene.instantiate()
	game.test_seed = 42
	game.persist_best = false
	game.drop_cooldown = 0.1
	root.add_child(game)
	await process_frame
	game.danger_monitor.set_physics_process(false)
	var accepted := 0
	for i in range(100):
		game._set_aim(360)
		if game.drop_animal():
			accepted += 1
		await physics_frame
		await physics_frame
		for body in game.pieces.get_children():
			body.queue_free()
		# Wait for the actual cooldown state, rather than assuming 12 ticks at 60 Hz.
		var max_ticks: int = ceili(game.drop_cooldown * Engine.physics_ticks_per_second) + 10
		for tick in range(max_ticks):
			if game._can_aim() and game.cooldown_left <= 0.0:
				break
			await physics_frame
	var ok: bool = accepted == 100 and game.spawn_count == 100
	print("100-drop fixture: requests=%d spawned=%d result=%s" % [accepted, game.spawn_count, "PASS" if ok else "FAIL"])
	quit(0 if ok else 1)
