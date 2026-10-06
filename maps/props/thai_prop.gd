extends Node3D
## สิ่งของในฉากธีมไทยแบบ 3D low-poly สร้างจากรูปทรงพื้นฐาน (จุดอ้างอิงอยู่ที่ฐาน, ด้านหน้าหันไปทาง +z)
## ภายหลังเปลี่ยนเป็นโมเดลจริง (.glb) ทีละชนิดได้โดยใช้ kind เดิม

const K = preload("res://maps/props/mesh_kit.gd")

## โทนพาสเทลแบบการ์ตูน
const WHITE := Color(1.0, 0.96, 0.9)
const RED := Color(0.96, 0.47, 0.45)
const GREEN_TRIM := Color(0.47, 0.78, 0.66)
const WOOD := Color(0.82, 0.6, 0.44)
const WOOD_DARK := Color(0.6, 0.42, 0.34)
const LEAF := Color(0.47, 0.76, 0.42)
const LEAF_LIGHT := Color(0.64, 0.87, 0.5)

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
	"cottage": Rect2(-56, -44, 112, 88),
	"haunted_house": Rect2(-64, -48, 128, 96),
	"well": Rect2(-22, -22, 44, 44),
	"rain_tree": Rect2(-18, -18, 36, 36),
	"mango": Rect2(-12, -12, 24, 24),
	"bamboo": Rect2(-22, -22, 44, 44),
	"dead_tree": Rect2(-10, -10, 20, 20),
}
const SWAYING := ["palm", "banana", "bamboo", "laundry", "haunted_house"]

## สีผนังบ้านพาสเทล: ชมพู มิ้นต์ ครีมเหลือง ฟ้า และหลังคาคู่กัน
const COTTAGE_WALLS := [Color(1.0, 0.86, 0.84), Color(0.84, 0.95, 0.86), Color(1.0, 0.93, 0.74), Color(0.84, 0.9, 1.0)]
const COTTAGE_ROOFS := [Color(0.93, 0.5, 0.5), Color(0.45, 0.72, 0.66), Color(0.95, 0.66, 0.4), Color(0.55, 0.62, 0.9)]
const HAUNT_WOOD := Color(0.6, 0.54, 0.62)
const HAUNT_DARK := Color(0.4, 0.34, 0.44)

var kind := ""
var variant := 0
var t := 0.0
var _sway_nodes: Array[Node3D] = []
var _lights: Array[OmniLight3D] = []
var _wisps: Array[Node3D] = []
var _wisp_base: Array[float] = []


func _ready() -> void:
	t = variant * 0.37
	if not has_meta("keep_rotation"):
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
		"cottage": _cottage()
		"haunted_house": _haunted_house()
		"well": _well()
		"jar": _jar(Vector3.ZERO)
		"laundry": _laundry()
		"flower_bed": _flower_bed()
		"boat": _boat()
		"pier": _pier()
		"fence": _fence(false)
		"broken_fence": _fence(true)
		"rain_tree": _rain_tree()
		"mango": _mango()
		"bamboo": _bamboo()
		"frangipani": _frangipani()
		"dead_tree": _dead_tree()
	set_process(kind in SWAYING)


func footprint() -> Rect2:
	return FOOTPRINTS.get(kind, Rect2())


func _process(delta: float) -> void:
	t += delta
	for i in _sway_nodes.size():
		_sway_nodes[i].rotation.z = sin(t * 1.2 + i * 0.7 + variant) * 0.04
		_sway_nodes[i].rotation.x = sin(t * 0.9 + i) * 0.03
	# ดวงไฟผีลอยขึ้นลงรอบบ้านร้าง
	for i in _wisps.size():
		_wisps[i].position.y = _wisp_base[i] + sin(t * 1.6 + i * 2.0) * 0.25


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
	_thai_roof(5.2, 7.6, 6.8, 3.4, 0.0, Color(0.98, 0.56, 0.52))
	# หน้าบันทอง
	K.roof(self, 6.4, 0.12, 2.9, 0.0, Vector3(0, 5.35, 3.42), K.gold())
	K.roof(self, 4.6, 0.14, 2.0, 0.0, Vector3(0, 5.55, 3.44), K.mat(RED.darkened(0.2)))
	K.sphere(self, 0.35, Vector3(0, 6.4, 3.55), K.gold(), 10, Vector3(1, 1, 0.3))
	K.roof(self, 6.4, 0.12, 2.9, 0.0, Vector3(0, 5.35, -3.42), K.gold())
	_chofa(Vector3(0, 8.55, 3.4), 1.6)
	_chofa(Vector3(0, 8.55, -3.4), 1.6)
	_night_light(Vector3(0, 2.5, 4.5), Color(1, 0.75, 0.4), 1.5, 9.0)


