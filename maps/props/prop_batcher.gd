extends RefCounted
## รวมชิ้นส่วนเล็กๆ ของของประดับหนึ่งชิ้น (บ้าน ต้นไม้ ตะเกียง ...) เป็น mesh เดียว
## ของประดับสร้างจากทรงพื้นฐานหลายสิบชิ้น แต่ละชิ้นคือการสั่งวาด 2 ครั้ง (ตัวมัน + เส้นขอบ)
## ทั้งแผนที่จึงมีหลายพันครั้งต่อเฟรม ทำให้มือถือกระตุก การรวมตามวัสดุเหลือไม่กี่ครั้งต่อชิ้น
## ส่วนที่ขยับเอง (กิ่งไม้ไหว เปลวไฟ ดวงไฟลอย) รวมแยกภายในโหนดของมัน เพื่อให้ยังขยับได้

const K = preload("res://maps/props/mesh_kit.gd")

## บิตรูปแบบข้อมูลจุดที่ต้องตรงกันถึงจะต่อ mesh เข้าด้วยกันได้
const FORMAT_MASK := Mesh.ARRAY_FORMAT_NORMAL | Mesh.ARRAY_FORMAT_TANGENT | Mesh.ARRAY_FORMAT_COLOR \
	| Mesh.ARRAY_FORMAT_TEX_UV | Mesh.ARRAY_FORMAT_TEX_UV2 | Mesh.ARRAY_FORMAT_BONES | Mesh.ARRAY_FORMAT_WEIGHTS


## ระยะ (เมตร) ที่ไกลกว่านี้ไม่วาดของประดับ: กล้องมุมสูงแบบ RO มองไกลสุดราว 40 เมตร
const VIEW_RANGE := 70.0

## วัสดุสีล้วนที่ค่าอื่นเหมือนกัน (ความด้าน เส้นขอบ ฯลฯ) ใช้วัสดุกลางตัวเดียว แล้วเก็บสีไว้ที่จุดแทน
## ชิ้นสีต่างกันจึงรวมเป็นก้อนเดียวได้ (เดิมแยกตามวัสดุ บ้านหนึ่งหลังยังวาดหลายสิบครั้ง)
static var _shared := {}  ## ค่าวัสดุ -> วัสดุกลางที่อ่านสีจากจุด
static var _tinted := {}  ## mesh|surface|สี -> ArrayMesh ที่ใส่สีที่จุดแล้ว


## รวม mesh ใต้ root (ยกเว้นใต้โหนดใน keep_apart ซึ่งจะรวมแยกในตัวเอง)
static func batch(root: Node3D, keep_apart: Array = []) -> void:
	for n in keep_apart:
		if n is Node3D and is_instance_valid(n):
			_merge(n, [])
	_merge(root, keep_apart)


static func _merge(root: Node3D, skip: Array) -> void:
	var groups := {}  ## key -> {"st": SurfaceTool, "mat": Material, "shadow": int}
	var used: Array[MeshInstance3D] = []
	_collect(root, root, Transform3D.IDENTITY, skip, groups, used)
	if used.size() < 2:
		return
	# แยก mesh ตามโหมดเงา (ชิ้นที่ไม่ทอดเงา เช่น ดวงไฟ ยังไม่ทอดเงาเหมือนเดิม)
	var meshes := {}
	for key in groups:
		var g: Dictionary = groups[key]
		var am: ArrayMesh = meshes.get(g["shadow"], null)
		if am == null:
			am = ArrayMesh.new()
			meshes[g["shadow"]] = am
		var st: SurfaceTool = g["st"]
		st.commit(am)
		am.surface_set_material(am.get_surface_count() - 1, g["mat"])
	for mode in meshes:
		var mi := MeshInstance3D.new()
		mi.name = "Batched"
		mi.mesh = meshes[mode]
		# ระดับภาพต่ำ (มือถือ): ของประดับไม่ทอดเงา เหลือเงาตัวละคร/ผี ลดการวาดซ้ำในแผนที่เงาได้มาก
		mi.cast_shadow = mode if K.detail >= 1.0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# ของไกลเกินกล้องมองเห็น (และเกินระยะเงา) ไม่ต้องวาด
		mi.visibility_range_end = VIEW_RANGE
		root.add_child(mi)
	for m in used:
		m.get_parent().remove_child(m)
		m.queue_free()


