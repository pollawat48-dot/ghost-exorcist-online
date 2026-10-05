extends Node2D
## ประเทศไทย แผนที่ 1: หมู่บ้านริมคลอง
## ฝั่งซ้ายเป็นหมู่บ้านกับวัด ข้ามสะพานไปฝั่งขวาเป็นทุ่งนา ป่ากล้วย และป่าช้าเก่า
## พื้นวาดด้วย shader, สิ่งของวาดด้วย thai_prop.gd, เดินด้วย AStarGrid2D (ข้ามคลองได้ทางสะพานเท่านั้น)

const Prop = preload("res://maps/props/thai_prop.gd")
const GROUND_SHADER = preload("res://maps/thailand/ground.gdshader")

const CELL := 32
const CANAL_X := 1220.0
const CANAL_WATER := 62.0
const CANAL_BANK := 80.0
const BRIDGE_Y := 1000.0
const BRIDGE_HALF := 40.0
const PATH_W := 30.0
const COURTYARD := Rect2(250, 560, 600, 520)
const PADDY := Rect2(1450, 150, 1150, 640)
const PLOT := Vector2(230, 160)
const GROVE := Rect2(1450, 1220, 850, 650)
const GRAVE_CENTER := Vector2(2780, 1250)
const GRAVE_R := 330.0
const PATH_SEGS := [
	[Vector2(150, 1000), Vector2(1140, 1000)],
	[Vector2(1300, 1000), Vector2(1700, 990)],
	[Vector2(1700, 990), Vector2(2250, 1060)],
	[Vector2(2250, 1060), Vector2(2700, 1090)],
	[Vector2(1700, 990), Vector2(1760, 790)],
	[Vector2(2250, 1060), Vector2(2200, 1230)],
	[Vector2(550, 1000), Vector2(550, 1550)],
	[Vector2(150, 1000), Vector2(150, 380)],
	[Vector2(150, 380), Vector2(900, 330)],
]

var country := "ประเทศไทย"
var map_name := "หมู่บ้านริมคลอง"
var world_rect := Rect2(0, 0, 3200, 2000)
var field_rect := Rect2(1350, 100, 1800, 1800)
var spawn_point := Vector2(560, 1000)
var spawns := [
	{"id": "krasue_noi", "count": 4, "rect": PADDY.grow(-40)},
	{"id": "krasue_noi", "count": 3, "rect": Rect2(2550, 1080, 450, 420)},
	{"id": "phi_takiang", "count": 3, "rect": GROVE.grow(-40)},
	{"id": "phi_takiang", "count": 2, "rect": Rect2(2650, 720, 450, 280)},
]
var lanterns: Array[Vector2] = []
var astar := AStarGrid2D.new()
var props_root: Node2D
var _placed: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	z_index = -10
	_rng.seed = 2026
	_build_ground()
	_build_bridge()
	_build_grid()


static func canal_center(y: float) -> float:
	return CANAL_X + sin(y * 0.0035) * 45.0 + sin(y * 0.011) * 12.0


func is_water(p: Vector2) -> bool:
	return absf(p.x - canal_center(p.y)) < CANAL_WATER and absf(p.y - BRIDGE_Y) > BRIDGE_HALF


func is_walkable(p: Vector2) -> bool:
	return world_rect.has_point(p) and not astar.is_point_solid(_cell(p))


func path_distance(p: Vector2) -> float:
	var best := INF
	for seg in PATH_SEGS:
		best = minf(best, Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1]).distance_to(p))
	return best


## หาเส้นทางเดินจาก from ไป to (ถ้าปลายทางเดินไม่ได้ จะไปจุดที่ใกล้ที่สุดแทน)
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := _nearest_open(_cell(from))
	var b := _nearest_open(_cell(to))
	var pts := astar.get_point_path(a, b)
	if pts.size() > 1:
		pts.remove_at(0)
	if pts.is_empty():
		return pts
	if b == _cell(to) and is_walkable(to):
		pts[pts.size() - 1] = to
	return pts


