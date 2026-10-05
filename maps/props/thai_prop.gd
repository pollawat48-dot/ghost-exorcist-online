extends Node2D
## สิ่งของในฉากธีมไทย วาดด้วยโค้ด (จุดอ้างอิงอยู่ที่ฐาน เพื่อให้ y-sort ซ้อนหน้าหลังถูกต้อง)
## จะเปลี่ยนเป็น sprite จริงเมื่อมีงานภาพ โดยใช้ kind เดิม

const WHITE := Color(0.96, 0.94, 0.89)
const GOLD := Color(0.95, 0.74, 0.22)
const RED := Color(0.7, 0.13, 0.1)
const GREEN_TRIM := Color(0.15, 0.45, 0.3)
const WOOD := Color(0.55, 0.35, 0.2)
const WOOD_DARK := Color(0.33, 0.2, 0.12)
const LEAF := Color(0.22, 0.52, 0.2)
const LEAF_LIGHT := Color(0.38, 0.68, 0.28)
const SHADOW := Color(0, 0, 0, 0.22)

## ขอบเขตที่เดินผ่านไม่ได้ (เทียบกับจุดฐาน)
const FOOTPRINTS := {
	"ubosot": Rect2(-160, -40, 320, 44),
	"chedi": Rect2(-72, -28, 144, 30),
	"ruin_chedi": Rect2(-64, -26, 128, 28),
	"sala": Rect2(-72, -20, 144, 22),
	"stilt_house": Rect2(-62, -14, 124, 16),
	"rice_hut": Rect2(-30, -10, 60, 12),
	"spirit_house": Rect2(-12, -8, 24, 10),
}
const ANIMATED := ["palm", "banana", "spirit_house", "scarecrow"]

var kind := ""
var variant := 0
var t := 0.0


func _ready() -> void:
	t = variant * 0.37
	set_process(kind in ANIMATED)


func footprint() -> Rect2:
	return FOOTPRINTS.get(kind, Rect2())


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	match kind:
		"ubosot": _draw_ubosot()
		"chedi": _draw_chedi(GOLD, false)
		"ruin_chedi": _draw_chedi(Color(0.58, 0.53, 0.47), true)
		"sala": _draw_sala()
		"stilt_house": _draw_stilt_house()
		"spirit_house": _draw_spirit_house()
		"bodhi": _draw_bodhi()
		"palm": _draw_palm()
		"banana": _draw_banana()
		"tomb": _draw_tomb()
		"lantern": _draw_lantern()
		"rice_hut": _draw_rice_hut()
		"scarecrow": _draw_scarecrow()
		"bush": _draw_bush()


# ---------- ตัวช่วยวาด ----------

func _ellipse(c: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)


func _curl(p: Vector2, dir: float, color: Color = GOLD) -> void:
	draw_polyline(PackedVector2Array([p, p + Vector2(dir * 7, -3), p + Vector2(dir * 10, -11), p + Vector2(dir * 6, -16)]), color, 3.0, true)


func _chofa(p: Vector2) -> void:
	draw_polyline(PackedVector2Array([p, p + Vector2(0, -10), p + Vector2(5, -19), p + Vector2(13, -21), p + Vector2(15, -15)]), GOLD, 4.0, true)


## หลังคาทรงไทยหนึ่งชั้น: ฐานกว้าง ยอดแคบ มีขอบทองและกระเบื้อง
func _roof(base_y: float, width: float, height: float, color: Color) -> void:
	var w := width / 2.0
	var top := w * 0.62
	var poly := PackedVector2Array([Vector2(-w, base_y), Vector2(w, base_y), Vector2(top, base_y - height), Vector2(-top, base_y - height)])
	draw_colored_polygon(poly, color)
	for i in range(1, 4):
		var yy := base_y - height * i / 4.0
		var ww := lerpf(w, top, i / 4.0)
		draw_line(Vector2(-ww, yy), Vector2(ww, yy), color.darkened(0.25), 1.5)
	draw_line(Vector2(-w, base_y), Vector2(w, base_y), GREEN_TRIM, 5.0)
	draw_line(poly[0], poly[3], GOLD, 3.0, true)
	draw_line(poly[1], poly[2], GOLD, 3.0, true)
	_curl(poly[0], -1.0)
	_curl(poly[1], 1.0)


