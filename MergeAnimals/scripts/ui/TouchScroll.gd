## Godot 4.7.2 ScrollContainer drags using mouse emulation, which this project
## intentionally disables to keep gameplay touch and mouse input separate.
## Track one real touch and cancel child button presses once a swipe begins.
class_name TouchScroll
extends Node

var area: ScrollContainer
var blocker: Control
var touch_id := -1
var start_position := Vector2.ZERO
var start_scroll := 0
var dragging := false

static func install(target: ScrollContainer, modal: Control = null) -> void:
	var handler := TouchScroll.new()
	handler.area = target
	handler.blocker = modal
	target.add_child(handler)

func _input(event: InputEvent) -> void:
	if not is_instance_valid(area) or not area.is_visible_in_tree(): return
	if is_instance_valid(blocker) and blocker.visible: return
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1 and area.get_global_rect().has_point(event.position):
			touch_id = event.index
			start_position = event.position
			start_scroll = area.scroll_vertical
			dragging = false
		elif not event.pressed and event.index == touch_id:
			if dragging: area.propagate_notification(Control.NOTIFICATION_SCROLL_END)
			touch_id = -1
			dragging = false
	elif event is InputEventScreenDrag and event.index == touch_id:
		var delta: Vector2 = event.position - start_position
		if not dragging and absf(delta.y) > 16.0:
			dragging = true
			area.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
		if dragging:
			area.scroll_vertical = roundi(start_scroll - delta.y)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		touch_id = -1
		dragging = false
