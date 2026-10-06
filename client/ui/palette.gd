extends RefCounted
## สีพาสเทลและไอคอนที่ HUD ใช้ร่วมกัน (วาดด้วยโค้ด ยังไม่มีภาพจากศิลปิน)

const CREAM := Color(1.0, 0.97, 0.92, 0.94)
const LAVENDER := Color(0.74, 0.64, 0.92)
const TEXT := Color(0.42, 0.29, 0.38)
const PINK := Color(1.0, 0.74, 0.8)
const PINK_DEEP := Color(0.96, 0.52, 0.62)
const MINT := Color(0.72, 0.92, 0.82)
const SKY := Color(0.7, 0.84, 1.0)
const LEMON := Color(1.0, 0.9, 0.62)
const HP := Color(0.47, 0.84, 0.48)
const HP_LOW := Color(0.98, 0.5, 0.55)
const SP := Color(0.5, 0.7, 0.98)
const EXP := Color(1.0, 0.78, 0.4)
const OUTLINE := Color(0.42, 0.29, 0.38)
const P_TEXT_DARK := Color(0.5, 0.36, 0.62)


static func panel_style(radius: int = 18, bg: Color = CREAM, border: Color = LAVENDER) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(3)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(10)
	s.shadow_color = Color(0.4, 0.25, 0.4, 0.18)
	s.shadow_size = 4
	s.shadow_offset = Vector2(0, 3)
	s.anti_aliasing = true
	return s


static func draw_round_bar(ci: CanvasItem, rect: Rect2, ratio: float, fill: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.9)
	bg.border_color = OUTLINE
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(int(rect.size.y / 2.0))
	ci.draw_style_box(bg, rect)
	ratio = clampf(ratio, 0.0, 1.0)
	if ratio <= 0.0:
		return
	var inner := rect.grow(-2.0)
	inner.size.x = maxf(inner.size.y, inner.size.x * ratio)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(int(inner.size.y / 2.0))
	ci.draw_style_box(fg, inner)
	# แถบเงาวาวด้านบนให้ดูนุ่มเหมือนเยลลี่
	var gloss := Rect2(inner.position + Vector2(inner.size.y * 0.4, 1), Vector2(maxf(0.0, inner.size.x - inner.size.y * 0.8), inner.size.y * 0.3))
	ci.draw_rect(gloss, Color(1, 1, 1, 0.45))