func _gable(base_y: float, half_w: float, height: float) -> void:
	var outer := PackedVector2Array([Vector2(-half_w, base_y), Vector2(half_w, base_y), Vector2(0, base_y - height)])
	draw_colored_polygon(outer, RED.darkened(0.25))
	var inner := PackedVector2Array([Vector2(-half_w * 0.72, base_y - 6), Vector2(half_w * 0.72, base_y - 6), Vector2(0, base_y - height * 0.8)])
	draw_colored_polygon(inner, Color(0.85, 0.58, 0.15))
	draw_circle(Vector2(0, base_y - height * 0.32), half_w * 0.16, GOLD.lightened(0.25))
	draw_polyline(PackedVector2Array([Vector2(-half_w - 10, base_y + 6), Vector2(0, base_y - height - 6), Vector2(half_w + 10, base_y + 6)]), GOLD, 5.0, true)
	_chofa(Vector2(0, base_y - height - 6))
	_curl(Vector2(-half_w - 10, base_y + 6), -1.0)
	_curl(Vector2(half_w + 10, base_y + 6), 1.0)


## ใบไม้วาดเป็นสามเหลี่ยมสองชิ้น เพราะสี่เหลี่ยมที่โค้งมากอาจไขว้กันจนวาดไม่ได้
func _leaf(base: Vector2, side_a: Vector2, tip: Vector2, side_b: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([base, side_a, tip]), color)
	draw_colored_polygon(PackedVector2Array([base, tip, side_b]), color)


func _sway(amount: float) -> float:
	return sin(t * 1.3 + variant) * amount


# ---------- สิ่งปลูกสร้าง ----------

func _draw_ubosot() -> void:
	_ellipse(Vector2(0, -4), 175, 18, SHADOW)
	draw_rect(Rect2(-160, -32, 320, 32), WHITE.darkened(0.08))
	draw_rect(Rect2(-160, -32, 320, 4), WHITE)
	draw_rect(Rect2(-30, -32, 60, 32), WHITE.darkened(0.16))
	for i in 3:
		draw_line(Vector2(-30, -22 + i * 10), Vector2(30, -22 + i * 10), WHITE.darkened(0.32), 1.0)
	draw_rect(Rect2(-122, -152, 244, 120), WHITE)
	for i in 7:
		var x := -116.0 + i * 38.0
		draw_rect(Rect2(x, -152, 10, 120), Color(0.99, 0.98, 0.95))
		draw_rect(Rect2(x - 2, -154, 14, 8), GOLD)
		draw_rect(Rect2(x - 2, -38, 14, 6), GOLD)
	for x in [-92.0, -54.0, 40.0, 78.0]:
		draw_rect(Rect2(x, -120, 16, 30), GOLD)
		draw_rect(Rect2(x + 2, -118, 12, 26), RED)
	draw_rect(Rect2(-22, -114, 44, 82), GOLD)
	draw_rect(Rect2(-18, -110, 36, 78), RED)
	draw_line(Vector2(0, -110), Vector2(0, -32), GOLD, 2.0)
	draw_rect(Rect2(-122, -152, 244, 10), Color(0, 0, 0, 0.15))
	_roof(-150, 310, 64, RED)
	_roof(-206, 226, 60, Color(0.76, 0.2, 0.12))
	_gable(-208, 64, 110)


func _draw_chedi(color: Color, ruined: bool) -> void:
	_ellipse(Vector2(0, -2), 85, 12, SHADOW)
	var base := WHITE if not ruined else color.darkened(0.1)
	draw_rect(Rect2(-72, -22, 144, 22), base)
	draw_rect(Rect2(-60, -42, 120, 20), base.lightened(0.05))
	draw_rect(Rect2(-48, -60, 96, 18), base)
	var bell := PackedVector2Array([Vector2(-52, -60), Vector2(52, -60), Vector2(44, -96), Vector2(-44, -96)])
	draw_colored_polygon(bell, color)
	draw_circle(Vector2(0, -100), 44.0, color)
	draw_arc(Vector2(0, -100), 34.0, PI * 1.05, PI * 1.45, 10, color.lightened(0.35), 4.0)
	if ruined:
		# ยอดหักพัง มีรอยร้าวและเถาวัลย์
		draw_colored_polygon(PackedVector2Array([Vector2(-18, -140), Vector2(-6, -168), Vector2(4, -150), Vector2(14, -176), Vector2(20, -140)]), color.darkened(0.1))
		for c in [[Vector2(-30, -80), Vector2(-18, -110), Vector2(-24, -128)], [Vector2(20, -60), Vector2(26, -90)]]:
			draw_polyline(PackedVector2Array(c), color.darkened(0.45), 2.0)
		for i in 14:
			var a := -PI * 0.1 - i * 0.2
			draw_circle(Vector2(cos(a) * 44, -100 + sin(a) * 44 + (i % 3) * 10), 5.0, Color(0.25, 0.45, 0.2))
		for i in 4:
			draw_rect(Rect2(-90 + i * 50, -8 - (i % 2) * 4, 14, 8), color.darkened(0.2))
		return
	draw_rect(Rect2(-16, -158, 32, 16), color.darkened(0.12))
	for i in 6:
		var w := 14.0 - i * 2.0
		draw_rect(Rect2(-w, -166 - i * 10, w * 2, 8), color.darkened(0.06 * (i % 2)))
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -222), Vector2(4, -222), Vector2(0, -272)]), color)
	draw_circle(Vector2(0, -274), 3.0, color.lightened(0.4))


