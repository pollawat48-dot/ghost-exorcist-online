extends Control
## จอยบนจอ: ลากนิ้ว (หรือเมาส์) ในวงกลมเพื่อเดินต่อเนื่อง ค่า value ยาวไม่เกิน 1 (y บวก = ลงล่างจอ)

const P = preload("res://client/ui/palette.gd")

var value := Vector2.ZERO
var _touch := -2
var _knob := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var center := get_global_rect().get_center()
	var radius := size.x * 0.5
	if event is InputEventScreenTouch:
		if event.pressed and _touch == -2 and event.position.distance_to(center) <= radius:
			_touch = event.index
			_update(event.position - center)
		elif not event.pressed and event.index == _touch:
			_reset()
	elif event is InputEventScreenDrag and event.index == _touch:
		_update(event.position - center)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			if event.position.distance_to(center) <= radius:
				get_viewport().set_input_as_handled()
		elif event.pressed and _touch == -2 and event.position.distance_to(center) <= radius:
			_touch = -1
			_update(event.position - center)
		elif not event.pressed and _touch == -1:
			_reset()
	elif event is InputEventMouseMotion and _touch == -1 and event.device != InputEvent.DEVICE_ID_EMULATION:
		_update(event.position - center)


func _update(d: Vector2) -> void:
	var reach := size.x * 0.32
	_knob = d.limit_length(reach)
	value = _knob / reach
	get_viewport().set_input_as_handled()
	queue_redraw()


func _reset() -> void:
	_touch = -2
	_knob = Vector2.ZERO
	value = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := size.x * 0.5
	draw_circle(c, r, Color(1, 0.97, 0.94, 0.55))
	draw_arc(c, r - 2, 0, TAU, 64, Color(P.LAVENDER, 0.9), 4.0, true)
	draw_arc(c, r * 0.62, 0, TAU, 48, Color(P.LAVENDER, 0.45), 2.0, true)
	for i in 4:
		var dir := Vector2.UP.rotated(i * PI / 2.0)
		var tip := c + dir * r * 0.84
		var side := dir.orthogonal() * r * 0.09
		draw_colored_polygon(PackedVector2Array([tip, tip - dir * r * 0.14 + side, tip - dir * r * 0.14 - side]), Color(P.LAVENDER, 0.9))
	var k := c + _knob
	draw_circle(k + Vector2(0, 3), r * 0.36, Color(0.4, 0.25, 0.4, 0.2))
	draw_circle(k, r * 0.36, P.PINK)
	draw_circle(k + Vector2(0, -r * 0.05), r * 0.27, P.PINK.lightened(0.3))
	draw_arc(k, r * 0.36, 0, TAU, 40, P.OUTLINE, 3.0, true)
