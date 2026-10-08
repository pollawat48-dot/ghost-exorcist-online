extends RefCounted
## สิ่งของในฉากธีมจีน (ท่าเรือ ป่าไผ่ สุสานจักรพรรดิฉิน กำแพงเมืองจีน เมืองผีเฟิงตู) แบบ low-poly พาสเทล
## thai_prop.gd ส่งชนิด (kind) ที่ตัวเองไม่รู้จักมาที่ build() ซึ่งสร้างชิ้นส่วนเป็นลูกของโหนด prop นั้นเลย
## ของที่ขยับได้ (โคมแกว่ง ใบเรือไหว เปลวไฟ ควันธูปลอย) ใส่ลงในรายการ _sway_nodes/_flames/_wisps ของ prop
## จุดอ้างอิงอยู่ที่ฐาน ด้านหน้าหันไปทาง +z (เรือสำเภาหันหัวไป +x, ท่าเรือยื่นไป +x)

const K = preload("res://maps/props/mesh_kit.gd")
const M = preload("res://maps/props/model_lib.gd")

const RED := Color(0.93, 0.4, 0.38)
const RED_DARK := Color(0.72, 0.28, 0.3)
const CREAM := Color(1.0, 0.95, 0.86)
const TEAL := Color(0.38, 0.64, 0.66)
const NAVY := Color(0.3, 0.36, 0.58)
const GOLD := Color(1.0, 0.8, 0.38)
const WOOD := Color(0.78, 0.56, 0.42)
const WOOD_DARK := Color(0.52, 0.36, 0.32)
const STONE := Color(0.8, 0.79, 0.8)
const WALL := Color(0.84, 0.77, 0.66)
const CLAY := Color(0.84, 0.6, 0.46)
const BRONZE := Color(0.46, 0.66, 0.6)
const LANTERN_RED := Color(1.0, 0.36, 0.3)
const GHOST_GLOW := Color(0.55, 1.0, 0.85)
const GHOST_ROOF := Color(0.34, 0.28, 0.42)
const ROOF_TILES := [Color(0.38, 0.64, 0.66), Color(0.5, 0.56, 0.72), Color(0.45, 0.66, 0.5), Color(0.95, 0.72, 0.4)]
const PINE_DARK := Color(0.3, 0.55, 0.45)
const PINE_LIGHT := Color(0.46, 0.7, 0.52)

## ขอบเขตที่เดินผ่านไม่ได้ (หน่วยตรรกะเกม เทียบกับจุดฐาน ไม่หมุนตาม prop)
## กำแพงเมืองจีนมีสองชนิด: great_wall วางตามแกน x, great_wall_ns วางตามแกน y ของแผนที่
const FOOTPRINTS := {
	"pagoda": Rect2(-110, -110, 220, 220),
	"chinese_house": Rect2(-88, -62, 176, 124),
	"ghost_house": Rect2(-88, -62, 176, 124),
	"cn_pavilion": Rect2(-72, -48, 144, 96),
	"cn_shrine": Rect2(-16, -14, 32, 28),
	"stone_lion": Rect2(-17, -21, 34, 42),
	"moon_gate": Rect2(-100, -10, 200, 20),
	"chinese_pine": Rect2(-12, -12, 24, 24),
	"plum_blossom": Rect2(-10, -10, 20, 20),
	"bamboo_cn": Rect2(-28, -28, 56, 56),
	"incense_burner": Rect2(-26, -26, 52, 52),
	"terracotta_statue": Rect2(-74, -22, 148, 44),
	"tomb_mound": Rect2(-88, -88, 176, 208),
	"stele": Rect2(-24, -26, 48, 52),
	"great_wall": Rect2(-128, -40, 256, 80),
	"great_wall_ns": Rect2(-40, -128, 80, 256),
	"watchtower": Rect2(-80, -80, 160, 160),
	"market_stall": Rect2(-44, -20, 88, 48),
	"taihu_rock": Rect2(-20, -20, 40, 40),
	"karst_peak": Rect2(-100, -100, 200, 200),
	"fish_rack": Rect2(-40, -8, 80, 16),
	"paper_offerings": Rect2(-18, -18, 36, 36),
}

static var _meshes := {}


## สร้างของชนิด kind ลงใน p (โหนด thai_prop) คืนค่า true ถ้ามีชิ้นที่ต้องขยับทุกเฟรม
static func build(p: Node3D, kind: String, v: int) -> bool:
	match kind:
		"pagoda": _pagoda(p, v)
		"paifang": _paifang(p, v)
		"chinese_house": _house(p, v, false)
		"ghost_house": _house(p, v, true)
		"cn_pavilion": _pavilion(p, v)
		"cn_shrine": _shrine(p, v)
		"red_lantern": _post_lantern(p, v, false)
		"ghost_lantern": _post_lantern(p, v, true)
		"lantern_string": _lantern_string(p, v)
		"stone_lion": _stone_lion(p, v)
		"moon_gate": _moon_gate(p, v)
		"chinese_pine": _chinese_pine(p, v)
		"plum_blossom": _plum_blossom(p, v)
		"bamboo_cn": _bamboo_grove(p, v)
		"junk_boat": _junk(p, v)
		"dock": _dock(p, v)
		"incense_burner": _ding(p, v)
		"terracotta_statue": _terracotta_row(p, v)
		"tomb_mound": _tomb_mound(p, v)
		"stele": _stele(p, v)
		"great_wall": _great_wall(p, v)
		"great_wall_ns":
			var turned := Node3D.new()
			turned.rotation.y = PI / 2.0
			p.add_child(turned)
			_great_wall(turned, v)
		"watchtower": _watchtower(p, v)
		"pass_gate": _pass_gate(p, v)
		"fengdu_gate": _fengdu_gate(p, v)
		"spirit_bridge": _bridge(p, v, true)
		"arch_bridge": _bridge(p, v, false)
		"paper_offerings": _offerings(p, v)
		"market_stall": _market_stall(p, v)
		"taihu_rock": _taihu_rock(p, v)
		"karst_peak": _karst_peak(p, v)
		"fish_rack": _fish_rack(p, v)
		"spider_lily": _spider_lily(p, v)
		_:
			return false
	return not (_list(p, "_sway_nodes").is_empty() and _list(p, "_flames").is_empty() and _list(p, "_wisps").is_empty())


static func footprint(kind: String) -> Rect2:
	return FOOTPRINTS.get(kind, Rect2())


# ---------- ตัวช่วย ----------

static func _list(p: Node3D, name: String) -> Array:
	return p.get(name)


static func _sway(p: Node3D, n: Node3D) -> void:
	_list(p, "_sway_nodes").append(n)


static func _flame(p: Node3D, n: Node3D) -> void:
	_list(p, "_flames").append(n)


static func _wisp(p: Node3D, n: Node3D) -> void:
	_list(p, "_wisps").append(n)
	_list(p, "_wisp_base").append(n.position.y)


static func _light(p: Node3D, pos: Vector3, color: Color, energy: float, light_range: float) -> void:
	p.call("_night_light", pos, color, energy, light_range)


## หลังคาปั้นหยา (hip roof): ฐานกว้าง w (แกน x) ลึก d (แกน z) สูง h สันหลังคาวิ่งตามด้านยาว
static func hip(parent: Node3D, w: float, d: float, h: float, pos: Vector3, material: Variant) -> MeshInstance3D:
	var swap := d > w
	var ww := d if swap else w
	var dd := w if swap else d
	var key := "hip%s|%s|%s" % [ww, dd, h]
	if not _meshes.has(key):
		var hw := ww / 2.0
		var hd := dd / 2.0
		var r := maxf((ww - dd) / 2.0, 0.01)
		var b0 := Vector3(-hw, 0, -hd)
		var b1 := Vector3(hw, 0, -hd)
		var b2 := Vector3(hw, 0, hd)
		var b3 := Vector3(-hw, 0, hd)
		var t0 := Vector3(-r, h, 0)
		var t1 := Vector3(r, h, 0)
		var faces: Array[PackedVector3Array] = [
			PackedVector3Array([b0, b1, b2, b3]), PackedVector3Array([b3, b2, t1, t0]),
			PackedVector3Array([b0, b1, t1, t0]), PackedVector3Array([b0, b3, t0]), PackedVector3Array([b1, b2, t1]),
		]
		_meshes[key] = K.convex_mesh(faces)
	return K.add(parent, _meshes[key], pos, material, Vector3(0, PI / 2.0 if swap else 0.0, 0))


## หลังคาจีน: ชายคาแผ่กว้างลาดน้อย + หลังคาทรงสูง สันหลังคามีหางม้วน มุมชายคางอนขึ้นทั้งสี่มุม
static func _cn_roof(n: Node3D, at: Vector3, w: float, d: float, h: float, col: Color, tip: Color = GOLD, fascia: Color = RED_DARK) -> void:
	var s := clampf(minf(w, d) / 3.0, 0.35, 1.0)
	var flare := clampf(minf(w, d) * 0.18, 0.14, 0.6)
	var sw := w + flare * 2.0
	var sd := d + flare * 2.0
	K.box(n, Vector3(sw - 0.12, 0.12, sd - 0.12), at + Vector3(0, -0.05, 0), K.mat(fascia))
	hip(n, sw, sd, h * 0.3, at, K.mat(col.lightened(0.1)))
	var wm := w * 0.94
	var dm := d * 0.94
	hip(n, wm, dm, h, at + Vector3(0, h * 0.15, 0), K.mat(col))
	var dark := K.mat(col.darkened(0.3))
	var ridge := absf(wm - dm) + 0.25
	var top := at + Vector3(0, h * 1.15 + 0.03, 0)
	var along := Vector3(1, 0, 0) if wm >= dm else Vector3(0, 0, 1)
	K.box(n, Vector3(ridge, 0.14 * s + 0.06, 0.16 * s + 0.04) if wm >= dm else Vector3(0.16 * s + 0.04, 0.14 * s + 0.06, ridge), top, dark)
	for side in [-1.0, 1.0]:
		var e: Vector3 = top + along * side * ridge / 2.0
		K.beam(n, e, e + along * side * 0.2 * s + Vector3(0, 0.4 * s, 0), 0.13 * s, dark)
		K.sphere(n, 0.08 * s, e + along * side * 0.24 * s + Vector3(0, 0.44 * s, 0), K.mat(tip), 6)
	var curl := K.mat(col.darkened(0.12))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var c := at + Vector3(sx * sw / 2.0, 0.04, sz * sd / 2.0)
			var out := Vector3(sx, 0, sz).normalized()
			var tip_pos := c + out * 0.22 * s + Vector3(0, 0.45 * s, 0)
			K.beam(n, c - out * 0.6 * s + Vector3(0, 0.08, 0), tip_pos, 0.14 * s, curl)
			K.sphere(n, 0.07 * s + 0.02, tip_pos, K.mat(tip), 6)