func _draw_sala() -> void:
	_ellipse(Vector2(0, -4), 85, 12, SHADOW)
	draw_rect(Rect2(-72, -16, 144, 16), WOOD)
	draw_rect(Rect2(-72, -16, 144, 3), WOOD.lightened(0.2))
	for x in [-62.0, -22.0, 18.0, 56.0]:
		draw_rect(Rect2(x, -86, 7, 70), Color(0.55, 0.15, 0.1))
	_roof(-84, 176, 42, RED)
	_gable(-120, 30, 44)


func _draw_stilt_house() -> void:
	var wall := WOOD.darkened(0.12 * (variant % 3))
	_ellipse(Vector2(0, -2), 74, 12, SHADOW)
	for x in [-54.0, -18.0, 18.0, 50.0]:
		draw_rect(Rect2(x - 4, -44, 8, 44), WOOD_DARK)
	draw_rect(Rect2(-64, -50, 128, 8), WOOD_DARK.lightened(0.1))
	draw_rect(Rect2(-56, -110, 112, 60), wall)
	for i in 12:
		draw_line(Vector2(-56 + i * 9.5, -110), Vector2(-56 + i * 9.5, -50), wall.darkened(0.2), 1.0)
	draw_rect(Rect2(-36, -96, 18, 22), Color(0.12, 0.08, 0.05))
	draw_rect(Rect2(16, -96, 18, 22), Color(0.12, 0.08, 0.05))
	draw_line(Vector2(62, 0), Vector2(56, -48), WOOD_DARK, 3.0)
	draw_line(Vector2(72, 0), Vector2(66, -48), WOOD_DARK, 3.0)
	for i in 5:
		var y := -8.0 - i * 9.0
		draw_line(Vector2(62 - i * 1.2, y), Vector2(72 - i * 1.2, y), WOOD_DARK, 2.0)
	var roof_c := Color(0.36, 0.22, 0.13) if variant % 2 == 0 else Color(0.6, 0.22, 0.15)
	draw_colored_polygon(PackedVector2Array([Vector2(-74, -106), Vector2(74, -106), Vector2(0, -176)]), roof_c)
	draw_colored_polygon(PackedVector2Array([Vector2(-50, -112), Vector2(50, -112), Vector2(0, -162)]), roof_c.lightened(0.12))
	draw_polyline(PackedVector2Array([Vector2(-80, -102), Vector2(0, -180), Vector2(80, -102)]), WOOD_DARK, 4.0, true)
	_curl(Vector2(-80, -102), -1.0, WOOD_DARK)
	_curl(Vector2(80, -102), 1.0, WOOD_DARK)


func _draw_spirit_house() -> void:
	_ellipse(Vector2(0, -2), 22, 6, SHADOW)
	draw_rect(Rect2(-5, -62, 10, 62), WHITE)
	draw_rect(Rect2(-24, -68, 48, 6), WHITE.darkened(0.1))
	draw_rect(Rect2(-15, -94, 30, 26), GOLD)
	draw_rect(Rect2(-6, -90, 12, 22), RED)
	draw_colored_polygon(PackedVector2Array([Vector2(-22, -94), Vector2(22, -94), Vector2(12, -108), Vector2(-12, -108)]), RED)
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -106), Vector2(12, -106), Vector2(0, -128)]), RED.darkened(0.2))
	draw_polyline(PackedVector2Array([Vector2(-14, -104), Vector2(0, -130), Vector2(14, -104)]), GOLD, 2.0, true)
	_chofa(Vector2(0, -130))
	# พวงมาลัย ของถวาย และควันธูป
	for i in 7:
		draw_circle(Vector2(-20 + i * 6.5, -66), 2.6, [Color(1, 0.85, 0.2), Color(1, 1, 1), Color(1, 0.4, 0.5)][i % 3])
	for i in 3:
		draw_rect(Rect2(-20 + i * 5, -76, 3, 8), Color(0.85, 0.1, 0.15))
	draw_line(Vector2(16, -68), Vector2(16, -80), Color(0.8, 0.3, 0.2), 1.0)
	var smoke := PackedVector2Array()
	for i in 8:
		smoke.append(Vector2(16 + sin(t * 2.0 + i * 0.8) * 3.0, -80 - i * 5))
	draw_polyline(smoke, Color(0.9, 0.9, 0.9, 0.5), 1.5, true)