func _chedi(ruined: bool) -> void:
	var stone := K.mat(Color(0.76, 0.72, 0.72), 0.0, 0.95) if ruined else K.mat(WHITE, 0.0, 0.6)
	var body: Material = K.mat(Color(0.72, 0.68, 0.68), 0.0, 0.95) if ruined else K.gold()
	K.cyl(self, 2.4, 2.6, 0.6, Vector3(0, 0.3, 0), stone, 16)
	K.cyl(self, 2.0, 2.2, 0.6, Vector3(0, 0.9, 0), stone, 16)
	K.cyl(self, 1.7, 1.8, 0.5, Vector3(0, 1.45, 0), stone, 16)
	K.cyl(self, 1.45, 1.75, 1.0, Vector3(0, 2.2, 0), body, 20)
	K.sphere(self, 1.5, Vector3(0, 2.9, 0), body, 20, Vector3(1, 0.95, 1))
	if ruined:
		# ยอดหัก ก้อนอิฐหล่น มอสเขียวเกาะ
		K.cyl(self, 0.3, 0.5, 0.9, Vector3(0.1, 4.6, 0), body, 8, Vector3(0.12, 0, 0.18))
		var moss := K.mat(Color(0.5, 0.74, 0.46))
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
			K.cyl(self, 0.12, 0.14, 2.4, Vector3(x, 1.6, z), K.mat(Color(0.9, 0.42, 0.42)), 8)
	K.box(self, Vector3(4.2, 0.35, 0.15), Vector3(0, 2.6, 1.2), K.gold())
	_thai_roof(2.8, 5.4, 3.6, 0.6, 3.6, RED)
	_thai_roof(3.4, 4.0, 3.2, 1.5, 0.0, Color(0.98, 0.56, 0.52))
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
	K.box(self, Vector3(0.6, 0.7, 0.05), Vector3(-0.8, 2.8, 1.27), K.mat(Color(0.45, 0.32, 0.4)))
	K.box(self, Vector3(0.6, 0.7, 0.05), Vector3(0.8, 2.8, 1.27), K.mat(Color(0.45, 0.32, 0.4)))
	var roof_c := Color(0.62, 0.42, 0.36) if variant % 2 == 0 else Color(0.92, 0.5, 0.48)
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
	K.roof(self, 2.4, 2.0, 1.1, 0.0, Vector3(0, 2.5, 0), Color(0.98, 0.84, 0.55))


# ---------- ต้นไม้และพืช ----------

func _bodhi() -> void:
	var bark := K.mat(Color(0.66, 0.5, 0.4), 0.0, 0.95)
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
	var leaves := [K.mat(Color(0.4, 0.68, 0.38)), K.mat(Color(0.5, 0.78, 0.44)), K.mat(Color(0.6, 0.85, 0.5))]
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
	var bark := K.mat(Color(0.74, 0.58, 0.44), 0.0, 0.95)
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
		K.sphere(crown, 0.18, Vector3(cos(i * 2.1) * 0.25, -0.25, sin(i * 2.1) * 0.25), K.mat(Color(0.62, 0.45, 0.3)), 8)


func _banana() -> void:
	K.cyl(self, 0.14, 0.2, 1.8, Vector3(0, 0.9, 0), K.mat(Color(0.62, 0.78, 0.42)), 8)
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
	var stone := K.mat(Color(0.8, 0.78, 0.82).darkened(0.08 * (variant % 3)), 0.0, 0.95)
	K.sphere(self, 0.8, Vector3(0, 0, -0.3), K.mat(Color(0.72, 0.62, 0.5)), 10, Vector3(1, 0.45, 1.2))
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
	K.box(self, Vector3(0.7, 0.7, 0.3), Vector3(0, 1.2, 0), K.mat(Color(0.55, 0.7, 0.95)))
	K.sphere(self, 0.22, Vector3(0, 1.85, 0), K.mat(Color(1.0, 0.9, 0.7)), 8)
	K.cyl(self, 0.01, 0.45, 0.35, Vector3(0, 2.1, 0), K.mat(Color(1.0, 0.85, 0.5)), 10)


