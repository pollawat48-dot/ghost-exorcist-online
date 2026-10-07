extends "res://maps/map_base.gd"
## แผนที่ล่าผีแบบตั้งค่าได้ (แผนที่ 3–6): แคมป์ทางเข้าฝั่งตะวันตก ทางดินยาวไปประตูฝั่งตะวันออก
## แผนที่ลูกกำหนดแค่ธีม (สีพื้น สิ่งของ จุดเกิดผี NPC) ใน _init() ส่วนการสร้างฉากอยู่ที่นี่ที่เดียว

const GROUND_SHADER = preload("res://maps/thailand/field_ground.gdshader")

const CAMP := Rect2(60, 760, 440, 480)
const PORTAL_WEST := Vector2(80, 1000)
const PORTAL_EAST := Vector2(2730, 1000)

## สีพื้น: grass_a, grass_b, tint, patch, path, camp, plaza, water
var theme := {}
var tint_amount := 0.7
## ลานดินเป็นหย่อมๆ [ศูนย์กลาง, รัศมี] และของที่โรยในลาน [[kind, ความถี่ต่อรัศมี]]
var patches := []
var patch_props := []
## แอ่งน้ำ [ศูนย์กลาง, รัศมี] เดินผ่านไม่ได้
var ponds := []
var pond_prop := "lotus"  ## ของริมน้ำ ("" = ไม่มี เช่น บ่อไฟในยมโลก)
## ลานหินโบราณ (กรุงเก่า/ยมโลก)
var plaza := Rect2()
## สิ่งก่อสร้างหลัก [[kind, pos]] และของที่โรยทั่วแผนที่ [[kind, rect, จำนวน]]
var landmarks := []
var scatters := []
## ของตกแต่งชิ้นเล็กจากโมเดลสำเร็จรูป [[kind, rect, จำนวน]] และสัตว์เดินเล่น [[kind, ศูนย์กลาง, รัศมี, จำนวน]]
var decor := []
var critters := []
var border_kinds := ["dead_tree", "bush"]
var border_weights := [0.5, 0.5]
var grass_base := Color(0.42, 0.55, 0.42)
var grass_tip := Color(0.68, 0.74, 0.6)
var grass_count := 3000
var mist_color := Color(0.82, 0.8, 0.92, 0.14)
var seed_value := 1
## ของประจำแคมป์ (แผนที่จีนเปลี่ยนเป็นศาลาจีน โคมแดง ศาลเจ้าที่)
var camp_hall := "sala"
var camp_lamp := "lantern"
var camp_shrine := "spirit_house"


func _ready() -> void:
	_rng.seed = seed_value
	_build_ground()
	_build_grid()


func is_water(p: Vector2) -> bool:
	for pond in ponds:
		if p.distance_to(pond[0]) < pond[1] - 8.0:
			return true
	return false


func _blocked(pos: Vector2, radius: float) -> bool:
	if CAMP.grow(radius).has_point(pos) or is_water(pos):
		return true
	for pond in ponds:
		if pos.distance_to(pond[0]) < pond[1] + radius:
			return true
	if cave_spot != Vector2.INF and pos.distance_to(cave_spot) < 110.0:
		return true
	return pos.distance_to(PORTAL_WEST) < 90.0 or pos.distance_to(PORTAL_EAST) < 90.0 or pos.distance_to(spawn_point) < 90.0


func minimap_color(p: Vector2) -> Color:
	if is_water(p):
		return theme["water"].lightened(0.15)
	if path_distance(p) < PATH_W * 0.6:
		return theme["path"].lightened(0.1)
	if CAMP.has_point(p):
		return theme["camp"]
	if plaza.has_area() and plaza.has_point(p):
		return theme["plaza"]
	for g in patches:
		if p.distance_to(g[0]) < g[1]:
			return theme["patch"]
	return theme["grass_b"]


func build_props() -> Node3D:
	super.build_props()
	# แคมป์ทางเข้า: กองไฟ ศาลา ตะเกียง (เหมือนกันทุกแผนที่ให้จำได้ว่าเป็นที่ปลอดภัย)
	_add("campfire", Vector2(420, 930))
	_add(camp_hall, Vector2(170, 830))
	for p in [Vector2(150, 1140), Vector2(470, 860), Vector2(470, 1160), Vector2(200, 900)]:
		_add(camp_lamp, p)
		lanterns.append(p)
	_add(camp_shrine, Vector2(140, 1210))
	for lm in landmarks:
		var node := _add(lm[0], lm[1])
		if lm.size() > 2:
			node.rotation.y = lm[2]
			node.set_meta("keep_rotation", true)
	for pond in ponds:
		# บัวและกกริมน้ำ
		if pond_prop == "":
			break
		var c: Vector2 = pond[0]
		var r: float = pond[1]
		for i in int(r / 30.0):
			var a := _rng.randf() * TAU
			var d := _rng.randf_range(0.2, 0.8) * r
			_add(pond_prop, c + Vector2(cos(a), sin(a)) * d)
	for g in patches:
		var center: Vector2 = g[0]
		var r: float = g[1]
		for pp in patch_props:
			for i in int(r / pp[1]):
				var a := _rng.randf() * TAU
				var d := sqrt(_rng.randf()) * (r - 30.0)
				_try_add(pp[0], center + Vector2(cos(a), sin(a) * 0.85) * d, true)
	for sc in scatters:
		_scatter(sc[0], sc[1], sc[2], true)
	_border_ring(border_kinds, border_weights)
	_build_grass()
	_build_mist()
	_build_life()
	return props_root


