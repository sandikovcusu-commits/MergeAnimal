extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", message])
	if not ok: failures += 1
func run() -> void:
	var game = (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	game.persist_best = false
	root.add_child(game)
	await process_frame
	var fx_script = load("res://scripts/effects/MergeEffects.gd")
	for kind in fx_script.KINDS:
		var fx = fx_script.new(); fx.effect_kind = kind; game.add_child(fx)
		await process_frame
		check(fx.effect_kind == kind and fx.process_mode == Node.PROCESS_MODE_PAUSABLE and fx.is_processing(), "%s animates without physics" % kind)
		fx.queue_free()
	await process_frame
	for theme_name in ["forest", "earth", "sunset", "snow", "gold", "berry", "sky", "cream"]:
		var ui_theme := load("res://assets/ui/themes/%s.tres" % theme_name) as Theme
		check(ui_theme.has_stylebox("focus", "Button"), "%s has keyboard focus style" % theme_name)
	game.reduced_effects = true
	var before := game.get_child_count()
	game._on_merged(game.animals[1], Vector2(300, 600))
	check(game.get_child_count() - before == 1, "reduced effects emits only one low-cost burst")
	var reduced_fx = game.get_children().back()
	check(reduced_fx.effect_kind == "soft_burst" and reduced_fx.reduced_visual, "reduced burst omits decorative second ring")
	game.reduced_effects = false
	before = game.get_child_count()
	game._on_merged(game.animals[1], Vector2(300, 600))
	check(game.get_child_count() - before >= 4, "regular merge emits layered effects")
	await create_timer(0.9).timeout
	var remaining := 0
	for node in game.get_children():
		if node.get_script() == fx_script: remaining += 1
	check(remaining == 0, "effects self-remove after playback")
	print("Day5 effects checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
