extends RefCounted
## ชุดเครื่องมือสร้างโมเดล 3D แบบ low-poly จากรูปทรงพื้นฐาน
## ใช้แทนโมเดลจริงชั่วคราว (เมื่อมีไฟล์ .glb จากนักออกแบบ ค่อยเปลี่ยนทีละชนิด)

## 1 เมตร = 32 หน่วยของตรรกะเกม (หน่วยเดิมจากเวอร์ชัน 2D)
const S := 1.0 / 32.0

## สีเส้นขอบแบบการ์ตูน (น้ำตาลอมม่วง ไม่ใช้ดำสนิทเพื่อให้ดูนุ่ม)
const OUTLINE_COLOR := Color(0.36, 0.24, 0.26)

## ตัวคูณความละเอียดของทรงกลม/ทรงกระบอก (ตั้งจาก client/graphics.gd ตามระดับคุณภาพภาพ)
## ทรงที่ตั้งใจให้เป็นเหลี่ยม (น้อยกว่า 8 ด้าน เช่น อัญมณี) คงเดิม ระดับต่ำ (<1) ลดเหลี่ยมแต่ไม่ต่ำกว่า 8
static var detail := 1.0

static var _materials := {}
static var _meshes := {}
static var _outline: StandardMaterial3D
## เส้นขอบเปิด/ปิดได้ตามระดับภาพ (ระดับประหยัดปิด ลดงานวาดเกือบครึ่ง) จึงจำวัสดุที่ต้องมีเส้นขอบไว้
static var outlines_on := true
## ชั้นลายละเอียดของพื้น (shader ดิน/หญ้า) ตั้งตามระดับภาพ
static var ground_octaves := 4
static var _outlined: Array[BaseMaterial3D] = []
static var _font: Font


static func font() -> Font:
	if _font == null:
		_font = load("res://assets/fonts/Mali-Bold.ttf")
	return _font


## เส้นขอบแบบ inverted hull: วาดผิวด้านหลังที่ขยายออกเล็กน้อยด้วยสีทึบ
static func outline() -> StandardMaterial3D:
	if _outline == null:
		_outline = StandardMaterial3D.new()
		_outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_outline.cull_mode = BaseMaterial3D.CULL_FRONT
		_outline.albedo_color = OUTLINE_COLOR
		_outline.grow = true
		_outline.grow_amount = 0.022
	return _outline


static func attach_outline(m: BaseMaterial3D) -> void:
	m.set_meta("outlined", true)
	_outlined.append(m)
	m.next_pass = outline() if outlines_on else null


static func set_outlines(on: bool) -> void:
	if on == outlines_on:
		return
	outlines_on = on
	for m in _outlined:
		if is_instance_valid(m):
			m.next_pass = outline() if on else null


