extends "res://maps/map_base.gd"
## ประเทศไทย แผนที่ 2: ป่าช้าวัดร้าง (ผีเลเวล 12–26 + บอสพญาเปรต)
## ทางเข้าฝั่งตะวันตกเป็นแคมป์ของตาสัปเหร่อ เดินตามทางดินไปทางตะวันออก
## ทางแยกเหนือไปลานเมรุร้าง ทางแยกใต้ไปลานเจดีย์บรรจุอัฐิ สุดทางตะวันออกเป็นป่าไผ่และดงเปรต

const GROUND_SHADER = preload("res://maps/thailand/graveyard.gdshader")

const CAMP := Rect2(60, 760, 440, 480)
const TEMPLE := Rect2(980, 200, 760, 520)
const MERU_POS := Vector2(1360, 380)
const OSSUARY_FIELD := Rect2(1500, 1330, 560, 480)
const PORTAL_WEST := Vector2(80, 1000)
const PORTAL_EAST := Vector2(2730, 1000)
## ลานหลุมศพ (ศูนย์กลาง, รัศมี)
const GRAVES := [
	[Vector2(720, 560), 250.0],
	[Vector2(760, 1480), 280.0],
	[Vector2(2330, 560), 290.0],
	[Vector2(2380, 1480), 290.0],
	[Vector2(1250, 1350), 200.0],
]
const PATH_SEGS := [
	[Vector2(60, 1000), Vector2(700, 990)],
	[Vector2(700, 990), Vector2(1250, 1060)],
	[Vector2(1250, 1060), Vector2(1850, 960)],
	[Vector2(1850, 960), Vector2(2760, 1000)],
	[Vector2(1250, 1060), Vector2(1330, 720)],
	[Vector2(1850, 960), Vector2(1790, 1330)],
	[Vector2(700, 990), Vector2(720, 800)],
	[Vector2(700, 990), Vector2(740, 1200)],
]


func _init() -> void:
	map_id = "pa_cha"
	map_name = "ป่าช้าวัดร้าง"
	world_rect = Rect2(0, 0, 2800, 2000)
	field_rect = Rect2(520, 120, 2200, 1780)
	spawn_point = Vector2(260, 1000)
	path_segs = PATH_SEGS
	gloom = 0.55
	firefly_color = Color(0.55, 0.95, 1.0)
	cave_spot = Vector2(560, 1820)
	spawns = [
		{"id": "phi_khamot", "count": 4, "rect": Rect2(560, 380, 380, 380)},
		{"id": "phi_khamot", "count": 4, "rect": Rect2(560, 1250, 420, 420)},
		{"id": "phi_pop", "count": 4, "rect": OSSUARY_FIELD.grow(-40)},
		{"id": "phi_pop", "count": 3, "rect": Rect2(1050, 760, 600, 180)},
		{"id": "phi_pret", "count": 3, "rect": Rect2(2120, 360, 440, 420)},
		{"id": "phi_pret", "count": 3, "rect": Rect2(2150, 1280, 440, 420)},
	]
	boss_id = "pret_king"
	boss_spawns = [
		{"name": "เมรุร้าง", "pos": MERU_POS + Vector2(0, 230)},
		{"name": "ลานเจดีย์บรรจุอัฐิ", "pos": OSSUARY_FIELD.get_center()},
		{"name": "ป่าไผ่ตะวันออก", "pos": Vector2(2560, 1000)},
	]
	npcs = [
		{"id": "ta_sappare", "name": "ตาสัปเหร่อ", "role": "quest", "pos": Vector2(330, 900),
			"look": {"robe": Color(0.6, 0.66, 0.78), "sash": Color(0.92, 0.85, 0.6), "hat": "farmer"}},
		{"id": "mae_kha", "name": "แม่ค้าน้ำมนต์", "role": "shop", "pos": Vector2(330, 1110),
			"look": {"robe": Color(0.78, 0.72, 0.98), "sash": Color(1.0, 0.7, 0.78), "hat": "bun"},
			"stock": ["herb_potion", "ya_hom_thong", "nam_mon", "nam_mon_yai"]},
		{"id": "pa_cha_warp", "name": "ร่างทรงนำทาง (วาร์ป)", "role": "warp", "pos": Vector2(470, 1010),
			"look": {"robe": Color(0.98, 0.95, 1.0), "sash": Color(0.55, 0.8, 1.0), "hat": "topknot"}},
	]
	portals = [
		{"pos": PORTAL_WEST, "to": "khlong_village", "to_pos": Vector2(3040, 1100), "name": "หมู่บ้านริมคลอง"},
		{"pos": PORTAL_EAST, "to": "krung_kao", "to_pos": Vector2(260, 1000), "name": "กรุงเก่าร้าง (Lv 32+)"},
	]


