extends "res://maps/map_base.gd"
## ถ้ำใต้แผนที่ (สุ่มว่าแผนที่ไหนมีถ้ำ): มืด มีผลึกเรืองแสง หินงอก ผีพิเศษของถ้ำ และก้อนหินแร่ให้ขุด
## ใช้ร่วมกันทุกถ้ำ ต่างกันที่ระดับ (tier) ซึ่งกำหนดผีพิเศษและโอกาสได้แร่หายาก

const GROUND_SHADER = preload("res://maps/thailand/field_ground.gdshader")
const World = preload("res://shared/data/world.gd")

const ENTRANCE := Vector2(110, 700)
const PATH_SEGS := [
	[Vector2(60, 700), Vector2(560, 650)],
	[Vector2(560, 650), Vector2(1000, 760)],
	[Vector2(1000, 760), Vector2(1450, 620)],
	[Vector2(1450, 620), Vector2(1700, 700)],
	[Vector2(560, 650), Vector2(620, 300)],
	[Vector2(1000, 760), Vector2(980, 1150)],
	[Vector2(1450, 620), Vector2(1400, 260)],
]
## โพรงที่มีผลึกและหินแร่ [ศูนย์กลาง, รัศมี]
const CHAMBERS := [
	[Vector2(620, 280), 190.0], [Vector2(980, 1150), 200.0], [Vector2(1400, 260), 190.0], [Vector2(1650, 1050), 200.0],
]

var parent_id := ""


## ตั้งค่าตามแผนที่แม่ (เรียกก่อน add_child)
func configure(parent_map: String, parent_exit: Vector2) -> void:
	parent_id = parent_map
	cave_tier = World.CAVE_TIER[parent_map]
	map_id = World.CAVE_PREFIX + parent_map
	map_name = World.map_name(map_id)
	world_rect = Rect2(0, 0, 1800, 1400)
	field_rect = Rect2(300, 100, 1450, 1250)
	spawn_point = ENTRANCE + Vector2(130, 0)
	path_segs = PATH_SEGS
	gloom = 1.0
	firefly_color = Color(0.6, 0.9, 1.0)
	gloom_sky = Color(0.08, 0.07, 0.12)
	gloom_horizon = Color(0.16, 0.14, 0.22)
	gloom_fog = Color(0.18, 0.16, 0.26)
	var ghost_id := "cave_" + parent_map
	spawns = [
		{"id": ghost_id, "count": 5, "rect": Rect2(450, 180, 340, 260)},
		{"id": ghost_id, "count": 5, "rect": Rect2(840, 1000, 320, 300)},
		{"id": ghost_id, "count": 3, "rect": Rect2(1250, 160, 320, 260)},
		{"id": ghost_id, "count": 5, "rect": Rect2(1480, 900, 280, 300)},
	]
	boss_id = ""
	boss_spawns = []
	npcs = []
	portals = [{"pos": ENTRANCE, "to": parent_map, "to_pos": parent_exit, "name": "ทางออก " + World.MAPS[parent_map]["name"]}]
	ore_rocks = []
	for c in CHAMBERS:
		for i in 3:
			var a: float = i * TAU / 3.0 + c[0].x * 0.01
			ore_rocks.append(c[0] + Vector2(cos(a), sin(a)) * c[1] * 0.55)
	ore_rocks.append(Vector2(800, 520))
	ore_rocks.append(Vector2(1230, 850))


func _ready() -> void:
	_rng.seed = 7700 + cave_tier
	_build_ground()
	_build_grid()
	for p in ore_rocks:
		_mark_solid(Rect2(p - Vector2(20, 16), Vector2(40, 32)))


func _blocked(pos: Vector2, radius: float) -> bool:
	if pos.distance_to(ENTRANCE) < 140.0 or pos.distance_to(spawn_point) < 90.0:
		return true
	for p in ore_rocks:
		if pos.distance_to(p) < 60.0 + radius * 0.5:
			return true
	return false


