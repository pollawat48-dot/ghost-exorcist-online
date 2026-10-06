extends "res://maps/map_base.gd"
## ประเทศไทย แผนที่ 1: หมู่บ้านริมคลอง (3D)
## ฝั่งซ้ายเป็นหมู่บ้านกับวัด ข้ามสะพานไปฝั่งขวาเป็นทุ่งนา ป่ากล้วย และป่าช้าเก่า
## ตรรกะของแผนที่ (เดิน, จุดเกิดผี) ใช้หน่วยเดิม 32 หน่วย = 1 เมตร บนพื้นราบ x/z
## พื้นและน้ำวาดด้วย shader, สิ่งของสร้างใน thai_prop.gd, ต้นข้าว/หญ้าใช้ MultiMesh

const GROUND_SHADER = preload("res://maps/thailand/ground.gdshader")
const WATER_SHADER = preload("res://maps/thailand/water.gdshader")

const CANAL_X := 1220.0
const CANAL_WATER := 62.0
const CANAL_BANK := 80.0
const BRIDGE_Y := 1000.0
const BRIDGE_HALF := 40.0
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
	[Vector2(2700, 1090), Vector2(3150, 1100)],
	[Vector2(1700, 990), Vector2(1760, 790)],
	[Vector2(2250, 1060), Vector2(2200, 1230)],
	[Vector2(550, 1000), Vector2(550, 1620)],
	[Vector2(150, 1000), Vector2(150, 380)],
	[Vector2(150, 380), Vector2(900, 330)],
]

## ประตูวาร์ปไปป่าช้าวัดร้าง อยู่สุดทางดินฝั่งตะวันออก
const PORTAL_EAST := Vector2(3130, 1100)
## ประตูไปลำธารใสเย็น (ตกปลา) สุดทางดินทางใต้ของหมู่บ้าน
const PORTAL_SOUTH := Vector2(550, 1620)


func _init() -> void:
	map_id = "khlong_village"
	map_name = "หมู่บ้านริมคลอง"
	world_rect = Rect2(0, 0, 3200, 2000)
	field_rect = Rect2(1350, 100, 1800, 1800)
	spawn_point = Vector2(560, 1000)
	path_segs = PATH_SEGS
	spawns = [
		{"id": "krasue_noi", "count": 4, "rect": PADDY.grow(-40)},
		{"id": "krasue_noi", "count": 3, "rect": Rect2(2550, 1150, 400, 350)},
		{"id": "phi_takiang", "count": 3, "rect": GROVE.grow(-40)},
		{"id": "phi_takiang", "count": 2, "rect": Rect2(2650, 720, 400, 260)},
	]
	# จุดที่บอสประจำถิ่น (นางพญากระสือ) สุ่มเกิด
	boss_id = "krasue_queen"
	boss_spawns = [
		{"name": "ป่าช้าเก่า", "pos": GRAVE_CENTER + Vector2(-60, 40)},
		{"name": "บ้านร้างหลังป่าช้า", "pos": Vector2(2900, 1840)},
		{"name": "ป่ากล้วย", "pos": GROVE.get_center()},
	]
	# NPC หน้าโบสถ์: ร้านยาของยาย กับหลวงตาที่ให้เควส
	npcs = [
		{"id": "yai_chan", "name": "ยายจันทร์ ร้านยา", "role": "shop", "pos": Vector2(650, 925),
			"look": {"robe": Color(0.98, 0.72, 0.62), "sash": Color(0.55, 0.78, 0.6), "hat": "bun"},
			"stock": ["herb_potion", "nam_mon", "ya_hom_thong", "nam_mon_yai"]},
		{"id": "luang_ta", "name": "หลวงตาเมือง", "role": "quest", "pos": Vector2(460, 925),
			"look": {"robe": Color(1.0, 0.66, 0.3), "sash": Color(0.95, 0.55, 0.25), "hat": "bald"}},
		{"id": "khru_yai", "name": "ครูใหญ่สำนัก (เปลี่ยนอาชีพ)", "role": "class", "pos": Vector2(760, 1045),
			"look": {"robe": Color(0.55, 0.5, 0.82), "sash": Color(1.0, 0.82, 0.35), "hat": "topknot"}},
		{"id": "village_warp", "name": "ร่างทรงนำทาง (วาร์ป)", "role": "warp", "pos": Vector2(940, 925),
			"look": {"robe": Color(0.98, 0.95, 1.0), "sash": Color(0.55, 0.8, 1.0), "hat": "topknot"}},
		{"id": "lung_lek", "name": "ลุงเหล็ก ร้านอาวุธ", "role": "shop", "sign": "ร้านอาวุธ", "pos": Vector2(940, 1075),
			"look": {"robe": Color(0.72, 0.62, 0.55), "sash": Color(0.95, 0.6, 0.4), "hat": "farmer"},
			"stock": ["maipai_staff", "suea_yant", "pha_khat_hua", "saisin", "mitmo", "khan_thanu", "khamphi_yant", "suea_kraphan", "mongkhon", "takrut", "phra_khrueang"]},
		{"id": "chang_lom", "name": "ช่างหลอมแร่", "role": "smith", "pos": Vector2(1060, 925),
			"look": {"robe": Color(0.55, 0.52, 0.6), "sash": Color(1.0, 0.6, 0.35), "hat": "headband"}},
	]
	portals = [
		{"pos": PORTAL_EAST, "to": "pa_cha", "to_pos": Vector2(260, 1000), "name": "ป่าช้าวัดร้าง (Lv 12+)"},
		{"pos": PORTAL_SOUTH, "to": "lam_than", "to_pos": Vector2(260, 1000), "name": "ลำธารใสเย็น (ตกปลา)"},
	]


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