## สร้างสิ่งของทั้งหมดใส่ container ที่ y-sort แล้วมาร์คจุดที่เดินผ่านไม่ได้
func build_props() -> Node2D:
	props_root = Node2D.new()
	props_root.name = "Props"
	props_root.y_sort_enabled = true

	# วัด
	_add("chedi", Vector2(760, 640))
	_add("ubosot", Vector2(520, 800))
	_add("sala", Vector2(320, 930))
	_add("sala", Vector2(780, 930))
	_add("bodhi", Vector2(960, 760))
	_add("spirit_house", Vector2(470, 1080))
	for x in range(260, 1101, 140):
		_add("lantern", Vector2(x, 965))
		lanterns.append(Vector2(x, 965))
	# บ้านเรือน
	for pos in [Vector2(330, 300), Vector2(620, 270), Vector2(880, 250), Vector2(300, 1330), Vector2(780, 1300), Vector2(330, 1720), Vector2(800, 1700)]:
		_add("stilt_house", pos)
	# มะพร้าวริมคลองทั้งสองฝั่ง
	for y in range(120, 1950, 150):
		if absf(y - BRIDGE_Y) > 120:
			_add("palm", Vector2(canal_center(y) - CANAL_BANK - 40 - _rng.randf() * 30, y))
			_add("palm", Vector2(canal_center(y + 70) + CANAL_BANK + 40 + _rng.randf() * 30, y + 70))
	_scatter("palm", Rect2(40, 80, 1000, 1850), 10, false)
	_scatter("bush", Rect2(40, 80, 1000, 1850), 16, false)
	# ทุ่งนา
	_add("rice_hut", Vector2(1700, 470))
	_add("rice_hut", Vector2(2340, 310))
	_add("scarecrow", Vector2(1990, 640))
	_add("scarecrow", Vector2(2160, 250))
	# ป่ากล้วย
	_scatter("banana", GROVE, 26, true)
	# ป่าช้าเก่า + เจดีย์ร้าง
	_add("ruin_chedi", Vector2(2870, 930))
	for i in 18:
		var a := _rng.randf() * TAU
		var r := sqrt(_rng.randf()) * (GRAVE_R - 40)
		_try_add("tomb", GRAVE_CENTER + Vector2(cos(a), sin(a) * 0.8) * r, true)
	_scatter("palm", Rect2(2450, 120, 700, 500), 6, true)
	_scatter("bush", field_rect, 20, true)
	return props_root


func _add(kind: String, pos: Vector2) -> void:
	var prop := Prop.new()
	prop.kind = kind
	prop.variant = _rng.randi() % 12
	prop.position = pos
	props_root.add_child(prop)
	_placed.append(pos)
	var fp: Rect2 = prop.footprint()
	if fp.has_area():
		_mark_solid(Rect2(pos + fp.position, fp.size))


func _try_add(kind: String, pos: Vector2, avoid_paths: bool) -> bool:
	if absf(pos.x - canal_center(pos.y)) < CANAL_BANK + 30 or COURTYARD.grow(20).has_point(pos) or PADDY.has_point(pos):
		return false
	if avoid_paths and path_distance(pos) < PATH_W + 24:
		return false
	for other in _placed:
		if other.distance_to(pos) < 48:
			return false
	_add(kind, pos)
	return true


func _scatter(kind: String, rect: Rect2, count: int, avoid_paths: bool) -> void:
	var added := 0
	var tries := 0
	while added < count and tries < count * 20:
		tries += 1
		var pos := Vector2(_rng.randf_range(rect.position.x, rect.end.x), _rng.randf_range(rect.position.y, rect.end.y))
		if path_distance(pos) < PATH_W + 24:
			continue
		if _try_add(kind, pos, avoid_paths):
			added += 1


