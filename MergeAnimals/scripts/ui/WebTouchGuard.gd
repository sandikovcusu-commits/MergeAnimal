extends Node

# Godot 4.7.2 Web turns DOM touchcancel into an ordinary touch release. A
# button can otherwise activate on cancellation, including irreversible Rescue.
# Cancel pending GUI button presses before the engine receives that release.
# The gameplay aim/remove handlers independently consume the cancelled touch ID.
signal touch_cancelled

var cancel_callback: JavaScriptObject

func _ready() -> void:
	if not OS.has_feature("web"): return
	cancel_callback = JavaScriptBridge.create_callback(_on_touch_cancel)
	var window := JavaScriptBridge.get_interface("window")
	window.addEventListener("touchcancel", cancel_callback, true)

func _on_touch_cancel(_arguments: Array) -> void:
	touch_cancelled.emit()
	get_tree().root.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
