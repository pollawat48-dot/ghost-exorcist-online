extends Node3D
## สิ่งของในฉากธีมไทยแบบ 3D low-poly สร้างจากรูปทรงพื้นฐาน (จุดอ้างอิงอยู่ที่ฐาน, ด้านหน้าหันไปทาง +z)
## ภายหลังเปลี่ยนเป็นโมเดลจริง (.glb) ทีละชนิดได้โดยใช้ kind เดิม

const K = preload("res://maps/props/mesh_kit.gd")

const WHITE := Color(0.95, 0.93, 0.88)
const RED := Color(0.66, 0.12, 0.09)
const GREEN_TRIM := Color(0.13, 0.42, 0.28)
const WOOD := Color(0.5, 0.32, 0.18)
const WOOD_DARK := Color(0.3, 0.18, 0.1)
const LEAF := Color(0.2, 0.46, 0.16)
const LEAF_LIGHT := Color(0.34, 0.6, 0.22)

## ขอบเขตที่เดินผ่านไม่ได้ (หน่วยตรรกะเกม เทียบกับจุดฐาน)
const FOOTPRINTS := {
	"ubosot": Rect2(-176, -112, 352, 224),
	"chedi": Rect2(-80, -80, 160, 160),
	"ruin_chedi": Rect2(-72, -72, 144, 144),
	"sala": Rect2(-72, -48, 144, 96),
	"stilt_house": Rect2(-64, -48, 128, 96),
	"rice_hut": Rect2(-30, -24, 60, 48),
	"spirit_house": Rect2(-12, -12, 24, 24),
	"bodhi": Rect2(-20, -20, 40, 40),
}
const SWAYING := ["palm", "banana"]

var kind := ""
var variant := 0
var t := 0.0
var _sway_nodes: Array[Node3D] = []
var _lights: Array[OmniLight3D] = []


func _ready() -> void:
	t = variant * 0.37
	rotation.y = 0.0
	match kind:
		"ubosot": _ubosot()
		"chedi": _chedi(false)
		"ruin_chedi": _chedi(true)
		"sala": _sala()
		"stilt_house": _stilt_house()
		"spirit_house": _spirit_house()
		"bodhi": _bodhi()
		"palm": _palm()
		"banana": _banana()
		"tomb": _tomb()
		"lantern": _lantern()
		"rice_hut": _rice_hut()
		"scarecrow": _scarecrow()
		"bush": _bush()
	set_process(kind in SWAYING)


func footprint() -> Rect2:
	return FOOTPRINTS.get(kind, Rect2())


func _process(delta: float) -> void:
	t += delta
	for i in _sway_nodes.size():
		_sway_nodes[i].rotation.z = sin(t * 1.2 + i * 0.7 + variant) * 0.04
		_sway_nodes[i].rotation.x = sin(t * 0.9 + i) * 0.03


