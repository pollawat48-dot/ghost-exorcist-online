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
