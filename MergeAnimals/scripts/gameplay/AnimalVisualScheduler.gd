extends Node
## One pausable callback for active animal visuals. Cosmetic only: no physics
## state or shape is touched. Previews and Reduced Effects are not registered.
var visuals: Array[AnimalCosmetic] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_process(false)

func register_visual(visual: AnimalCosmetic) -> void:
	if not visuals.has(visual): visuals.append(visual)
	set_process(not visuals.is_empty())

func unregister_visual(visual: AnimalCosmetic) -> void:
	visuals.erase(visual)
	set_process(not visuals.is_empty())

func _process(delta: float) -> void:
	for visual in visuals:
		# Individual branches may be paused independently of the scene tree.
		if is_instance_valid(visual) and visual.can_process():
			visual.advance_visual(delta)