func _draw_rice_hut() -> void:
	_ellipse(Vector2(0, -2), 36, 8, SHADOW)
	for x in [-26.0, 22.0]:
		draw_rect(Rect2(x, -34, 5, 34), WOOD_DARK)
	draw_rect(Rect2(-30, -38, 60, 6), WOOD)
	for x in [-26.0, 22.0]:
		draw_rect(Rect2(x, -64, 4, 26), WOOD_DARK)
	var thatch := Color(0.78, 0.64, 0.35)
	draw_colored_polygon(PackedVector2Array([Vector2(-42, -60), Vector2(42, -60), Vector2(0, -98)]), thatch)
	for i in 8:
		draw_line(Vector2(-36 + i * 10, -60), Vector2(-4 + i * 1.2, -92), thatch.darkened(0.2), 1.0)


# ---------- ต้นไม้และพืช ----------

func _draw_bodhi() -> void:
	_ellipse(Vector2(0, -4), 95, 22, SHADOW)
	draw_colored_polygon(PackedVector2Array([Vector2(-28, 0), Vector2(28, 0), Vector2(16, -120), Vector2(-16, -120)]), Color(0.45, 0.33, 0.25))
	draw_polyline(PackedVector2Array([Vector2(-28, 0), Vector2(-44, 6)]), Color(0.45, 0.33, 0.25), 6.0)
	draw_polyline(PackedVector2Array([Vector2(28, 0), Vector2(46, 4)]), Color(0.45, 0.33, 0.25), 6.0)
	# ผ้าสามสีผูกต้นไม้
	var cloth := [Color(1, 0.25, 0.45), Color(1, 0.85, 0.2), Color(0.3, 0.8, 0.35)]
	for i in 3:
		draw_rect(Rect2(-24 + i * 1.5, -58 + i * 8, 48 - i * 3, 7), cloth[i])
	for c in [[-60.0, -190.0, 62.0], [55.0, -195.0, 64.0], [0.0, -235.0, 70.0], [-30.0, -160.0, 50.0], [35.0, -160.0, 50.0]]:
		draw_circle(Vector2(c[0], c[1]), c[2], Color(0.16, 0.4, 0.17))
	for c in [[-50.0, -210.0, 34.0], [45.0, -215.0, 32.0], [0.0, -255.0, 36.0]]:
		draw_circle(Vector2(c[0], c[1]), c[2], Color(0.24, 0.52, 0.22))
	for i in 6:
		var x := -70.0 + i * 28.0
		draw_line(Vector2(x, -150), Vector2(x + 3, -110 + (i % 2) * 15), Color(0.4, 0.3, 0.22), 1.5)


func _draw_palm() -> void:
	_ellipse(Vector2(0, -2), 26, 7, SHADOW)
	var lean := (12.0 + variant % 4 * 6.0) * (1.0 if variant % 2 == 0 else -1.0)
	var top := Vector2(lean + _sway(3.0), -150 - variant % 3 * 12)
	var trunk := PackedVector2Array()
	for i in 9:
		var f := i / 8.0
		trunk.append(Vector2(top.x * f * f, top.y * f))
	draw_polyline(trunk, Color(0.5, 0.4, 0.28), 9.0, true)
	for i in range(1, 9):
		var p := trunk[i]
		draw_line(p + Vector2(-5, 0), p + Vector2(5, 0), Color(0.38, 0.3, 0.2), 1.5)
	for i in 8:
		var a := -PI / 2.0 + (i - 3.5) * 0.48 + _sway(0.06)
		var dir := Vector2(cos(a), sin(a))
		var length := 62.0 + (i % 3) * 8.0
		var tip := top + dir * length + Vector2(0, 26 + absf(dir.x) * 14.0)
		var mid := top + dir * length * 0.5 + Vector2(0, -6)
		var perp := Vector2(-dir.y, dir.x) * 7.0
		_leaf(top, mid + perp, tip, mid - perp, LEAF if i % 2 == 0 else LEAF_LIGHT)
		draw_polyline(PackedVector2Array([top, mid, tip]), LEAF.darkened(0.3), 1.0, true)
	for i in 3:
		draw_circle(top + Vector2(-6 + i * 6, 8), 5.0, Color(0.42, 0.3, 0.12))


