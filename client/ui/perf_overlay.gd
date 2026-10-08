extends CanvasLayer
## ตัวบอกความลื่นของเกม (มุมจอบน): FPS เวลาต่อเฟรม จำนวนครั้งที่วาด ความละเอียดที่เรนเดอร์
## เปิด/ปิดได้ในหน้าต่างตั้งค่า ใช้ดูว่าเครื่องไหนหนักตรงไหน

const P = preload("res://client/ui/palette.gd")
const Graphics = preload("res://client/graphics.gd")

static var config_path := "user://settings.cfg"

var label: Label
var _t := 0.0
var _frames := 0
var _worst := 0.0


static func enabled() -> bool:
	var cfg := ConfigFile.new()
	cfg.load(config_path)
	return bool(cfg.get_value("debug", "show_fps", true))


static func set_enabled(tree: SceneTree, on: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(config_path)
	cfg.set_value("debug", "show_fps", on)
	cfg.save(config_path)
	if tree != null:
		for o in tree.get_nodes_in_group("perf_overlay"):
			o.visible = on


func _ready() -> void:
	layer = 90
	add_to_group("perf_overlay")
	label = P.label("", 12, Color(1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.2))
	label.add_theme_constant_override("outline_size", 4)
	label.position = Vector2(8, 176)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	visible = enabled()
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)


func _process(delta: float) -> void:
	_t += delta
	_frames += 1
	_worst = maxf(_worst, delta)
	if _t < 0.5:
		return
	if visible:
		var vp := get_viewport()
		var rid := vp.get_viewport_rid()
		var size: Vector2 = Vector2(vp.get_visible_rect().size) * vp.scaling_3d_scale
		var gpu := RenderingServer.viewport_get_measured_render_time_gpu(rid)
		# ตัวเรนเดอร์มือถือ (OpenGL) วัดเวลา GPU ไม่ได้ จะได้ 0 จึงไม่แสดง
		label.text = "FPS %d  (ช้าสุด %.0f ms)\nเกม %.1f ms  สั่งวาด %.1f ms%s\nวาด %d ครั้ง  %dk เหลี่ยม\n%dx%d  ภาพ:%s" % [
			roundi(_frames / _t), _worst * 1000.0,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			RenderingServer.viewport_get_measured_render_time_cpu(rid),
			("  GPU %.1f ms" % gpu) if gpu > 0.0 else "",
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0),
			int(size.x), int(size.y), Graphics.NAMES[Graphics.level()]]
	_t = 0.0
	_frames = 0
	_worst = 0.0