# ---------- หมู่บ้าน: บ้านคน ของใช้ ----------

## บ้านไม้หลังเล็กสีพาสเทล ใต้ถุนเตี้ย มีระเบียง หน้าต่างกล่องดอกไม้ และโอ่งน้ำข้างบ้าน
func _cottage() -> void:
	var c := variant % COTTAGE_WALLS.size()
	var wall := K.mat(COTTAGE_WALLS[c])
	var roof_c: Color = COTTAGE_ROOFS[(c + variant / 4) % COTTAGE_ROOFS.size()]
	var trim := K.mat(WOOD_DARK)
	for x in [-1.6, 1.6]:
		for z in [-1.2, 1.2]:
			K.cyl(self, 0.09, 0.09, 0.6, Vector3(x, 0.3, z), trim, 6)
	K.box(self, Vector3(3.6, 0.16, 2.8), Vector3(0, 0.66, 0), K.mat(WOOD))
	K.box(self, Vector3(3.0, 1.6, 2.1), Vector3(0, 1.54, -0.2), wall)
	for x in [-1.5, 1.5]:
		K.box(self, Vector3(0.12, 1.64, 0.12), Vector3(x, 1.54, 0.86), trim)
	# ประตูกับลูกบิด
	K.box(self, Vector3(0.66, 1.15, 0.06), Vector3(0.6, 1.32, 0.86), K.mat(WOOD_DARK.lightened(0.1)))
	K.sphere(self, 0.04, Vector3(0.38, 1.3, 0.9), K.gold(), 6)
	# หน้าต่างบานเปิด + กล่องดอกไม้
	var glass := K.mat(Color(0.98, 0.86, 0.55), 0.0, 0.4)
	var shutter := K.mat(COTTAGE_ROOFS[(c + 1) % COTTAGE_ROOFS.size()])
	K.box(self, Vector3(0.62, 0.55, 0.05), Vector3(-0.7, 1.7, 0.87), glass)
	K.box(self, Vector3(0.7, 0.07, 0.07), Vector3(-0.7, 1.99, 0.89), K.mat(WHITE))
	K.box(self, Vector3(0.07, 0.62, 0.07), Vector3(-0.7, 1.7, 0.9), K.mat(WHITE))
	for sx in [-1.12, -0.28]:
		K.box(self, Vector3(0.22, 0.6, 0.05), Vector3(sx, 1.7, 0.92), shutter)
	K.box(self, Vector3(0.75, 0.16, 0.18), Vector3(-0.7, 1.35, 0.97), K.mat(WOOD))
	var petals := [Color(1, 0.55, 0.65), Color(1, 0.85, 0.4), Color(1, 1, 1), Color(0.8, 0.6, 1)]
	for i in 6:
		K.sphere(self, 0.07, Vector3(-0.98 + i * 0.11, 1.48, 0.98), K.mat(petals[(i + variant) % 4]), 6)
	# ระเบียงหน้าบ้าน + บันได
	K.box(self, Vector3(0.9, 0.1, 0.45), Vector3(0.6, 0.42, 1.55), K.mat(WOOD))
	K.box(self, Vector3(0.9, 0.1, 0.45), Vector3(0.6, 0.2, 1.85), K.mat(WOOD))
	# หลังคาจั่ว ยื่นชายคาออกมา
	K.roof(self, 3.9, 3.2, 1.45, 0.0, Vector3(0, 2.32, -0.05), roof_c)
	K.box(self, Vector3(0.12, 0.12, 3.3), Vector3(0, 3.78, -0.05), K.mat(roof_c.darkened(0.2)))
	for side in [-1.0, 1.0]:
		K.beam(self, Vector3(side * 2.0, 2.28, 1.58), Vector3(0, 3.82, 1.58), 0.12, K.mat(WHITE))
	K.sphere(self, 0.16, Vector3(0, 3.05, 1.56), K.mat(WHITE), 8, Vector3(1, 1, 0.3))
	# ของข้างบ้าน
	_jar(Vector3(-2.1, 0, 1.0))
	if variant % 2 == 0:
		_jar(Vector3(-2.35, 0, 0.4), 0.8)
	K.cyl(self, 0.2, 0.15, 0.3, Vector3(1.55, 0.15, 1.65), K.mat(Color(0.86, 0.5, 0.4)), 8)
	K.sphere(self, 0.28, Vector3(1.55, 0.48, 1.65), K.mat(LEAF), 8)
	_night_light(Vector3(-0.7, 1.7, 1.4), Color(1, 0.75, 0.4), 0.9, 4.5)