func _blocked(pos: Vector2, radius: float) -> bool:
	return absf(pos.x - canal_center(pos.y)) < CANAL_BANK + radius or COURTYARD.grow(20).has_point(pos) \
		or PADDY.has_point(pos) or pos.distance_to(PORTAL_EAST) < 90.0 or pos.distance_to(PORTAL_SOUTH) < 90.0


func minimap_color(p: Vector2) -> Color:
	if is_water(p):
		return Color(0.55, 0.78, 0.96)
	if path_distance(p) < PATH_W * 0.6:
		return Color(0.98, 0.88, 0.7)
	if COURTYARD.has_point(p):
		return Color(1.0, 0.94, 0.84)
	if p.distance_to(GRAVE_CENTER) < GRAVE_R:
		return Color(0.82, 0.78, 0.9)
	if PADDY.has_point(p):
		return Color(0.78, 0.93, 0.56)
	if GROVE.has_point(p):
		return Color(0.52, 0.76, 0.5)
	return Color(0.68, 0.86, 0.56)


## สร้างสิ่งของทั้งหมดใส่ container ที่ y-sort แล้วมาร์คจุดที่เดินผ่านไม่ได้
func build_props() -> Node3D:
	super.build_props()

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
	_build_village_details()
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
	_build_haunted_corner()
	_build_border_trees()
	_build_rice()
	_build_grass()
	_build_lotus()
	return props_root


## บ้านคน ต้นไม้ และของใช้ในหมู่บ้านฝั่งวัด + บ้านชาวนาฝั่งทุ่ง
func _build_village_details() -> void:
	var cottages := [
		Vector2(180, 190), Vector2(470, 160), Vector2(760, 140), Vector2(1020, 300),
		Vector2(320, 1170), Vector2(800, 1170), Vector2(1010, 1420), Vector2(140, 1500),
		Vector2(720, 1500), Vector2(420, 1530), Vector2(1000, 1720), Vector2(560, 1860), Vector2(150, 1880),
		Vector2(1580, 900), Vector2(2470, 880), Vector2(2950, 380),
	]
	for c in cottages:
		if _place("cottage", c, 64.0, 110.0):
			_place("flower_bed", c + Vector2(-20, 74), 0.0, 20.0)
			if _rng.randf() < 0.4 and _clear_of_props(c + Vector2(66, 84), 30.0):
				_add("fence", c + Vector2(66, 84))
			if _rng.randf() < 0.45:
				_place("laundry", c + Vector2(92, 10), 0.0, 30.0)
			if _rng.randf() < 0.5:
				_place("mango", c + Vector2(-100, -50), 14.0, 60.0)
	for w in [Vector2(450, 1300), Vector2(2380, 960), Vector2(950, 1580)]:
		_place("well", w, 24.0, 70.0)
	# ลีลาวดีมุมลานวัด
	for f in [Vector2(240, 520), Vector2(830, 520), Vector2(240, 720), Vector2(830, 700)]:
		_add("frangipani", f)
	# จามจุรีต้นใหญ่ให้ร่มเงา
	for r in [Vector2(1050, 620), Vector2(120, 1080), Vector2(1560, 1080), Vector2(2560, 560)]:
		_place("rain_tree", r, 30.0, 90.0)
	_scatter("mango", Rect2(40, 80, 1050, 1850), 12, true)
	# กอไผ่ตามขอบหมู่บ้านและริมป่ากล้วย
	_scatter("bamboo", Rect2(10, 80, 80, 1850), 7, true)
	_scatter("bamboo", Rect2(1380, 1150, 120, 760), 4, true)
	_scatter("bamboo", Rect2(2300, 1250, 150, 650), 4, true)
	# เรือพายจอดริมคลอง + ท่าน้ำ
	for y in [640.0, 1360.0, 1680.0]:
		var boat := _add("boat", Vector2(canal_center(y) - 26.0, y))
		boat.rotation.y = _rng.randf_range(-0.25, 0.25)
		boat.set_meta("keep_rotation", true)
	_add("pier", Vector2(canal_center(760.0) - CANAL_WATER - 40.0, 760.0))