func _draw_banana() -> void:
	_ellipse(Vector2(0, -2), 28, 7, SHADOW)
	draw_rect(Rect2(-6, -64, 12, 64), Color(0.42, 0.52, 0.22))
	draw_line(Vector2(-3, -60), Vector2(-3, 0), Color(0.32, 0.42, 0.18), 2.0)
	var top := Vector2(_sway(2.0), -62)
	for i in 6:
		var a := -PI / 2.0 + (i - 2.5) * 0.55 + _sway(0.05)
		var dir := Vector2(cos(a), sin(a))
		var length := 58.0 + (i % 2) * 14.0
		var tip := top + dir * length + Vector2(0, absf(dir.x) * 22.0)
		var mid := top + dir * length * 0.55
		var perp := Vector2(-dir.y, dir.x) * 15.0
		_leaf(top, mid + perp, tip, mid - perp * 0.6, LEAF_LIGHT if i % 2 == 0 else LEAF)
		draw_line(top, tip, LEAF_LIGHT.lightened(0.25), 1.5, true)
	if variant % 3 == 0:
		for i in 5:
			_ellipse(top + Vector2(12 + (i % 2) * 6, 10 + i * 6), 5, 3, Color(0.7, 0.8, 0.25))
		_ellipse(top + Vector2(16, 46), 6, 9, Color(0.55, 0.15, 0.3))


func _draw_bush() -> void:
	_ellipse(Vector2(0, -2), 26, 7, SHADOW)
	draw_circle(Vector2(-12, -12), 14.0, LEAF.darkened(0.1))
	draw_circle(Vector2(12, -12), 14.0, LEAF.darkened(0.1))
	draw_circle(Vector2(0, -20), 16.0, LEAF)
	draw_circle(Vector2(-4, -24), 7.0, LEAF_LIGHT)
	if variant % 2 == 0:
		for i in 4:
			draw_circle(Vector2(-14 + i * 9, -14 - (i % 2) * 10), 2.5, Color(1, 0.45, 0.6))


# ---------- ของในป่าช้า/ทุ่ง ----------

func _draw_tomb() -> void:
	var stone := Color(0.62, 0.6, 0.58).darkened(0.08 * (variant % 3))
	_ellipse(Vector2(0, -2), 26, 8, SHADOW)
	var mound := PackedVector2Array()
	for i in 11:
		var a := PI + PI * i / 10.0
		mound.append(Vector2(cos(a) * 24, -2 + sin(a) * 14))
	draw_colored_polygon(mound, Color(0.45, 0.4, 0.3))
	draw_rect(Rect2(-9, -34, 18, 26), stone)
	draw_circle(Vector2(0, -34), 9.0, stone)
	draw_line(Vector2(0, -36), Vector2(0, -14), Color(0.65, 0.12, 0.1) if variant % 2 == 0 else stone.darkened(0.4), 2.0)
	if variant % 4 == 1:
		for i in 3:
			draw_line(Vector2(12 + i * 3, -2), Vector2(12 + i * 3, -14), Color(0.8, 0.3, 0.2), 1.0)


func _draw_lantern() -> void:
	draw_rect(Rect2(-2, -64, 4, 64), WOOD_DARK)
	draw_line(Vector2(0, -62), Vector2(12, -62), WOOD_DARK, 2.0)
	draw_line(Vector2(10, -62), Vector2(10, -56), Color(0.2, 0.2, 0.2), 1.0)
	_ellipse(Vector2(10, -48), 7, 9, Color(0.92, 0.3, 0.15))
	draw_line(Vector2(3, -48), Vector2(17, -48), GOLD, 1.0)
	draw_rect(Rect2(7, -58, 6, 2), GOLD)
	draw_rect(Rect2(7, -40, 6, 2), GOLD)


func _draw_scarecrow() -> void:
	var s := _sway(2.0)
	draw_line(Vector2(0, 0), Vector2(s, -70), WOOD_DARK, 4.0)
	draw_line(Vector2(-26 + s, -52), Vector2(26 + s, -52), WOOD_DARK, 4.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-16 + s, -56), Vector2(16 + s, -56), Vector2(12 + s, -26), Vector2(-12 + s, -26)]), Color(0.3, 0.45, 0.75))
	draw_circle(Vector2(s, -68), 9.0, Color(0.85, 0.75, 0.5))
	draw_circle(Vector2(-3 + s, -69), 1.3, Color.BLACK)
	draw_circle(Vector2(3 + s, -69), 1.3, Color.BLACK)
	draw_colored_polygon(PackedVector2Array([Vector2(-18 + s, -72), Vector2(18 + s, -72), Vector2(s, -90)]), Color(0.8, 0.65, 0.3))