## โอ่งมังกรเคลือบสีน้ำตาลแดง มีลายคาดสีทองและฝาไม้
func _jar(pos: Vector3, s: float = 1.0) -> void:
	K.sphere(self, 0.36 * s, pos + Vector3(0, 0.36 * s, 0), K.mat(Color(0.62, 0.36, 0.32), 0.0, 0.35), 12, Vector3(1, 1.1, 1))
	K.cyl(self, 0.33 * s, 0.33 * s, 0.07 * s, pos + Vector3(0, 0.45 * s, 0), K.mat(Color(1.0, 0.8, 0.4)), 12)
	K.cyl(self, 0.22 * s, 0.22 * s, 0.06 * s, pos + Vector3(0, 0.76 * s, 0), K.mat(WOOD), 10)


func _well() -> void:
	var stone := K.mat(Color(0.82, 0.8, 0.86))
	K.cyl(self, 0.7, 0.75, 0.75, Vector3(0, 0.37, 0), stone, 14)
	K.cyl(self, 0.56, 0.56, 0.02, Vector3(0, 0.74, 0), K.mat(Color(0.4, 0.62, 0.85), 0.0, 0.2, 0.0, false), 14)
	for x in [-0.6, 0.6]:
		K.cyl(self, 0.06, 0.06, 1.8, Vector3(x, 1.2, 0), K.mat(WOOD_DARK), 6)
	K.cyl(self, 0.05, 0.05, 1.3, Vector3(0, 1.8, 0), K.mat(WOOD), 6, Vector3(0, 0, PI / 2.0))
	K.roof(self, 1.7, 1.4, 0.6, 0.0, Vector3(0, 2.05, 0), Color(0.93, 0.5, 0.5))
	K.cyl(self, 0.01, 0.01, 0.6, Vector3(0, 1.48, 0), K.mat(Color(0.9, 0.85, 0.7)), 4)
	K.cyl(self, 0.13, 0.1, 0.2, Vector3(0, 1.1, 0), K.mat(Color(0.6, 0.75, 0.95)), 8)


## ราวตากผ้า ผ้าสีพาสเทลแกว่งตามลม
func _laundry() -> void:
	for z in [-1.4, 1.4]:
		K.cyl(self, 0.05, 0.06, 1.9, Vector3(0, 0.95, z), K.mat(WOOD_DARK), 6)
	K.cyl(self, 0.012, 0.012, 2.8, Vector3(0, 1.82, 0), K.mat(WHITE), 4, Vector3(PI / 2.0, 0, 0))
	var colors := [Color(1, 0.7, 0.75), Color(0.7, 0.85, 1), Color(1, 0.92, 0.6), Color(0.75, 0.93, 0.8), Color(0.85, 0.75, 1)]
	for i in 5:
		var cloth := Node3D.new()
		cloth.position = Vector3(0, 1.82, -1.1 + i * 0.55)
		add_child(cloth)
		var h := 0.5 + (i + variant) % 3 * 0.15
		K.box(cloth, Vector3(0.04, h, 0.42), Vector3(0, -h / 2.0, 0), K.mat(colors[(i + variant) % 5]))
		_sway_nodes.append(cloth)


func _flower_bed() -> void:
	K.box(self, Vector3(1.4, 0.18, 0.6), Vector3(0, 0.09, 0), K.mat(WOOD))
	K.box(self, Vector3(1.3, 0.1, 0.5), Vector3(0, 0.2, 0), K.mat(Color(0.55, 0.42, 0.36), 0.0, 0.9, 0.0, false))
	var colors := [Color(1, 0.55, 0.65), Color(1, 0.85, 0.4), Color(0.85, 0.65, 1), Color(1, 1, 1), Color(1, 0.65, 0.45)]
	for i in 12:
		var x := -0.55 + (i % 6) * 0.22
		var z := -0.12 + (i / 6) * 0.24
		K.cyl(self, 0.015, 0.015, 0.25, Vector3(x, 0.35, z), K.mat(LEAF.darkened(0.15)), 4)
		K.sphere(self, 0.08, Vector3(x, 0.5, z), K.mat(colors[(i + variant) % 5]), 6)


