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
		_:
			pass