## โคมกระดาษแขวน (จุด top = ปลายเชือก) แกว่งตามลม คืนค่าโหนดหมุน
static func _hang_lantern(p: Node3D, parent: Node3D, top: Vector3, s: float, col: Color, glow: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = top
	parent.add_child(pivot)
	K.cyl(pivot, 0.012, 0.012, 0.22 * s, Vector3(0, -0.11 * s, 0), K.mat(GOLD), 4)
	K.cyl(pivot, 0.1 * s, 0.13 * s, 0.07 * s, Vector3(0, -0.25 * s, 0), K.gold(), 8)
	K.sphere(pivot, 0.25 * s, Vector3(0, -0.5 * s, 0), K.mat(col, glow, 0.6), 12, Vector3(1, 0.88, 1))
	var band := TorusMesh.new()
	band.inner_radius = 0.235 * s
	band.outer_radius = 0.265 * s
	band.rings = 12
	band.ring_segments = 4
	K.add(pivot, band, Vector3(0, -0.5 * s, 0), K.mat(col.darkened(0.2), glow * 0.5, 0.6))
	K.cyl(pivot, 0.13 * s, 0.1 * s, 0.07 * s, Vector3(0, -0.75 * s, 0), K.gold(), 8)
	K.cyl(pivot, 0.025 * s, 0.05 * s, 0.24 * s, Vector3(0, -0.9 * s, 0), K.mat(col.darkened(0.1) if col.r > col.g else GOLD), 6)
	_sway(p, pivot)
	return pivot


## ลูกไฟผีลอยขึ้นลง (ใช้ในเมืองผีและสุสาน)
static func _ghost_wisp(p: Node3D, pos: Vector3, col: Color) -> void:
	var w := Node3D.new()
	w.position = pos
	p.add_child(w)
	K.sphere(w, 0.1, Vector3.ZERO, K.mat(col, 3.0, 0.5, 0.0, false), 8)
	K.sphere(w, 0.2, Vector3.ZERO, K.mat(Color(col, 0.3), 1.5, 0.5, 0.0, false), 8)
	_wisp(p, w)


static func _rot_y(v: Vector3, a: float) -> Vector3:
	return v.rotated(Vector3.UP, a)


# ---------- สิ่งปลูกสร้าง ----------

## เจดีย์จีนแปดเหลี่ยมห้าชั้น: ผนังครีม เสาแดง หลังคาเคลือบชายคางอน แขวนกระดิ่งทอง ยอดฉัตรทอง
static func _pagoda(p: Node3D, v: int) -> void:
	var stone := K.mat(STONE)
	var tile_c: Color = ROOF_TILES[v % 3]
	K.cyl(p, 3.3, 3.5, 0.5, Vector3(0, 0.25, 0), stone, 8)
	K.cyl(p, 2.9, 3.0, 0.35, Vector3(0, 0.67, 0), K.mat(STONE.lightened(0.06)), 8)
	for i in 3:
		K.box(p, Vector3(1.4, 0.28, 0.4), Vector3(0, 0.14 + i * 0.28, 3.65 - i * 0.35), stone)
	var door_mat := K.mat(Color(0.42, 0.3, 0.38))
	var y := 0.85
	for i in 5:
		var r := 2.2 - i * 0.3
		var bh := 1.5 - i * 0.1
		K.cyl(p, r, r, bh, Vector3(0, y + bh / 2.0, 0), K.mat(CREAM if i % 2 == 0 else Color(1.0, 0.88, 0.84)), 8)
		for k in 8:
			var a := k * TAU / 8.0
			K.cyl(p, 0.09, 0.09, bh, Vector3(sin(a) * r, y + bh / 2.0, cos(a) * r), K.mat(RED), 6)
		for k in 4:
			var a := k * TAU / 4.0 + TAU / 16.0
			var face := Vector3(sin(a), 0, cos(a)) * r * 0.93
			K.box(p, Vector3(0.55, bh * 0.5, 0.1), face + Vector3(0, y + bh * 0.4, 0), door_mat, Vector3(0, a, 0))
			K.cyl(p, 0.275, 0.275, 0.1, face + Vector3(0, y + bh * 0.65, 0), door_mat, 10, Vector3(PI / 2.0, a, 0))
		K.cyl(p, r + 0.3, r + 0.05, 0.22, Vector3(0, y + bh + 0.04, 0), K.mat(RED_DARK), 8)
		var rr := r + 1.0
		K.cyl(p, r * 0.55, rr, 0.55, Vector3(0, y + bh + 0.42, 0), K.mat(tile_c), 8)
		var curl := K.mat(tile_c.darkened(0.15))
		for k in 8:
			var a := k * TAU / 8.0
			var dir := Vector3(sin(a), 0, cos(a))
			var c := dir * rr + Vector3(0, y + bh + 0.16, 0)
			K.beam(p, c - dir * 0.5 + Vector3(0, 0.15, 0), c + dir * 0.2 + Vector3(0, 0.42, 0), 0.13, curl)
			K.sphere(p, 0.07, c + dir * 0.22 + Vector3(0, 0.46, 0), K.gold(), 6)
			if k % 2 == 1:
				K.cyl(p, 0.01, 0.01, 0.25, c + Vector3(0, -0.05, 0), K.gold(), 4)
				K.sphere(p, 0.07, c + Vector3(0, -0.2, 0), K.gold(), 6, Vector3(1, 1.3, 1))
		y += bh + 0.7
	K.cyl(p, 0.3, 0.45, 0.4, Vector3(0, y, 0), K.gold(), 8)
	for i in 5:
		K.cyl(p, 0.22 - i * 0.03, 0.22 - i * 0.03, 0.08, Vector3(0, y + 0.35 + i * 0.22, 0), K.gold(), 10)
	K.cyl(p, 0.04, 0.05, 1.4, Vector3(0, y + 0.9, 0), K.gold(), 6)
	K.sphere(p, 0.18, Vector3(0, y + 1.7, 0), K.gold(), 10)
	for x in [-1.25, 1.25]:
		_hang_lantern(p, p, Vector3(x, 2.25, 2.55), 1.0, LANTERN_RED, 0.7)
	_light(p, Vector3(0, 2.0, 3.2), Color(1, 0.6, 0.38), 1.8, 9.0)


## ซุ้มประตูไผฟาง: เสาแดงสี่ต้น คานเขียวขอบทอง ป้ายกลาง หลังคาสามยอด (กลางสูงสุด)
static func _paifang(p: Node3D, v: int) -> void:
	var red := K.mat(RED)
	var stone := K.mat(STONE)
	var tile_c: Color = ROOF_TILES[v % ROOF_TILES.size()]
	for x in [-3.0, -1.3, 1.3, 3.0]:
		var h := 5.0 if absf(x) < 2.0 else 3.9
		K.box(p, Vector3(0.7, 0.55, 0.7), Vector3(x, 0.27, 0), stone)
		K.box(p, Vector3(0.36, 0.9, 1.3), Vector3(x, 0.45, 0), stone)
		K.cyl(p, 0.2, 0.22, h, Vector3(x, h / 2.0, 0), red, 10)
	K.box(p, Vector3(3.2, 0.36, 0.36), Vector3(0, 4.25, 0), K.mat(TEAL))
	K.box(p, Vector3(3.0, 0.1, 0.4), Vector3(0, 4.25, 0), K.gold())
	K.box(p, Vector3(2.8, 0.3, 0.3), Vector3(0, 3.45, 0), K.mat(RED_DARK))
	for z in [0.19, -0.19]:
		K.box(p, Vector3(1.3, 0.62, 0.1), Vector3(0, 3.85, z), K.gold())
		K.box(p, Vector3(1.1, 0.46, 0.12), Vector3(0, 3.85, z), K.mat(NAVY))
		for i in 3:
			K.box(p, Vector3(0.12, 0.26, 0.13), Vector3(-0.3 + i * 0.3, 3.85, z), K.gold())
	for side in [-1.0, 1.0]:
		K.box(p, Vector3(1.8, 0.3, 0.3), Vector3(side * 2.15, 3.35, 0), K.mat(TEAL))
		K.box(p, Vector3(1.6, 0.24, 0.26), Vector3(side * 2.15, 2.85, 0), K.mat(RED_DARK))
		_cn_roof(p, Vector3(side * 2.15, 3.55, 0), 2.0, 0.8, 0.6, tile_c)
	_cn_roof(p, Vector3(0, 4.45, 0), 3.2, 0.9, 0.8, tile_c)
	for x in [-0.75, 0.75]:
		_hang_lantern(p, p, Vector3(x, 3.3, 0), 0.9, LANTERN_RED, 0.7)
	_light(p, Vector3(0, 2.6, 0.6), Color(1, 0.55, 0.35), 1.6, 7.0)


## บ้านจีน: ฐานหิน เสาแดงหน้าบ้าน ประตูแดง หน้าต่างลายตาราง หลังคากระเบื้องชายคางอน โคมแดงสองดวง
## dark = บ้านในเมืองผี (ผนังม่วงหม่น หลังคาดำ โคมผีสีเขียว)
static func _house(p: Node3D, v: int, dark: bool) -> void:
	var walls := [CREAM, Color(1.0, 0.9, 0.84), Color(0.95, 0.93, 0.84)]
	var wall_c: Color = Color(0.6, 0.54, 0.66) if dark else walls[v % 3]
	var pillar := K.mat(Color(0.5, 0.26, 0.34) if dark else RED)
	var roof_c: Color = GHOST_ROOF if dark else ROOF_TILES[(v / 3) % ROOF_TILES.size()]
	var trim := K.mat(Color(0.3, 0.24, 0.32) if dark else WOOD_DARK)
	K.box(p, Vector3(5.4, 0.45, 3.8), Vector3(0, 0.22, 0), K.mat(STONE.darkened(0.35) if dark else STONE))
	K.box(p, Vector3(1.4, 0.22, 0.4), Vector3(0, 0.11, 2.05), K.mat(STONE.darkened(0.4) if dark else STONE.darkened(0.08)))
	K.box(p, Vector3(4.4, 2.3, 2.6), Vector3(0, 1.6, -0.3), K.mat(wall_c))
	for x in [-2.2, 2.2]:
		K.box(p, Vector3(0.16, 2.3, 0.16), Vector3(x, 1.6, 1.0), trim)
	K.box(p, Vector3(4.5, 0.16, 0.12), Vector3(0, 0.55, 1.0), trim)
	for x in [-2.3, -0.8, 0.8, 2.3]:
		K.cyl(p, 0.11, 0.12, 2.5, Vector3(x, 1.7, 1.5), pillar, 8)
	K.box(p, Vector3(4.9, 0.24, 0.26), Vector3(0, 2.85, 1.5), pillar)
	K.box(p, Vector3(4.9, 0.14, 0.28), Vector3(0, 2.62, 1.5), K.mat(Color(0.3, 0.4, 0.4) if dark else TEAL))
	# ประตูบานคู่ ห่วงทอง
	K.box(p, Vector3(1.2, 1.9, 0.08), Vector3(0, 1.4, 1.0), trim)
	K.box(p, Vector3(1.04, 1.78, 0.1), Vector3(0, 1.36, 1.0), K.mat(Color(0.35, 0.22, 0.3) if dark else RED_DARK))
	K.box(p, Vector3(0.03, 1.78, 0.12), Vector3(0, 1.36, 1.0), trim)
	for x in [-0.14, 0.14]:
		K.sphere(p, 0.05, Vector3(x, 1.35, 1.07), K.gold(), 6)
	K.box(p, Vector3(1.3, 0.38, 0.06), Vector3(0, 2.5, 1.04), K.gold())
	K.box(p, Vector3(1.14, 0.26, 0.08), Vector3(0, 2.5, 1.04), K.mat(Color(0.18, 0.14, 0.2) if dark else NAVY))
	# หน้าต่างลายตาราง
	var glass := K.mat(Color(0.55, 1.0, 0.8) if dark else Color(1.0, 0.86, 0.6), 0.8 if dark else 0.15, 0.6)
	var lattice := K.mat(Color(0.32, 0.26, 0.34) if dark else Color(0.62, 0.36, 0.32))
	for x in [-1.45, 1.45]:
		K.box(p, Vector3(1.0, 0.9, 0.06), Vector3(x, 1.65, 1.0), lattice)
		K.box(p, Vector3(0.84, 0.74, 0.07), Vector3(x, 1.65, 1.0), glass)
		for k in 3:
			K.box(p, Vector3(0.04, 0.74, 0.09), Vector3(x - 0.21 + k * 0.21, 1.65, 1.0), lattice)
			K.box(p, Vector3(0.84, 0.04, 0.09), Vector3(x, 1.47 + k * 0.18, 1.0), lattice)
	_cn_roof(p, Vector3(0, 2.97, -0.12), 4.9, 3.5, 1.4, roof_c, GHOST_GLOW if dark else GOLD)
	var lantern_c := GHOST_GLOW if dark else LANTERN_RED
	for x in [-1.55, 1.55]:
		_hang_lantern(p, p, Vector3(x, 2.73, 1.6), 0.85, lantern_c, 1.6 if dark else 0.7)
	if dark:
		_light(p, Vector3(0, 2.0, 2.2), Color(0.5, 1.0, 0.8), 1.4, 6.5)
	else:
		_light(p, Vector3(0, 2.0, 2.2), Color(1, 0.6, 0.38), 1.3, 6.5)
		if v % 2 == 0:
			K.cyl(p, 0.24, 0.18, 0.4, Vector3(-2.75, 0.2, 1.7), K.mat(Color(0.55, 0.72, 0.85)), 10)
			K.sphere(p, 0.36, Vector3(-2.75, 0.62, 1.7), K.mat(Color(0.45, 0.72, 0.45)), 8)
		else:
			K.cyl(p, 0.26, 0.3, 0.55, Vector3(2.8, 0.28, 1.6), K.mat(Color(0.6, 0.42, 0.36)), 10)
			K.cyl(p, 0.24, 0.24, 0.05, Vector3(2.8, 0.56, 1.6), K.mat(WOOD), 10)


## ศาลาจีน (เก๋งจีน) ในแคมป์: เสาแดงหกต้น ม้านั่ง โต๊ะหินกลางศาลา
static func _pavilion(p: Node3D, v: int) -> void:
	var stone := K.mat(STONE)
	var red := K.mat(RED)
	K.box(p, Vector3(4.4, 0.45, 3.0), Vector3(0, 0.22, 0), stone)
	K.box(p, Vector3(1.3, 0.22, 0.4), Vector3(0, 0.11, 1.65), stone)
	for x in [-1.8, 0.0, 1.8]:
		for z in [-1.15, 1.15]:
			if x == 0.0 and z > 0.0:
				continue
			K.cyl(p, 0.11, 0.12, 2.6, Vector3(x, 1.75, z), red, 8)
	for z in [-1.15, 1.15]:
		K.box(p, Vector3(3.9, 0.22, 0.22), Vector3(0, 3.0, z), K.mat(TEAL))
		K.box(p, Vector3(3.9, 0.08, 0.24), Vector3(0, 2.86, z), K.gold())
	for x in [-1.8, 1.8]:
		K.box(p, Vector3(0.22, 0.22, 2.5), Vector3(x, 3.0, 0), K.mat(TEAL))
	# ม้านั่งริมศาลา
	K.box(p, Vector3(3.4, 0.08, 0.4), Vector3(0, 0.85, -1.0), K.mat(WOOD))
	for x in [-1.6, 1.6]:
		K.box(p, Vector3(0.4, 0.08, 2.0), Vector3(x, 0.85, 0), K.mat(WOOD))
	K.cyl(p, 0.45, 0.32, 0.6, Vector3(0, 0.75, 0), stone, 12)
	for i in 3:
		K.cyl(p, 0.06, 0.07, 0.1, Vector3(-0.15 + i * 0.15, 1.1, 0), K.mat(Color(0.95, 0.95, 1.0)), 8)
	_cn_roof(p, Vector3(0, 3.1, 0), 4.2, 2.9, 1.4, ROOF_TILES[v % 3])
	for x in [-1.8, 1.8]:
		_hang_lantern(p, p, Vector3(x, 2.88, 1.3), 0.8, LANTERN_RED, 0.7)
	_light(p, Vector3(0, 2.4, 0.8), Color(1, 0.6, 0.38), 1.4, 7.0)


## ศาลเจ้าที่ (ถู่ตี้กง) ขนาดเล็ก มีกระถางธูปและเทียนแดง
static func _shrine(p: Node3D, v: int) -> void:
	K.box(p, Vector3(0.95, 0.55, 0.75), Vector3(0, 0.27, 0), K.mat(STONE))
	K.box(p, Vector3(0.7, 0.55, 0.5), Vector3(0, 0.82, -0.05), K.mat(RED))
	K.box(p, Vector3(0.42, 0.4, 0.04), Vector3(0, 0.8, 0.21), K.mat(Color(0.3, 0.2, 0.26)))
	K.sphere(p, 0.1, Vector3(0, 0.82, 0.12), K.gold(), 8, Vector3(1, 1.2, 1))
	K.sphere(p, 0.06, Vector3(0, 0.97, 0.12), K.mat(Color(1.0, 0.88, 0.75)), 6)
	_cn_roof(p, Vector3(0, 1.1, -0.05), 0.75, 0.55, 0.3, ROOF_TILES[v % 3])
	K.cyl(p, 0.1, 0.08, 0.12, Vector3(0, 0.6, 0.28), K.mat(BRONZE), 8)
	for i in 3:
		K.cyl(p, 0.008, 0.008, 0.2, Vector3(-0.03 + i * 0.03, 0.76, 0.28), K.mat(Color(0.85, 0.3, 0.25)), 4)
	for x in [-0.32, 0.32]:
		K.cyl(p, 0.03, 0.03, 0.16, Vector3(x, 0.63, 0.25), K.mat(RED), 6)
		K.sphere(p, 0.025, Vector3(x, 0.74, 0.25), K.mat(Color(1.0, 0.8, 0.4), 3.0, 0.5, 0.0, false), 4, Vector3(1, 1.6, 1))
	_light(p, Vector3(0, 0.9, 0.5), Color(1, 0.55, 0.35), 0.9, 3.5)


## เสาโคม: โคมแดง (หรือโคมผีสีเขียวฟ้าเรืองแสงในเมืองผี) แขวนจากคานไม้
static func _post_lantern(p: Node3D, v: int, ghost: bool) -> void:
	var post := K.mat(Color(0.3, 0.24, 0.34) if ghost else RED_DARK)
	var two := v % 2 == 0
	K.box(p, Vector3(0.35, 0.25, 0.35), Vector3(0, 0.12, 0), K.mat(STONE.darkened(0.3) if ghost else STONE))
	K.cyl(p, 0.06, 0.07, 2.6, Vector3(0, 1.3, 0), post, 8)
	var arm := 0.65
	K.box(p, Vector3(arm * 2.0 + 0.1 if two else arm + 0.1, 0.08, 0.08), Vector3(0.0 if two else arm / 2.0, 2.5, 0), post)
	var col := (Color(0.6, 0.8, 1.0) if v % 3 == 0 else GHOST_GLOW) if ghost else LANTERN_RED
	var xs := [-arm + 0.05, arm - 0.05] if two else [arm - 0.05]
	for x in xs:
		K.sphere(p, 0.05, Vector3(x + signf(x) * 0.06, 2.53, 0), K.gold() if not ghost else K.mat(col, 1.0), 6)
		_hang_lantern(p, p, Vector3(x, 2.46, 0), 1.0, col, 1.8 if ghost else 0.8)
	K.sphere(p, 0.08, Vector3(0, 2.66, 0), K.gold() if not ghost else K.mat(col, 1.0), 8)
	if ghost:
		_ghost_wisp(p, Vector3(0.3, 3.0 + (v % 3) * 0.2, 0.2), col)
		_light(p, Vector3(0.0 if two else arm, 1.9, 0.3), col, 1.8, 6.5)
	else:
		_light(p, Vector3(0.0 if two else arm, 1.9, 0.3), Color(1.0, 0.5, 0.35), 1.8, 6.5)


## สายโคมแดงขึงระหว่างเสาสองต้น (ยาวตามแกน x) ใช้ขึงข้ามถนน
static func _lantern_string(p: Node3D, v: int) -> void:
	var post := K.mat(RED_DARK)
	var half := 2.7
	for x in [-half, half]:
		K.box(p, Vector3(0.3, 0.2, 0.3), Vector3(x, 0.1, 0), K.mat(STONE))
		K.cyl(p, 0.06, 0.07, 3.3, Vector3(x, 1.65, 0), post, 8)
		K.sphere(p, 0.09, Vector3(x, 3.35, 0), K.gold(), 8)
	var cols := [LANTERN_RED, Color(1.0, 0.55, 0.4), LANTERN_RED, Color(1.0, 0.75, 0.4), LANTERN_RED]
	var prev := Vector3(-half, 3.2, 0)
	for i in 7:
		var x := -half + (i + 1) * (half * 2.0) / 8.0
		var sag := 0.55 * (1.0 - pow(x / half, 2.0))
		var pt := Vector3(x, 3.2 - sag, 0)
		K.beam(p, prev, pt, 0.025, K.mat(Color(0.5, 0.3, 0.3)))
		prev = pt
		if i % 2 == 0 or i == 3:
			_hang_lantern(p, p, pt, 0.75, cols[(i + v) % cols.size()], 0.8)
		else:
			K.box(p, Vector3(0.18, 0.18, 0.02), pt + Vector3(0, -0.12, 0), K.mat([Color(0.75, 0.88, 1.0), Color(1.0, 0.85, 0.5), Color(0.8, 1.0, 0.8)][(i + v) % 3]), Vector3(0, 0, PI / 4.0))
	K.beam(p, prev, Vector3(half, 3.2, 0), 0.025, K.mat(Color(0.5, 0.3, 0.3)))
	_light(p, Vector3(0, 2.4, 0), Color(1.0, 0.5, 0.35), 1.6, 6.5)


## สิงโตหินเฝ้าประตู: แผงคอขดเป็นก้อน ตาโต ใต้อุ้งเท้ามีลูกแก้ว (หรือลูกสิงโต)
static func _stone_lion(p: Node3D, v: int) -> void:
	var st := K.mat(Color(0.82, 0.81, 0.86))
	var dark := K.mat(Color(0.66, 0.64, 0.72))
	K.box(p, Vector3(0.95, 0.7, 1.25), Vector3(0, 0.35, 0), K.mat(Color(0.72, 0.7, 0.75)))
	K.box(p, Vector3(1.05, 0.1, 1.35), Vector3(0, 0.74, 0), dark)
	K.sphere(p, 0.38, Vector3(0, 1.08, -0.22), st, 12, Vector3(1.1, 0.85, 1.1))
	K.sphere(p, 0.3, Vector3(0, 1.3, 0.1), st, 12, Vector3(1.0, 1.25, 0.9))
	for x in [-0.2, 0.2]:
		K.cyl(p, 0.09, 0.1, 0.5, Vector3(x, 1.03, 0.33), st, 8)
		K.sphere(p, 0.12, Vector3(x, 0.83, 0.42), st, 8, Vector3(1, 0.7, 1.2))
	K.sphere(p, 0.38, Vector3(0, 1.78, 0.22), st, 14)
	for i in 11:
		var a := PI * 1.1 * (float(i) / 10.0) - PI * 0.05
		K.sphere(p, 0.14, Vector3(cos(a) * 0.38, 1.78 + sin(a) * 0.36, 0.06), dark, 8)
	for i in 4:
		K.sphere(p, 0.11, Vector3(-0.15 + (i % 2) * 0.3, 1.45 - (i / 2) * 0.15, 0.36), dark, 6)
	for x in [-0.14, 0.14]:
		K.sphere(p, 0.08, Vector3(x, 1.86, 0.55), K.mat(Color(0.95, 0.95, 0.98)), 8)
		K.sphere(p, 0.04, Vector3(x, 1.86, 0.62), K.mat(Color(0.3, 0.26, 0.32)), 6)
	K.sphere(p, 0.08, Vector3(0, 1.74, 0.62), dark, 8, Vector3(1.3, 0.9, 1))
	K.box(p, Vector3(0.24, 0.05, 0.04), Vector3(0, 1.6, 0.58), K.mat(Color(0.5, 0.42, 0.5)))
	K.sphere(p, 0.15, Vector3(0, 1.2, -0.62), dark, 8)
	if v % 2 == 0:
		K.sphere(p, 0.17, Vector3(0.33, 0.95, 0.45), K.mat(Color(0.88, 0.86, 0.92)), 10)
		var ring := TorusMesh.new()
		ring.inner_radius = 0.15
		ring.outer_radius = 0.18
		K.add(p, ring, Vector3(0.33, 0.95, 0.45), dark, Vector3(PI / 2.0, 0, 0.4))
	else:
		K.sphere(p, 0.15, Vector3(-0.32, 0.9, 0.45), st, 8)
		K.sphere(p, 0.11, Vector3(-0.32, 1.08, 0.52), st, 8)


## กำแพงขาวหลังคากระเบื้อง มีประตูวงพระจันทร์ (ยาว 6 เมตรตามแกน x)
static func _moon_gate(p: Node3D, v: int) -> void:
	var wall := K.mat(Color(0.98, 0.96, 0.94))
	var r := 1.15
	var cy := 1.3
	var top := 2.6
	K.box(p, Vector3(6.2, 0.2, 0.5), Vector3(0, 0.1, 0), K.mat(STONE.darkened(0.08)))
	for side in [-1.0, 1.0]:
		K.box(p, Vector3(3.1 - r, top, 0.4), Vector3(side * (r + (3.1 - r) / 2.0), top / 2.0, 0), wall)
	var strips := 10
	for i in strips:
		var x := -r + (i + 0.5) * (2.0 * r / strips)
		var dy := sqrt(maxf(r * r - x * x, 0.0))
		var up := cy + dy
		K.box(p, Vector3(2.0 * r / strips + 0.01, top - up, 0.4), Vector3(x, (top + up) / 2.0, 0), wall)
		var low := cy - dy
		if low > 0.02:
			K.box(p, Vector3(2.0 * r / strips + 0.01, low, 0.4), Vector3(x, low / 2.0, 0), wall)
	var ring := TorusMesh.new()
	ring.inner_radius = r - 0.02
	ring.outer_radius = r + 0.14
	ring.rings = 24
	ring.ring_segments = 6
	K.add(p, ring, Vector3(0, cy, 0), K.mat(Color(0.62, 0.66, 0.74)), Vector3(PI / 2.0, 0, 0), Vector3(1, 1.8, 1))
	K.box(p, Vector3(6.3, 0.12, 0.6), Vector3(0, top + 0.03, 0), K.mat(Color(0.55, 0.58, 0.68)))
	hip(p, 6.4, 0.85, 0.35, Vector3(0, top + 0.08, 0), K.mat(Color(0.5, 0.54, 0.66)))
	# หน้าต่างลายดอกไม้สองข้าง
	for side in [-1.0, 1.0]:
		K.cyl(p, 0.32, 0.32, 0.42, Vector3(side * 2.1, 1.6, 0), K.mat(Color(0.62, 0.66, 0.74)), 8, Vector3(PI / 2.0, 0, 0))
		K.cyl(p, 0.24, 0.24, 0.44, Vector3(side * 2.1, 1.6, 0), K.mat(Color(0.42, 0.62, 0.5)), 8, Vector3(PI / 2.0, 0, 0))
	if v % 2 == 0:
		for i in 3:
			K.sphere(p, 0.3 - i * 0.05, Vector3(-2.6 + i * 0.35, top + 0.25, 0.25), K.mat(Color(0.5, 0.74, 0.48)), 8)


# ---------- ต้นไม้ ----------

## สนจีนทรงบอนไซ ลำต้นบิด ใบเป็นแผ่นเมฆซ้อนชั้น
static func _chinese_pine(p: Node3D, v: int) -> void:
	var bark := K.mat(Color(0.56, 0.42, 0.42), 0.0, 0.95)
	var turn := v * 0.8
	var trunk := [Vector3(0, 0, 0), Vector3(0.3, 1.2, 0.1), Vector3(-0.15, 2.3, 0.0), Vector3(0.25, 3.2, -0.1), Vector3(0.0, 3.9, 0.0)]
	for i in 4:
		K.beam(p, _rot_y(trunk[i], turn), _rot_y(trunk[i + 1], turn), 0.36 - i * 0.06, bark)
	for i in 3:
		var a := i * 2.1 + turn
		K.beam(p, Vector3(0, 0.25, 0), Vector3(cos(a) * 0.55, -0.02, sin(a) * 0.55), 0.14, bark)
	var pads := [[Vector3(1.4, 2.2, 0.3), 1.0], [Vector3(-1.2, 2.9, -0.2), 0.95], [Vector3(0.7, 3.6, 0.7), 0.8], [Vector3(-0.1, 4.25, 0.0), 1.0], [Vector3(-0.5, 1.6, -1.0), 0.7]]
	var dark := K.mat(PINE_DARK)
	var light := K.mat(PINE_LIGHT)
	for pad in pads:
		var c: Vector3 = _rot_y(pad[0], turn)
		var s: float = pad[1]
		K.beam(p, Vector3(c.x * 0.15, c.y - 0.45, c.z * 0.15), c + Vector3(0, -0.1, 0), 0.1, bark)
		K.sphere(p, s, c, dark, 10, Vector3(1.35, 0.36, 1.1))
		K.sphere(p, s * 0.72, c + Vector3(0.05, 0.16, 0.0), light, 10, Vector3(1.3, 0.34, 1.05))


## ต้นเหมยบาน: กิ่งคดดำ ดอกชมพูฟูเป็นกระจุก (บางต้นดอกขาว) กลีบร่วงบนพื้น
static func _plum_blossom(p: Node3D, v: int) -> void:
	var bark := K.mat(Color(0.42, 0.3, 0.34), 0.0, 0.95)
	var white := v % 3 == 2
	var cols := [Color(1.0, 0.76, 0.84), Color(1.0, 0.86, 0.9), Color(0.98, 0.62, 0.74)]
	if white:
		cols = [Color(1.0, 0.98, 0.96), Color(1.0, 0.9, 0.93), Color(0.96, 0.94, 1.0)]
	K.beam(p, Vector3(0, 0, 0), Vector3(0.2, 1.4, 0.05), 0.26, bark)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9100 + v
	var fluff := K.mat(cols[1])
	for i in 5:
		var a := i * TAU / 5.0 + v * 0.7
		var mid := Vector3(0.2 + cos(a) * 0.8, 1.9 + rng.randf() * 0.5, 0.05 + sin(a) * 0.8)
		K.beam(p, Vector3(0.2, 1.3, 0.05), mid, 0.14, bark)
		for k in 2:
			var b := a + (k - 0.5) * 1.1
			var tip := mid + Vector3(cos(b) * 0.65, 0.5 + rng.randf() * 0.4, sin(b) * 0.65)
			K.beam(p, mid, tip, 0.08, bark)
			K.sphere(p, 0.55, tip, fluff, 10, Vector3(1.0, 0.72, 1.0))
			for f in 5:
				var fa := f * 1.3 + b
				var off := Vector3(cos(fa) * 0.5, rng.randf_range(-0.2, 0.3), sin(fa) * 0.5)
				K.sphere(p, rng.randf_range(0.12, 0.18), tip + off, K.mat(cols[(f + i) % 3], 0.12), 6)
	var petal := K.mat(cols[0], 0.0, 0.9, 0.0, false)
	for i in 7:
		var a := rng.randf() * TAU
		var d := rng.randf_range(0.5, 1.8)
		K.cyl(p, 0.07, 0.07, 0.01, Vector3(cos(a) * d, 0.03, sin(a) * d), petal, 6)


## กอไผ่จีนหนาแน่น ลำสูง 5–8 เมตร: รวมเป็น mesh เดียวต่อแบบเพื่อให้วาดเร็ว ทั้งกอไหวตามลม
static func _bamboo_grove(p: Node3D, v: int) -> void:
	var key := "bamboo%d" % (v % 4)
	if not _meshes.has(key):
		_meshes[key] = _bamboo_mesh(v % 4)
	var holder := Node3D.new()
	p.add_child(holder)
	var mi := MeshInstance3D.new()
	mi.mesh = _meshes[key]
	mi.rotation.y = v * 0.9
	mi.set_surface_override_material(0, K.mat(Color(0.56, 0.8, 0.5)))
	mi.set_surface_override_material(1, K.mat(Color(0.44, 0.74, 0.44)))
	mi.set_surface_override_material(2, K.mat(Color(0.62, 0.86, 0.52)))
	holder.add_child(mi)
	_sway(p, holder)
	for i in 2:
		var a := v * 1.7 + i * 2.6
		K.cyl(p, 0.0, 0.09, 0.35, Vector3(cos(a) * 0.95, 0.17, sin(a) * 0.95), K.mat(Color(0.7, 0.66, 0.42)), 6)


static func _bamboo_mesh(seed_v: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7700 + seed_v
	var stalk := CylinderMesh.new()
	stalk.top_radius = 0.07
	stalk.bottom_radius = 0.085
	stalk.height = 1.0
	stalk.radial_segments = 6
	stalk.rings = 1
	var ring := CylinderMesh.new()
	ring.top_radius = 0.1
	ring.bottom_radius = 0.1
	ring.height = 0.06
	ring.radial_segments = 6
	ring.rings = 1
	var leaf := SphereMesh.new()
	leaf.radius = 0.5
	leaf.height = 1.0
	leaf.radial_segments = 6
	leaf.rings = 3
	# ใช้ get_mesh_arrays() (คำนวณบน CPU) จึงทำงานได้แม้รันแบบ headless
	var src := [stalk.get_mesh_arrays(), ring.get_mesh_arrays(), leaf.get_mesh_arrays()]
	var parts := []
	for i in 3:
		parts.append([PackedVector3Array(), PackedVector3Array(), PackedInt32Array()])
	var count := 11 + seed_v
	for i in count:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 0.75
		var base := Vector3(cos(a) * r, 0, sin(a) * r)
		var up := (Vector3.UP + Vector3(cos(a), 0, sin(a)) * rng.randf_range(0.03, 0.13)).normalized()
		var tilt := Basis(Quaternion(Vector3.UP, up))
		var h := rng.randf_range(5.0, 8.0)
		_append(parts[0], src[0], Transform3D(tilt * Basis.from_scale(Vector3(1, h, 1)), base + up * h / 2.0))
		var y := 0.7
		while y < h - 0.3:
			_append(parts[0], src[1], Transform3D(tilt, base + up * y))
			y += 0.85
		# ใบไผ่เป็นช่อรีเรียวห้อยลงจากข้อบนๆ (ทรงรีแบนดูนุ่มกว่ากล่อง)
		for k in 12:
			var ly := h * rng.randf_range(0.5, 1.0)
			var la := rng.randf() * TAU
			var dir := Vector3(cos(la), 0, sin(la))
			var size := rng.randf_range(0.8, 1.25)
			var lb := Basis(Vector3.UP, atan2(dir.x, dir.z)) * Basis(Vector3.RIGHT, rng.randf_range(0.35, 0.75)) * Basis.from_scale(Vector3(0.16, 0.035, 0.62) * size)
			_append(parts[1 + k % 2], src[2], Transform3D(lb, base + up * ly + dir * 0.3 * size + Vector3(0, -0.08, 0)))
	var mesh := ArrayMesh.new()
	for part in parts:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = part[0]
		arrays[Mesh.ARRAY_NORMAL] = part[1]
		arrays[Mesh.ARRAY_INDEX] = part[2]
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## ต่อรูปทรง (arrays จาก get_mesh_arrays) ที่แปลงตำแหน่งแล้วเข้า part = [vertices, normals, indices]
static func _append(part: Array, arrays: Array, xf: Transform3D) -> void:
	var verts: PackedVector3Array = part[0]
	var normals: PackedVector3Array = part[1]
	var indices: PackedInt32Array = part[2]
	var offset := verts.size()
	var nb := xf.basis.inverse().transposed()
	for v in arrays[Mesh.ARRAY_VERTEX]:
		verts.append(xf * v)
	for n in arrays[Mesh.ARRAY_NORMAL]:
		normals.append((nb * n).normalized())
	for idx in arrays[Mesh.ARRAY_INDEX]:
		indices.append(offset + idx)
	part[0] = verts
	part[1] = normals
	part[2] = indices


# ---------- ท่าเรือ ----------

## ตัวเรือสำเภา: ทรงตัดของพีระมิด (ด้านข้างเป็นระนาบ) หัวแหลมไป +x
static func _junk_hull() -> ArrayMesh:
	if _meshes.has("junk_hull"):
		return _meshes["junk_hull"]
	var top := [Vector3(-3.1, 1.0, -1.25), Vector3(1.8, 1.0, -1.25), Vector3(3.7, 1.0, 0.0), Vector3(1.8, 1.0, 1.25), Vector3(-3.1, 1.0, 1.25)]
	var apex := Vector3(0.2, -3.0, 0.0)
	var bottom := []
	for t in top:
		bottom.append(apex + (t - apex) * 0.675)
	var faces: Array[PackedVector3Array] = [PackedVector3Array(top), PackedVector3Array(bottom)]
	for i in top.size():
		var j := (i + 1) % top.size()
		faces.append(PackedVector3Array([top[i], top[j], bottom[j], bottom[i]]))
	_meshes["junk_hull"] = K.convex_mesh(faces)
	return _meshes["junk_hull"]


## เรือสำเภาจีน: ใบเรือมีโครงไม้เป็นปล้อง ท้ายเรือยกสูงมีเก๋ง หัวเรือมีตาเรือ (ฐานอยู่ที่ระดับน้ำ)
static func _junk(p: Node3D, v: int) -> void:
	var body := Node3D.new()
	body.position.y = -0.35
	p.add_child(body)
	var hull_c: Color = [Color(0.66, 0.46, 0.38), Color(0.58, 0.42, 0.4), Color(0.7, 0.52, 0.4)][v % 3]
	K.add(body, _junk_hull(), Vector3.ZERO, K.mat(hull_c))
	var top := [Vector3(-3.1, 1.05, -1.25), Vector3(1.8, 1.05, -1.25), Vector3(3.7, 1.05, 0.0), Vector3(1.8, 1.05, 1.25), Vector3(-3.1, 1.05, 1.25)]
	for i in 5:
		K.beam(body, top[i], top[(i + 1) % 5], 0.16, K.mat(RED))
	K.box(body, Vector3(4.8, 0.05, 2.2), Vector3(-0.4, 1.0, 0), K.mat(WOOD))
	# ท้ายเรือยกสูง มีเก๋งเล็ก
	K.box(body, Vector3(1.5, 0.9, 2.4), Vector3(-2.4, 1.45, 0), K.mat(hull_c.lightened(0.08)))
	K.box(body, Vector3(1.6, 0.12, 2.5), Vector3(-2.4, 1.92, 0), K.mat(RED))
	K.box(body, Vector3(0.9, 0.7, 1.3), Vector3(-2.3, 2.3, 0), K.mat(CREAM))
	_cn_roof(body, Vector3(-2.3, 2.65, 0), 1.0, 1.5, 0.45, RED_DARK)
	K.box(body, Vector3(1.0, 0.35, 1.5), Vector3(2.2, 1.2, 0), K.mat(hull_c.lightened(0.08)))
	K.beam(body, Vector3(3.5, 1.0, 0), Vector3(4.3, 1.6, 0), 0.1, K.mat(WOOD_DARK))
	# ตาเรือ
	for s in [-1.0, 1.0]:
		K.sphere(body, 0.2, Vector3(2.75, 0.75, s * 0.52), K.mat(Color(1, 1, 1)), 10, Vector3(1.0, 1.0, 0.4))
		K.sphere(body, 0.1, Vector3(2.82, 0.75, s * 0.58), K.mat(Color(0.2, 0.15, 0.2)), 8, Vector3(1.0, 1.0, 0.4))
		K.box(body, Vector3(4.0, 0.14, 0.05), Vector3(-0.5, 0.55, s * 1.05), K.mat(Color(1.0, 0.9, 0.6)))
	var sail_cols := [Color(0.97, 0.56, 0.46), Color(0.98, 0.78, 0.5), Color(1.0, 0.92, 0.82), Color(0.94, 0.62, 0.6)]
	var sail_c: Color = sail_cols[v % sail_cols.size()]
	var batten := K.mat(WOOD_DARK)
	for m in [[1.3, 6.0, 2.4], [-0.4, 7.2, 3.0], [-2.9, 4.6, 1.7]]:
		var mx: float = m[0]
		var mh: float = m[1]
		var mw: float = m[2]
		K.cyl(body, 0.06, 0.1, mh, Vector3(mx, 1.0 + mh / 2.0, 0), K.mat(WOOD_DARK), 6)
		var sail := Node3D.new()
		sail.position = Vector3(mx, 1.0, 0.0)
		body.add_child(sail)
		_sway(p, sail)
		var panels := 5
		var y0 := 0.9
		var ph := (mh - 1.3 - y0) / panels
		for i in panels:
			var pw := mw * (0.85 + i * 0.07)
			var c := sail_c if i % 2 == 0 else sail_c.lightened(0.12)
			K.box(sail, Vector3(pw, ph - 0.03, 0.05), Vector3(-pw / 2.0 + 0.35, y0 + ph * (i + 0.5), 0.12), K.mat(c))
			K.box(sail, Vector3(pw + 0.12, 0.05, 0.1), Vector3(-pw / 2.0 + 0.35, y0 + ph * i, 0.12), batten)
		var top_w := mw * (0.85 + panels * 0.07)
		K.box(sail, Vector3(top_w + 0.12, 0.06, 0.1), Vector3(-top_w / 2.0 + 0.35, y0 + ph * panels, 0.12), batten)
	var flag := Node3D.new()
	flag.position = Vector3(-0.4, 8.2, 0)
	body.add_child(flag)
	K.box(flag, Vector3(0.7, 0.32, 0.03), Vector3(-0.36, 0, 0), K.mat(RED))
	K.box(flag, Vector3(0.18, 0.18, 0.04), Vector3(-0.36, 0, 0), K.gold(), Vector3(0, 0, PI / 4.0))
	_sway(p, flag)
	for z in [-0.9, 0.9]:
		_hang_lantern(p, body, Vector3(-3.25, 1.9, z), 0.6, LANTERN_RED, 0.8)
	_light(p, Vector3(-3.0, 1.5, 0), Color(1, 0.55, 0.35), 1.3, 7.0)


## ท่าเทียบเรือไม้ ยื่นไปทาง +x ยาว 7 เมตร มีหลักผูกเรือ เชือก ลังสินค้า และเสาโคม
static func _dock(p: Node3D, v: int) -> void:
	var length := 7.0
	var dark := K.mat(WOOD_DARK)
	K.box(p, Vector3(length, 0.14, 2.2), Vector3(length / 2.0, 0.05, 0), K.mat(WOOD))
	for i in int(length / 0.5):
		K.box(p, Vector3(0.03, 0.15, 2.22), Vector3(0.25 + i * 0.5, 0.05, 0), dark)
	for x in [0.4, 2.4, 4.4, 6.6]:
		for z in [-1.08, 1.08]:
			K.cyl(p, 0.1, 0.1, 1.6, Vector3(x, -0.35, z), dark, 6)
	for x in [3.4, 6.6]:
		for z in [-0.95, 0.95]:
			K.cyl(p, 0.1, 0.12, 0.4, Vector3(x, 0.32, z), dark, 8)
			K.cyl(p, 0.14, 0.14, 0.06, Vector3(x, 0.54, z), dark, 8)
	var rope := TorusMesh.new()
	rope.inner_radius = 0.12
	rope.outer_radius = 0.24
	K.add(p, rope, Vector3(5.6, 0.16, 0.55), K.mat(Color(0.92, 0.82, 0.6)))
	K.box(p, Vector3(0.6, 0.6, 0.6), Vector3(1.2, 0.42, -0.55), K.mat(Color(0.86, 0.66, 0.46)))
	if v % 2 == 0:
		K.box(p, Vector3(0.45, 0.45, 0.45), Vector3(1.25, 0.95, -0.5), K.mat(Color(0.8, 0.6, 0.42)), Vector3(0, 0.4, 0))
	M.spawn(p, "survival/barrel", Vector3(2.0, 0.12, -0.65), 2.4)
	K.cyl(p, 0.05, 0.06, 2.4, Vector3(length - 0.3, 1.3, 1.0), K.mat(RED_DARK), 6)
	K.box(p, Vector3(0.6, 0.06, 0.06), Vector3(length - 0.3, 2.45, 0.75), K.mat(RED_DARK))
	_hang_lantern(p, p, Vector3(length - 0.3, 2.42, 0.5), 0.75, LANTERN_RED, 0.8)
	_light(p, Vector3(length - 0.3, 1.9, 0.5), Color(1, 0.55, 0.35), 1.4, 6.0)


## แผงขายของตลาดท่าเรือ: ผ้าใบลายทาง ผลไม้/ปลา/เครื่องลายคราม/ม้วนผ้าไหม ป้ายผ้าแดงห้อย
static func _market_stall(p: Node3D, v: int) -> void:
	var dark := K.mat(WOOD_DARK)
	K.box(p, Vector3(2.4, 0.1, 1.1), Vector3(0, 0.85, 0.25), K.mat(WOOD))
	for x in [-1.1, 1.1]:
		for z in [-0.2, 0.7]:
			K.cyl(p, 0.05, 0.05, 0.85, Vector3(x, 0.42, z), dark, 6)
	var awning: Array = [[RED, CREAM], [Color(0.98, 0.76, 0.42), CREAM], [Color(0.5, 0.72, 0.86), CREAM]][v % 3]
	K.box(p, Vector3(2.4, 0.5, 0.04), Vector3(0, 0.56, 0.8), K.mat(awning[0]))
	for x in [-1.25, 1.25]:
		K.cyl(p, 0.05, 0.05, 2.5, Vector3(x, 1.25, -0.35), dark, 6)
		K.cyl(p, 0.05, 0.05, 2.1, Vector3(x, 1.05, 1.1), dark, 6)
	for i in 5:
		K.box(p, Vector3(0.56, 0.06, 1.85), Vector3(-1.12 + i * 0.56, 2.32, 0.38), K.mat(awning[i % 2]), Vector3(-0.25, 0, 0))
	for i in 5:
		K.sphere(p, 0.1, Vector3(-1.12 + i * 0.56, 2.04, 1.3), K.mat(awning[0]), 6, Vector3(2.6, 0.7, 0.6))
	match v % 4:
		0:
			var fruit := [Color(1.0, 0.62, 0.3), Color(1.0, 0.78, 0.6), Color(0.6, 0.85, 0.4), Color(1.0, 0.45, 0.45)]
			for i in 12:
				K.sphere(p, 0.11, Vector3(-0.95 + (i % 6) * 0.38, 0.99 + (i / 6) * 0.06, 0.05 + (i / 6) * 0.35), K.mat(fruit[(i + v) % 4]), 8)
		1:
			for i in 5:
				var fish := Vector3(-0.85 + i * 0.42, 0.97, 0.3)
				K.sphere(p, 0.12, fish, K.mat(Color(0.7, 0.82, 0.95), 0.0, 0.4), 8, Vector3(1.8, 0.6, 0.7))
				K.cyl(p, 0.0, 0.1, 0.15, fish + Vector3(0.24, 0, 0), K.mat(Color(0.6, 0.72, 0.9)), 4, Vector3(0, 0, PI / 2.0))
		2:
			for i in 5:
				var jar := Vector3(-0.9 + i * 0.45, 1.05, 0.25)
				K.sphere(p, 0.15, jar, K.mat(Color(0.95, 0.97, 1.0), 0.0, 0.3), 10, Vector3(1, 1.2, 1))
				K.cyl(p, 0.1, 0.11, 0.05, jar + Vector3(0, 0.0, 0), K.mat(Color(0.35, 0.5, 0.85)), 10)
				K.cyl(p, 0.05, 0.07, 0.12, jar + Vector3(0, 0.2, 0), K.mat(Color(0.95, 0.97, 1.0), 0.0, 0.3), 8)
		3:
			var silk := [Color(1.0, 0.6, 0.7), Color(0.6, 0.85, 0.8), Color(1.0, 0.85, 0.5), Color(0.75, 0.68, 1.0)]
			for i in 4:
				K.cyl(p, 0.12, 0.12, 0.9, Vector3(-0.75 + i * 0.5, 1.02, 0.25), K.mat(silk[i]), 10, Vector3(PI / 2.0, 0, 0))
	K.box(p, Vector3(0.36, 1.0, 0.03), Vector3(1.25, 1.5, 1.14), K.gold())
	K.box(p, Vector3(0.3, 0.92, 0.04), Vector3(1.25, 1.5, 1.15), K.mat(RED))
	_hang_lantern(p, p, Vector3(-1.25, 2.0, 1.25), 0.55, LANTERN_RED, 0.8)
	_light(p, Vector3(0, 1.8, 1.0), Color(1, 0.6, 0.38), 0.9, 4.5)


## ราวตากปลาเค็มริมท่าเรือ
static func _fish_rack(p: Node3D, v: int) -> void:
	var dark := K.mat(WOOD_DARK)
	for x in [-1.1, 1.1]:
		K.beam(p, Vector3(x - 0.25, 0, 0), Vector3(x, 1.7, 0), 0.08, dark)
		K.beam(p, Vector3(x + 0.25, 0, 0), Vector3(x, 1.7, 0), 0.08, dark)
	K.cyl(p, 0.035, 0.035, 2.5, Vector3(0, 1.65, 0), dark, 6, Vector3(0, 0, PI / 2.0))
	for i in 7:
		var x := -0.9 + i * 0.3
		var f := Node3D.new()
		f.position = Vector3(x, 1.62, 0)
		p.add_child(f)
		K.cyl(f, 0.006, 0.006, 0.12, Vector3(0, -0.06, 0), K.mat(CREAM), 4)
		K.sphere(f, 0.08, Vector3(0, -0.3, 0), K.mat(Color(0.82, 0.86, 0.92) if (i + v) % 3 else Color(0.95, 0.75, 0.55), 0.0, 0.4), 8, Vector3(0.6, 2.2, 0.4))
		K.cyl(f, 0.0, 0.07, 0.1, Vector3(0, -0.52, 0), K.mat(Color(0.7, 0.76, 0.86)), 4, Vector3(PI, 0, 0))
		_sway(p, f)
	K.cyl(p, 0.3, 0.25, 0.3, Vector3(0.9, 0.15, 0.45), K.mat(Color(0.9, 0.78, 0.55)), 10)


# ---------- วัด / สุสาน ----------

## กระถางธูปติ่ง (ติ่งสัมฤทธิ์สามขา) ธูปติดไฟ ควันลอยขึ้น
static func _ding(p: Node3D, v: int) -> void:
	var br := K.mat(BRONZE, 0.0, 0.5, 0.3)
	K.box(p, Vector3(1.6, 0.3, 1.6), Vector3(0, 0.15, 0), K.mat(STONE))
	for k in 3:
		var a := k * TAU / 3.0 + PI / 6.0
		K.cyl(p, 0.08, 0.12, 0.6, Vector3(sin(a) * 0.42, 0.6, cos(a) * 0.42), br, 8)
	K.cyl(p, 0.62, 0.48, 0.62, Vector3(0, 1.1, 0), br, 14)
	K.cyl(p, 0.6, 0.6, 0.08, Vector3(0, 1.18, 0), K.gold(), 14)
	var rim := TorusMesh.new()
	rim.inner_radius = 0.56
	rim.outer_radius = 0.68
	K.add(p, rim, Vector3(0, 1.41, 0), br)
	K.cyl(p, 0.57, 0.57, 0.02, Vector3(0, 1.38, 0), K.mat(Color(0.78, 0.75, 0.72)), 14)
	for x in [-0.52, 0.52]:
		var ear := TorusMesh.new()
		ear.inner_radius = 0.1
		ear.outer_radius = 0.17
		K.add(p, ear, Vector3(x, 1.62, 0), br, Vector3(PI / 2.0, 0, 0))
	for i in 5:
		var x := -0.2 + i * 0.1
		var z := 0.06 * (i % 2)
		K.cyl(p, 0.015, 0.015, 0.6, Vector3(x, 1.68, z), K.mat(Color(0.85, 0.3, 0.25)), 4)
		K.sphere(p, 0.025, Vector3(x, 1.99, z), K.mat(Color(1.0, 0.6, 0.3), 3.0, 0.5, 0.0, false), 4)
	for i in 3:
		var puff := Node3D.new()
		puff.position = Vector3(0.1 * (i - 1), 2.3 + i * 0.55, 0.05 * i)
		p.add_child(puff)
		K.sphere(puff, 0.16 + i * 0.07, Vector3.ZERO, K.mat(Color(0.95, 0.95, 1.0, 0.4), 0.3, 0.9, 0.0, false), 8)
		_wisp(p, puff)
	_light(p, Vector3(0, 2.0, 0.5), Color(1, 0.6, 0.35), 1.0, 4.5)


## แถวนักรบดินเผาสามตัวบนฐานดิน (บางตัวหัวหลุด) หันหน้าไป +z
static func _terracotta_row(p: Node3D, v: int) -> void:
	K.box(p, Vector3(4.6, 0.25, 1.3), Vector3(0, 0.12, 0), K.mat(Color(0.74, 0.6, 0.46)))
	for i in 3:
		_warrior(p, Vector3(-1.5 + i * 1.5, 0.25, 0), v + i, (v + i) % 5 == 3)


static func _warrior(p: Node3D, at: Vector3, v: int, broken: bool) -> void:
	var clay := K.mat(CLAY)
	var armor := K.mat(Color(0.7, 0.5, 0.42))
	var plate := K.mat(Color(0.58, 0.4, 0.36))
	var skin := K.mat(Color(0.9, 0.7, 0.56))
	for x in [-0.12, 0.12]:
		K.cyl(p, 0.08, 0.09, 0.42, at + Vector3(x, 0.21, 0), clay, 8)
		K.box(p, Vector3(0.16, 0.08, 0.26), at + Vector3(x, 0.04, 0.05), plate)
	K.cyl(p, 0.28, 0.36, 0.42, at + Vector3(0, 0.6, 0), clay, 10)
	K.box(p, Vector3(0.58, 0.5, 0.4), at + Vector3(0, 1.04, 0), armor)
	for r in 3:
		K.box(p, Vector3(0.6, 0.03, 0.42), at + Vector3(0, 0.88 + r * 0.14, 0), plate)
	for side in [-1.0, 1.0]:
		K.sphere(p, 0.13, at + Vector3(side * 0.32, 1.24, 0), armor, 8)
		var hand := at + Vector3(side * 0.36, 0.82, 0.16)
		K.beam(p, at + Vector3(side * 0.34, 1.2, 0), hand, 0.12, clay)
		K.sphere(p, 0.07, hand, skin, 6)
	if broken:
		K.cyl(p, 0.1, 0.12, 0.12, at + Vector3(0, 1.34, 0), skin, 8)
		K.sphere(p, 0.24, at + Vector3(0.45, 0.24 - at.y + 0.25, 0.5), skin, 10)
		K.sphere(p, 0.09, at + Vector3(0.52, 0.42 - at.y + 0.25, 0.42), plate, 6)
	else:
		K.cyl(p, 0.09, 0.1, 0.1, at + Vector3(0, 1.33, 0), skin, 8)
		K.sphere(p, 0.27, at + Vector3(0, 1.6, 0), skin, 12)
		K.sphere(p, 0.27, at + Vector3(0, 1.66, -0.05), plate, 12, Vector3(1.02, 0.7, 1.0))
		K.sphere(p, 0.1, at + Vector3(0.12, 1.9, -0.05), plate, 8)
		for x in [-0.09, 0.09]:
			K.box(p, Vector3(0.08, 0.025, 0.02), at + Vector3(x, 1.6, 0.26), K.mat(Color(0.35, 0.24, 0.24)))
		K.box(p, Vector3(0.16, 0.03, 0.02), at + Vector3(0, 1.5, 0.26), K.mat(Color(0.5, 0.32, 0.3)))
	if v % 2 == 0:
		var hand := at + Vector3(0.36, 0.82, 0.16)
		K.beam(p, hand + Vector3(0, -0.55, 0), hand + Vector3(0, 1.55, 0), 0.05, K.mat(WOOD_DARK))
		K.cyl(p, 0.0, 0.07, 0.28, hand + Vector3(0, 1.68, 0), K.mat(BRONZE, 0.0, 0.5, 0.3), 6)


## เนินสุสานดินโบราณ ขอบหิน แผ่นศิลาจารึก แท่นบูชามีผลไม้และธูป
static func _tomb_mound(p: Node3D, v: int) -> void:
	var stone := K.mat(Color(0.76, 0.7, 0.62))
	K.cyl(p, 2.6, 2.75, 0.5, Vector3(0, 0.25, 0), stone, 14)
	K.cyl(p, 2.66, 2.66, 0.08, Vector3(0, 0.52, 0), K.mat(Color(0.84, 0.78, 0.68)), 14)
	K.sphere(p, 2.45, Vector3(0, 0.45, 0), K.mat(Color(0.62, 0.66, 0.44)), 16, Vector3(1, 0.52, 1))
	for i in 6:
		var a := i * TAU / 6.0 + v
		K.sphere(p, 0.3, Vector3(cos(a) * 1.4, 1.4 - (i % 2) * 0.2, sin(a) * 1.4), K.mat(Color(0.7, 0.74, 0.5)), 6, Vector3(1, 0.5, 1))
	K.box(p, Vector3(1.2, 0.3, 0.5), Vector3(0, 0.15, 2.6), stone)
	K.box(p, Vector3(0.9, 1.3, 0.22), Vector3(0, 0.95, 2.6), K.mat(Color(0.82, 0.8, 0.78)))
	K.cyl(p, 0.45, 0.45, 0.22, Vector3(0, 1.6, 2.6), K.mat(Color(0.82, 0.8, 0.78)), 12, Vector3(PI / 2.0, 0, 0))
	for i in 3:
		K.box(p, Vector3(0.05, 0.85, 0.02), Vector3(-0.2 + i * 0.2, 0.95, 2.72), K.mat(Color(0.5, 0.46, 0.48)))
	K.box(p, Vector3(1.4, 0.5, 0.6), Vector3(0, 0.25, 3.25), stone)
	var fruit := [Color(1.0, 0.62, 0.3), Color(1.0, 0.75, 0.7), Color(1.0, 0.85, 0.4)]
	for i in 3:
		K.sphere(p, 0.09, Vector3(-0.45 + i * 0.09, 0.58, 3.25 + (i % 2) * 0.08), K.mat(fruit[i]), 6)
	K.cyl(p, 0.12, 0.1, 0.14, Vector3(0.35, 0.57, 3.25), K.mat(BRONZE), 8)
	for i in 3:
		K.cyl(p, 0.008, 0.008, 0.22, Vector3(0.32 + i * 0.03, 0.74, 3.25), K.mat(Color(0.85, 0.3, 0.25)), 4)
		K.sphere(p, 0.015, Vector3(0.32 + i * 0.03, 0.86, 3.25), K.mat(Color(1.0, 0.6, 0.3), 3.0, 0.5, 0.0, false), 4)
	_light(p, Vector3(0, 1.0, 3.6), Color(1, 0.6, 0.35), 0.8, 4.0)


## ศิลาจารึกบนหลังเต่าปี้ซี่ (bixi)
static func _stele(p: Node3D, v: int) -> void:
	var st := K.mat(Color(0.74, 0.73, 0.76))
	var st2 := K.mat(Color(0.84, 0.83, 0.86))
	var dark := K.mat(Color(0.5, 0.48, 0.54))
	K.sphere(p, 0.7, Vector3(0, 0.35, 0), st, 12, Vector3(1.0, 0.55, 1.35))
	for i in 5:
		var a := i * TAU / 5.0
		K.sphere(p, 0.16, Vector3(cos(a) * 0.42, 0.62, sin(a) * 0.55), dark, 6, Vector3(1, 0.4, 1))
	K.beam(p, Vector3(0, 0.35, 0.7), Vector3(0, 0.48, 1.0), 0.18, st)
	K.sphere(p, 0.24, Vector3(0, 0.5, 1.08), st, 10)
	for x in [-0.09, 0.09]:
		K.sphere(p, 0.04, Vector3(x, 0.58, 1.28), dark, 6)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			K.sphere(p, 0.16, Vector3(sx * 0.55, 0.1, sz * 0.6), st, 6, Vector3(1.2, 0.6, 1))
	K.box(p, Vector3(0.95, 1.8, 0.26), Vector3(0, 1.55, 0), st2)
	K.cyl(p, 0.48, 0.48, 0.26, Vector3(0, 2.45, 0), st2, 14, Vector3(PI / 2.0, 0, 0))
	for x in [-0.22, 0.22]:
		K.sphere(p, 0.12, Vector3(x, 2.72, 0), dark, 8)
	for i in 4:
		K.box(p, Vector3(0.05, 1.2, 0.02), Vector3(-0.27 + i * 0.18, 1.5, 0.135), dark)
	K.box(p, Vector3(0.82, 0.04, 0.02), Vector3(0, 2.18, 0.135), dark)
	K.box(p, Vector3(0.82, 0.04, 0.02), Vector3(0, 0.85, 0.135), dark)
	if v % 3 == 0:
		K.sphere(p, 0.2, Vector3(0.4, 0.9, 0.1), K.mat(Color(0.52, 0.7, 0.48)), 6)
		K.sphere(p, 0.15, Vector3(-0.35, 0.55, 0.6), K.mat(Color(0.52, 0.7, 0.48)), 6)


# ---------- กำแพงเมืองจีน ----------

## กำแพงเมืองจีนช่วงยาว 8 เมตร (ตามแกน x) สูง 3 เมตร บนสุดมีทางเดินและใบเสมา
static func _great_wall(n: Node3D, v: int) -> void:
	var wall := K.mat(WALL)
	var line := K.mat(WALL.darkened(0.12))
	K.box(n, Vector3(8.0, 0.4, 2.6), Vector3(0, 0.2, 0), K.mat(WALL.darkened(0.15)))
	K.box(n, Vector3(8.0, 3.0, 2.2), Vector3(0, 1.7, 0), wall)
	for y in [0.95, 1.65, 2.35]:
		K.box(n, Vector3(8.02, 0.05, 2.22), Vector3(0, y, 0), line)
	K.box(n, Vector3(8.0, 0.16, 2.3), Vector3(0, 3.16, 0), line)
	K.box(n, Vector3(8.0, 0.06, 1.7), Vector3(0, 3.26, 0), K.mat(Color(0.72, 0.68, 0.62)))
	for z in [-1.0, 1.0]:
		K.box(n, Vector3(8.0, 0.32, 0.24), Vector3(0, 3.38, z), wall)
		for i in 8:
			K.box(n, Vector3(0.55, 0.5, 0.24), Vector3(-3.5 + i, 3.78, z), wall)
	var moss := K.mat(Color(0.52, 0.7, 0.48))
	for i in 3:
		var x := -3.0 + float((v * 3 + i * 5) % 7)
		K.sphere(n, 0.35, Vector3(x, 0.3, 1.2 * (1.0 if i % 2 == 0 else -1.0)), moss, 6, Vector3(1.3, 0.6, 0.6))


## หอสังเกตการณ์บนกำแพง: ตัวหอก่ออิฐ ประตูโค้ง ช่องธนู ศาลาหลังคาจีนบนยอด ธงสะบัด
static func _watchtower(p: Node3D, v: int) -> void:
	var wall := K.mat(WALL)
	var line := K.mat(WALL.darkened(0.12))
	var hole := K.mat(Color(0.3, 0.24, 0.3))
	K.box(p, Vector3(5.0, 0.5, 5.0), Vector3(0, 0.25, 0), K.mat(WALL.darkened(0.15)))
	K.box(p, Vector3(4.6, 5.0, 4.6), Vector3(0, 2.5, 0), wall)
	for y in [1.2, 2.4, 3.6]:
		K.box(p, Vector3(4.62, 0.05, 4.62), Vector3(0, y, 0), line)
	K.box(p, Vector3(4.9, 0.2, 4.9), Vector3(0, 5.1, 0), line)
	for k in 4:
		var a := k * PI / 2.0
		var out := Vector3(sin(a), 0, cos(a))
		var side := Vector3(cos(a), 0, -sin(a))
		K.box(p, Vector3(4.8, 0.32, 0.24), out * 2.3 + Vector3(0, 5.36, 0), wall, Vector3(0, a, 0))
		for i in 5:
			K.box(p, Vector3(0.55, 0.5, 0.24), out * 2.3 + side * (-2.0 + i) + Vector3(0, 5.76, 0), wall, Vector3(0, a, 0))
		if k % 2 == 0:
			K.box(p, Vector3(1.2, 1.7, 0.1), out * 2.31 + Vector3(0, 0.85 + 0.5, 0), hole, Vector3(0, a, 0))
			K.cyl(p, 0.6, 0.6, 0.1, out * 2.31 + Vector3(0, 2.2, 0), hole, 12, Vector3(PI / 2.0, a, 0))
		for s in [-1.1, 1.1]:
			K.box(p, Vector3(0.24, 0.6, 0.1), out * 2.31 + side * s + Vector3(0, 3.7, 0), hole, Vector3(0, a, 0))
	var red := K.mat(RED)
	for sx in [-1.3, 1.3]:
		for sz in [-1.3, 1.3]:
			K.cyl(p, 0.1, 0.11, 1.8, Vector3(sx, 6.1, sz), red, 8)
	K.box(p, Vector3(2.0, 1.2, 2.0), Vector3(0, 5.8, 0), K.mat(CREAM))
	_cn_roof(p, Vector3(0, 7.0, 0), 3.2, 3.2, 1.2, Color(0.52, 0.55, 0.66))
	var flag_cols := [RED, Color(1.0, 0.82, 0.4)]
	for k in 2:
		var pole := Vector3(-2.15 if k == 0 else 2.15, 5.2, 2.15 if k == 0 else -2.15)
		K.cyl(p, 0.04, 0.05, 2.6, pole + Vector3(0, 1.3, 0), K.mat(WOOD_DARK), 6)
		var flag := Node3D.new()
		flag.position = pole + Vector3(0, 2.3, 0)
		p.add_child(flag)
		K.box(flag, Vector3(0.05, 0.7, 1.0), Vector3(0, -0.3, 0.52), K.mat(flag_cols[(k + v) % 2]))
		K.box(flag, Vector3(0.06, 0.14, 1.0), Vector3(0, 0.02, 0.52), K.gold())
		_sway(p, flag)
	_hang_lantern(p, p, Vector3(0, 6.95, 1.75), 0.8, LANTERN_RED, 0.8)
	_light(p, Vector3(0, 6.2, 2.0), Color(1, 0.6, 0.38), 1.5, 9.0)


## ประตูด่านบนกำแพง (ยาวตามแกน x) ช่องประตูโค้งกว้าง 3.2 เมตร มีหอประตูหลังคาจีนบนยอด
## ไม่มี footprint ในตัว: แผนที่ต้องกันทางเดินตรงตอม่อสองข้างเอง
static func _pass_gate(p: Node3D, v: int) -> void:
	var wall := K.mat(WALL)
	var line := K.mat(WALL.darkened(0.12))
	for side in [-1.0, 1.0]:
		K.box(p, Vector3(2.2, 4.4, 3.0), Vector3(side * 2.7, 2.2, 0), wall)
		K.box(p, Vector3(2.4, 0.4, 3.2), Vector3(side * 2.7, 0.2, 0), K.mat(WALL.darkened(0.15)))
	K.box(p, Vector3(7.6, 1.0, 3.0), Vector3(0, 4.9, 0), wall)
	for y in [1.2, 2.4, 3.6]:
		for side in [-1.0, 1.0]:
			K.box(p, Vector3(2.22, 0.05, 3.02), Vector3(side * 2.7, y, 0), line)
	var r := 1.6
	var cy := 2.8
	var strips := 10
	for i in strips:
		var x := -r + (i + 0.5) * (2.0 * r / strips)
		var up := cy + sqrt(maxf(r * r - x * x, 0.0))
		K.box(p, Vector3(2.0 * r / strips + 0.01, 4.4 - up, 3.0), Vector3(x, (4.4 + up) / 2.0, 0), wall)
	var trim := K.mat(Color(0.7, 0.66, 0.62))
	for z in [-1.52, 1.52]:
		for i in 8:
			var a0 := PI * i / 8.0
			var a1 := PI * (i + 1) / 8.0
			K.beam(p, Vector3(cos(a0) * (r + 0.12), cy + sin(a0) * (r + 0.12), z), Vector3(cos(a1) * (r + 0.12), cy + sin(a1) * (r + 0.12), z), 0.22, trim)
		K.box(p, Vector3(1.8, 0.7, 0.1), Vector3(0, 4.85, z * 1.02), K.gold())
		K.box(p, Vector3(1.6, 0.54, 0.12), Vector3(0, 4.85, z * 1.02), K.mat(NAVY))
	for z in [-1.4, 1.4]:
		for i in 8:
			K.box(p, Vector3(0.55, 0.5, 0.24), Vector3(-3.5 + i, 5.65, z), wall)
	K.box(p, Vector3(5.4, 1.7, 2.2), Vector3(0, 6.25, 0), K.mat(RED))
	for x in [-1.8, -0.6, 0.6, 1.8]:
		for z in [-1.11, 1.11]:
			K.box(p, Vector3(0.6, 0.8, 0.04), Vector3(x, 6.3, z), K.mat(Color(0.98, 0.86, 0.6), 0.15))
	_cn_roof(p, Vector3(0, 7.1, 0), 5.8, 2.6, 1.5, Color(0.5, 0.53, 0.66))
	for z in [-1.7, 1.7]:
		for x in [-1.0, 1.0]:
			_hang_lantern(p, p, Vector3(x, 4.35, z), 0.85, LANTERN_RED, 0.8)
	_light(p, Vector3(0, 3.5, 2.4), Color(1, 0.6, 0.38), 1.6, 9.0)
	_light(p, Vector3(0, 3.5, -2.4), Color(1, 0.6, 0.38), 1.2, 9.0)


# ---------- เมืองผีเฟิงตู ----------

## ประตูผีเฟิงตู (กุ่ยเหมินกวาน): เสาหินดำทึบ หัวกะโหลกบนเสา ป้ายดำ ม่านหมอกม่วงเรืองแสงในช่องประตู
static func _fengdu_gate(p: Node3D, v: int) -> void:
	var dark := K.mat(Color(0.38, 0.32, 0.44))
	var trim := K.mat(Color(0.58, 0.26, 0.36))
	var bone := K.mat(Color(0.94, 0.92, 0.86))
	for x in [-2.6, 2.6]:
		K.box(p, Vector3(1.5, 0.6, 1.5), Vector3(x, 0.3, 0), K.mat(Color(0.3, 0.26, 0.34)))
		K.box(p, Vector3(1.0, 5.0, 1.0), Vector3(x, 2.9, 0), dark)
		for y in [1.4, 2.8, 4.2]:
			K.box(p, Vector3(1.06, 0.12, 1.06), Vector3(x, y, 0), trim)
		K.sphere(p, 0.36, Vector3(x, 6.15, 0.1), bone, 12, Vector3(1, 0.95, 1))
		K.box(p, Vector3(0.36, 0.2, 0.3), Vector3(x, 5.85, 0.2), bone)
		for ex in [-0.13, 0.13]:
			K.sphere(p, 0.09, Vector3(x + ex, 6.17, 0.4), K.mat(Color(0.5, 1.0, 0.8), 2.5, 0.5, 0.0, false), 6)
	K.box(p, Vector3(6.6, 0.55, 1.2), Vector3(0, 5.55, 0), trim)
	K.box(p, Vector3(6.0, 0.35, 0.9), Vector3(0, 4.55, 0), dark)
	for z in [0.48, -0.48]:
		K.box(p, Vector3(2.6, 1.0, 0.12), Vector3(0, 5.0, z), K.gold())
		K.box(p, Vector3(2.4, 0.84, 0.14), Vector3(0, 5.0, z), K.mat(Color(0.16, 0.12, 0.2)))
		for i in 3:
			K.box(p, Vector3(0.28, 0.5, 0.16), Vector3(-0.7 + i * 0.7, 5.0, z), K.mat(Color(1.0, 0.36, 0.36), 1.2))
	_cn_roof(p, Vector3(0, 5.85, 0), 6.4, 1.6, 1.2, GHOST_ROOF, GHOST_GLOW, Color(0.45, 0.2, 0.3))
	K.box(p, Vector3(4.2, 4.2, 0.04), Vector3(0, 2.25, 0), K.mat(Color(0.62, 0.4, 0.95, 0.2), 1.2, 0.5, 0.0, false))
	for x in [-1.5, 1.5]:
		_hang_lantern(p, p, Vector3(x, 4.35, 0.62), 1.0, GHOST_GLOW, 1.8)
	for i in 4:
		_ghost_wisp(p, Vector3(-2.0 + i * 1.3, 1.6 + (i % 2) * 1.0, 1.0 - (i % 2) * 2.0), [GHOST_GLOW, Color(0.75, 0.55, 1.0)][i % 2])
	_light(p, Vector3(0, 2.6, 1.5), Color(0.7, 0.5, 1.0), 2.0, 9.0)
	_light(p, Vector3(0, 2.6, -1.5), Color(0.5, 1.0, 0.8), 1.4, 8.0)


## สะพาน (ยาว 9 เมตรตามแกน x): ghost = สะพานไน่เหอหินซีดพื้นราบ (เดินข้ามได้) มีโคมผี
## ไม่ใช่ = สะพานโค้งราวแดงในสวน (ประดับกลางสระ)
static func _bridge(p: Node3D, v: int, ghost: bool) -> void:
	var deck := K.mat(Color(0.74, 0.72, 0.82) if ghost else Color(0.86, 0.84, 0.82))
	var rail := K.mat(Color(0.84, 0.82, 0.9) if ghost else RED)
	var length := 9.0
	var rise := 0.0 if ghost else 1.3
	var n := 12
	for i in n:
		var t0 := float(i) / n
		var t1 := float(i + 1) / n
		var a := Vector3(-length / 2.0 + t0 * length, rise * sin(PI * t0), 0)
		var b := Vector3(-length / 2.0 + t1 * length, rise * sin(PI * t1), 0)
		var mid := (a + b) / 2.0
		var ang := atan2(b.y - a.y, b.x - a.x)
		var seg := a.distance_to(b)
		K.box(p, Vector3(seg + 0.06, 0.25, 2.0), mid, deck, Vector3(0, 0, ang))
		for z in [-0.95, 0.95]:
			K.box(p, Vector3(seg + 0.02, 0.09, 0.12), mid + Vector3(0, 0.62, z), rail, Vector3(0, 0, ang))
			if i % 2 == 0 and i > 0:
				K.box(p, Vector3(0.13, 0.6, 0.13), a + Vector3(0, 0.32, z), rail)
				K.sphere(p, 0.09, a + Vector3(0, 0.66, z), rail, 6)
	for side in [-1.0, 1.0]:
		for z in [-0.95, 0.95]:
			K.box(p, Vector3(0.22, 0.95, 0.22), Vector3(side * length / 2.0, 0.47, z), rail)
	if ghost:
		for side in [-1.0, 1.0]:
			_hang_lantern(p, p, Vector3(side * (length / 2.0 - 0.1), 1.6, 1.05), 0.7, GHOST_GLOW, 1.8)
			K.cyl(p, 0.04, 0.04, 0.7, Vector3(side * (length / 2.0 - 0.1), 1.25, 0.95), rail, 6)
			K.box(p, Vector3(0.05, 0.05, 0.2), Vector3(side * (length / 2.0 - 0.1), 1.6, 1.0), rail)
		_ghost_wisp(p, Vector3(0, 2.6, 0), GHOST_GLOW)
		_light(p, Vector3(0, 2.4, 0), Color(0.5, 1.0, 0.8), 1.6, 8.0)


## กองกระดาษเงินกระดาษทองไหว้ผี กับเตาเผากระดาษที่ไฟลุกอยู่ และบ้านกระดาษจำลอง
static func _offerings(p: Node3D, v: int) -> void:
	var iron := K.mat(Color(0.32, 0.28, 0.34), 0.0, 0.5, 0.3)
	for k in 3:
		var a := k * TAU / 3.0
		K.cyl(p, 0.04, 0.05, 0.3, Vector3(sin(a) * 0.3, 0.15, cos(a) * 0.3), iron, 6)
	K.cyl(p, 0.45, 0.32, 0.5, Vector3(0, 0.55, 0), iron, 10)
	var rim := TorusMesh.new()
	rim.inner_radius = 0.42
	rim.outer_radius = 0.5
	K.add(p, rim, Vector3(0, 0.8, 0), iron)
	K.cyl(p, 0.4, 0.4, 0.03, Vector3(0, 0.76, 0), K.mat(Color(1.0, 0.5, 0.25), 2.5, 0.4, 0.0, false), 10)
	for i in 3:
		var f := Node3D.new()
		f.position = Vector3((i - 1) * 0.15, 0.78, (i % 2) * 0.1 - 0.05)
		p.add_child(f)
		var c: Color = [Color(1.0, 0.55, 0.3), Color(1.0, 0.82, 0.38), Color(1.0, 0.45, 0.4)][i]
		K.cyl(f, 0.0, 0.16 - i * 0.03, 0.55 - i * 0.1, Vector3(0, 0.27, 0), K.mat(c, 2.5, 0.5, 0.0, false), 8)
		_flame(p, f)
	var gold := Color(1.0, 0.82, 0.42)
	var silver := Color(0.86, 0.88, 0.95)
	for i in 5:
		var a := i * 1.3 + v
		var pos := Vector3(cos(a) * 0.85, 0, sin(a) * 0.85)
		var hgt := 0.08 + (i % 3) * 0.06
		K.box(p, Vector3(0.36, hgt, 0.26), pos + Vector3(0, hgt / 2.0, 0), K.mat(gold if i % 2 == 0 else silver, 0.15), Vector3(0, a, 0))
		K.box(p, Vector3(0.16, 0.02, 0.16), pos + Vector3(0, hgt + 0.01, 0), K.mat(RED), Vector3(0, a, 0))
	for i in 3:
		K.sphere(p, 0.1, Vector3(0.55 + i * 0.12, 0.06, 0.55 - i * 0.08), K.mat(gold, 0.3, 0.3, 0.6), 8, Vector3(1.6, 0.7, 1.0))
	K.box(p, Vector3(0.45, 0.4, 0.4), Vector3(-0.75, 0.2, -0.55), K.mat(Color(1.0, 0.92, 0.8)))
	hip(p, 0.6, 0.55, 0.25, Vector3(-0.75, 0.4, -0.55), K.mat(RED))
	K.box(p, Vector3(0.12, 0.2, 0.02), Vector3(-0.75, 0.12, -0.34), K.mat(RED_DARK))
	_light(p, Vector3(0, 1.3, 0.2), Color(1, 0.55, 0.3), 1.6, 5.5)


## พลับพลึงแดง (ดอกไม้แห่งยมโลก) เป็นกอ กลีบเรียวม้วนชี้ขึ้น
static func _spider_lily(p: Node3D, v: int) -> void:
	var stem := K.mat(Color(0.4, 0.6, 0.42))
	var red := K.mat(Color(1.0, 0.32, 0.36), 0.5, 0.6)
	var count := 4 + v % 3
	for i in count:
		var a := i * TAU / count + v
		var base := Vector3(cos(a) * 0.25, 0, sin(a) * 0.25)
		var h := 0.45 + (i % 3) * 0.1
		var head := base + Vector3(cos(a) * 0.05, h, sin(a) * 0.05)
		K.beam(p, base, head, 0.025, stem)
		for k in 6:
			var b := k * TAU / 6.0 + i
			var dir := Vector3(cos(b), 0.6, sin(b)).normalized()
			K.beam(p, head, head + dir * 0.16, 0.025, red)
			K.beam(p, head + dir * 0.16, head + dir * 0.18 + Vector3(0, 0.08, 0), 0.015, red)


# ---------- ภูมิประเทศ ----------

## หินไท่หูในสวนจีน มีรูพรุน
static func _taihu_rock(p: Node3D, v: int) -> void:
	var rock := K.mat(Color(0.74, 0.76, 0.82))
	var hole := K.mat(Color(0.38, 0.38, 0.46))
	var parts := [[Vector3(0, 0.4, 0), 0.55], [Vector3(0.15, 1.0, 0.05), 0.42], [Vector3(-0.1, 1.5, -0.05), 0.36], [Vector3(0.2, 1.95, 0), 0.28], [Vector3(-0.35, 0.3, 0.3), 0.32]]
	for i in parts.size():
		var c: Vector3 = _rot_y(parts[i][0], v * 1.1)
		K.sphere(p, parts[i][1], c, rock, 7, Vector3(1.0, 1.15, 0.85))
	for i in 3:
		var c: Vector3 = _rot_y(parts[i + 1][0], v * 1.1)
		K.sphere(p, 0.1 + i * 0.02, c + _rot_y(Vector3(0.1, 0.05, 0.32), v * 1.1), hole, 6)
	K.sphere(p, 0.3, Vector3(0.4, 0.12, -0.3), K.mat(Color(0.5, 0.74, 0.5)), 6, Vector3(1.2, 0.6, 1.0))


## ภูเขาหินปูนทรงแท่ง (แบบกุ้ยหลิน) มีต้นไม้ตามไหล่เขา ใช้เป็นแนวเขารอบขอบแผนที่
static func _karst_peak(p: Node3D, v: int) -> void:
	var rock := K.mat([Color(0.62, 0.68, 0.68), Color(0.7, 0.7, 0.74), Color(0.66, 0.72, 0.66)][v % 3])
	var green := K.mat(Color(0.42, 0.64, 0.48))
	var green2 := K.mat(Color(0.52, 0.74, 0.52))
	var h := 9.0 + float(v % 4) * 2.2
	var w := 2.8 + float(v % 3) * 0.5
	K.cyl(p, w * 0.55, w, h * 0.55, Vector3(0, h * 0.275, 0), rock, 9)
	K.cyl(p, w * 0.32, w * 0.56, h * 0.35, Vector3(0, h * 0.55 + h * 0.175, 0), rock, 9)
	K.sphere(p, w * 0.34, Vector3(0, h * 0.9, 0), rock, 9, Vector3(1, 1.2, 1))
	K.sphere(p, w * 0.4, Vector3(0, h * 0.98, 0), green, 9, Vector3(1, 0.5, 1))
	for i in 5:
		var a := i * 1.7 + v
		var y := h * (0.3 + 0.12 * i)
		var r := lerpf(w, w * 0.4, (y / h))
		K.sphere(p, 0.7 + (i % 2) * 0.3, Vector3(cos(a) * r, y, sin(a) * r), green if i % 2 == 0 else green2, 8, Vector3(1.3, 0.55, 1.3))