## เรือพายจอดในคลอง (ฐานอยู่ที่ระดับน้ำ)
func _boat() -> void:
	K.sphere(self, 1.0, Vector3(0, -0.45, 0), K.mat(Color(0.7, 0.48, 0.36)), 12, Vector3(0.55, 0.3, 2.0))
	K.sphere(self, 0.95, Vector3(0, -0.38, 0), K.mat(Color(0.5, 0.34, 0.28), 0.0, 0.9, 0.0, false), 12, Vector3(0.48, 0.2, 1.9))
	K.box(self, Vector3(1.0, 0.06, 0.25), Vector3(0, -0.25, 0.5), K.mat(WOOD))
	K.cyl(self, 0.01, 0.42, 0.25, Vector3(0, -0.12, -0.6), K.mat(Color(1.0, 0.86, 0.55)), 12)
	K.beam(self, Vector3(0.3, -0.2, 0.9), Vector3(0.9, -0.5, 2.0), 0.06, K.mat(WOOD_DARK))
	if variant % 2 == 0:
		for i in 3:
			K.sphere(self, 0.12, Vector3(-0.15 + i * 0.15, -0.2, -1.1), K.mat(Color(1, 0.7, 0.4)), 6)


## ท่าน้ำไม้ยื่นลงคลอง ยาวไปทาง +x
func _pier() -> void:
	K.box(self, Vector3(3.0, 0.14, 1.6), Vector3(1.2, 0.05, 0), K.mat(WOOD))
	for x in [0.0, 1.3, 2.6]:
		for z in [-0.7, 0.7]:
			K.cyl(self, 0.08, 0.08, 1.4, Vector3(x, -0.6, z), K.mat(WOOD_DARK), 6)
	for z in [-0.75, 0.75]:
		K.box(self, Vector3(2.8, 0.06, 0.06), Vector3(1.3, 0.6, z), K.mat(WOOD_DARK))
		for x in [0.0, 1.3, 2.6]:
			K.cyl(self, 0.04, 0.04, 0.55, Vector3(x, 0.35, z), K.mat(WOOD_DARK), 4)


## รั้วไม้ระแนงยาว 3 เมตรตามแกน x (แบบพังก็มีเสาเอียงและไม้หาย)
func _fence(broken: bool) -> void:
	var wood := K.mat(HAUNT_WOOD if broken else Color(0.95, 0.9, 0.82))
	for i in 7:
		if broken and (i + variant) % 3 == 0:
			continue
		var x := -1.5 + i * 0.5
		var tilt := ((i * 7 + variant) % 5 - 2) * 0.12 if broken else 0.0
		var h := 0.9 - (0.3 if broken and i % 2 == 1 else 0.0)
		K.box(self, Vector3(0.14, h, 0.06), Vector3(x, h / 2.0, 0), wood, Vector3(0, 0, tilt))
		if not broken:
			K.box(self, Vector3(0.1, 0.1, 0.06), Vector3(x, h + 0.02, 0), wood, Vector3(0, 0, PI / 4.0))
	K.box(self, Vector3(3.1 if not broken else 1.6, 0.08, 0.05), Vector3(0 if not broken else -0.7, 0.55, -0.05), wood, Vector3(0, 0, 0.0 if not broken else 0.15))
	if not broken:
		K.box(self, Vector3(3.1, 0.08, 0.05), Vector3(0, 0.25, -0.05), wood)


# ---------- บ้านร้าง ----------

