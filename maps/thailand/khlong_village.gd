extends Node3D
## ประเทศไทย แผนที่ 1: หมู่บ้านริมคลอง (3D)
## ฝั่งซ้ายเป็นหมู่บ้านกับวัด ข้ามสะพานไปฝั่งขวาเป็นทุ่งนา ป่ากล้วย และป่าช้าเก่า
## ตรรกะของแผนที่ (เดิน, จุดเกิดผี) ใช้หน่วยเดิม 32 หน่วย = 1 เมตร บนพื้นราบ x/z
## พื้นและน้ำวาดด้วย shader, สิ่งของสร้างใน thai_prop.gd, ต้นข้าว/หญ้าใช้ MultiMesh

const K = preload("res://maps/props/mesh_kit.gd")
const Prop = preload("res://maps/props/thai_prop.gd")
const GROUND_SHADER = preload("res://maps/thailand/ground.gdshader")
const WATER_SHADER = preload("res://maps/thailand/water.gdshader")
const FOLIAGE_SHADER = preload("res://maps/thailand/foliage.gdshader")

const CELL := 32
const CANAL_X := 1220.0
const CANAL_WATER := 62.0
const CANAL_BANK := 80.0
const BRIDGE_Y := 1000.0
const BRIDGE_HALF := 40.0
const PATH_W := 30.0
const COURTYARD := Rect2(200, 460, 680, 620)
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
var props_root: Node3D
var _placed: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 2026
	_build_ground()
	_build_water()
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
func build_props() -> Node3D:
	props_root = Node3D.new()
	props_root.name = "Props"

	# วัด
	_add("chedi", Vector2(528, 585))
	_add("ubosot", Vector2(528, 790))
	_add("sala", Vector2(268, 880))
	_add("sala", Vector2(790, 880))
	_add("bodhi", Vector2(950, 760))
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
	_build_border_trees()
	_build_rice()
	_build_grass()
	_build_lotus()
	return props_root


func _add(kind: String, pos: Vector2) -> void:
	var prop := Prop.new()
	prop.kind = kind
	prop.variant = _rng.randi() % 12
	prop.position = K.to3d(pos)
	if kind in ["palm", "banana", "bush", "tomb"]:
		prop.rotation.y = _rng.randf() * TAU
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
	var spacing := 64.0 if kind == "tomb" else 48.0
	for other in _placed:
		if other.distance_to(pos) < spacing:
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


func _terrain_material(shader: Shader) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("canal_x", CANAL_X)
	mat.set_shader_parameter("canal_water", CANAL_WATER)
	mat.set_shader_parameter("canal_bank", CANAL_BANK)
	mat.set_shader_parameter("bridge_y", BRIDGE_Y)
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
	return mat


func _build_ground() -> void:
	var size := world_rect.size * K.S
	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = int(size.x * 4)
	plane.subdivide_depth = int(size.y * 4)
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	ground.material_override = _terrain_material(GROUND_SHADER)
	ground.position = Vector3(size.x / 2.0, 0, size.y / 2.0)
	ground.extra_cull_margin = 4.0
	add_child(ground)
	# พื้นรอบนอกแผนที่ ไม่ให้เห็นขอบโลก
	var outer_mesh := PlaneMesh.new()
	outer_mesh.size = size + Vector2(400, 400)
	var outer := MeshInstance3D.new()
	outer.name = "OuterGround"
	outer.mesh = outer_mesh
	outer.material_override = K.mat(Color(0.2, 0.36, 0.14), 0.0, 1.0)
	outer.position = Vector3(size.x / 2.0, -0.12, size.y / 2.0)
	add_child(outer)


func _build_water() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, world_rect.size.y * K.S)
	var water := MeshInstance3D.new()
	water.name = "Water"
	water.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	water.material_override = mat
	water.position = Vector3(CANAL_X * K.S, -0.45, world_rect.size.y * K.S / 2.0)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)


func _build_bridge() -> void:
	var bridge := Node3D.new()
	bridge.name = "Bridge"
	add_child(bridge)
	var cx := canal_center(BRIDGE_Y) * K.S
	var z := BRIDGE_Y * K.S
	var length := (CANAL_BANK + 20.0) * 2.0 * K.S
	var width := BRIDGE_HALF * 2.0 * K.S
	var plank := K.mat(Color(0.58, 0.4, 0.24))
	var dark := K.mat(Color(0.33, 0.2, 0.11))
	var i := 0.0
	while i < length:
		var x := cx - length / 2.0 + i
		K.box(bridge, Vector3(0.36, 0.08, width), Vector3(x + 0.18, 0.12 + sin(i / length * PI) * 0.35, z), plank if int(i * 3) % 2 == 0 else K.mat(Color(0.52, 0.36, 0.21)))
		i += 0.38
	for side in [-1.0, 1.0]:
		var rz: float = z + side * (width / 2.0 + 0.05)
		for k in 7:
			var x := cx - length / 2.0 + k * length / 6.0
			var y := 0.12 + sin(float(k) / 6.0 * PI) * 0.35
			K.box(bridge, Vector3(0.14, 1.6, 0.14), Vector3(x, y, rz), dark)
		for k in 6:
			var x0 := cx - length / 2.0 + k * length / 6.0
			var x1 := x0 + length / 6.0
			K.beam(bridge, Vector3(x0, 0.95 + sin(float(k) / 6.0 * PI) * 0.35, rz), Vector3(x1, 0.95 + sin(float(k + 1) / 6.0 * PI) * 0.35, rz), 0.09, dark)