static func to3d(p: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(p.x * S, height, p.y * S)


## วัสดุแบบการ์ตูน: แสงเงาเป็นขั้น (toon), ขอบสว่างนุ่มๆ และมีเส้นขอบ
static func mat(color: Color, emission: float = 0.0, roughness: float = 0.85, metallic: float = 0.0, outlined: bool = true) -> StandardMaterial3D:
	var key := "%s|%s|%s|%s|%s" % [color.to_html(), emission, roughness, metallic, outlined]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic * 0.4
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.rim_enabled = true
	m.rim = 0.2
	m.rim_tint = 0.6
	if outlined and color.a >= 1.0 and emission < 2.0:
		attach_outline(m)
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_materials[key] = m
	return m


static func gold() -> StandardMaterial3D:
	return mat(Color(1.0, 0.8, 0.38), 0.0, 0.35, 0.75)


static func _as_mat(c: Variant) -> Material:
	return c if c is Material else mat(c)


static func add(parent: Node3D, mesh: Mesh, pos: Vector3, material: Variant, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _as_mat(material)
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi


static func box(parent: Node3D, size: Vector3, pos: Vector3, material: Variant, rot := Vector3.ZERO) -> MeshInstance3D:
	var key := "box%s" % size
	if not _meshes.has(key):
		var m := BoxMesh.new()
		m.size = size
		_meshes[key] = m
	return add(parent, _meshes[key], pos, material, rot)


## ทรงกระบอก/กรวย (pos = จุดกึ่งกลาง)
static func cyl(parent: Node3D, r_top: float, r_bottom: float, h: float, pos: Vector3, material: Variant, sides: int = 12, rot := Vector3.ZERO) -> MeshInstance3D:
	sides = _smooth(sides)
	var key := "cyl%s|%s|%s|%s" % [r_top, r_bottom, h, sides]
	if not _meshes.has(key):
		var m := CylinderMesh.new()
		m.top_radius = r_top
		m.bottom_radius = r_bottom
		m.height = h
		m.radial_segments = sides
		m.rings = 1
		_meshes[key] = m
	return add(parent, _meshes[key], pos, material, rot)


## ความถี่ของจุดบนพื้นแผนที่ (พื้นยุบเป็นคลอง/ทางเดินด้วย shader) ระดับต่ำใช้จุดน้อยลง
static func ground_detail() -> float:
	return minf(1.0, detail)


static func _smooth(n: int) -> int:
	if n < 8 or detail == 1.0:
		return n
	return maxi(8, int(round(n * detail)))


static func sphere(parent: Node3D, r: float, pos: Vector3, material: Variant, segs: int = 12, scl := Vector3.ONE) -> MeshInstance3D:
	segs = _smooth(segs)
	var key := "sph%s|%s" % [r, segs]
	if not _meshes.has(key):
		var m := SphereMesh.new()
		m.radius = r
		m.height = r * 2.0
		m.radial_segments = segs
		m.rings = maxi(2, segs / 2)
		_meshes[key] = m
	return add(parent, _meshes[key], pos, material, Vector3.ZERO, scl)


## หลังคาจั่ว: หน้าตัดสี่เหลี่ยมคางหมู กว้าง width (แกน x) ยาว depth (แกน z) สูง height
## top_width = 0 คือจั่วแหลม
static func roof(parent: Node3D, width: float, depth: float, height: float, top_width: float, pos: Vector3, material: Variant, rot := Vector3.ZERO) -> MeshInstance3D:
	var key := "roof%s|%s|%s|%s" % [width, depth, height, top_width]
	if not _meshes.has(key):
		var w := width / 2.0
		var t := top_width / 2.0
		var d := depth / 2.0
		var section := [Vector2(-w, 0), Vector2(w, 0), Vector2(t, height), Vector2(-t, height)]
		var faces: Array[PackedVector3Array] = []
		for i in 4:
			var a: Vector2 = section[i]
			var b: Vector2 = section[(i + 1) % 4]
			if a.distance_to(b) < 0.001:
				continue
			faces.append(PackedVector3Array([Vector3(a.x, a.y, -d), Vector3(b.x, b.y, -d), Vector3(b.x, b.y, d), Vector3(a.x, a.y, d)]))
		for z in [-d, d]:
			var cap := PackedVector3Array()
			for p in section:
				if cap.is_empty() or Vector2(cap[cap.size() - 1].x, cap[cap.size() - 1].y).distance_to(p) > 0.001:
					cap.append(Vector3(p.x, p.y, z))
			faces.append(cap)
		_meshes[key] = convex_mesh(faces)
	return add(parent, _meshes[key], pos, material, rot)


## สร้าง mesh จากหน้าตัดนูน (แต่ละหน้าเป็นรูปหลายเหลี่ยมระนาบเดียว) โดยคำนวณทิศหน้าให้เอง
static func convex_mesh(faces: Array[PackedVector3Array]) -> ArrayMesh:
	var center := Vector3.ZERO
	var count := 0
	for f in faces:
		for v in f:
			center += v
			count += 1
	center /= count
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		var fc := Vector3.ZERO
		for v in f:
			fc += v
		fc /= f.size()
		var n := (f[1] - f[0]).cross(f[2] - f[0]).normalized()
		if n.dot(fc - center) < 0.0:
			n = -n
		for i in range(1, f.size() - 1):
			var a := f[0]
			var b := f[i]
			var c := f[i + 1]
			# Godot ใช้ด้านหน้าแบบตามเข็มนาฬิกา
			if (b - a).cross(c - a).dot(n) > 0.0:
				var tmp := b
				b = c
				c = tmp
			for v in [a, b, c]:
				st.set_normal(n)
				st.add_vertex(v)
	return st.commit()


## แคปซูล (ทรงยาวหัวท้ายมน) ใช้ทำแขน ขา ลำตัว: h = ความยาวรวมทั้งหัวท้าย
static func capsule(parent: Node3D, r: float, h: float, pos: Vector3, material: Variant, rot := Vector3.ZERO, scl := Vector3.ONE, segs: int = 12) -> MeshInstance3D:
	segs = _smooth(segs)
	var key := "cap%s|%s|%s" % [r, h, segs]
	if not _meshes.has(key):
		var m := CapsuleMesh.new()
		m.radius = r
		m.height = maxf(h, r * 2.0)
		m.radial_segments = segs
		m.rings = maxi(2, segs / 3)
		_meshes[key] = m
	return add(parent, _meshes[key], pos, material, rot, scl)


## แท่งยาวระหว่างจุด a กับ b (ใช้ทำคานเฉียง ขอบหลังคา ราก ฯลฯ)
static func beam(parent: Node3D, a: Vector3, b: Vector3, thickness: float, material: Variant) -> MeshInstance3D:
	var mid := (a + b) / 2.0
	var mi := box(parent, Vector3(thickness, a.distance_to(b), thickness), mid, material)
	var dir := (b - a).normalized()
	var up := Vector3.UP
	var axis := up.cross(dir)
	if axis.length() > 0.0001:
		mi.quaternion = Quaternion(axis.normalized(), up.angle_to(dir))
	elif dir.y < 0.0:
		mi.rotation = Vector3(PI, 0, 0)
	return mi


static func label(parent: Node3D, text: String, pos: Vector3, color: Color, size: int = 40) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = size
	l.font = font()
	l.outline_size = 12
	l.modulate = color
	l.outline_modulate = Color(0.36, 0.24, 0.3, 0.9)
	l.pixel_size = 0.006
	l.no_depth_test = true
	l.render_priority = 5
	parent.add_child(l)
	return l
