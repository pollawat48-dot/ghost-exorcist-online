extends Node3D
## ส่วนที่ทุกแผนที่ใช้ร่วมกัน: ตารางเดิน (A*), วางสิ่งของ, หญ้า/ต้นไม้แบบ MultiMesh
## ตรรกะแผนที่ใช้หน่วยเกม 32 หน่วย = 1 เมตร บนพื้นราบ x/z
## แผนที่ลูกต้องกำหนด: country, map_name, world_rect, field_rect, spawn_point, spawns,
## boss_id, boss_spawns, npcs, portals แล้วเขียน build_props() กับ minimap_color()

const K = preload("res://maps/props/mesh_kit.gd")
const Prop = preload("res://maps/props/thai_prop.gd")
const FOLIAGE_SHADER = preload("res://maps/thailand/foliage.gdshader")

const CELL := 32
const PATH_W := 30.0
const ROTATED_KINDS := ["palm", "banana", "bush", "mango", "rain_tree", "bamboo", "frangipani", "dead_tree", "well", "ossuary"]

var map_id := ""
var country := "ประเทศไทย"
var map_name := ""
var world_rect := Rect2()
var field_rect := Rect2()
var spawn_point := Vector2.ZERO
var spawns := []
var boss_id := ""
var boss_spawns := []
## NPC: {"id", "name", "role": "shop"/"quest", "pos", "look": {"robe","sash","hat"}, "stock": [...]}
var npcs := []
## ประตูวาร์ป: {"pos", "to": map_id, "to_pos", "name"}
var portals := []
## ความหม่นของแผนที่ 0..1 (ป่าช้ามืดครึ้มกว่าหมู่บ้าน ตะเกียงและผีเรืองแสงแม้ตอนกลางวัน)
var gloom := 0.0
var firefly_color := Color(0.75, 1.0, 0.35)
## สีท้องฟ้า/หมอกเมื่อแผนที่หม่น (ยมโลกเป็นโทนแดง ถ้ำมืดเกือบดำ)
var gloom_sky := Color(0.42, 0.38, 0.62)
var gloom_horizon := Color(0.72, 0.66, 0.8)
var gloom_fog := Color(0.5, 0.46, 0.66)
## จุดปากถ้ำ ใช้เมื่อแผนที่นี้ถูกสุ่มให้มีถ้ำ (Vector2.INF = แผนที่นี้ไม่มีที่ให้ถ้ำ)
var cave_spot := Vector2.INF
## เฉพาะในถ้ำ: ตำแหน่งก้อนหินแร่ และระดับถ้ำ (ยิ่งสูงแร่หายากยิ่งออกบ่อย)
var ore_rocks: Array[Vector2] = []
var cave_tier := 0
var path_segs := []
var lanterns: Array[Vector2] = []
var astar := AStarGrid2D.new()
var props_root: Node3D
var _placed: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()


func is_water(_p: Vector2) -> bool:
	return false


func is_walkable(p: Vector2) -> bool:
	return world_rect.has_point(p) and not astar.is_point_solid(_cell(p))


func path_distance(p: Vector2) -> float:
	var best := INF
	for seg in path_segs:
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


func build_props() -> Node3D:
	props_root = Node3D.new()
	props_root.name = "Props"
	return props_root


func minimap_color(_p: Vector2) -> Color:
	return Color(0.68, 0.86, 0.56)


## ห้ามวางของตรงนี้ (แผนที่ลูกเพิ่มเงื่อนไขเอง เช่น คลอง ลานวัด)
func _blocked(_pos: Vector2, _radius: float) -> bool:
	return false


func _add(kind: String, pos: Vector2) -> Node3D:
	var prop := Prop.new()
	prop.kind = kind
	prop.variant = _rng.randi() % 12
	prop.position = K.to3d(pos)
	if kind in ROTATED_KINDS:
		prop.rotation.y = _rng.randf() * TAU
		prop.set_meta("keep_rotation", true)
	props_root.add_child(prop)
	_placed.append(pos)
	var fp: Rect2 = prop.footprint()
	if fp.has_area():
		_mark_solid(Rect2(pos + fp.position, fp.size))
	return prop


func _try_add(kind: String, pos: Vector2, avoid_paths: bool) -> bool:
	if _blocked(pos, 30.0):
		return false
	if avoid_paths and path_distance(pos) < PATH_W + 24:
		return false
	for n in npcs:
		if pos.distance_to(n["pos"]) < 70.0:
			return false
	var spacing := 64.0 if kind == "tomb" else 48.0
	if not _clear_of_props(pos, spacing):
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


func _clear_of_props(p: Vector2, dist: float) -> bool:
	for other in _placed:
		if other.distance_to(p) < dist:
			return false
	return true


## กอหญ้า/ต้นข้าวหนึ่งกอ: ใบเรียวหลายใบ สีเข้มที่โคน อ่อนที่ปลาย
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


## แนวต้นไม้รอบขอบแผนที่ (อยู่นอกพื้นที่เดิน) ให้ขอบโลกดูเป็นป่า
func _border_ring(kinds: Array, weights: Array, skip: Callable = Callable()) -> void:
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
		edge += _rng.randf_range(70, 140)
		if skip.is_valid() and skip.call(p):
			continue
		var roll := _rng.randf()
		var kind: String = kinds[kinds.size() - 1]
		var acc := 0.0
		for i in kinds.size():
			acc += weights[i]
			if roll < acc:
				kind = kinds[i]
				break
		var prop := Prop.new()
		prop.kind = kind
		prop.variant = _rng.randi() % 12
		prop.position = K.to3d(p)
		prop.rotation.y = _rng.randf() * TAU
		if kind == "bush":
			prop.scale = Vector3.ONE * _rng.randf_range(1.5, 3.0)
		props_root.add_child(prop)


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