## กอข้าวหนึ่งกอ: ใบเรียวหลายใบ สีเข้มที่โคน อ่อนที่ปลาย
func _tuft_mesh(blades: int, height: float, spread: float, base: Color, tip: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = blades * 7 + int(height * 100)
	for b in blades:
		var a := TAU * b / blades + rng.randf() * 0.5
		var dir := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-dir.z, 0, dir.x) * 0.03
		var h := height * rng.randf_range(0.75, 1.1)
		var top := dir * spread * h + Vector3(0, h, 0)
		var mid := dir * spread * 0.4 * h + Vector3(0, h * 0.55, 0)
		var n := Vector3.UP
		for v in [[-side, base], [side, base], [mid + side * 0.6, base.lerp(tip, 0.5)],
				[-side, base], [mid + side * 0.6, base.lerp(tip, 0.5)], [mid - side * 0.6, base.lerp(tip, 0.5)],
				[mid - side * 0.6, base.lerp(tip, 0.5)], [mid + side * 0.6, base.lerp(tip, 0.5)], [top, tip]]:
			st.set_color(v[1])
			st.set_normal(n)
			st.add_vertex(v[0])
	return st.commit()


func _foliage(mesh: Mesh, transforms: Array[Transform3D], colors: Array[Color], name_: String) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = name_
	mmi.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = FOLIAGE_SHADER
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	props_root.add_child(mmi)


func _build_rice() -> void:
	var mesh := _tuft_mesh(9, 0.75, 0.35, Color(0.12, 0.3, 0.06), Color(0.42, 0.7, 0.16))
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var step := 14.0
	var y := PADDY.position.y
	while y < PADDY.end.y:
		var x := PADDY.position.x
		while x < PADDY.end.x:
			var c := Vector2(fposmod(x - PADDY.position.x, PLOT.x), fposmod(y - PADDY.position.y, PLOT.y))
			var p := Vector2(x + _rng.randf_range(-3, 3), y + _rng.randf_range(-3, 3))
			if c.x > 22 and c.y > 22 and c.x < PLOT.x - 6 and c.y < PLOT.y - 6 and _clear_of_props(p, 40.0):
				var plot_id := Vector2i(int((x - PADDY.position.x) / PLOT.x), int((y - PADDY.position.y) / PLOT.y))
				var ripe := (plot_id.x * 7 + plot_id.y * 13) % 5 == 0
				var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.85, 1.15))
				transforms.append(Transform3D(basis, K.to3d(p, -0.1)))
				colors.append(Color(1.9, 1.35, 0.5) if ripe else Color(1, 1, 1))
			x += step
		y += step
	_foliage(mesh, transforms, colors, "Rice")


func _build_grass() -> void:
	var mesh := _tuft_mesh(6, 0.35, 0.5, Color(0.16, 0.32, 0.1), Color(0.45, 0.68, 0.25))
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var tries := 0
	while transforms.size() < 3500 and tries < 20000:
		tries += 1
		var p := Vector2(_rng.randf_range(0, world_rect.size.x), _rng.randf_range(0, world_rect.size.y))
		if PADDY.grow(10).has_point(p) or COURTYARD.has_point(p) or path_distance(p) < PATH_W + 6:
			continue
		if absf(p.x - canal_center(p.y)) < CANAL_BANK + 4:
			continue
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.7, 1.4))
		transforms.append(Transform3D(basis, K.to3d(p, -0.05)))
		var g := _rng.randf_range(0.8, 1.15)
		colors.append(Color(g, g, g * 0.9))
	_foliage(mesh, transforms, colors, "Grass")


func _build_lotus() -> void:
	var pad := K.mat(Color(0.2, 0.45, 0.18), 0.0, 0.6)
	var flower := K.mat(Color(1.0, 0.6, 0.75), 0.15, 0.6)
	var y := 30.0
	while y < world_rect.size.y:
		if absf(y - BRIDGE_Y) > 90:
			for side in [-1.0, 1.0]:
				if _rng.randf() < 0.55:
					var p := Vector2(canal_center(y) + side * _rng.randf_range(30, 52), y)
					K.cyl(props_root, 0.4, 0.4, 0.02, K.to3d(p, -0.43), pad, 12)
					if _rng.randf() < 0.35:
						K.sphere(props_root, 0.14, K.to3d(p, -0.3), flower, 8, Vector3(1, 0.8, 1))
		y += 36.0


## แนวต้นไม้รอบขอบแผนที่ (อยู่นอกพื้นที่เดิน) ให้ขอบโลกดูเป็นป่า
func _build_border_trees() -> void:
	var w := world_rect.size
	var edge := 0.0
	while edge < 2.0 * (w.x + w.y):
		var p: Vector2
		if edge < w.x:
			p = Vector2(edge, -_rng.randf_range(60, 220))
		elif edge < w.x + w.y:
			p = Vector2(w.x + _rng.randf_range(60, 220), edge - w.x)
		elif edge < 2.0 * w.x + w.y:
			p = Vector2(edge - w.x - w.y, w.y + _rng.randf_range(60, 220))
		else:
			p = Vector2(-_rng.randf_range(60, 220), edge - 2.0 * w.x - w.y)
		var kind := "palm" if _rng.randf() < 0.55 else "bush"
		if absf(p.x - canal_center(clampf(p.y, 0, w.y))) > CANAL_BANK + 40:
			var prop := Prop.new()
			prop.kind = kind
			prop.variant = _rng.randi() % 12
			prop.position = K.to3d(p)
			prop.rotation.y = _rng.randf() * TAU
			if kind == "bush":
				prop.scale = Vector3.ONE * _rng.randf_range(1.5, 3.0)
			props_root.add_child(prop)
		edge += _rng.randf_range(70, 140)


func _clear_of_props(p: Vector2, dist: float) -> bool:
	for other in _placed:
		if other.distance_to(p) < dist:
			return false
	return true


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
