extends Control
## ปุ่มกลม/สี่เหลี่ยมมนสำหรับทั้งมือถือ (แตะ หลายนิ้วพร้อมกันได้) และ PC (คลิกเมาส์)
## จัดการ input เองใน _input เพื่อให้กดได้ขณะอีกนิ้วกำลังลากจอยอยู่

const P = preload("res://client/ui/palette.gd")

signal pressed

var kind := ""  ## ไอคอน: sword / water / herb / "" (ช่องว่าง)
var round := true
var fill := P.PINK
var hotkey := ""
var count := -1  ## -1 = ไม่แสดงจำนวน
var cooldown := 0.0  ## 0..1 ส่วนที่ยังติดคูลดาวน์
var badge := false  ## จุดแดงมุมขวาบน (มีแต้มให้ใช้ ฯลฯ)
var caption := ""  ## ข้อความใต้ปุ่ม
var lit := false  ## เปิดใช้งานอยู่ (เช่น ออโต้) วาดวงแสงรอบปุ่ม
var _touch := -2  ## -2 = ไม่ได้กด, -1 = เมาส์, อื่นๆ = index นิ้ว


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if lit:
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _hit(event.position):
			_press(event.index)
		elif not event.pressed and event.index == _touch:
			_release()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			# เมาส์จำลองจากการแตะ: แตะจริงจัดการไปแล้ว แค่กันไม่ให้ไปสั่งเดินในฉาก
			if _hit(event.position):
				get_viewport().set_input_as_handled()
		elif event.pressed and _hit(event.position):
			_press(-1)
		elif not event.pressed and _touch == -1:
			_release()


func _press(index: int) -> void:
	_touch = index
	get_viewport().set_input_as_handled()
	pressed.emit()
	queue_redraw()


func _release() -> void:
	_touch = -2
	queue_redraw()


func _hit(p: Vector2) -> bool:
	var r := get_global_rect()
	if round:
		return p.distance_to(r.get_center()) <= r.size.x * 0.5
	return r.has_point(p)


func _draw() -> void:
	var down := _touch != -2
	var sz := size * (0.94 if down else 1.0)
	var off := (size - sz) * 0.5
	var c := off + sz * 0.5
	if round:
		var r := sz.x * 0.5
		if lit:
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 220.0)
			draw_circle(c, r + 5.0 + pulse * 3.0, Color(1.0, 0.85, 0.4, 0.45))
		draw_circle(c + Vector2(0, 3), r, Color(0.4, 0.25, 0.4, 0.2))
		draw_circle(c, r, fill.darkened(0.08) if down else fill)
		draw_circle(c + Vector2(0, -r * 0.12), r * 0.8, fill.lightened(0.25))
		draw_arc(c, r - 1.5, 0, TAU, 48, P.OUTLINE, 3.0, true)
	else:
		var st := P.panel_style(12, fill, P.OUTLINE)
		st.set_border_width_all(2)
		st.shadow_size = 2
		draw_style_box(st, Rect2(off, sz))
	if kind != "":
		P.draw_icon(self, kind, c, sz.x * (0.62 if round else 0.7))
	if cooldown > 0.0:
		if round:
			draw_arc(c, sz.x * 0.25, -PI / 2, -PI / 2 + TAU * cooldown, 32, Color(0.3, 0.2, 0.3, 0.45), sz.x * 0.5, false)
		else:
			draw_rect(Rect2(off + Vector2(0, sz.y * (1.0 - cooldown)), Vector2(sz.x, sz.y * cooldown)), Color(0.3, 0.2, 0.3, 0.4))
	var font := get_theme_default_font()
	if hotkey != "":
		draw_string_outline(font, off + Vector2(5, 15), hotkey, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color.WHITE)
		draw_string(font, off + Vector2(5, 15), hotkey, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, P.TEXT)
	if count >= 0:
		var t := str(count)
		var inset := sz.x * 0.2 if round else 6.0
		var pos := off + Vector2(sz.x - inset - font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x, sz.y - inset * 0.6)
		draw_string_outline(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, Color.WHITE)
		draw_string(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, P.TEXT)
	if badge:
		var bp := off + Vector2(sz.x * 0.86, sz.y * 0.14)
		draw_circle(bp, 8.0, Color.WHITE)
		draw_circle(bp, 6.0, P.PINK_DEEP)
	if caption != "":
		var cw := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var cp := Vector2((size.x - cw) / 2.0, size.y + 13)
		draw_string_outline(font, cp, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color.WHITE)
		draw_string(font, cp, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, P.TEXT)