## มุมตะวันออกเฉียงใต้: บ้านร้างหลังป่าช้า มีต้นไม้ตาย รั้วพัง และหลุมศพเก่า
func _build_haunted_corner() -> void:
	_add("haunted_house", Vector2(2760, 1770))
	var second := _add("haunted_house", Vector2(3060, 1640))
	second.variant = 1
	for f in [Vector2(2660, 1880), Vector2(2860, 1890), Vector2(2990, 1760)]:
		_add("broken_fence", f)
	for d in [Vector2(2580, 1690), Vector2(2930, 1600), Vector2(3120, 1880), Vector2(2560, 1900), Vector2(2860, 1650), Vector2(2450, 1560)]:
		_place("dead_tree", d, 10.0, 60.0)
	for i in 6:
		_try_add("tomb", Vector2(_rng.randf_range(2450, 3150), _rng.randf_range(1620, 1960)), true)
	_scatter("bush", Rect2(2450, 1600, 700, 380), 5, true)


## วางสิ่งปลูกสร้างถ้าที่ว่างพอ: ไม่ทับคลอง ทาง ลานวัด ทุ่งนา ป่า และไม่ชิดของอื่นเกิน gap
func _place(kind: String, pos: Vector2, radius: float, gap: float) -> bool:
	if not world_rect.grow(-radius).has_point(pos):
		return false
	if absf(pos.x - canal_center(pos.y)) < CANAL_BANK + radius + 10.0:
		return false
	if path_distance(pos) < PATH_W * 0.5 + radius + 8.0:
		return false
	for area in [COURTYARD.grow(20), PADDY, GROVE]:
		if area.grow(radius).has_point(pos):
			return false
	if pos.distance_to(GRAVE_CENTER) < GRAVE_R + radius:
		return false
	if pos.distance_to(spawn_point) < 80.0 or pos.distance_to(PORTAL_EAST) < 90.0 or pos.distance_to(PORTAL_SOUTH) < 90.0:
		return false
	if not _clear_of_props(pos, gap):
		return false
	_add(kind, pos)
	return true


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
	outer.material_override = K.mat(Color(0.62, 0.8, 0.46), 0.0, 1.0, 0.0, false)
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
	var plank := K.mat(Color(0.86, 0.64, 0.46))
	var dark := K.mat(Color(0.64, 0.45, 0.36))
	var i := 0.0
	while i < length:
		var x := cx - length / 2.0 + i
		K.box(bridge, Vector3(0.36, 0.08, width), Vector3(x + 0.18, 0.12 + sin(i / length * PI) * 0.35, z), plank if int(i * 3) % 2 == 0 else K.mat(Color(0.8, 0.58, 0.42)))
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


func _build_rice() -> void:
	var mesh := _tuft_mesh(9, 0.75, 0.35, Color(0.4, 0.66, 0.3), Color(0.72, 0.92, 0.48))
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
				colors.append(Color(1.4, 1.15, 0.6) if ripe else Color(1, 1, 1))
			x += step
		y += step
	_foliage(mesh, transforms, colors, "Rice")


func _build_grass() -> void:
	var mesh := _tuft_mesh(6, 0.35, 0.5, Color(0.46, 0.7, 0.34), Color(0.7, 0.9, 0.5))
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
	var pad := K.mat(Color(0.5, 0.78, 0.45), 0.0, 0.6)
	var flower := K.mat(Color(1.0, 0.66, 0.8), 0.15, 0.6)
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


