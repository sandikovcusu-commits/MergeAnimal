extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, description: String) -> void:
	checks += 1
	print("%s: %s" % ["PASS" if ok else "FAIL", description])
	if not ok: failures += 1
func _initialize() -> void:
	var names := ["play", "pause", "restart", "settings", "home", "collection", "challenge", "sound", "music", "mute", "undo", "remove", "rescue", "trophy", "star", "lock", "check", "close", "back", "reward"]
	for name in names:
		var icon := load("res://assets/ui/icons/%s.svg" % name) as Texture2D
		check(icon != null and icon.get_size() == Vector2(48,48), "icon %s imports" % name)
	for name in ["forest", "earth", "sunset", "snow", "gold", "berry", "sky", "cream"]:
		var theme := load("res://assets/ui/themes/%s.tres" % name) as Theme
		for state in ["normal", "hover", "pressed", "disabled"]:
			check(theme != null and theme.has_stylebox(state, "Button"), "%s %s style" % [name, state])
	var scene := load("res://scenes/game/Game.tscn") as PackedScene
	var game := scene.instantiate()
	check(game.get_node("HUD").theme != null, "HUD has native theme")
	game.free()
	print("Day4.1 UI checks: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