## ไอคอนเล็กๆ: sword (ดาบไขว้), water (หยดน้ำมนต์), herb (ขวดยาหอม)
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> void:
	match kind:
		"sword":
			for sgn in [-1.0, 1.0]:
				var t := Transform2D(sgn * PI / 4.0, c)
				ci.draw_set_transform_matrix(t)
				var blade := PackedVector2Array([Vector2(-s * 0.09, s * 0.25), Vector2(-s * 0.09, -s * 0.5), Vector2(0, -s * 0.66), Vector2(s * 0.09, -s * 0.5), Vector2(s * 0.09, s * 0.25)])
				ci.draw_colored_polygon(blade, Color(0.93, 0.95, 1.0))
				ci.draw_polyline(blade + PackedVector2Array([blade[0]]), OUTLINE, 2.0, true)
				ci.draw_rect(Rect2(-s * 0.24, s * 0.22, s * 0.48, s * 0.1), LEMON)
				ci.draw_rect(Rect2(-s * 0.24, s * 0.22, s * 0.48, s * 0.1), OUTLINE, false, 2.0)
				ci.draw_rect(Rect2(-s * 0.06, s * 0.32, s * 0.12, s * 0.26), Color(0.8, 0.55, 0.45))
				ci.draw_circle(Vector2(0, s * 0.62), s * 0.07, LEMON)
			ci.draw_set_transform_matrix(Transform2D())
		"water":
			var drop := PackedVector2Array([c + Vector2(0, -s * 0.52)])
			for i in 21:
				var a := lerpf(-PI * 0.2, PI * 1.2, i / 20.0)
				drop.append(c + Vector2(cos(a) * s * 0.34, sin(a) * s * 0.34 + s * 0.12))
			ci.draw_colored_polygon(drop, Color(0.55, 0.78, 1.0))
			ci.draw_polyline(drop + PackedVector2Array([drop[0]]), OUTLINE, 2.0, true)
			ci.draw_circle(c + Vector2(-s * 0.12, s * 0.06), s * 0.08, Color(1, 1, 1, 0.85))
		"herb":
			var body := Rect2(c + Vector2(-s * 0.28, -s * 0.18), Vector2(s * 0.56, s * 0.62))
			var st := StyleBoxFlat.new()
			st.bg_color = Color(0.68, 0.9, 0.62)
			st.border_color = OUTLINE
			st.set_border_width_all(2)
			st.set_corner_radius_all(int(s * 0.18))
			ci.draw_style_box(st, body)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.12, -s * 0.4), Vector2(s * 0.24, s * 0.22)), Color(0.82, 0.6, 0.45))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.12, -s * 0.4), Vector2(s * 0.24, s * 0.22)), OUTLINE, false, 2.0)
			ci.draw_circle(c + Vector2(0, s * 0.14), s * 0.12, Color(1, 1, 1, 0.8))
			ci.draw_circle(c + Vector2(0, s * 0.14), s * 0.06, Color(0.5, 0.8, 0.45))
		"slash":
			var arc := PackedVector2Array()
			for i in 13:
				var a := lerpf(-2.4, -0.2, i / 12.0)
				arc.append(c + Vector2(cos(a), sin(a)) * s * 0.42 + Vector2(-s * 0.05, s * 0.18))
			ci.draw_polyline(arc, Color(1, 1, 1), s * 0.16, true)
			ci.draw_polyline(arc, Color(0.6, 0.8, 1.0), s * 0.07, true)
			draw_icon(ci, "sword_one", c + Vector2(s * 0.08, -s * 0.02), s * 0.8)
		"sword_one":
			ci.draw_set_transform_matrix(Transform2D(PI / 4.0, c))
			var blade := PackedVector2Array([Vector2(-s * 0.08, s * 0.2), Vector2(-s * 0.08, -s * 0.45), Vector2(0, -s * 0.58), Vector2(s * 0.08, -s * 0.45), Vector2(s * 0.08, s * 0.2)])
			ci.draw_colored_polygon(blade, Color(0.93, 0.95, 1.0))
			ci.draw_polyline(blade + PackedVector2Array([blade[0]]), OUTLINE, 2.0, true)
			ci.draw_rect(Rect2(-s * 0.2, s * 0.18, s * 0.4, s * 0.09), LEMON)
			ci.draw_rect(Rect2(-s * 0.05, s * 0.27, s * 0.1, s * 0.22), Color(0.8, 0.55, 0.45))
			ci.draw_set_transform_matrix(Transform2D())
		"shield":
			var pts := PackedVector2Array([c + Vector2(-s * 0.32, -s * 0.38), c + Vector2(s * 0.32, -s * 0.38), c + Vector2(s * 0.3, s * 0.05), c + Vector2(0, s * 0.45), c + Vector2(-s * 0.3, s * 0.05)])
			ci.draw_colored_polygon(pts, LEMON)
			ci.draw_polyline(pts + PackedVector2Array([pts[0]]), OUTLINE, 2.0, true)
			ci.draw_line(c + Vector2(0, -s * 0.25), c + Vector2(0, s * 0.28), PINK_DEEP, 3.0)
			ci.draw_line(c + Vector2(-s * 0.18, -s * 0.05), c + Vector2(s * 0.18, -s * 0.05), PINK_DEEP, 3.0)
		"storm":
			for k in 3:
				ci.draw_arc(c, s * (0.14 + k * 0.12), k * 1.2, k * 1.2 + PI * 1.3, 20, [Color(0.6, 0.8, 1.0), LAVENDER, Color(1, 1, 1)][k], 3.0, true)
		"star":
			var star := PackedVector2Array()
			for i in 10:
				var r := s * (0.46 if i % 2 == 0 else 0.2)
				var a := -PI / 2.0 + i * PI / 5.0
				star.append(c + Vector2(cos(a), sin(a)) * r)
			ci.draw_colored_polygon(star, LEMON)
			ci.draw_polyline(star + PackedVector2Array([star[0]]), OUTLINE, 2.0, true)
		"arrow":
			ci.draw_line(c + Vector2(-s * 0.36, s * 0.36), c + Vector2(s * 0.3, -s * 0.3), Color(0.75, 0.52, 0.36), 4.0, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.42, -s * 0.42), c + Vector2(s * 0.12, -s * 0.3), c + Vector2(s * 0.3, -s * 0.12)]), Color(0.85, 0.9, 1.0))
			for k in 2:
				var o := c + Vector2(-s * (0.24 + k * 0.1), s * (0.24 + k * 0.1))
				ci.draw_line(o, o + Vector2(-s * 0.14, 0), PINK_DEEP, 3.0)
				ci.draw_line(o, o + Vector2(0, s * 0.14), PINK_DEEP, 3.0)
		"fire":
			var flame := PackedVector2Array()
			for i in 17:
				var a := lerpf(0.0, TAU, i / 16.0)
				var r := s * (0.3 + 0.12 * maxf(0.0, -sin(a)))
				flame.append(c + Vector2(cos(a) * r * 0.85, sin(a) * r + s * 0.08 - maxf(0.0, -sin(a)) * s * 0.2))
			ci.draw_colored_polygon(flame, Color(1.0, 0.55, 0.35))
			ci.draw_polyline(flame, OUTLINE, 2.0, true)
			ci.draw_circle(c + Vector2(0, s * 0.12), s * 0.14, LEMON)
		"heal":
			ci.draw_circle(c, s * 0.36, Color(0.7, 0.95, 0.72))
			ci.draw_arc(c, s * 0.36, 0, TAU, 32, OUTLINE, 2.0, true)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.07, -s * 0.22), Vector2(s * 0.14, s * 0.44)), Color(1, 1, 1))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.22, -s * 0.07), Vector2(s * 0.44, s * 0.14)), Color(1, 1, 1))
		"crown":
			var pts := PackedVector2Array([c + Vector2(-s * 0.4, s * 0.25), c + Vector2(-s * 0.4, -s * 0.15), c + Vector2(-s * 0.2, s * 0.02), c + Vector2(0, -s * 0.35), c + Vector2(s * 0.2, s * 0.02), c + Vector2(s * 0.4, -s * 0.15), c + Vector2(s * 0.4, s * 0.25)])
			ci.draw_colored_polygon(pts, LEMON)
			ci.draw_polyline(pts + PackedVector2Array([pts[0]]), OUTLINE, 2.0, true)
		"user":
			ci.draw_circle(c + Vector2(0, -s * 0.15), s * 0.2, PINK)
			ci.draw_arc(c + Vector2(0, -s * 0.15), s * 0.2, 0, TAU, 24, OUTLINE, 2.0, true)
			ci.draw_arc(c + Vector2(0, s * 0.42), s * 0.36, PI * 1.15, PI * 1.85, 20, OUTLINE, 3.0, true)
		"book":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.32, -s * 0.3), Vector2(s * 0.64, s * 0.58)), SKY)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.32, -s * 0.3), Vector2(s * 0.64, s * 0.58)), OUTLINE, false, 2.0)
			ci.draw_line(c + Vector2(0, -s * 0.3), c + Vector2(0, s * 0.28), OUTLINE, 2.0)
		"bag":
			var st := StyleBoxFlat.new()
			st.bg_color = Color(0.95, 0.78, 0.55)
			st.border_color = OUTLINE
			st.set_border_width_all(2)
			st.set_corner_radius_all(int(s * 0.16))
			ci.draw_style_box(st, Rect2(c + Vector2(-s * 0.32, -s * 0.18), Vector2(s * 0.64, s * 0.52)))
			ci.draw_arc(c + Vector2(0, -s * 0.18), s * 0.16, PI, TAU, 16, OUTLINE, 3.0, true)
		"auto":
			# ลูกศรวนสองเส้น (เล่นอัตโนมัติ)
			for k in 2:
				var a0 := k * PI + 0.3
				ci.draw_arc(c, s * 0.3, a0, a0 + PI * 0.75, 16, P_TEXT_DARK, s * 0.1, true)
				var tip := c + Vector2(cos(a0 + PI * 0.75), sin(a0 + PI * 0.75)) * s * 0.3
				var dir := Vector2(-sin(a0 + PI * 0.75), cos(a0 + PI * 0.75))
				var side := Vector2(-dir.y, dir.x)
				ci.draw_colored_polygon(PackedVector2Array([tip + dir * s * 0.16, tip + side * s * 0.12, tip - side * s * 0.12]), P_TEXT_DARK)
			ci.draw_circle(c, s * 0.1, PINK_DEEP)
		"gear":
			var pts := PackedVector2Array()
			for i in 32:
				var a := i * TAU / 32.0
				var r := s * (0.38 if (i / 2) % 2 == 0 else 0.28)
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			ci.draw_colored_polygon(pts, Color(0.86, 0.82, 0.95))
			ci.draw_polyline(pts + PackedVector2Array([pts[0]]), OUTLINE, 2.0, true)
			ci.draw_circle(c, s * 0.12, Color.WHITE)
			ci.draw_arc(c, s * 0.12, 0, TAU, 16, OUTLINE, 2.0, true)
		"scroll":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.26, -s * 0.3), Vector2(s * 0.52, s * 0.6)), Color(1.0, 0.95, 0.8))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.26, -s * 0.3), Vector2(s * 0.52, s * 0.6)), OUTLINE, false, 2.0)
			for k in 3:
				ci.draw_line(c + Vector2(-s * 0.16, -s * 0.14 + k * s * 0.13), c + Vector2(s * 0.16, -s * 0.14 + k * s * 0.13), Color(0.7, 0.55, 0.5), 2.0)
			for y in [-0.33, 0.33]:
				ci.draw_rect(Rect2(c + Vector2(-s * 0.32, s * y - s * 0.05), Vector2(s * 0.64, s * 0.1)), Color(0.86, 0.64, 0.48))
			ci.draw_circle(c + Vector2(s * 0.2, s * 0.2), s * 0.08, PINK_DEEP)
		"coin":
			ci.draw_circle(c, s * 0.36, LEMON)
			ci.draw_arc(c, s * 0.36, 0, TAU, 24, OUTLINE, 2.0, true)
			ci.draw_arc(c, s * 0.24, 0, TAU, 20, Color(0.85, 0.6, 0.2), 2.0, true)
		_:
			pass


## ปุ่มข้อความสีพาสเทลสำหรับหน้าต่างเมนู
static func button(text: String, fill: Color = PINK, font_size: int = 15) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var st := StyleBoxFlat.new()
		st.bg_color = fill
		if state == "hover":
			st.bg_color = fill.lightened(0.15)
		elif state == "pressed":
			st.bg_color = fill.darkened(0.1)
		elif state == "disabled":
			st.bg_color = Color(0.88, 0.86, 0.88)
		elif state == "focus":
			st.draw_center = false
		st.border_color = OUTLINE
		st.set_border_width_all(2)
		st.set_corner_radius_all(12)
		st.content_margin_left = 10
		st.content_margin_right = 10
		st.content_margin_top = 3
		st.content_margin_bottom = 3
		b.add_theme_stylebox_override(state, st)
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(key, TEXT)
	b.add_theme_color_override("font_disabled_color", Color(0.6, 0.55, 0.6))
	return b


static func label(text: String, font_size: int = 15, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l