func _night_light(pos: Vector3, color: Color, energy: float, light_range: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.omni_range = light_range
	light.light_energy = 0.0
	light.shadow_enabled = false
	light.set_meta("base_energy", energy)
	light.add_to_group("night_light")
	add_child(light)


# ---------- ตัวช่วย ----------

## หลังคาทรงไทยหนึ่งชั้น + ขอบเขียว + ปั้นลมทอง
func _thai_roof(y: float, width: float, depth: float, height: float, top_width: float, color: Color) -> void:
	K.roof(self, width, depth, height, top_width, Vector3(0, y, 0), color)
	K.box(self, Vector3(width + 0.1, 0.12, 0.12), Vector3(0, y + 0.03, depth / 2.0), GREEN_TRIM)
	K.box(self, Vector3(width + 0.1, 0.12, 0.12), Vector3(0, y + 0.03, -depth / 2.0), GREEN_TRIM)
	for side in [-1.0, 1.0]:
		for z in [depth / 2.0 + 0.05, -depth / 2.0 - 0.05]:
			K.beam(self, Vector3(side * width / 2.0, y, z), Vector3(side * top_width / 2.0, y + height, z), 0.14, K.gold())
			# หางหงส์
			K.beam(self, Vector3(side * width / 2.0, y, z), Vector3(side * (width / 2.0 + 0.3), y + 0.45, z), 0.12, K.gold())


func _chofa(pos: Vector3, size: float = 1.0) -> void:
	K.beam(self, pos, pos + Vector3(0, 0.45, 0.15) * size, 0.1 * size, K.gold())
	K.beam(self, pos + Vector3(0, 0.45, 0.15) * size, pos + Vector3(0, 0.6, 0.45) * size, 0.08 * size, K.gold())


# ---------- สิ่งปลูกสร้าง ----------

func _ubosot() -> void:
	var white := K.mat(WHITE, 0.0, 0.7)
	K.box(self, Vector3(11, 0.6, 7), Vector3(0, 0.3, 0), K.mat(WHITE.darkened(0.06)))
	for i in 3:
		K.box(self, Vector3(2.4, 0.2, 0.35), Vector3(0, 0.1 + i * 0.2, 3.95 - i * 0.35), K.mat(WHITE.darkened(0.12)))
	K.box(self, Vector3(8, 3.6, 5), Vector3(0, 2.4, 0), white)
	for i in 7:
		var x := -3.9 + i * 1.3
		for z in [2.75, -2.75]:
			K.cyl(self, 0.2, 0.22, 3.6, Vector3(x, 2.4, z), white, 10)
			K.box(self, Vector3(0.5, 0.25, 0.5), Vector3(x, 4.15, z), K.gold())
	K.box(self, Vector3(1.6, 2.7, 0.08), Vector3(0, 1.95, 2.52), K.gold())
	K.box(self, Vector3(1.3, 2.5, 0.1), Vector3(0, 1.85, 2.54), K.mat(RED))
	for x in [-2.6, 2.6]:
		K.box(self, Vector3(0.8, 1.1, 0.08), Vector3(x, 2.6, 2.52), K.gold())
		K.box(self, Vector3(0.6, 0.9, 0.1), Vector3(x, 2.6, 2.54), K.mat(RED))
	for z in [-1.5, 0.0, 1.5]:
		for side in [-1.0, 1.0]:
			K.box(self, Vector3(0.1, 1.0, 0.6), Vector3(side * 4.02, 2.6, z), K.mat(RED))
	_thai_roof(4.2, 10.4, 7.6, 1.0, 7.2, RED)
	_thai_roof(5.2, 7.6, 6.8, 3.4, 0.0, Color(0.72, 0.16, 0.1))
	# หน้าบันทอง
	K.roof(self, 6.4, 0.12, 2.9, 0.0, Vector3(0, 5.35, 3.42), K.gold())
	K.roof(self, 4.6, 0.14, 2.0, 0.0, Vector3(0, 5.55, 3.44), K.mat(RED.darkened(0.2)))
	K.sphere(self, 0.35, Vector3(0, 6.4, 3.55), K.gold(), 10, Vector3(1, 1, 0.3))
	K.roof(self, 6.4, 0.12, 2.9, 0.0, Vector3(0, 5.35, -3.42), K.gold())
	_chofa(Vector3(0, 8.55, 3.4), 1.6)
	_chofa(Vector3(0, 8.55, -3.4), 1.6)
	_night_light(Vector3(0, 2.5, 4.5), Color(1, 0.75, 0.4), 1.5, 9.0)


func _chedi(ruined: bool) -> void:
	var stone := K.mat(Color(0.55, 0.52, 0.47), 0.0, 0.95) if ruined else K.mat(WHITE, 0.0, 0.6)
	var body: Material = K.mat(Color(0.52, 0.49, 0.44), 0.0, 0.95) if ruined else K.gold()
	K.cyl(self, 2.4, 2.6, 0.6, Vector3(0, 0.3, 0), stone, 16)
	K.cyl(self, 2.0, 2.2, 0.6, Vector3(0, 0.9, 0), stone, 16)
	K.cyl(self, 1.7, 1.8, 0.5, Vector3(0, 1.45, 0), stone, 16)
	K.cyl(self, 1.45, 1.75, 1.0, Vector3(0, 2.2, 0), body, 20)
	K.sphere(self, 1.5, Vector3(0, 2.9, 0), body, 20, Vector3(1, 0.95, 1))
	if ruined:
		# ยอดหัก ก้อนอิฐหล่น มอสเขียวเกาะ
		K.cyl(self, 0.3, 0.5, 0.9, Vector3(0.1, 4.6, 0), body, 8, Vector3(0.12, 0, 0.18))
		var moss := K.mat(Color(0.22, 0.4, 0.18))
		for i in 9:
			var a := i * 0.7 + variant
			K.sphere(self, 0.25 + (i % 3) * 0.08, Vector3(cos(a) * 1.4, 2.0 + (i % 4) * 0.5, sin(a) * 1.4), moss, 8)
		for i in 6:
			var a := i * 1.1
			K.box(self, Vector3(0.5, 0.3, 0.35), Vector3(cos(a) * 3.2, 0.15, sin(a) * 3.0), stone, Vector3(0, a, 0.2))
		return
	K.box(self, Vector3(1.0, 0.5, 1.0), Vector3(0, 4.55, 0), body)
	for i in 7:
		var r := 0.42 - i * 0.05
		K.cyl(self, r * 0.85, r, 0.3, Vector3(0, 4.95 + i * 0.32, 0), body, 14)
	K.cyl(self, 0.01, 0.12, 2.2, Vector3(0, 8.3, 0), body, 10)
	K.sphere(self, 0.08, Vector3(0, 9.45, 0), body, 8)


func _sala() -> void:
	K.box(self, Vector3(4.6, 0.4, 3.0), Vector3(0, 0.2, 0), K.mat(WOOD))
	for x in [-1.9, 0.0, 1.9]:
		for z in [-1.2, 1.2]:
			K.cyl(self, 0.12, 0.14, 2.4, Vector3(x, 1.6, z), K.mat(Color(0.55, 0.14, 0.1)), 8)
	K.box(self, Vector3(4.2, 0.35, 0.15), Vector3(0, 2.6, 1.2), K.gold())
	_thai_roof(2.8, 5.4, 3.6, 0.6, 3.6, RED)
	_thai_roof(3.4, 4.0, 3.2, 1.5, 0.0, Color(0.72, 0.16, 0.1))
	K.roof(self, 3.2, 0.1, 1.25, 0.0, Vector3(0, 3.45, 1.62), K.gold())
	_chofa(Vector3(0, 4.9, 1.6))
	_chofa(Vector3(0, 4.9, -1.6))


func _stilt_house() -> void:
	var wall := K.mat(WOOD.darkened(0.1 * (variant % 3)))
	for x in [-1.7, 0.0, 1.7]:
		for z in [-1.2, 1.2]:
			K.cyl(self, 0.1, 0.1, 1.5, Vector3(x, 0.75, z), K.mat(WOOD_DARK), 6)
	K.box(self, Vector3(4.0, 0.15, 3.0), Vector3(0, 1.55, 0), K.mat(WOOD_DARK.lightened(0.1)))
	K.box(self, Vector3(3.4, 1.9, 2.5), Vector3(0, 2.6, 0), wall)
	for i in 8:
		K.box(self, Vector3(0.04, 1.9, 0.02), Vector3(-1.6 + i * 0.46, 2.6, 1.26), K.mat(WOOD_DARK))
	K.box(self, Vector3(0.6, 0.7, 0.05), Vector3(-0.8, 2.8, 1.27), K.mat(Color(0.08, 0.05, 0.03)))
	K.box(self, Vector3(0.6, 0.7, 0.05), Vector3(0.8, 2.8, 1.27), K.mat(Color(0.08, 0.05, 0.03)))
	var roof_c := Color(0.32, 0.2, 0.12) if variant % 2 == 0 else Color(0.55, 0.2, 0.13)
	K.roof(self, 4.6, 3.6, 2.2, 0.0, Vector3(0, 3.5, 0), roof_c)
	for z in [1.85, -1.85]:
		for side in [-1.0, 1.0]:
			K.beam(self, Vector3(side * 2.4, 3.4, z), Vector3(0, 5.8, z), 0.12, K.mat(WOOD_DARK))
	# บันได
	for side in [-0.3, 0.3]:
		K.beam(self, Vector3(1.4 + side, 0, 2.6), Vector3(1.4 + side, 1.55, 1.5), 0.08, K.mat(WOOD_DARK))
	for i in 4:
		K.box(self, Vector3(0.6, 0.05, 0.12), Vector3(1.4, 0.35 + i * 0.35, 2.4 - i * 0.25), K.mat(WOOD_DARK))
	_night_light(Vector3(0, 2.6, 1.8), Color(1, 0.7, 0.35), 0.8, 5.0)


func _spirit_house() -> void:
	K.cyl(self, 0.08, 0.1, 1.3, Vector3(0, 0.65, 0), K.mat(WHITE), 8)
	K.box(self, Vector3(0.9, 0.06, 0.9), Vector3(0, 1.32, 0), K.mat(WHITE.darkened(0.1)))
	K.box(self, Vector3(0.5, 0.45, 0.5), Vector3(0, 1.58, 0), K.gold())
	K.box(self, Vector3(0.18, 0.32, 0.02), Vector3(0, 1.53, 0.26), K.mat(RED))
	K.roof(self, 0.7, 0.66, 0.22, 0.4, Vector3(0, 1.8, 0), RED)
	K.roof(self, 0.42, 0.56, 0.4, 0.0, Vector3(0, 2.0, 0), RED.darkened(0.15))
	_chofa(Vector3(0, 2.4, 0.28), 0.35)
	var colors := [Color(1, 0.85, 0.2), Color(1, 1, 1), Color(1, 0.4, 0.5)]
	for i in 10:
		var a := TAU * i / 10.0
		K.sphere(self, 0.05, Vector3(cos(a) * 0.4, 1.38, sin(a) * 0.4), K.mat(colors[i % 3]), 6)
	for i in 3:
		K.box(self, Vector3(0.05, 0.14, 0.05), Vector3(-0.25 + i * 0.1, 1.42, 0.33), K.mat(Color(0.85, 0.1, 0.15)))
	_night_light(Vector3(0, 1.7, 0.5), Color(1, 0.6, 0.3), 0.8, 3.0)


func _rice_hut() -> void:
	for x in [-0.8, 0.8]:
		for z in [-0.6, 0.6]:
			K.cyl(self, 0.06, 0.06, 2.6, Vector3(x, 1.3, z), K.mat(WOOD_DARK), 6)
	K.box(self, Vector3(1.9, 0.1, 1.5), Vector3(0, 0.9, 0), K.mat(WOOD))
	K.roof(self, 2.4, 2.0, 1.1, 0.0, Vector3(0, 2.5, 0), Color(0.75, 0.62, 0.32))


# ---------- ต้นไม้และพืช ----------

func _bodhi() -> void:
	var bark := K.mat(Color(0.42, 0.33, 0.25), 0.0, 0.95)
	K.cyl(self, 0.45, 0.75, 4.0, Vector3(0, 2.0, 0), bark, 10)
	for i in 5:
		var a := i * TAU / 5.0
		K.beam(self, Vector3(0, 0.6, 0), Vector3(cos(a) * 1.2, -0.1, sin(a) * 1.2), 0.25, bark)
	var cloth := [Color(1, 0.25, 0.45), Color(1, 0.85, 0.2), Color(0.3, 0.8, 0.35)]
	for i in 3:
		K.cyl(self, 0.66 - i * 0.02, 0.68 - i * 0.02, 0.18, Vector3(0, 1.2 + i * 0.2, 0), K.mat(cloth[i]), 12)
	for i in 5:
		var a := i * TAU / 5.0 + 0.3
		K.beam(self, Vector3(0, 3.8, 0), Vector3(cos(a) * 2.0, 5.4, sin(a) * 2.0), 0.3, bark)
	var leaves := [K.mat(Color(0.15, 0.36, 0.13)), K.mat(Color(0.2, 0.44, 0.16)), K.mat(Color(0.26, 0.5, 0.18))]
	for i in 14:
		var a := i * 2.4
		var r := 1.0 + (i % 4) * 0.7
		K.sphere(self, 1.5 + (i % 3) * 0.4, Vector3(cos(a) * r, 5.6 + (i % 5) * 0.45, sin(a) * r), leaves[i % 3], 10)
	for i in 8:
		var a := i * 0.8
		K.cyl(self, 0.03, 0.03, 2.2, Vector3(cos(a) * 2.6, 3.8, sin(a) * 2.6), bark, 4)


func _palm() -> void:
	var lean := Vector3((variant % 5 - 2) * 0.35, 0, (variant % 3 - 1) * 0.3)
	var height := 6.5 + (variant % 4) * 0.6
	var bark := K.mat(Color(0.45, 0.36, 0.26), 0.0, 0.95)
	var prev := Vector3.ZERO
	for i in range(1, 8):
		var f := i / 7.0
		var p := lean * f * f * 3.0 + Vector3(0, height * f, 0)
		K.beam(self, prev, p, 0.28 - f * 0.08, bark)
		prev = p
	var crown := Node3D.new()
	crown.position = prev
	add_child(crown)
	_sway_nodes.append(crown)
	for i in 10:
		var a := i * TAU / 10.0 + variant
		var frond := Node3D.new()
		frond.rotation = Vector3(0, a, 0)
		crown.add_child(frond)
		var length := 2.8 + (i % 3) * 0.4
		# ทางมะพร้าวโค้งลง สร้างเป็นสามท่อน
		var pts := [Vector3.ZERO, Vector3(0, 0.3, length * 0.4), Vector3(0, 0.0, length * 0.75), Vector3(0, -0.8, length)]
		for k in 3:
			K.beam(frond, pts[k], pts[k + 1], 0.06, K.mat(LEAF.darkened(0.2)))
			var w := 0.9 - k * 0.25
			K.box(frond, Vector3(w, 0.03, pts[k].distance_to(pts[k + 1])), (pts[k] + pts[k + 1]) / 2.0,
				K.mat(LEAF if i % 2 == 0 else LEAF_LIGHT), Vector3(-atan2(pts[k + 1].y - pts[k].y, pts[k + 1].z - pts[k].z), 0, 0))
	for i in 3:
		K.sphere(crown, 0.18, Vector3(cos(i * 2.1) * 0.25, -0.25, sin(i * 2.1) * 0.25), K.mat(Color(0.4, 0.28, 0.12)), 8)


func _banana() -> void:
	K.cyl(self, 0.14, 0.2, 1.8, Vector3(0, 0.9, 0), K.mat(Color(0.4, 0.5, 0.2)), 8)
	var crown := Node3D.new()
	crown.position = Vector3(0, 1.8, 0)
	add_child(crown)
	_sway_nodes.append(crown)
	for i in 7:
		var a := i * TAU / 7.0 + variant
		var leaf := Node3D.new()
		leaf.rotation = Vector3(0, a, 0)
		crown.add_child(leaf)
		var lift := 0.5 + (i % 3) * 0.25
		K.box(leaf, Vector3(0.7, 0.03, 1.8), Vector3(0, 0.45 * lift, 0.9), K.mat(LEAF_LIGHT if i % 2 == 0 else LEAF), Vector3(-lift * 0.6, 0, 0))
		K.box(leaf, Vector3(0.05, 0.05, 1.8), Vector3(0, 0.47 * lift, 0.9), K.mat(LEAF_LIGHT.lightened(0.25)), Vector3(-lift * 0.6, 0, 0))
	if variant % 3 == 0:
		for i in 6:
			K.sphere(crown, 0.09, Vector3(0.3, -0.15 - i * 0.1, 0.1 + (i % 2) * 0.1), K.mat(Color(0.65, 0.75, 0.25)), 6, Vector3(1, 0.6, 1.6))
		K.sphere(crown, 0.16, Vector3(0.32, -0.85, 0.15), K.mat(Color(0.5, 0.12, 0.28)), 8, Vector3(1, 1.5, 1))


func _bush() -> void:
	var leaf := K.mat(LEAF.darkened(0.1))
	K.sphere(self, 0.5, Vector3(-0.35, 0.35, 0), leaf, 8)
	K.sphere(self, 0.5, Vector3(0.35, 0.35, 0.1), leaf, 8)
	K.sphere(self, 0.6, Vector3(0, 0.55, -0.1), K.mat(LEAF), 8)
	if variant % 2 == 0:
		for i in 6:
			var a := i * 1.05
			K.sphere(self, 0.08, Vector3(cos(a) * 0.55, 0.6 + (i % 2) * 0.25, sin(a) * 0.45), K.mat(Color(1, 0.45, 0.6)), 6)


# ---------- ของในป่าช้า/ทุ่ง ----------

func _tomb() -> void:
	var stone := K.mat(Color(0.6, 0.58, 0.55).darkened(0.08 * (variant % 3)), 0.0, 0.95)
	K.sphere(self, 0.8, Vector3(0, 0, -0.3), K.mat(Color(0.42, 0.37, 0.27)), 10, Vector3(1, 0.45, 1.2))
	K.box(self, Vector3(0.6, 0.85, 0.15), Vector3(0, 0.43, 0.55), stone)
	K.cyl(self, 0.3, 0.3, 0.15, Vector3(0, 0.86, 0.55), stone, 10, Vector3(PI / 2.0, 0, 0))
	if variant % 2 == 0:
		K.box(self, Vector3(0.08, 0.6, 0.02), Vector3(0, 0.45, 0.64), K.mat(Color(0.65, 0.1, 0.08)))
	if variant % 4 == 1:
		for i in 3:
			K.cyl(self, 0.01, 0.01, 0.35, Vector3(-0.1 + i * 0.1, 0.18, 0.85), K.mat(Color(0.8, 0.3, 0.2)), 4)


func _lantern() -> void:
	K.cyl(self, 0.05, 0.06, 2.0, Vector3(0, 1.0, 0), K.mat(WOOD_DARK), 6)
	K.box(self, Vector3(0.45, 0.05, 0.05), Vector3(0.2, 1.95, 0), K.mat(WOOD_DARK))
	K.sphere(self, 0.2, Vector3(0.38, 1.65, 0), K.mat(Color(0.95, 0.3, 0.12), 1.2), 10, Vector3(1, 1.25, 1))
	K.cyl(self, 0.12, 0.12, 0.05, Vector3(0.38, 1.9, 0), K.gold(), 8)
	_night_light(Vector3(0.38, 1.6, 0), Color(1, 0.55, 0.25), 2.0, 6.0)


func _scarecrow() -> void:
	K.cyl(self, 0.04, 0.05, 2.0, Vector3(0, 1.0, 0), K.mat(WOOD_DARK), 6)
	K.box(self, Vector3(1.4, 0.06, 0.06), Vector3(0, 1.45, 0), K.mat(WOOD_DARK))
	K.box(self, Vector3(0.7, 0.7, 0.3), Vector3(0, 1.2, 0), K.mat(Color(0.3, 0.45, 0.75)))
	K.sphere(self, 0.22, Vector3(0, 1.85, 0), K.mat(Color(0.85, 0.75, 0.5)), 8)
	K.cyl(self, 0.01, 0.45, 0.35, Vector3(0, 2.1, 0), K.mat(Color(0.8, 0.65, 0.3)), 10)
