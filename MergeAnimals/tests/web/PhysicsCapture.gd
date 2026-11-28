extends Node
## TEST ONLY: outline the real board, never spawn or alter physics state.
var enabled := false
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func _process(_delta: float) -> void:
	var game := get_tree().current_scene
	if not enabled and game and game.has_method("create_animal") and int(JavaScriptBridge.eval("window.__enablePhysicsOutlines ? 1 : 0")) == 1:
		game.debug_outlines = true
		game.queue_redraw()
		enabled = true
		JavaScriptBridge.eval("window.__physicsOutlinesEnabled = true")
