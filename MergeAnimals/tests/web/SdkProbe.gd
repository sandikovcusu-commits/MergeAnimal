extends Node
# Only copied into a temporary CI export, never production.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if not OS.has_feature("web"): return
	var state := {"sdk_state": AdManager.sdk_state, "environment": AdManager.sdk_environment, "provider": AdManager.provider, "rewards_available": AdManager.rewarded_available(), "playing": AdManager.gameplay_active}
	JavaScriptBridge.eval("window.__sdkProbe=" + JSON.stringify(state))