func _build_ground() -> void:
	var ground := ColorRect.new()
	ground.size = world_rect.size
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter("canal_x", CANAL_X)
	mat.set_shader_parameter("canal_water", CANAL_WATER)
	mat.set_shader_parameter("canal_bank", CANAL_BANK)
	mat.set_shader_parameter("courtyard", _rect_vec(COURTYARD))
	mat.set_shader_parameter("paddy", _rect_vec(PADDY))
	mat.set_shader_parameter("plot", PLOT)
	mat.set_shader_parameter("grove", _rect_vec(GROVE))
	mat.set_shader_parameter("grave_center", GRAVE_CENTER)
	mat.set_shader_parameter("grave_r", GRAVE_R)
	mat.set_shader_parameter("path_w", PATH_W)
	var segs := PackedVector2Array()
	for seg in PATH_SEGS:
		segs.append(seg[0])
		segs.append(seg[1])
	mat.set_shader_parameter("path_segs", segs)
	mat.set_shader_parameter("seg_count", PATH_SEGS.size())
	ground.material = mat
	add_child(ground)


func _build_bridge() -> void:
	var bridge := Node2D.new()
	bridge.draw.connect(_draw_bridge.bind(bridge))
	add_child(bridge)


func _draw_bridge(bridge: Node2D) -> void:
	var cx := canal_center(BRIDGE_Y)
	var x0 := cx - CANAL_BANK - 14.0
	var w := (CANAL_BANK + 14.0) * 2.0
	bridge.draw_rect(Rect2(x0, BRIDGE_Y + BRIDGE_HALF, w, 10), Color(0, 0, 0, 0.25))
	bridge.draw_rect(Rect2(x0, BRIDGE_Y - BRIDGE_HALF, w, BRIDGE_HALF * 2), Color(0.6, 0.42, 0.25))
	var x := x0
	while x < x0 + w:
		bridge.draw_line(Vector2(x, BRIDGE_Y - BRIDGE_HALF), Vector2(x, BRIDGE_Y + BRIDGE_HALF), Color(0.42, 0.28, 0.16), 2.0)
		x += 12.0
	for y in [BRIDGE_Y - BRIDGE_HALF - 4.0, BRIDGE_Y + BRIDGE_HALF - 2.0]:
		bridge.draw_rect(Rect2(x0, y, w, 6), Color(0.38, 0.24, 0.13))
		for i in 6:
			bridge.draw_rect(Rect2(x0 + i * (w - 8) / 5.0, y - 12, 8, 18), Color(0.33, 0.2, 0.11))


func _build_grid() -> void:
	astar.region = Rect2i(0, 0, ceili(world_rect.size.x / CELL), ceili(world_rect.size.y / CELL))
	astar.cell_size = Vector2(CELL, CELL)
	astar.offset = Vector2(CELL / 2.0, CELL / 2.0)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for x in astar.region.size.x:
		for y in astar.region.size.y:
			var center := Vector2(x * CELL + CELL / 2.0, y * CELL + CELL / 2.0)
			if is_water(center):
				astar.set_point_solid(Vector2i(x, y))


func _mark_solid(rect: Rect2) -> void:
	for x in range(floori(rect.position.x / CELL), ceili(rect.end.x / CELL)):
		for y in range(floori(rect.position.y / CELL), ceili(rect.end.y / CELL)):
			var c := Vector2i(x, y)
			if astar.is_in_boundsv(c) and rect.has_point(Vector2(x * CELL + CELL / 2.0, y * CELL + CELL / 2.0)):
				astar.set_point_solid(c)


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(p.x / CELL), 0, astar.region.size.x - 1),
		clampi(int(p.y / CELL), 0, astar.region.size.y - 1))


func _nearest_open(c: Vector2i) -> Vector2i:
	if not astar.is_point_solid(c):
		return c
	for r in range(1, 8):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var n := c + Vector2i(dx, dy)
				if astar.is_in_boundsv(n) and not astar.is_point_solid(n):
					return n
	return c


func _rect_vec(r: Rect2) -> Vector4:
	return Vector4(r.position.x, r.position.y, r.size.x, r.size.y)