func _haunted_house() -> void:
	var body := Node3D.new()
	body.rotation = Vector3(0.0, 0.0, 0.05 if variant % 2 == 0 else -0.05)
	add_child(body)
	var wood := K.mat(HAUNT_WOOD)
	var dark := K.mat(HAUNT_DARK)
	for x in [-1.7, 0.0, 1.7]:
		for z in [-1.2, 1.2]:
			K.cyl(body, 0.1, 0.1, 1.5 + (0.1 if x > 0 else 0.0), Vector3(x, 0.75, z), dark, 6)
	K.box(body, Vector3(4.0, 0.15, 3.0), Vector3(0, 1.55, 0), dark)
	K.box(body, Vector3(3.4, 1.9, 2.5), Vector3(0, 2.6, 0), wood)
	for i in 8:
		K.box(body, Vector3(0.05, 1.9, 0.02), Vector3(-1.6 + i * 0.46, 2.6, 1.26), dark)
	# หน้าต่างตอกไม้ปิดเป็นกากบาท
	for x in [-0.95, 0.95]:
		K.box(body, Vector3(0.7, 0.7, 0.04), Vector3(x, 2.85, 1.27), K.mat(Color(0.18, 0.14, 0.24), 0.0, 0.9, 0.0, false))
		K.box(body, Vector3(0.95, 0.1, 0.05), Vector3(x, 2.85, 1.31), wood, Vector3(0, 0, 0.6))
		K.box(body, Vector3(0.95, 0.1, 0.05), Vector3(x, 2.85, 1.32), wood, Vector3(0, 0, -0.6))
	# ประตูแง้มเปิด
	K.box(body, Vector3(0.7, 1.2, 0.04), Vector3(0.0, 2.25, 1.27), K.mat(Color(0.12, 0.1, 0.18), 0.0, 0.9, 0.0, false))
	K.box(body, Vector3(0.7, 1.2, 0.06), Vector3(0.3, 2.25, 1.55), dark, Vector3(0, -1.0, 0))
	# หลังคาพังเป็นแผ่น มีรูโหว่ ด้านหนึ่งยุบลง
	var slope := atan2(2.0, 2.4)
	var plank_len := sqrt(2.0 * 2.0 + 2.4 * 2.4)
	K.box(body, Vector3(plank_len, 0.12, 3.6), Vector3(-1.2, 4.5, 0), K.mat(HAUNT_DARK.lightened(0.1)), Vector3(0, 0, slope))
	for i in 4:
		if i == 1:
			continue
		var droop := 0.25 if i == 3 else 0.0
		K.box(body, Vector3(plank_len, 0.12, 0.8), Vector3(1.2, 4.5 - droop, -1.35 + i * 0.9), K.mat(HAUNT_DARK.lightened(0.05 * i)), Vector3(0, 0, -slope - droop * 0.5))
	for z in [1.85, -1.85]:
		K.beam(body, Vector3(-2.4, 3.4, z), Vector3(0, 5.5, z), 0.12, dark)
		K.beam(body, Vector3(2.4, 3.3, z), Vector3(0, 5.5, z), 0.12, dark)
	# บันไดหัก
	K.beam(body, Vector3(1.1, 0, 2.6), Vector3(1.1, 1.55, 1.5), 0.08, dark)
	K.beam(self, Vector3(1.7, 0.05, 2.9), Vector3(2.1, 0.35, 2.1), 0.08, dark)
	for i in [0, 2]:
		K.box(body, Vector3(0.6, 0.05, 0.12), Vector3(1.4, 0.35 + i * 0.35, 2.4 - i * 0.25), dark)
	K.box(self, Vector3(0.6, 0.05, 0.12), Vector3(2.0, 0.04, 2.5), dark, Vector3(0, 0.6, 0.1))
	# ใยแมงมุมตามมุมบ้าน
	var web := K.mat(Color(0.95, 0.95, 1.0, 0.7), 0.3, 0.8, 0.0, false)
	for side in [-1.0, 1.0]:
		var corner := Vector3(side * 1.7, 3.5, 1.3)
		for k in 3:
			K.beam(body, corner, corner + Vector3(-side * (0.3 + k * 0.15), -0.25 - k * 0.12, 0.02), 0.012, web)
	# เถาวัลย์ห้อยจากชายคา
	for i in 5:
		var x := -1.9 + i * 0.95
		K.cyl(body, 0.03, 0.03, 0.6 + (i % 3) * 0.3, Vector3(x, 3.3 - (i % 3) * 0.15, 1.75), K.mat(Color(0.45, 0.65, 0.45)), 4)
		K.sphere(body, 0.14, Vector3(x, 3.55, 1.75), K.mat(Color(0.5, 0.72, 0.48)), 6)
	# ป้ายเตือน "ห้ามเข้า"
	K.cyl(self, 0.05, 0.05, 1.3, Vector3(-2.5, 0.65, 2.6), dark, 6, Vector3(0, 0, 0.12))
	K.box(self, Vector3(1.1, 0.5, 0.06), Vector3(-2.42, 1.25, 2.62), K.mat(Color(0.86, 0.8, 0.7)), Vector3(0, 0, -0.08))
	var sign := Label3D.new()
	sign.text = "ห้ามเข้า!"
	sign.font = K.font()
	sign.font_size = 64
	sign.pixel_size = 0.0045
	sign.modulate = Color(0.75, 0.2, 0.3)
	sign.outline_size = 0
	sign.position = Vector3(-2.42, 1.25, 2.66)
	sign.rotation = Vector3(0, 0, -0.08)
	add_child(sign)
	# ดวงไฟผีสีเขียวม่วงลอยอยู่รอบบ้าน
	for i in 3:
		var wisp := Node3D.new()
		var base := 3.0 + i * 0.6
		wisp.position = Vector3(-1.5 + i * 1.5, base, 1.9 + (i % 2) * 0.5)
		add_child(wisp)
		var col := Color(0.6, 1.0, 0.75) if i % 2 == 0 else Color(0.8, 0.6, 1.0)
		K.sphere(wisp, 0.13, Vector3.ZERO, K.mat(col, 3.0, 0.5, 0.0, false), 8)
		K.sphere(wisp, 0.22, Vector3.ZERO, K.mat(Color(col, 0.3), 1.5, 0.5, 0.0, false), 8)
		_wisps.append(wisp)
		_wisp_base.append(base)
	_night_light(Vector3(0, 2.6, 1.6), Color(0.6, 0.9, 0.7), 1.4, 6.0)
	_night_light(Vector3(0, 3.4, 0), Color(0.75, 0.5, 1.0), 1.0, 5.0)


