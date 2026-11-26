extends Control
signal shown(id: StringName)
signal achievement_shown(id: String)
var queue: Array = []
var displaying := false
var reduced_effects := false
var card: PanelContainer
var image: TextureRect
var text: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = Vector2(140, 285)
	size = Vector2(440, 104)
	z_index = 20
	card = PanelContainer.new(); card.size = size; card.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(card)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 12); row.mouse_filter = Control.MOUSE_FILTER_IGNORE; card.add_child(row)
	image = TextureRect.new(); image.custom_minimum_size = Vector2(92, 92); image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; image.mouse_filter = Control.MOUSE_FILTER_IGNORE; row.add_child(image)
	text = Label.new(); text.size_flags_horizontal = Control.SIZE_EXPAND_FILL; text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; text.add_theme_font_size_override("font_size", 21); text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; text.mouse_filter = Control.MOUSE_FILTER_IGNORE; row.add_child(text)
	visible = false

func enqueue(data: AnimalData) -> void:
	queue.append({"kind": "animal", "data": data})
	if not displaying: _show_next()

func enqueue_achievement(data: AchievementData) -> void:
	queue.append({"kind": "achievement", "data": data})
	if not displaying: _show_next()

func _show_next() -> void:
	if queue.is_empty():
		displaying = false; visible = false; return
	displaying = true
	var item: Dictionary = queue.pop_front()
	if item.kind == "animal":
		var data: AnimalData = item.data
		image.texture = data.sprite
		text.text = "%s\n%s · %s %d" % [tr("ANIMAL_DISCOVERED"), tr(data.translation_key), tr("LEVEL"), data.level]
		shown.emit(data.id)
	else:
		var achievement: AchievementData = item.data
		image.texture = achievement.icon
		text.text = "%s\n%s" % [tr("ACHIEVEMENT_UNLOCKED"), achievement.localized_title()]
		achievement_shown.emit(achievement.id)
	visible = true
	card.modulate.a = 1.0 if reduced_effects else 0.0
	var tween := create_tween()
	if not reduced_effects: tween.tween_property(card, "modulate:a", 1.0, 0.2)
	tween.tween_interval(2.0)
	if not reduced_effects: tween.tween_property(card, "modulate:a", 0.0, 0.2)
	tween.tween_callback(_show_next)