func minimap_color(p: Vector2) -> Color:
	if path_distance(p) < PATH_W * 0.8:
		return Color(0.55, 0.5, 0.62)
	for c in CHAMBERS:
		if p.distance_to(c[0]) < c[1]:
			return Color(0.45, 0.5, 0.66)
	return Color(0.3, 0.28, 0.36)


func build_props() -> Node3D:
	super.build_props()
	for c in CHAMBERS:
		for i in 4:
			var a := _rng.randf() * TAU
			_try_add("crystal", c[0] + Vector2(cos(a), sin(a)) * c[1] * _rng.randf_range(0.7, 0.95), true)
	_scatter("stalagmite", Rect2(200, 60, 1550, 1290), 45, true)
	_scatter("rock", Rect2(200, 60, 1550, 1290), 16, true)
	_scatter("crystal", Rect2(300, 100, 1450, 1200), 8, true)
	_border_ring(["stalagmite", "rock"], [0.7, 0.3])
	# ผนังถ้ำ: หินงอกหนาแน่นรอบขอบ
	for i in 60:
		var t := float(i) / 60.0
		for edge in [Vector2(t * world_rect.size.x, -30), Vector2(t * world_rect.size.x, world_rect.size.y + 30)]:
			var prop := Prop.new()
			prop.kind = "stalagmite"
			prop.variant = i % 12
			prop.position = K.to3d(edge)
			prop.scale = Vector3.ONE * _rng.randf_range(1.4, 2.4)
			props_root.add_child(prop)
	return props_root


func _build_ground() -> void:
	var size := world_rect.size * K.S
	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = int(size.x * 2 * K.ground_detail())
	plane.subdivide_depth = int(size.y * 2 * K.ground_detail())
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF  # พื้นรับเงาอย่างเดียว ไม่ต้องวาดซ้ำในแผนที่เงา
	ground.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter("detail_octaves", K.ground_octaves)
	var segs := PackedVector2Array()
	for seg in PATH_SEGS:
		segs.append(seg[0])
		segs.append(seg[1])
	mat.set_shader_parameter("path_segs", segs)
	mat.set_shader_parameter("seg_count", PATH_SEGS.size())
	mat.set_shader_parameter("path_w", PATH_W + 10.0)
	var circles := PackedVector3Array()
	for c in CHAMBERS:
		circles.append(Vector3(c[0].x, c[0].y, c[1]))
	mat.set_shader_parameter("patches", circles)
	mat.set_shader_parameter("patch_count", circles.size())
	mat.set_shader_parameter("camp", Vector4(-500, -500, 1, 1))
	mat.set_shader_parameter("grass_a", Color(0.36, 0.33, 0.42))
	mat.set_shader_parameter("grass_b", Color(0.44, 0.4, 0.5))
	mat.set_shader_parameter("tint", Color(0.38, 0.42, 0.58))
	mat.set_shader_parameter("patch_col", Color(0.45, 0.5, 0.66))
	mat.set_shader_parameter("path_col", Color(0.58, 0.52, 0.6))
	ground.material_override = mat
	ground.position = Vector3(size.x / 2.0, 0, size.y / 2.0)
	add_child(ground)
	var outer_mesh := PlaneMesh.new()
	outer_mesh.size = size + Vector2(400, 400)
	var outer := MeshInstance3D.new()
	outer.mesh = outer_mesh
	outer.material_override = K.mat(Color(0.22, 0.2, 0.26), 0.0, 1.0, 0.0, false)
	outer.position = Vector3(size.x / 2.0, -0.15, size.y / 2.0)
	add_child(outer)
	# เพดานถ้ำ: แผ่นมืดสูงเหนือหัวบังแสงอาทิตย์ (กล้องอยู่ต่ำกว่า)
	var roof := MeshInstance3D.new()
	var roof_mesh := PlaneMesh.new()
	roof_mesh.size = size + Vector2(400, 400)
	roof.mesh = roof_mesh
	roof.rotation.x = PI
	roof.position = Vector3(size.x / 2.0, 40.0, size.y / 2.0)
	roof.material_override = K.mat(Color(0.1, 0.09, 0.13), 0.0, 1.0, 0.0, false)
	roof.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	add_child(roof)