func _dead_tree() -> void:
	var bark := K.mat(Color(0.5, 0.44, 0.52), 0.0, 0.95)
	K.cyl(self, 0.2, 0.32, 2.6, Vector3(0, 1.3, 0), bark, 8, Vector3(0, 0, 0.08))
	var tips := []
	for i in 4:
		var a := i * TAU / 4.0 + variant
		var start := Vector3(0.1, 1.8 + i * 0.25, 0)
		var mid := start + Vector3(cos(a) * 0.9, 0.8, sin(a) * 0.9)
		var tip := mid + Vector3(cos(a + 0.8) * 0.6, 0.3 + (i % 2) * 0.4, sin(a + 0.8) * 0.6)
		K.beam(self, start, mid, 0.12, bark)
		K.beam(self, mid, tip, 0.07, bark)
		tips.append(tip)
	for i in 3:
		var a := i * 2.1
		K.beam(self, Vector3(0, 0.2, 0), Vector3(cos(a) * 0.7, -0.05, sin(a) * 0.7), 0.14, bark)
	# ผ้าแพรสีซีดผูกกิ่ง
	if variant % 2 == 0:
		var tip: Vector3 = tips[1]
		K.box(self, Vector3(0.08, 0.6, 0.2), tip + Vector3(0, -0.3, 0), K.mat(Color(0.85, 0.5, 0.6)))


# ---------- ต้นไม้เพิ่ม ----------

## ต้นจามจุรี ทรงร่มกว้าง มีดอกปุยสีชมพู
func _rain_tree() -> void:
	var bark := K.mat(Color(0.62, 0.48, 0.4), 0.0, 0.95)
	K.cyl(self, 0.38, 0.55, 2.6, Vector3(0, 1.3, 0), bark, 10)
	for i in 5:
		var a := i * TAU / 5.0 + variant
		K.beam(self, Vector3(0, 2.4, 0), Vector3(cos(a) * 2.4, 3.9, sin(a) * 2.4), 0.28, bark)
	var greens := [K.mat(Color(0.42, 0.72, 0.42)), K.mat(Color(0.5, 0.8, 0.46)), K.mat(Color(0.58, 0.85, 0.5))]
	K.sphere(self, 2.4, Vector3(0, 4.5, 0), greens[0], 14, Vector3(1.5, 0.45, 1.5))
	for i in 7:
		var a := i * TAU / 7.0
		K.sphere(self, 1.5, Vector3(cos(a) * 2.6, 4.3 + (i % 2) * 0.3, sin(a) * 2.6), greens[i % 3], 10, Vector3(1, 0.55, 1))
	K.sphere(self, 1.6, Vector3(0, 5.2, 0), greens[2], 12, Vector3(1.2, 0.5, 1.2))
	for i in 14:
		var a := i * 2.4
		var r := 1.2 + (i % 4) * 0.7
		K.sphere(self, 0.12, Vector3(cos(a) * r, 5.1 + (i % 3) * 0.15, sin(a) * r), K.mat(Color(1, 0.62, 0.75)), 6)