static func _collect(root: Node3D, node: Node, xf: Transform3D, skip: Array, groups: Dictionary, used: Array[MeshInstance3D]) -> void:
	for c in node.get_children():
		if not c is Node3D or c in skip:
			continue
		# ข้ามโมเดลจากไฟล์ที่มีท่าทางเคลื่อนไหวของตัวเอง (สัตว์เลี้ยง .glb)
		if c.scene_file_path != "" and not c.find_children("*", "AnimationPlayer", true, false).is_empty():
			continue
		var n3 := c as Node3D
		var cxf := xf * n3.transform
		if c is MeshInstance3D and _mergeable(c):
			var mi := c as MeshInstance3D
			for s in mi.mesh.get_surface_count():
				var mat := mi.get_active_material(s)
				if _colorable(mat):
					var ck := _class_key(mat)
					var key := "c|%s|%d" % [ck, mi.cast_shadow]
					if not groups.has(key):
						groups[key] = {"st": SurfaceTool.new(), "mat": _shared_mat(ck, mat), "shadow": mi.cast_shadow}
					(groups[key]["st"] as SurfaceTool).append_from(_tinted_mesh(mi.mesh, s, (mat as BaseMaterial3D).albedo_color), 0, cxf)
					continue
				# ทรงพื้นฐาน (PrimitiveMesh) มี normal/tangent/uv ครบเหมือนกันหมด
				var fmt: int = (mi.mesh as ArrayMesh).surface_get_format(s) & FORMAT_MASK if mi.mesh is ArrayMesh else -1
				var key := "%d|%d|%d" % [mat.get_instance_id() if mat != null else 0, mi.cast_shadow, fmt]
				if not groups.has(key):
					var st := SurfaceTool.new()
					groups[key] = {"st": st, "mat": mat, "shadow": mi.cast_shadow}
				(groups[key]["st"] as SurfaceTool).append_from(mi.mesh, s, cxf)
			used.append(mi)
		if c.get_child_count() > 0:
			_collect(root, c, cxf, skip, groups, used)


## รวมได้เฉพาะ mesh ธรรมดาที่มองเห็นและไม่มีกระดูก/ความโปร่งใสรายชิ้น
static func _mergeable(mi: MeshInstance3D) -> bool:
	if mi.mesh == null or not mi.visible or mi.transparency > 0.0 or mi.skeleton != NodePath("") and mi.has_node(mi.skeleton) and mi.get_node(mi.skeleton) is Skeleton3D:
		return false
	if mi.mesh is ArrayMesh:
		for s in mi.mesh.get_surface_count():
			if (mi.mesh as ArrayMesh).surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
				return false
	elif not mi.mesh is PrimitiveMesh:
		return false
	return true


## วัสดุสีล้วนทึบแสง ไม่มีลาย ไม่เรืองแสง: ย้ายสีไปไว้ที่จุดได้
static func _colorable(mat: Material) -> bool:
	if not mat is StandardMaterial3D:
		return false
	var m := mat as StandardMaterial3D
	return m.albedo_texture == null and m.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED \
		and not m.emission_enabled and not m.vertex_color_use_as_albedo and m.albedo_color.a >= 1.0


static func _class_key(m: StandardMaterial3D) -> String:
	return "%.3f|%.3f|%d|%d|%d|%.2f|%.2f|%d|%d|%d" % [m.roughness, m.metallic, m.diffuse_mode, m.specular_mode,
		int(m.rim_enabled), m.rim, m.rim_tint, m.cull_mode, m.shading_mode,
		int(m.has_meta("outlined"))]


static func _shared_mat(key: String, src: StandardMaterial3D) -> StandardMaterial3D:
	if not _shared.has(key):
		var m: StandardMaterial3D = src.duplicate()
		m.albedo_color = Color.WHITE
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.remove_meta("outlined")
		m.next_pass = null
		if src.has_meta("outlined"):
			K.attach_outline(m)
		_shared[key] = m
	return _shared[key]


## สำเนาผิวของ mesh ที่มีแค่ตำแหน่ง/ทิศผิว/สี (ทุกชิ้นรูปแบบเดียวกัน ต่อกันได้หมด)
static func _tinted_mesh(mesh: Mesh, surface: int, color: Color) -> ArrayMesh:
	var key := "%d|%d|%s" % [mesh.get_instance_id(), surface, color.to_html()]
	if _tinted.has(key):
		return _tinted[key]
	var src := mesh.surface_get_arrays(surface)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = src[Mesh.ARRAY_VERTEX]
	arr[Mesh.ARRAY_NORMAL] = src[Mesh.ARRAY_NORMAL]
	# ทุกชิ้นต้องมีดัชนีจุด ไม่งั้นต่อกับชิ้นที่มีดัชนีแล้วรูปร่างเพี้ยน (หลังคาหาย)
	var idx = src[Mesh.ARRAY_INDEX]
	if idx == null or (idx as PackedInt32Array).is_empty():
		idx = PackedInt32Array(range((src[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()))
	arr[Mesh.ARRAY_INDEX] = idx
	var cols := PackedColorArray()
	cols.resize((src[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
	cols.fill(color)
	arr[Mesh.ARRAY_COLOR] = cols
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_tinted[key] = am
	return am
