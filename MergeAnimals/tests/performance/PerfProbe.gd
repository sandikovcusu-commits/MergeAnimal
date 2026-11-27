extends Node
# CI-only autoload. The release export never contains this file.
var last_id := 0
var scene_name := ""
var mode := ""
var elapsed := 0.0
var sample := 0.0
var counters := {}
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(delta: float) -> void:
	var game = get_tree().current_scene
	if game and scene_name != game.name:
		scene_name = game.name
		if game.name == "MainMenu": JavaScriptBridge.eval("window.__benchMenuReady=performance.now()")
	var raw = JavaScriptBridge.eval("JSON.stringify(window.__perfCmd||null)")
	if typeof(raw) == TYPE_STRING:
		var cmd = JSON.parse_string(raw)
		if cmd is Dictionary and int(cmd.get("id", 0)) != last_id:
			last_id = int(cmd.id)
			if str(cmd.get("op", "")) == "setup" and game and game.has_method("create_animal"):
				setup(game, str(cmd.get("mode", "")))
			JavaScriptBridge.eval("window.__perfAck=" + str(last_id))
	if not game or not game.has_method("create_animal"): return
	elapsed += delta
	if mode in ["collision", "chain", "golden", "effects", "reduced"] and elapsed >= (0.2 if mode in ["effects", "reduced"] else 3.0):
		elapsed = 0.0
		if mode == "collision":
			for animal in game.pieces.get_children():
				animal.sleeping = false
				animal.apply_central_impulse(Vector2(randf_range(-30, 30), randf_range(-120, -30)))
		elif mode in ["chain", "golden"]:
			for animal in game.pieces.get_children(): animal.queue_free()
			call_deferred("make_merges", game, mode)
		else:
			game._on_merged(game.animals[1], Vector2(300 + randf_range(-60, 60), 700 + randf_range(-60, 60)))
	sample += delta
	if sample >= 1.0:
		sample = 0.0
		var monitor := {"physics_s":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS), "process_s":Performance.get_monitor(Performance.TIME_PROCESS), "draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC), "objects":Performance.get_monitor(Performance.OBJECT_COUNT), "nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "bodies":game.pieces.get_child_count(), "merges":game.merge_manager.merge_count, "effects":get_tree().get_nodes_in_group("visual_effects").size(), "audio_latency_s":Performance.get_monitor(Performance.AUDIO_OUTPUT_LATENCY)}
		JavaScriptBridge.eval("window.__perfMon && window.__perfMon.push(" + JSON.stringify(monitor) + ")")
func setup(game, scenario: String) -> void:
	mode = scenario
	if scenario == "natural": return
	game.persist_best = false # fixture avoids stress saves and profile pollution; normal gameplay is separately measured
	game.danger_monitor.set_physics_process(false) # stable synthetic load, not natural overflow
	for child in game.pieces.get_children(): child.queue_free()
	if scenario in ["10", "20", "40", "collision", "effects", "reduced"]:
		var count := int(scenario) if scenario in ["10", "20", "40"] else 20
		for i in range(count):
			var body = game.create_animal(game.animals[0], Vector2(145 + (i % 8) * 58, 600 + int(i / 8) * 65))
			body.merge_locked = true # isolate stable body/collision cost; real merge tests separate
			body.can_sleep = false
	if scenario == "reduced":
		game.reduced_effects = true
		get_node("/root/AudioManager").reduced_effects = true
func make_merges(game, scenario: String) -> void:
	if not is_instance_valid(game): return
	var index: int = game.animals.size() - 1 if scenario == "golden" else 0
	var n := 2 if scenario == "golden" else 4
	for i in range(n):
		var a = game.create_animal(game.animals[index], Vector2(210 + (i % 2) * 38 + int(i / 2) * 180, 700))
		a.linear_velocity = Vector2(30 if i % 2 == 0 else -30, 0)
