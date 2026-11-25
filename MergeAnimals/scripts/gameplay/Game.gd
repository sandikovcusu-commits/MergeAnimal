extends Node2D

# These bounds must agree with the wall shapes in Game.tscn.
@export var left_bound: float = 91.0
@export var right_bound: float = 629.0
@export var floor_height: float = 1094.0
@export var spawn_height: float = 350.0
@export_range(0.1, 2.0) var drop_cooldown: float = 0.5
@export var test_seed: int = 0 # 0 means randomize; nonzero makes sequences repeatable.
@export var animals: Array[AnimalData] = []
@export var animal_scene: PackedScene

@onready var pieces: Node2D = $Pieces
@onready var next_label: Label = $HUD/NextLabel
var current_data: AnimalData
var next_data: AnimalData
var aim_x: float = 360.0
var cooldown_left: float = 0.0
var active_touch: int = -1
var mouse_down: bool = false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	assert(animals.size() > 0 and animal_scene != null, "Configure animal resources and scene")
	if test_seed == 0:
		rng.randomize()
	else:
		rng.seed = test_seed
	current_data = _pick_animal()
	next_data = _pick_animal()
	_update_hud()
	queue_redraw()

func _process(delta: float) -> void:
	cooldown_left = maxf(0.0, cooldown_left - delta)

func _pick_animal() -> AnimalData:
	return animals[rng.randi_range(0, animals.size() - 1)]

func _set_aim(x: float) -> void:
	aim_x = clampf(x, left_bound + current_data.radius, right_bound - current_data.radius)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and active_touch == -1 and _inside_input_area(event.position):
			active_touch = event.index
			_set_aim(event.position.x)
		elif not event.pressed and event.index == active_touch:
			_set_aim(event.position.x)
			active_touch = -1
			drop_animal()
	elif event is InputEventScreenDrag and event.index == active_touch:
		_set_aim(event.position.x)
	elif event is InputEventMouseMotion and active_touch == -1:
		_set_aim(event.position.x)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and active_touch == -1:
		if event.pressed:
			mouse_down = _inside_input_area(event.position)
			if mouse_down:
				_set_aim(event.position.x)
		elif mouse_down:
			mouse_down = false
			_set_aim(event.position.x)
			drop_animal()

func _inside_input_area(point: Vector2) -> bool:
	return point.x >= left_bound and point.x <= right_bound and point.y >= 235.0 and point.y <= floor_height

func drop_animal() -> bool:
	if cooldown_left > 0.0:
		return false
	var animal := animal_scene.instantiate() as Animal
	animal.data = current_data
	animal.position = Vector2(clampf(aim_x, left_bound + current_data.radius, right_bound - current_data.radius), spawn_height)
	pieces.add_child(animal)
	cooldown_left = drop_cooldown
	current_data = next_data
	next_data = _pick_animal()
	_set_aim(aim_x)
	_update_hud()
	return true

func _update_hud() -> void:
	next_label.text = "NEXT  ·  " + next_data.display_name.to_upper()

func _draw() -> void:
	# Temporary, original diagnostic scene visuals; final art comes later.
	draw_rect(Rect2(0, 0, 720, 1280), Color("e8efdc"))
	draw_rect(Rect2(72, 280, 576, 830), Color("b8d0ab"))
	draw_rect(Rect2(left_bound, 300, right_bound - left_bound, floor_height - 300), Color("f7ebcf"))
	draw_line(Vector2(left_bound, 465), Vector2(right_bound, 465), Color("d68a77"), 2.0)
	if current_data:
		var x := clampf(aim_x, left_bound + current_data.radius, right_bound - current_data.radius)
		draw_dashed_line(Vector2(x, spawn_height + current_data.radius + 12), Vector2(x, floor_height - 8), Color(0.38, 0.48, 0.37, 0.35), 2.0, 8.0)
		draw_circle(Vector2(x, spawn_height), current_data.radius + 2, Color("60483e"))
		draw_circle(Vector2(x, spawn_height), current_data.radius, current_data.placeholder_color)