func _ready() -> void:
	_rng.seed = 4242
	_build_ground()
	_build_grid()


func _blocked(pos: Vector2, radius: float) -> bool:
	if CAMP.grow(radius).has_point(pos) or TEMPLE.grow(-40).has_point(pos):
		return true
	if pos.distance_to(cave_spot) < 110.0:
		return true
	return pos.distance_to(PORTAL_WEST) < 90.0 or pos.distance_to(PORTAL_EAST) < 90.0 or pos.distance_to(spawn_point) < 90.0


func minimap_color(p: Vector2) -> Color:
	if path_distance(p) < PATH_W * 0.6:
		return Color(0.9, 0.82, 0.7)
	if CAMP.has_point(p):
		return Color(0.95, 0.85, 0.7)
	if TEMPLE.has_point(p):
		return Color(0.84, 0.82, 0.88)
	if OSSUARY_FIELD.has_point(p):
		return Color(0.9, 0.88, 0.92)
	for g in GRAVES:
		if p.distance_to(g[0]) < g[1]:
			return Color(0.78, 0.72, 0.8)
	return Color(0.6, 0.7, 0.58)


func build_props() -> Node3D:
	super.build_props()
	# แคมป์ทางเข้า: กองไฟ ตะเกียง ศาลาเก่า
	_add("campfire", Vector2(420, 930))
	_add("sala", Vector2(170, 830))
	for p in [Vector2(150, 1140), Vector2(470, 860), Vector2(470, 1160), Vector2(200, 900)]:
		_add("lantern", p)
		lanterns.append(p)
	_add("jar", Vector2(400, 1170))
	_add("jar", Vector2(430, 1190))
	_add("spirit_house", Vector2(140, 1210))
	# ลานเมรุร้างทางเหนือ
	_add("meru", MERU_POS)
	_add("ruin_chedi", Vector2(1080, 360))
	_add("ruin_chedi", Vector2(1650, 340))
	for p in [Vector2(1040, 640), Vector2(1700, 650), Vector2(1100, 180), Vector2(1620, 170)]:
		var wall := _add("ruin_wall", p)
		wall.rotation.y = 0.0 if p.y > 400 else PI
		wall.set_meta("keep_rotation", true)
	_add("bodhi", Vector2(1880, 300))
	_add("haunted_house", Vector2(1960, 700))
	for x in [1180.0, 1540.0]:
		_add("lantern", Vector2(x, 690))
		lanterns.append(Vector2(x, 690))
	# ลานเจดีย์บรรจุอัฐิทางใต้ เรียงเป็นแถว
	var oy := OSSUARY_FIELD.position.y + 60.0
	while oy < OSSUARY_FIELD.end.y - 40.0:
		var ox := OSSUARY_FIELD.position.x + 50.0
		while ox < OSSUARY_FIELD.end.x - 30.0:
			var jitter := Vector2(_rng.randf_range(-8, 8), _rng.randf_range(-6, 6))
			if path_distance(Vector2(ox, oy)) > PATH_W + 20.0:
				_add("ossuary", Vector2(ox, oy) + jitter)
			ox += 95.0
		oy += 110.0
	# หลุมศพตามลานต่างๆ พร้อมกระถางธูป
	for g in GRAVES:
		var center: Vector2 = g[0]
		var r: float = g[1]
		for i in int(r / 13.0):
			var a := _rng.randf() * TAU
			var d := sqrt(_rng.randf()) * (r - 30.0)
			var pos := center + Vector2(cos(a), sin(a) * 0.85) * d
			if _try_add("tomb", pos, true) and _rng.randf() < 0.35:
				_add("incense", pos + Vector2(0, 34))
		for i in 3:
			_try_add("ossuary", center + Vector2(_rng.randf_range(-r, r), _rng.randf_range(-r, r)) * 0.7, true)
	# ต้นไม้ตาย ป่าไผ่ พุ่มไม้
	_scatter("dead_tree", Rect2(520, 120, 2200, 1780), 34, true)
	_scatter("bamboo", Rect2(2450, 120, 300, 1760), 16, true)
	_scatter("bamboo", Rect2(40, 120, 400, 560), 5, true)
	_scatter("bamboo", Rect2(40, 1300, 400, 600), 5, true)
	_scatter("bush", Rect2(40, 120, 2700, 1780), 30, true)
	_border_ring(["dead_tree", "bamboo", "bush"], [0.35, 0.35, 0.3])
	_build_grass()
	_build_mist()
	_build_life()
	return props_root


