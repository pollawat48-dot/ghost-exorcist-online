extends Node
## บรรยากาศ: วงจรกลางวัน–กลางคืน, แสงตะเกียง, ผีเรืองแสงตอนกลางคืน, หิ่งห้อย, หมอก

signal phase_changed(text: String)

const DAY_LENGTH := 240.0
const DAY_COLOR := Color(1, 1, 1)
const DUSK_COLOR := Color(1.0, 0.78, 0.62)
const NIGHT_COLOR := Color(0.3, 0.34, 0.6)

## 0..1 ของหนึ่งวัน: 0–0.42 กลางวัน, 0.42–0.55 พลบค่ำ, 0.55–0.88 กลางคืน, 0.88–1 รุ่งสาง
var time_of_day := 0.05
var night := 0.0
var phase := ""
var map: Node2D
var ghosts: Node
var canvas_modulate: CanvasModulate
var fx: Node2D
var fireflies: CPUParticles2D
var _t := 0.0


func setup(map_ref: Node2D, ghosts_ref: Node) -> void:
	map = map_ref
	ghosts = ghosts_ref


func _ready() -> void:
	canvas_modulate = CanvasModulate.new()
	add_child(canvas_modulate)

	# เลเยอร์แสงเรือง ไม่โดนความมืดของ CanvasModulate แต่เลื่อนตามกล้อง
	var layer := CanvasLayer.new()
	layer.layer = 1
	layer.follow_viewport_enabled = true
	add_child(layer)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	fx = Node2D.new()
	fx.material = additive
	fx.draw.connect(_draw_fx)
	layer.add_child(fx)

	fireflies = CPUParticles2D.new()
	fireflies.material = additive
	fireflies.amount = 120
	fireflies.lifetime = 6.0
	fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fireflies.emission_rect_extents = map.field_rect.size / 2.0
	fireflies.position = map.field_rect.get_center()
	fireflies.gravity = Vector2.ZERO
	fireflies.spread = 180.0
	fireflies.initial_velocity_min = 4.0
	fireflies.initial_velocity_max = 16.0
	fireflies.scale_amount_min = 2.0
	fireflies.scale_amount_max = 3.5
	fireflies.color = Color(0.75, 1.0, 0.4)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(0.3, Color(1, 1, 1, 1))
	ramp.add_point(0.7, Color(1, 1, 1, 1))
	fireflies.color_ramp = ramp
	fireflies.emitting = false
	layer.add_child(fireflies)
	tick(0.0)


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	_t += delta
	time_of_day = fposmod(time_of_day + delta / DAY_LENGTH, 1.0)
	night = _night_factor(time_of_day)
	var c := DAY_COLOR.lerp(DUSK_COLOR, clampf(night * 2.0, 0.0, 1.0))
	canvas_modulate.color = c.lerp(NIGHT_COLOR, clampf(night * 2.0 - 1.0, 0.0, 1.0))
	fireflies.emitting = night > 0.3
	fireflies.modulate.a = night
	var p := _phase_name(time_of_day)
	if p != phase:
		phase = p
		phase_changed.emit(phase)
	fx.queue_redraw()


func _night_factor(t: float) -> float:
	if t < 0.42:
		return 0.0
	if t < 0.55:
		return smoothstep(0.42, 0.55, t)
	if t < 0.88:
		return 1.0
	return 1.0 - smoothstep(0.88, 1.0, t)


func _phase_name(t: float) -> String:
	if t < 0.42:
		return "กลางวัน"
	if t < 0.55:
		return "พลบค่ำ"
	if t < 0.88:
		return "กลางคืน"
	return "รุ่งสาง"


func _glow(pos: Vector2, radius: float, color: Color, strength: float) -> void:
	for i in 10:
		fx.draw_circle(pos, radius * (1.0 - i * 0.09), Color(color, strength * 0.09))


func _draw_fx() -> void:
	if night <= 0.01:
		return
	for i in map.lanterns.size():
		var p: Vector2 = map.lanterns[i] + Vector2(10, -48)
		_glow(p, 46.0 + sin(_t * 3.0 + i) * 3.0, Color(1.0, 0.55, 0.2), night)
		fx.draw_circle(p, 6.0, Color(1.0, 0.8, 0.4, night))
	for g in ghosts.get_children():
		if g.has_method("take_damage") and g.alive:
			_glow(g.position, 34.0, g.data["color"], night * 0.8)
	# หมอกลอยต่ำตอนกลางคืน
	for i in 10:
		var base := Vector2(1400 + (i * 397) % 1700, 150 + (i * 613) % 1700)
		var drift := Vector2(sin(_t * 0.05 + i) * 120.0, cos(_t * 0.04 + i * 2.0) * 40.0)
		var r := 140.0 + (i % 3) * 40.0
		for k in 8:
			fx.draw_circle(base + drift, r * (1.0 - k * 0.11), Color(0.5, 0.55, 0.7, 0.008 * night))
