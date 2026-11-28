extends SceneTree
# Release acceptance is deliberately separate from DEV regressions.
# A nonzero exit is expected while missing art remains.
var failures := 0
func check(ok: bool, description: String) -> void:
	print("%s: %s" % ["PASS" if ok else "FAIL", description])
	if not ok: failures += 1
func _initialize() -> void:
	var game := (load("res://scenes/game/Game.tscn") as PackedScene).instantiate()
	for data in game.animals:
		check(data.sprite != null, "%s normal sprite" % data.id)
		check(data.happy_sprite != null, "%s happy sprite" % data.id)
		check(data.surprise_sprite != null, "%s surprise sprite" % data.id)
	game.free()
	# A license review must be independently documented; file existence is not proof.
	print("RELEASE BLOCKED: model/vendor and applicable commercial terms are not verified.")
	failures += 1
	print("Acceptance missing or blocked: %d" % failures)
	quit(1 if failures else 0)