## ของตกแต่งชิ้นเล็ก (โมเดลสำเร็จรูป CC0) กับสัตว์ที่เดินเล่น วางท้ายสุดเพื่อไม่ให้ตำแหน่งของเดิมเปลี่ยน
func _build_life() -> void:
	# ของใช้ในแคมป์: ลังเสบียง ถังไม้ ป้ายบอกทาง
	_add("crate", Vector2(250, 1185))
	_add("barrel", Vector2(212, 1165))
	_add("signpost", Vector2(530, 940))
	for d in decor:
		_scatter(d[0], d[1], d[2], true)
	for c in critters:
		_add_critters(c[0], c[1], c[2], c[3])


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
	for seg in path_segs:
		segs.append(seg[0])
		segs.append(seg[1])
	mat.set_shader_parameter("path_segs", segs)
	mat.set_shader_parameter("seg_count", path_segs.size())
	mat.set_shader_parameter("path_w", PATH_W)
	mat.set_shader_parameter("patches", _circles(patches))
	mat.set_shader_parameter("patch_count", patches.size())
	mat.set_shader_parameter("ponds", _circles(ponds))
	mat.set_shader_parameter("pond_count", ponds.size())
	if plaza.has_area():
		mat.set_shader_parameter("plaza", _rect_vec(plaza))
	mat.set_shader_parameter("camp", _rect_vec(CAMP))
	for key in ["grass_a", "grass_b", "tint", "patch", "path", "camp", "plaza", "water"]:
		var uniform: String = key + ("_col" if key in ["patch", "path", "camp", "plaza", "water"] else "")
		mat.set_shader_parameter(uniform, theme[key])
	mat.set_shader_parameter("tint_amount", tint_amount)
	ground.material_override = mat
	ground.position = Vector3(size.x / 2.0, 0, size.y / 2.0)
	ground.extra_cull_margin = 4.0
	add_child(ground)
	var outer_mesh := PlaneMesh.new()
	outer_mesh.size = size + Vector2(400, 400)
	var outer := MeshInstance3D.new()
	outer.name = "OuterGround"
	outer.mesh = outer_mesh
	outer.material_override = K.mat(theme["grass_a"].darkened(0.1), 0.0, 1.0, 0.0, false)
	outer.position = Vector3(size.x / 2.0, -0.15, size.y / 2.0)
	add_child(outer)


func _circles(list: Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	for c in list:
		out.append(Vector3(c[0].x, c[0].y, c[1]))
	return out


func _build_grass() -> void:
	var mesh := _tuft_mesh(6, 0.42, 0.5, grass_base, grass_tip)
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var tries := 0
	while transforms.size() < grass_count and tries < grass_count * 7:
		tries += 1
		var p := Vector2(_rng.randf_range(0, world_rect.size.x), _rng.randf_range(0, world_rect.size.y))
		if CAMP.has_point(p) or path_distance(p) < PATH_W + 6 or is_water(p):
			continue
		if plaza.has_area() and plaza.has_point(p):
			continue
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.7, 1.5))
		transforms.append(Transform3D(basis, K.to3d(p, -0.05)))
		var g := _rng.randf_range(0.8, 1.15)
		colors.append(Color(g * 0.95, g, g * 1.05))
	_foliage(mesh, transforms, colors, "Grass")


## หมอกลอยต่ำเป็นหย่อมๆ ตามลานดิน
func _build_mist() -> void:
	if mist_color.a <= 0.0:
		return
	var mist := K.mat(mist_color, 0.0, 1.0, 0.0, false)
	for g in patches:
		for i in 4:
			var a := _rng.randf() * TAU
			var p: Vector2 = g[0] + Vector2(cos(a), sin(a)) * _rng.randf_range(0, g[1])
			var puff := K.sphere(props_root, 1.0, K.to3d(p, 0.15), mist, 10, Vector3(_rng.randf_range(1.8, 3.0), 0.25, _rng.randf_range(1.5, 2.5)))
			puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## NPC มาตรฐานของแคมป์: คนให้เควส ร้านยา และร่างทรงวาร์ป (แผนที่ลูกเพิ่มร้านอื่นเองได้)
func camp_npcs(quest_id: String, quest_name: String, quest_look: Dictionary, potions: Array) -> Array:
	return [
		{"id": quest_id, "name": quest_name, "role": "quest", "pos": Vector2(330, 900), "look": quest_look},
		{"id": map_id + "_shop", "name": "แม่ค้ายาแคมป์", "role": "shop", "pos": Vector2(330, 1110),
			"look": {"robe": Color(0.78, 0.72, 0.98), "sash": Color(1.0, 0.7, 0.78), "hat": "bun"}, "stock": potions},
		{"id": map_id + "_warp", "name": "ร่างทรงนำทาง (วาร์ป)", "role": "warp", "pos": Vector2(470, 1010),
			"look": {"robe": Color(0.98, 0.95, 1.0), "sash": Color(0.55, 0.8, 1.0), "hat": "topknot"}},
	]


## ประตูวาร์ปสองฝั่ง: ตะวันตกกลับแผนที่ก่อนหน้า ตะวันออกไปแผนที่ถัดไป ("" = ไม่มี)
func gates(prev_id: String, prev_name: String, prev_entry: Vector2, next_id: String, next_name: String) -> Array:
	var list := [{"pos": PORTAL_WEST, "to": prev_id, "to_pos": prev_entry, "name": prev_name}]
	if next_id != "":
		list.append({"pos": PORTAL_EAST, "to": next_id, "to_pos": Vector2(260, 1000), "name": next_name})
	return list