## ต้นมะม่วง พุ่มกลมแน่น บางต้นมีผลสีเหลือง
func _mango() -> void:
	var bark := K.mat(Color(0.58, 0.42, 0.34), 0.0, 0.95)
	K.cyl(self, 0.18, 0.26, 2.0, Vector3(0, 1.0, 0), bark, 8)
	var greens := [K.mat(Color(0.36, 0.62, 0.38)), K.mat(Color(0.44, 0.7, 0.42))]
	K.sphere(self, 1.3, Vector3(0, 2.8, 0), greens[0], 12)
	for i in 4:
		var a := i * TAU / 4.0 + variant
		K.sphere(self, 0.9, Vector3(cos(a) * 0.9, 2.5 + (i % 2) * 0.5, sin(a) * 0.9), greens[i % 2], 10)
	if variant % 2 == 0:
		for i in 6:
			var a := i * 1.1
			K.sphere(self, 0.13, Vector3(cos(a) * 1.25, 2.1 + (i % 3) * 0.3, sin(a) * 1.25), K.mat(Color(1, 0.8, 0.35)), 6, Vector3(0.9, 1.2, 0.9))


## กอไผ่ ลำเป็นปล้อง เอนออกจากกลางกอ ไหวตามลม
func _bamboo() -> void:
	var stalk_c := [Color(0.6, 0.8, 0.45), Color(0.7, 0.85, 0.5)]
	var count := 7 + variant % 4
	for i in count:
		var a := i * TAU / count + variant
		var stalk := Node3D.new()
		stalk.position = Vector3(cos(a) * 0.35, 0, sin(a) * 0.35)
		stalk.rotation = Vector3(sin(a) * 0.12, 0, -cos(a) * 0.12)
		add_child(stalk)
		_sway_nodes.append(stalk)
		var h := 4.0 + (i % 3) * 0.8
		K.cyl(stalk, 0.07, 0.08, h, Vector3(0, h / 2.0, 0), K.mat(stalk_c[i % 2]), 6)
		var y := 0.7
		while y < h:
			K.cyl(stalk, 0.09, 0.09, 0.05, Vector3(0, y, 0), K.mat(Color(0.5, 0.66, 0.38)), 6)
			y += 0.75
		for k in 3:
			var la := k * 2.1 + i
			K.box(stalk, Vector3(0.12, 0.02, 0.7), Vector3(cos(la) * 0.3, h - 0.4 - k * 0.5, sin(la) * 0.3), K.mat(LEAF_LIGHT if k % 2 == 0 else LEAF), Vector3(0.3, la, 0))


## ต้นลีลาวดี กิ่งแตกเป็นง่าม ปลายกิ่งมีช่อใบและดอกสีขาว/ชมพู
func _frangipani() -> void:
	var bark := K.mat(Color(0.7, 0.62, 0.56), 0.0, 0.9)
	var petal := Color(1, 1, 0.95) if variant % 2 == 0 else Color(1, 0.72, 0.82)
	K.cyl(self, 0.14, 0.2, 1.2, Vector3(0, 0.6, 0), bark, 8)
	for i in 4:
		var a := i * TAU / 4.0 + variant * 0.5
		var mid := Vector3(cos(a) * 0.7, 1.9, sin(a) * 0.7)
		K.beam(self, Vector3(0, 1.1, 0), mid, 0.12, bark)
		for k in 2:
			var b := a + (k - 0.5) * 0.9
			var tip := mid + Vector3(cos(b) * 0.5, 0.6, sin(b) * 0.5)
			K.beam(self, mid, tip, 0.08, bark)
			K.sphere(self, 0.4, tip + Vector3(0, 0.1, 0), K.mat(LEAF), 8, Vector3(1, 0.5, 1))
			for f in 3:
				var fa := f * 2.1 + b
				K.sphere(self, 0.08, tip + Vector3(cos(fa) * 0.2, 0.3, sin(fa) * 0.2), K.mat(petal, 0.2), 6, Vector3(1, 0.5, 1))
				K.sphere(self, 0.03, tip + Vector3(cos(fa) * 0.2, 0.34, sin(fa) * 0.2), K.mat(Color(1, 0.85, 0.35), 0.0, 0.8, 0.0, false), 4)