## ของตกแต่งชิ้นเล็ก (โมเดลสำเร็จรูป CC0): เทียน โกศ โลงเก่า ตอไม้ เศษซาก + หมาวัดกับแมวดำ
## วางท้ายสุดเพื่อไม่ให้ตำแหน่งของเดิมเปลี่ยน
func _build_life() -> void:
	_add("crate", Vector2(250, 1185))
	_add("barrel", Vector2(212, 1165))
	_add("signpost", Vector2(530, 940))
	for g in GRAVES:
		var area := Rect2(g[0] - Vector2(g[1], g[1]) * 0.8, Vector2(g[1], g[1]) * 1.6)
		_scatter("candles", area, 3, true)
		_scatter("urn", area, 2, true)
	_scatter("coffin", Rect2(980, 200, 760, 520), 3, true)
	_scatter("debris", Rect2(520, 120, 2200, 1780), 12, true)
	_scatter("stump", Rect2(520, 120, 2200, 1780), 10, true)
	_scatter("mushrooms", Rect2(520, 120, 2200, 1780), 8, true)
	_add_critters("dog", Vector2(300, 1000), 160.0, 2)
	_add_critters("cat", Vector2(1360, 800), 220.0, 1)


func _build_ground() -> void:
	var size := world_rect.size * K.S
	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = int(size.x * 2)
	plane.subdivide_depth = int(size.y * 2)
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	var segs := PackedVector2Array()
	for seg in PATH_SEGS:
		segs.append(seg[0])
		segs.append(seg[1])
	mat.set_shader_parameter("path_segs", segs)
	mat.set_shader_parameter("seg_count", PATH_SEGS.size())
	mat.set_shader_parameter("path_w", PATH_W)
	var graves := PackedVector3Array()
	for g in GRAVES:
		graves.append(Vector3(g[0].x, g[0].y, g[1]))
	graves.append(Vector3(OSSUARY_FIELD.get_center().x, OSSUARY_FIELD.get_center().y, 300.0))
	mat.set_shader_parameter("graves", graves)
	mat.set_shader_parameter("grave_count", graves.size())
	mat.set_shader_parameter("temple", _rect_vec(TEMPLE))
	mat.set_shader_parameter("camp", _rect_vec(CAMP))
	ground.material_override = mat
	ground.position = Vector3(size.x / 2.0, 0, size.y / 2.0)
	ground.extra_cull_margin = 4.0
	add_child(ground)
	var outer_mesh := PlaneMesh.new()
	outer_mesh.size = size + Vector2(400, 400)
	var outer := MeshInstance3D.new()
	outer.name = "OuterGround"
	outer.mesh = outer_mesh
	outer.material_override = K.mat(Color(0.5, 0.6, 0.5), 0.0, 1.0, 0.0, false)
	outer.position = Vector3(size.x / 2.0, -0.15, size.y / 2.0)
	add_child(outer)


func _build_grass() -> void:
	var mesh := _tuft_mesh(6, 0.42, 0.5, Color(0.42, 0.55, 0.42), Color(0.68, 0.74, 0.6))
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var tries := 0
	while transforms.size() < 3000 and tries < 20000:
		tries += 1
		var p := Vector2(_rng.randf_range(0, world_rect.size.x), _rng.randf_range(0, world_rect.size.y))
		if TEMPLE.has_point(p) or CAMP.has_point(p) or path_distance(p) < PATH_W + 6:
			continue
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.7, 1.5))
		transforms.append(Transform3D(basis, K.to3d(p, -0.05)))
		var g := _rng.randf_range(0.8, 1.15)
		colors.append(Color(g * 0.95, g, g * 1.05))
	_foliage(mesh, transforms, colors, "Grass")


## หมอกลอยต่ำๆ เป็นหย่อมๆ ตามลานหลุมศพ
func _build_mist() -> void:
	var mist := K.mat(Color(0.82, 0.8, 0.92, 0.14), 0.0, 1.0, 0.0, false)
	for g in GRAVES:
		for i in 5:
			var a := _rng.randf() * TAU
			var p: Vector2 = g[0] + Vector2(cos(a), sin(a)) * _rng.randf_range(0, g[1])
			var puff := K.sphere(props_root, 1.0, K.to3d(p, 0.15), mist, 10, Vector3(_rng.randf_range(1.8, 3.0), 0.25, _rng.randf_range(1.5, 2.5)))
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
