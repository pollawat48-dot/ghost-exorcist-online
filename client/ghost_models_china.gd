extends RefCounted
## โมเดลผีจีนแบบชิบิน่ารัก (เรียกจาก ghost.gd _build_model)
## g = โหนดผี (ghost.gd): ใช้ g.model, g.dangles, g.float_height, g.label_y, g.crown_y, g.hop, g.is_boss()

const K = preload("res://maps/props/mesh_kit.gd")


## สร้างโมเดลตามชนิด คืน false ถ้าไม่รู้จักชนิดนี้
static func build(g, kind: String, c: Color, eye: Material, shine: Material, blush: Material) -> bool:
	match kind:
		"jiangshi":
			_jiangshi(g, c, eye, shine, blush)
		"drowned":
			_drowned(g, c, eye, shine, blush)
		"fox":
			_fox(g, c, eye, shine, blush)
		"hanged":
			_hanged(g, c, eye, shine, blush)
		"nu_gui":
			_nu_gui(g, c, eye, shine, blush)
		"terracotta":
			_terracotta(g, c, eye, shine, blush)
		"painted_skin":
			_painted_skin(g, c, eye, shine, blush)
		"hanba":
			_hanba(g, c, eye, shine, blush)
		"bone":
			_bone(g, c, eye, shine, blush)
		"ox_head":
			_ox_head(g, c, eye, shine, blush)
		"horse_face":
			_horse_face(g, c, eye, shine, blush)
		"impermanence":
			_impermanence(g, c, eye, shine, blush)
		"yama":
			_yama(g, c, eye, shine, blush)
		_:
			return false
	return true


# ---------- ตัวช่วย ----------

## ตาโต + ประกาย + แก้มแดง (center = กลางระหว่างตา)
static func _face(m: Node3D, center: Vector3, spread: float, eye: Material, shine: Material, blush: Material, size: float = 1.0) -> void:
	for x in [-spread, spread]:
		K.sphere(m, 0.075 * size, center + Vector3(x, 0, 0), eye, 10, Vector3(0.85, 1.2, 0.5))
		K.sphere(m, 0.027 * size, center + Vector3(x + 0.025 * size, 0.04 * size, 0.04 * size), shine, 6)
		K.sphere(m, 0.055 * size, center + Vector3(x * 1.6, -0.1 * size, -0.02), blush, 8, Vector3(1.2, 0.6, 0.4))


static func _mouth(m: Node3D, pos: Vector3, size: float = 1.0) -> void:
	K.sphere(m, 0.04 * size, pos, K.mat(Color(0.6, 0.25, 0.35), 0.0, 0.8, 0.0, false), 6, Vector3(1.4, 0.9, 0.6))


## โหนดห้อยแกว่ง (ghost._sync หมุนแกน x ให้)
static func _dangle(g, pos: Vector3) -> Node3D:
	var d := Node3D.new()
	d.position = pos
	g.model.add_child(d)
	g.dangles.append(d)
	return d


static func _ring(parent: Node3D, inner: float, outer: float, pos: Vector3, material: Variant, rot := Vector3.ZERO) -> void:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 12
	t.ring_segments = 6
	K.add(parent, t, pos, material, rot)


## แขนห้อยสั้นๆ พร้อมมือกลม (คืนโหนดแขน)
static func _arm(g, side: float, at: Vector3, length: float, r: float, sleeve: Material, hand: Material) -> Node3D:
	var d := _dangle(g, at)
	K.cyl(d, r * 0.85, r, length, Vector3(side * 0.04, -length * 0.45, 0), sleeve, 8, Vector3(0, 0, side * 0.15))
	K.sphere(d, r * 0.9, Vector3(side * 0.08, -length * 0.95, 0.02), hand, 8)
	return d


# ---------- เจียงซือ (ผีดิบจีน) ----------

## ชุดขุนนางชิง หมวกกลมมีจุก ยันต์เหลืองแปะหน้าผาก ยื่นแขนไปข้างหน้า กระโดดดึ๋งๆ
static func _jiangshi(g, c: Color, eye: Material, shine: Material, blush: Material) -> void:
	var m: Node3D = g.model
	g.float_height = 0.04
	g.hop = true
	g.label_y = 2.25
	var robe := K.mat(c, 0.15, 0.7)
	var trim := K.mat(c.darkened(0.5), 0.0, 0.7)
	var skin := K.mat(Color(0.84, 0.96, 0.86), 0.15, 0.7)
	var hat := K.mat(Color(0.24, 0.22, 0.32), 0.0, 0.7)
	var red := K.mat(Color(0.92, 0.28, 0.32), 0.3, 0.6)
	var paper := K.mat(Color(1.0, 0.88, 0.35), 0.4, 0.7)
	# ตัวป้อมๆ + ขอบชายเสื้อ + คอเสื้อ
	K.cyl(m, 0.26, 0.36, 0.8, Vector3(0, 0.5, 0), robe, 14)
	K.cyl(m, 0.37, 0.37, 0.08, Vector3(0, 0.13, 0), trim, 14)
	K.cyl(m, 0.21, 0.23, 0.07, Vector3(0, 0.92, 0), trim, 12)
	# ผ้าปักอกสี่เหลี่ยม (ปู่ฟาง)
	K.box(m, Vector3(0.3, 0.26, 0.04), Vector3(0, 0.58, 0.31), K.mat(Color(1.0, 0.82, 0.45), 0.2, 0.6))
	K.sphere(m, 0.06, Vector3(0, 0.58, 0.34), red, 8, Vector3(1, 1, 0.4))
	for x in [-0.13, 0.13]:
		K.box(m, Vector3(0.14, 0.1, 0.24), Vector3(x, 0.05, 0.04), K.mat(Color(0.2, 0.18, 0.24)))
	# หัว + หน้า
	K.sphere(m, 0.36, Vector3(0, 1.25, 0), skin, 16)
	_face(m, Vector3(0, 1.2, 0.31), 0.16, eye, shine, blush)
	_mouth(m, Vector3(0, 1.07, 0.33), 0.8)
	# หมวกกลมปีกงอน + พู่แดง + จุกบนยอด
	K.sphere(m, 0.33, Vector3(0, 1.5, 0), hat, 14, Vector3(1, 0.62, 1))
	K.cyl(m, 0.44, 0.34, 0.12, Vector3(0, 1.5, 0), hat, 16)
	K.cyl(m, 0.06, 0.3, 0.13, Vector3(0, 1.66, 0), red, 14)
	K.sphere(m, 0.075, Vector3(0, 1.76, 0), K.mat(Color(1.0, 0.45, 0.4), 0.6, 0.4), 8)
	# ยันต์เหลืองห้อยจากปีกหมวกแปะหน้าผาก (ไม่บังตา)
	K.box(m, Vector3(0.17, 0.3, 0.02), Vector3(0, 1.33, 0.36), paper, Vector3(-0.05, 0, 0))
	K.box(m, Vector3(0.03, 0.2, 0.012), Vector3(0, 1.33, 0.372), red, Vector3(-0.05, 0, 0))
	for y in [1.41, 1.26]:
		K.box(m, Vector3(0.1, 0.03, 0.012), Vector3(0, y, 0.374), red, Vector3(-0.05, 0, 0.3))
	# แขนยื่นตรงไปข้างหน้า (แกว่งขึ้นลงตอนกระโดด)
	for side in [-1.0, 1.0]:
		var d := _dangle(g, Vector3(side * 0.27, 0.82, 0.05))
		K.cyl(d, 0.09, 0.11, 0.48, Vector3(0, 0, 0.2), robe, 8, Vector3(PI / 2, 0, 0))
		K.cyl(d, 0.115, 0.115, 0.06, Vector3(0, 0, 0.43), trim, 8, Vector3(PI / 2, 0, 0))
		K.sphere(d, 0.085, Vector3(0, 0, 0.52), skin, 8, Vector3(1, 0.8, 1.1))
	g.crown_y = 1.45


# ---------- ผีน้ำ (สุ่ยกุ่ย) ----------

## ผีจมน้ำตัวเปียก สีฟ้าซีด ผมยาวเปียกมีสาหร่ายพัน หยดน้ำติ๋งๆ
static func _drowned(g, c: Color, eye: Material, shine: Material, blush: Material) -> void:
	var m: Node3D = g.model
	g.float_height = 0.95
	g.label_y = 2.15
	var skin := K.mat(Color(0.8, 0.93, 1.0).lerp(c, 0.15), 0.25, 0.5)
	var robe := K.mat(c.lerp(Color.WHITE, 0.35), 0.25, 0.35)
	var hair := K.mat(Color(0.16, 0.24, 0.32), 0.0, 0.35)
	var weed := K.mat(Color(0.35, 0.72, 0.45), 0.2, 0.6)
	var drop := K.mat(Color(0.55, 0.85, 1.0, 0.8), 1.6, 0.2, 0.0, false)
	# ตัวทรงหยดน้ำ ชายผ้าเป็นคลื่น
	K.cyl(m, 0.3, 0.44, 0.55, Vector3(0, -0.3, 0), robe, 14)
	for i in 7:
		var a := i * TAU / 7.0
		K.sphere(m, 0.11, Vector3(cos(a) * 0.42, -0.58, sin(a) * 0.42), robe, 8)
	# หัว + ผมเปียกแปะหัว + ผมยาวด้านหลัง
	K.sphere(m, 0.38, Vector3(0, 0.15, 0), skin, 16)
	K.sphere(m, 0.4, Vector3(0, 0.25, -0.08), hair, 16, Vector3(1.05, 0.88, 1.0))
	K.box(m, Vector3(0.66, 0.85, 0.1), Vector3(0, -0.15, -0.3), hair)
	for i in 5:
		var a := -0.6 + i * 0.3
		K.cyl(m, 0.06, 0.02, 0.22, Vector3(sin(a) * 0.3, 0.38, 0.22 + cos(a) * 0.03), hair, 6, Vector3(0.6, 0, -a * 0.5))
	_face(m, Vector3(0, 0.12, 0.34), 0.14, eye, shine, blush)
	K.sphere(m, 0.035, Vector3(0, -0.04, 0.36), K.mat(Color(0.45, 0.3, 0.45), 0.0, 0.8, 0.0, false), 8)
	# สาหร่ายบนหัว
	for x in [-0.12, 0.05]:
		K.sphere(m, 0.09, Vector3(x, 0.5, 0.05), weed, 6, Vector3(0.6, 1.4, 0.4))
	# ปอยผมยาวข้างแก้ม (แกว่ง) มีหยดน้ำที่ปลาย
	for side in [-1.0, 1.0]:
		var d := _dangle(g, Vector3(side * 0.33, 0.2, 0.06))
		K.cyl(d, 0.075, 0.035, 0.75, Vector3(0, -0.37, 0), hair, 6)
		K.sphere(d, 0.05, Vector3(0, -0.8, 0), drop, 8, Vector3(1, 1.3, 1))
	# สาหร่ายห้อยจากชายผ้า
	for i in 3:
		var d := _dangle(g, Vector3(-0.25 + i * 0.25, -0.55, 0.25 - absf(i - 1.0) * 0.08))
		K.cyl(d, 0.035, 0.02, 0.35, Vector3(0, -0.15, 0), weed, 5)
		K.sphere(d, 0.06, Vector3(0.04, -0.12, 0), weed, 6, Vector3(1.3, 0.6, 0.5))
	# หยดน้ำที่หยดลงมา
	for p in [Vector3(0.2, -0.9, 0.15), Vector3(-0.15, -1.05, 0.0), Vector3(0.05, -0.8, -0.2)]:
		K.sphere(m, 0.045, p, drop, 8, Vector3(1, 1.4, 1))
	g.crown_y = 0.2


# ---------- จิ้งจอกเจ้าเสน่ห์ (หูลีจิง) ----------

## จิ้งจอกนั่งตัวกลม หูแหลม หางฟูหลายหาง (บอสเก้าหาง) มีไฟจิ้งจอกลอยรอบตัว
static func _fox(g, c: Color, eye: Material, shine: Material, blush: Material) -> void:
	var m: Node3D = g.model
	g.float_height = 0.2
	g.label_y = 2.1
	var boss: bool = g.is_boss()
	var fur := K.mat(c, 0.15, 0.8)
	var white := K.mat(Color(1.0, 0.97, 0.92), 0.15, 0.8)
	var dark := K.mat(c.darkened(0.55), 0.0, 0.8)
	# ตัวนั่ง + อกขนขาว + เท้าหน้า
	K.sphere(m, 0.4, Vector3(0, 0.4, -0.05), fur, 14, Vector3(1, 1.05, 1))
	K.sphere(m, 0.26, Vector3(0, 0.5, 0.22), white, 12)
	for x in [-0.15, 0.15]:
		K.sphere(m, 0.1, Vector3(x, 0.08, 0.28), white, 8, Vector3(1, 0.8, 1.3))
	# หัว + ขนแก้มฟู + ปากขาว + จมูก
	K.sphere(m, 0.38, Vector3(0, 1.0, 0.08), fur, 16)
	for side in [-1.0, 1.0]:
		K.sphere(m, 0.15, Vector3(side * 0.3, 0.86, 0.12), white, 8, Vector3(1.2, 0.8, 1))
		# หูแหลม + ในหู
		K.cyl(m, 0.0, 0.14, 0.34, Vector3(side * 0.2, 1.38, 0.0), fur, 8, Vector3(0, 0, -side * 0.3))
		K.cyl(m, 0.0, 0.08, 0.22, Vector3(side * 0.2, 1.36, 0.06), white, 6, Vector3(0, 0, -side * 0.3))
		K.cyl(m, 0.0, 0.05, 0.1, Vector3(side * 0.25, 1.52, 0.0), dark, 6, Vector3(0, 0, -side * 0.3))
	K.sphere(m, 0.16, Vector3(0, 0.89, 0.38), white, 10, Vector3(1.1, 0.75, 1.0))
	K.sphere(m, 0.05, Vector3(0, 0.94, 0.53), K.mat(Color(0.25, 0.15, 0.2)), 8)
	_face(m, Vector3(0, 1.06, 0.38), 0.15, eye, shine, blush)
	# ลายจุดแดงกลางหน้าผาก
	K.sphere(m, 0.035, Vector3(0, 1.2, 0.43), K.mat(Color(1.0, 0.35, 0.45), 1.0, 0.5, 0.0, false), 6, Vector3(0.7, 1.4, 0.5))
	# หางฟู (บอส = เก้าหาง) แต่ละหางแกว่งไม่พร้อมกัน
	var n := 9 if boss else 3
	var spread := 1.15 if boss else 0.5
	for i in n:
		var a := -spread + spread * 2.0 * i / float(n - 1)
		var d := _dangle(g, Vector3(0, 0.25, -0.32))
		var t := Node3D.new()
		# กางเป็นพัดขึ้นด้านหลัง เอนออกนิดๆ สลับสั้นยาว
		t.rotation = Vector3(-0.35 - (0.2 if i % 2 == 1 else 0.0), 0, a)
		d.add_child(t)
		var r := 0.16 if boss else 0.19
		K.sphere(t, r, Vector3(0, 0.45, 0), fur, 10, Vector3(1, 2.6, 1))
		K.sphere(t, r * 0.85, Vector3(0, 0.88, 0), white, 8, Vector3(1, 1.4, 1))
	# ไฟจิ้งจอก (ดวงไฟฟ้าลอยข้างตัว)
	var fire := K.mat(Color(0.55, 0.85, 1.0), 2.2, 0.3, 0.0, false)
	var core := K.mat(Color(0.92, 1.0, 1.0), 2.5, 0.3, 0.0, false)
	var spots := [Vector3(-0.62, 0.95, 0.15), Vector3(0.62, 0.75, 0.1)]
	if boss:
		spots.append(Vector3(0, 1.75, -0.2))
	for p in spots:
		var d := _dangle(g, p)
		K.sphere(d, 0.1, Vector3(0, 0.08, 0), fire, 10, Vector3(1, 1.3, 1))
		K.cyl(d, 0.0, 0.07, 0.18, Vector3(0, 0.22, 0), fire, 6)
		K.sphere(d, 0.05, Vector3(0, 0.07, 0), core, 6)
	g.crown_y = 1.05


# ---------- ผีผูกคอ (เตี้ยวสื่อกุ่ย) ----------

## ชุดขาว ลิ้นแดงยาวห้อย มีเชือกบ่วงที่คอ เท้าเล็กๆ ห้อยแกว่ง
static func _hanged(g, c: Color, eye: Material, shine: Material, blush: Material) -> void:
	var m: Node3D = g.model
	g.float_height = 0.9
	g.label_y = 2.95
	var robe := K.mat(c.lerp(Color.WHITE, 0.65), 0.25, 0.7)
	var skin := K.mat(Color(0.95, 0.95, 1.0), 0.2, 0.7)
	var hair := K.mat(Color(0.18, 0.16, 0.24), 0.0, 0.6)
	var rope := K.mat(Color(0.82, 0.66, 0.45), 0.0, 0.9)
	var tongue := K.mat(Color(0.95, 0.3, 0.38), 0.4, 0.5)
	K.cyl(m, 0.22, 0.36, 0.8, Vector3(0, 0.4, 0), robe, 14)
	K.cyl(m, 0.37, 0.37, 0.06, Vector3(0, 0.03, 0), K.mat(c.lerp(Color.WHITE, 0.3)), 14)
	K.sphere(m, 0.36, Vector3(0, 1.12, 0), skin, 16)
	K.sphere(m, 0.38, Vector3(0, 1.2, -0.07), hair, 16, Vector3(1.0, 0.86, 1.0))
	K.box(m, Vector3(0.6, 0.6, 0.1), Vector3(0, 0.9, -0.27), hair)
	# หน้าตาง่วงๆ ปากชมพูมีลิ้นยาวห้อย (แกว่ง)
	_face(m, Vector3(0, 1.15, 0.33), 0.14, eye, shine, blush)
	K.sphere(m, 0.06, Vector3(0, 1.0, 0.33), K.mat(Color(0.6, 0.22, 0.32)), 8, Vector3(1.3, 0.8, 0.6))
	var t := _dangle(g, Vector3(0, 1.0, 0.36))
	K.box(t, Vector3(0.12, 0.5, 0.04), Vector3(0, -0.25, 0.04), tongue)
	K.sphere(t, 0.065, Vector3(0, -0.5, 0.04), tongue, 8, Vector3(1, 0.8, 0.6))
	# บ่วงเชือกรอบคอ ปมด้านหลัง เชือกโยงขึ้นฟ้า
	_ring(m, 0.2, 0.26, Vector3(0, 0.86, 0), rope)
	K.sphere(m, 0.08, Vector3(0, 0.92, -0.25), rope, 8)
	K.beam(m, Vector3(0, 0.92, -0.25), Vector3(0, 1.95, -0.32), 0.05, rope)
	# แขนเสื้อห้อย
	for side in [-1.0, 1.0]:
		_arm(g, side, Vector3(side * 0.25, 0.72, 0.02), 0.38, 0.09, robe, skin)
	# เท้าเล็กๆ ห้อยแกว่ง
	for x in [-0.1, 0.1]:
		var d := _dangle(g, Vector3(x, 0.02, 0.02))
		K.cyl(d, 0.045, 0.045, 0.3, Vector3(0, -0.15, 0), skin, 6)
		K.sphere(d, 0.07, Vector3(0, -0.32, 0.04), K.mat(Color(0.85, 0.35, 0.45)), 8, Vector3(1, 0.7, 1.5))
	g.crown_y = 1.15


# ---------- ผีผู้หญิง (หนวี่กุ่ย) ----------

## สาวชุดฮั่นฝูขาว ผมดำยาวปิดหน้า แอบมองผ่านช่องผม ลอยไปมา
static func _nu_gui(g, c: Color, eye: Material, shine: Material, blush: Material) -> void:
	var m: Node3D = g.model
	g.float_height = 0.6
	g.label_y = 2.75
	var dress := K.mat(c.lerp(Color.WHITE, 0.6), 0.3, 0.7)
	var accent := K.mat(c.darkened(0.1), 0.2, 0.7)
	var skin := K.mat(Color(1.0, 0.95, 0.96), 0.15, 0.7)
	var hair := K.mat(Color(0.14, 0.12, 0.2), 0.0, 0.55)
	K.cyl(m, 0.2, 0.48, 1.0, Vector3(0, 0.5, 0), dress, 16)
	for i in 8:
		var a := i * TAU / 8.0
		K.sphere(m, 0.1, Vector3(cos(a) * 0.46, 0.02, sin(a) * 0.46), dress, 8)
	# สายคาดเอว + คอเสื้อไขว้
	K.cyl(m, 0.29, 0.31, 0.1, Vector3(0, 0.78, 0), accent, 14)
	for side in [-1.0, 1.0]:
		K.box(m, Vector3(0.05, 0.3, 0.03), Vector3(side * 0.06, 0.93, 0.21), accent, Vector3(-0.2, 0, side * 0.55))
		# แขนเสื้อกว้างพลิ้ว
		var d := _dangle(g, Vector3(side * 0.22, 1.08, 0.0))
		K.cyl(d, 0.06, 0.2, 0.55, Vector3(side * 0.08, -0.25, 0), dress, 10, Vector3(0, 0, side * 0.25))
	# หัว + ผมดำคลุม + ม่านผมด้านหน้าปิดหน้าเกือบหมด
	K.sphere(m, 0.33, Vector3(0, 1.45, 0), skin, 16)
	K.sphere(m, 0.36, Vector3(0, 1.52, -0.04), hair, 16, Vector3(1.05, 0.95, 1.0))
	K.box(m, Vector3(0.66, 1.0, 0.1), Vector3(0, 1.08, -0.27), hair)
	for side in [-1.0, 1.0]:
		K.box(m, Vector3(0.21, 0.7, 0.07), Vector3(side * 0.2, 1.3, 0.25), hair, Vector3(0, side * 0.5, 0))
	K.box(m, Vector3(0.3, 0.12, 0.08), Vector3(0, 1.64, 0.27), hair, Vector3(-0.4, 0, 0))
	# ตาแอบมองผ่านช่องผม
	_face(m, Vector3(0, 1.46, 0.31), 0.065, eye, shine, blush, 0.8)
	# ปิ่นดอกไม้
	K.sphere(m, 0.07, Vector3(0.26, 1.72, 0.0), K.mat(Color(1.0, 0.55, 0.65), 0.6, 0.6), 8)
	g.crown_y = 1.5


# ---------- ทหารดินเผา (ปิงหม่าหย่ง) ----------

## ทหารดินเผาตัวป้อม เกราะเกล็ด มวยผม ถือทวนจี่ (บอส = จักรพรรดิประดับทอง)
static func _terracotta(g, c: Color, eye: Material, shine: Material, blush: Material) -> void:
	var m: Node3D = g.model
	g.float_height = 0.15
	g.label_y = 2.5
	var boss: bool = g.is_boss()
	var clay_c := Color(0.84, 0.58, 0.44).lerp(c, 0.3)
	var clay := K.mat(clay_c, 0.05, 0.9)
	var plate := K.gold() if boss else K.mat(clay_c.darkened(0.3), 0.0, 0.85)
	var rivet := K.mat(Color(0.9, 0.3, 0.3), 0.5, 0.5) if boss else K.mat(clay_c.lightened(0.25), 0.0, 0.8)
	var dark := K.mat(clay_c.darkened(0.45), 0.0, 0.9)
	# ขา + รองเท้า + กระโปรงเกราะ
	for x in [-0.13, 0.13]:
		K.cyl(m, 0.09, 0.1, 0.3, Vector3(x, 0.15, 0), clay, 8)
		K.box(m, Vector3(0.15, 0.08, 0.24), Vector3(x, 0.03, 0.04), dark)
	K.cyl(m, 0.3, 0.38, 0.3, Vector3(0, 0.42, 0), clay, 14)
	# ลำตัวเกราะเกล็ด
	K.cyl(m, 0.28, 0.3, 0.5, Vector3(0, 0.8, 0), clay, 14)
	for row in 3:
		for col in 3:
			var p := Vector3(-0.12 + col * 0.12, 0.66 + row * 0.13, 0.29)
			K.box(m, Vector3(0.1, 0.11, 0.04), p, plate)
			K.sphere(m, 0.018, p + Vector3(0, 0, 0.025), rivet, 4)
	K.cyl(m, 0.31, 0.31, 0.07, Vector3(0, 0.58, 0), plate, 14)
	for side in [-1.0, 1.0]:
		K.sphere(m, 0.15, Vector3(side * 0.3, 1.0, 0), plate, 10, Vector3(1, 0.7, 1))
	# หัว + ผมรวบ + มวยผมเอียงข้าง
	K.sphere(m, 0.34, Vector3(0, 1.33, 0), clay, 16)
	K.sphere(m, 0.35, Vector3(0, 1.41, -0.06), dark, 16, Vector3(1, 0.82, 1))
	K.sphere(m, 0.12, Vector3(0.12, 1.72, -0.02), dark, 10)
	K.cyl(m, 0.08, 0.1, 0.06, Vector3(0.12, 1.64, -0.02), plate, 8)
	_face(m, Vector3(0, 1.32, 0.31), 0.13, eye, shine, blush)
	# หนวดจิ๋ว
	for side in [-1.0, 1.0]:
		K.box(m, Vector3(0.08, 0.025, 0.02), Vector3(side * 0.045, 1.2, 0.335), dark, Vector3(0, 0, side * 0.35))
	# แขน (แขนขวาจับทวน)
	for side in [-1.0, 1.0]:
		_arm(g, side, Vector3(side * 0.33, 0.95, 0.02), 0.4, 0.08, clay, clay)
	var wood := K.mat(Color(0.55, 0.36, 0.28))
	var blade := K.gold() if boss else K.mat(Color(0.78, 0.82, 0.86), 0.2, 0.4, 0.5)
	K.beam(m, Vector3(0.46, 0.05, 0.12), Vector3(0.46, 2.0, 0.12), 0.05, wood)
	K.cyl(m, 0.0, 0.07, 0.28, Vector3(0.46, 2.14, 0.12), blade, 6)
	K.box(m, Vector3(0.22, 0.06, 0.03), Vector3(0.36, 1.9, 0.12), blade, Vector3(0, 0, 0.25))
	K.sphere(m, 0.06, Vector3(0.46, 1.95, 0.12), K.mat(Color(0.95, 0.3, 0.3)), 6)
	g.crown_y = 1.38


# ---------- ผีหนังทาสี (ฮว่าพี) ----------

## นางงามชุดสวย หน้ากากผิวมนุษย์ลอกออกครึ่งหนึ่ง เห็นหน้าปีศาจสีเขียว ถือพู่กัน
static func _painted_skin(g, c: Color, eye: Material, shine: Material, blush: Material) -> void:
	var m: Node3D = g.model
	g.float_height = 0.3
	g.label_y = 2.65
	var dress := K.mat(c, 0.3, 0.7)
	var skin := K.mat(Color(1.0, 0.92, 0.88), 0.1, 0.7)
	var demon := K.mat(Color(0.5, 0.86, 0.5), 0.3, 0.6)
	var hair := K.mat(Color(0.18, 0.14, 0.22), 0.0, 0.55)
	K.cyl(m, 0.18, 0.55, 1.1, Vector3(0, 0.55, 0), dress, 16)
	K.cyl(m, 0.25, 0.27, 0.1, Vector3(0, 0.95, 0), K.mat(Color(1.0, 0.95, 0.8)), 14)
	K.cyl(m, 0.14, 0.19, 0.3, Vector3(0, 1.27, 0), K.mat(c.lightened(0.35)), 12)
	# หัวปีศาจเขียว + หน้ากากผิวคนเลื่อนไปซ้าย (ฝั่งขวาเห็นเขียว)
	K.sphere(m, 0.34, Vector3(0, 1.72, 0), demon, 16)
	K.sphere(m, 0.35, Vector3(-0.19, 1.72, 0.0), skin, 16, Vector3(0.95, 1, 0.95))
	# แผ่นหนังที่ลอกงอขึ้น
	K.box(m, Vector3(0.16, 0.26, 0.02), Vector3(0.26, 1.62, 0.24), skin, Vector3(0.3, 1.1, -0.3))
	K.cyl(m, 0.025, 0.025, 0.26, Vector3(0.32, 1.6, 0.3), skin, 6, Vector3(0, 0, 0.25))
	# ตาซ้ายคนสวย ตาขวาปีศาจเรืองเหลือง
	K.sphere(m, 0.065, Vector3(-0.16, 1.73, 0.28), eye, 10, Vector3(0.85, 1.2, 0.5))
	K.sphere(m, 0.024, Vector3(-0.14, 1.77, 0.32), shine, 6)
	K.sphere(m, 0.05, Vector3(-0.26, 1.63, 0.25), blush, 8, Vector3(1.2, 0.6, 0.4))
	K.sphere(m, 0.075, Vector3(0.13, 1.74, 0.3), K.mat(Color(1.0, 0.92, 0.3), 2.0, 0.3, 0.0, false), 10, Vector3(1.1, 0.9, 0.5))
	K.sphere(m, 0.032, Vector3(0.13, 1.74, 0.335), eye, 6, Vector3(0.5, 1.4, 0.5))
	for k in 2:
		K.cyl(m, 0.0, 0.028, 0.08, Vector3(0.09 + k * 0.08, 1.56, 0.3), K.mat(Color(1, 1, 1)), 6, Vector3(PI, 0, 0))
	K.sphere(m, 0.035, Vector3(-0.08, 1.6, 0.31), K.mat(Color(0.9, 0.3, 0.4), 0.2, 0.6), 6, Vector3(1.3, 0.8, 0.6))
	# ผมดำมวยคู่ + ปิ่นทอง
	K.sphere(m, 0.36, Vector3(0, 1.82, -0.1), hair, 16, Vector3(1, 0.9, 1))
	K.box(m, Vector3(0.58, 0.7, 0.1), Vector3(0, 1.45, -0.28), hair)
	for side in [-1.0, 1.0]:
		K.sphere(m, 0.13, Vector3(side * 0.22, 2.06, -0.06), hair, 10)
	K.beam(m, Vector3(-0.38, 2.08, -0.04), Vector3(0.1, 2.12, -0.04), 0.025, K.gold())
	K.sphere(m, 0.045, Vector3(-0.38, 2.0, -0.04), K.mat(Color(0.9, 1.0, 0.95), 1.0, 0.3), 6)
	# แขน + พู่กันในมือขวา
	for side in [-1.0, 1.0]:
		var d := _dangle(g, Vector3(side * 0.22, 1.3, 0.05))
		K.cyl(d, 0.05, 0.13, 0.5, Vector3(side * 0.08, -0.22, 0), dress, 8, Vector3(0, 0, side * 0.3))
		K.sphere(d, 0.06, Vector3(side * 0.15, -0.48, 0.02), skin, 8)
		if side > 0:
			K.beam(d, Vector3(0.15, -0.38, -0.02), Vector3(0.17, -0.72, 0.18), 0.035, K.mat(Color(0.6, 0.4, 0.3)))
			K.cyl(d, 0.035, 0.0, 0.1, Vector3(0.175, -0.77, 0.21), K.mat(Color(0.95, 0.3, 0.4)), 6, Vector3(-0.55, 0, 0))
	g.crown_y = 1.85


# ---------- ฮั่นป๋า (ปีศาจแล้ง) ----------

## ปีศาจตัวจิ๋วผิวแดง ตาเดียวโต ผมเป็นเปลวไฟ มีไอร้อนรอบตัว
static func _hanba(g, c: Color, eye: Material, shine: Material, blush: Material) -> void:
	var m: Node3D = g.model
	g.float_height = 0.5
	g.label_y = 1.95
	var skin := K.mat(c, 0.35, 0.6)
	var belly := K.mat(c.lerp(Color(1.0, 0.9, 0.7), 0.55), 0.2, 0.7)
	var flame := K.mat(Color(1.0, 0.55, 0.2), 2.2, 0.4, 0.0, false)
	var flame_in := K.mat(Color(1.0, 0.92, 0.4), 2.5, 0.4, 0.0, false)
	K.sphere(m, 0.42, Vector3.ZERO, skin, 16)
	K.sphere(m, 0.25, Vector3(0, -0.12, 0.24), belly, 12, Vector3(1, 1, 0.6))
	# ตาเดียวโต
	K.sphere(m, 0.13, Vector3(0, 0.08, 0.37), K.mat(Color(1, 1, 1), 0.3, 0.5), 12, Vector3(1, 1.1, 0.5))
	K.sphere(m, 0.09, Vector3(0, 0.07, 0.42), eye, 10, Vector3(0.9, 1.1, 0.5))
	K.sphere(m, 0.035, Vector3(0.03, 0.12, 0.45), shine, 6)
	for x in [-0.22, 0.22]:
		K.sphere(m, 0.06, Vector3(x, -0.06, 0.33), blush, 8, Vector3(1.2, 0.6, 0.4))
	# ปากยิ้ม + เขี้ยวจิ๋ว
	K.sphere(m, 0.06, Vector3(0, -0.12, 0.38), K.mat(Color(0.55, 0.18, 0.25), 0.0, 0.8, 0.0, false), 8, Vector3(1.6, 0.7, 0.5))
	K.cyl(m, 0.0, 0.02, 0.05, Vector3(0.04, -0.1, 0.42), K.mat(Color(1, 1, 1)), 6, Vector3(PI, 0, 0))
	# ผมเปลวไฟ
	for i in 5:
		var a := -0.9 + i * 0.45
		var h := 0.45 - absf(a) * 0.15
		K.cyl(m, 0.0, 0.12, h, Vector3(sin(a) * 0.22, 0.38 + h * 0.4, -0.05), flame, 8, Vector3(-0.15, 0, -a * 0.6))
		K.cyl(m, 0.0, 0.06, h * 0.6, Vector3(sin(a) * 0.22, 0.36 + h * 0.3, 0.02), flame_in, 6, Vector3(-0.15, 0, -a * 0.6))
	# ไอร้อน + ลูกไฟจิ๋วลอยรอบ
	K.sphere(m, 0.62, Vector3(0, 0.05, 0), K.mat(Color(1.0, 0.6, 0.3, 0.16), 1.5, 0.5, 0.0, false), 14)
	for i in 4:
		var a := i * TAU / 4.0 + 0.4
		K.sphere(m, 0.04, Vector3(cos(a) * 0.6, 0.3 + sin(i * 2.1) * 0.25, sin(a) * 0.5), flame_in, 6)
	# แขนขาสั้นๆ
	for side in [-1.0, 1.0]:
		var d := _dangle(g, Vector3(side * 0.4, 0.0, 0.05))
		K.cyl(d, 0.06, 0.08, 0.22, Vector3(side * 0.04, -0.09, 0), skin, 8, Vector3(0, 0, side * 0.5))
		K.cyl(m, 0.07, 0.08, 0.16, Vector3(side * 0.15, -0.44, 0), skin, 8)
		K.sphere(m, 0.09, Vector3(side * 0.15, -0.53, 0.05), skin, 8, Vector3(1, 0.6, 1.3))
	g.crown_y = 0.5


# ---------- ผีกระดูกขาว (ไป๋กู่) ----------

## โครงกระดูกหัวโตตาโบ๋เรืองแสง (บอส = นางปีศาจกระดูกขาว ผมยาวชุดพลิ้ว)
static func _bone(g, c: Color, eye: Material, shine: Material, blush: Material) -> void:
	var m: Node3D = g.model
	g.float_height = 0.35
	g.label_y = 2.25
	var boss: bool = g.is_boss()
	var bone := K.mat(Color(0.97, 0.95, 0.9).lerp(c, 0.15), 0.2, 0.7)
	var glow := K.mat(c.lerp(Color(0.6, 0.9, 1.0), 0.4), 2.5, 0.3, 0.0, false)
	# ชุดพลิ้วของนางปีศาจ (บอส) ใส่ก่อนให้คลุมกระดูกท่อนล่าง
	if boss:
		K.cyl(m, 0.2, 0.5, 0.95, Vector3(0, 0.42, 0), K.mat(Color(0.95, 0.92, 1.0, 0.75), 0.5, 0.6), 16)
		K.cyl(m, 0.2, 0.22, 0.08, Vector3(0, 0.88, 0), K.mat(c.darkened(0.2), 0.3), 12)
	# สะโพก + กระดูกสันหลัง + ซี่โครง
	K.sphere(m, 0.17, Vector3(0, 0.25, 0), bone, 10, Vector3(1.3, 0.7, 0.9))
	K.cyl(m, 0.05, 0.05, 0.65, Vector3(0, 0.6, 0), bone, 6)
	for i in 3:
		var r := 0.2 - absf(i - 1.0) * 0.03
		_ring(m, r - 0.04, r, Vector3(0, 0.6 + i * 0.12, 0.02), bone)
	# ขา + เท้าห้อย
	for x in [-0.1, 0.1]:
		var d := _dangle(g, Vector3(x, 0.18, 0))
		K.cyl(d, 0.04, 0.04, 0.34, Vector3(0, -0.17, 0), bone, 6)
		K.sphere(d, 0.06, Vector3(0, -0.36, 0.04), bone, 6, Vector3(1, 0.7, 1.5))
	# แขน
	for side in [-1.0, 1.0]:
		_arm(g, side, Vector3(side * 0.24, 0.86, 0.0), 0.42, 0.04, bone, bone)
	# หัวกะโหลกโต + กราม + ตาโบ๋มีแสง + จมูกสามเหลี่ยม + ฟัน
	K.sphere(m, 0.36, Vector3(0, 1.25, 0), bone, 16)
	K.sphere(m, 0.2, Vector3(0, 1.03, 0.1), bone, 10, Vector3(1.2, 0.7, 1.0))
	for x in [-0.14, 0.14]:
		K.sphere(m, 0.1, Vector3(x, 1.27, 0.3), eye, 10, Vector3(1, 1.1, 0.5))
		K.sphere(m, 0.04, Vector3(x + 0.015, 1.29, 0.35), glow, 6)
		K.sphere(m, 0.05, Vector3(x * 1.65, 1.15, 0.27), blush, 8, Vector3(1.2, 0.6, 0.4))
	K.cyl(m, 0.035, 0.0, 0.07, Vector3(0, 1.15, 0.34), eye, 3, Vector3(PI / 2 - 0.3, 0, 0))
	for x in [-0.06, 0.0, 0.06]:
		K.box(m, Vector3(0.04, 0.05, 0.02), Vector3(x, 1.02, 0.29), K.mat(Color(1, 1, 1)))
	if boss:
		# ผมดำยาว + ปิ่นดอกไม้
		var hair := K.mat(Color(0.16, 0.14, 0.22), 0.0, 0.55)
		K.sphere(m, 0.38, Vector3(0, 1.36, -0.08), hair, 16, Vector3(1.05, 0.85, 1.0))
		K.box(m, Vector3(0.62, 0.9, 0.1), Vector3(0, 0.95, -0.28), hair)
		K.sphere(m, 0.07, Vector3(0.26, 1.55, 0.05), K.mat(Color(1.0, 0.6, 0.75), 0.8, 0.6), 8)
	g.crown_y = 1.25


# ---------- หัววัว (หนิวโถว) ----------

## ยามนรกหัววัว ตัวล่ำ เขาโค้ง ห่วงจมูกทอง ถือสามง่าม
static func _ox_head(g, c: Color, eye: Material, shine: Material, blush: Material) -> void:
	var m: Node3D = g.model
	var skin := K.mat(c, 0.15, 0.7)
	var muzzle := K.mat(c.lerp(Color(1.0, 0.86, 0.8), 0.6), 0.1, 0.7)
	_guard_body(g, skin)
	K.sphere(m, 0.4, Vector3(0, 1.45, 0.02), skin, 16)
	K.sphere(m, 0.24, Vector3(0, 1.32, 0.32), muzzle, 12, Vector3(1.3, 0.85, 0.8))
	var dark := K.mat(Color(0.3, 0.18, 0.22))
	for x in [-0.09, 0.09]:
		K.sphere(m, 0.035, Vector3(x, 1.34, 0.51), dark, 6)
	_ring(m, 0.06, 0.085, Vector3(0, 1.22, 0.51), K.gold(), Vector3(PI / 2, 0, 0))
	_face(m, Vector3(0, 1.56, 0.34), 0.16, eye, shine, blush)
	var horn := K.mat(Color(1.0, 0.95, 0.82), 0.1, 0.6)
	for side in [-1.0, 1.0]:
		# เขาโค้งออกข้างแล้วชี้ขึ้น
		K.cyl(m, 0.07, 0.1, 0.3, Vector3(side * 0.42, 1.72, 0), horn, 8, Vector3(0, 0, -side * 1.1))
		K.cyl(m, 0.0, 0.07, 0.25, Vector3(side * 0.56, 1.92, 0), horn, 8, Vector3(0, 0, -side * 0.25))
		K.sphere(m, 0.1, Vector3(side * 0.42, 1.5, -0.04), skin, 8, Vector3(1.4, 0.6, 0.8))
	K.sphere(m, 0.1, Vector3(0, 1.82, 0.05), dark, 8, Vector3(1.3, 0.7, 1))
	# สามง่าม
	var metal := K.mat(Color(0.82, 0.85, 0.92), 0.2, 0.4, 0.5)
	K.beam(m, Vector3(0.68, 0.0, 0.22), Vector3(0.68, 2.3, 0.22), 0.06, K.mat(Color(0.5, 0.32, 0.26)))
	K.box(m, Vector3(0.38, 0.06, 0.06), Vector3(0.68, 2.3, 0.22), metal)
	for dx in [-0.17, 0.0, 0.17]:
		K.cyl(m, 0.0, 0.045, 0.3 if dx == 0.0 else 0.22, Vector3(0.68 + dx, 2.45 if dx == 0.0 else 2.41, 0.22), metal, 6)
	g.label_y = 2.95
	g.crown_y = 1.95


## ตัวยามนรก (ใช้ร่วมหัววัว/หน้าม้า): เสื้อเกราะแดง เข็มขัดทอง ขาสั้น แขนล่ำ
static func _guard_body(g, skin: Material) -> void:
	var m: Node3D = g.model
	g.float_height = 0.15
	var vest := K.mat(Color(0.82, 0.3, 0.34), 0.1, 0.7)
	var pants := K.mat(Color(0.3, 0.26, 0.36))
	for x in [-0.2, 0.2]:
		K.cyl(m, 0.13, 0.14, 0.3, Vector3(x, 0.17, 0), pants, 8)
		K.box(m, Vector3(0.2, 0.1, 0.26), Vector3(x, 0.04, 0.03), K.mat(Color(0.22, 0.18, 0.24)))
	K.sphere(m, 0.5, Vector3(0, 0.72, 0), vest, 16, Vector3(1.1, 0.95, 0.9))
	K.cyl(m, 0.5, 0.5, 0.09, Vector3(0, 0.48, 0), K.gold(), 16)
	K.sphere(m, 0.08, Vector3(0, 0.48, 0.46), K.mat(Color(0.4, 0.9, 0.7), 0.8, 0.4), 8)
	for side in [-1.0, 1.0]:
		K.sphere(m, 0.17, Vector3(side * 0.48, 0.98, 0), K.gold(), 10, Vector3(1, 0.7, 1))
		var d := _dangle(g, Vector3(side * 0.58, 0.92, 0.05))
		K.cyl(d, 0.11, 0.13, 0.5, Vector3(side * 0.04, -0.24, 0), skin, 8, Vector3(0, 0, side * 0.15))
		K.sphere(d, 0.14, Vector3(side * 0.08, -0.52, 0.02), skin, 8)


# ---------- หน้าม้า (หม่าเมี่ยน) ----------

## ยามนรกหน้าม้า จมูกยาว หูตั้ง แผงคอ ถือโซ่ตรวน
static func _horse_face(g, c: Color, eye: Material, shine: Material, blush: Material) -> void:
	var m: Node3D = g.model
	var skin := K.mat(c, 0.15, 0.7)
	var muzzle := K.mat(c.lerp(Color(1.0, 0.92, 0.85), 0.55), 0.1, 0.7)
	var mane := K.mat(c.darkened(0.6), 0.0, 0.7)
	_guard_body(g, skin)
	K.sphere(m, 0.35, Vector3(0, 1.52, 0), skin, 16)
	K.sphere(m, 0.21, Vector3(0, 1.38, 0.3), muzzle, 12, Vector3(1.05, 0.9, 1.6))
	var dark := K.mat(Color(0.3, 0.18, 0.22))
	for x in [-0.08, 0.08]:
		K.sphere(m, 0.035, Vector3(x, 1.42, 0.62), dark, 6)
	K.sphere(m, 0.045, Vector3(0, 1.27, 0.55), K.mat(Color(0.6, 0.25, 0.35), 0.0, 0.8, 0.0, false), 6, Vector3(1.6, 0.6, 0.6))
	_face(m, Vector3(0, 1.62, 0.28), 0.16, eye, shine, blush)
	for side in [-1.0, 1.0]:
		K.cyl(m, 0.0, 0.09, 0.28, Vector3(side * 0.18, 1.9, -0.04), skin, 6, Vector3(0, 0, -side * 0.25))
	# แผงคอจากหน้าผากไปท้ายทอย + ปอยผมหน้าม้า
	for i in 6:
		var a := -0.3 + i * 0.32
		K.sphere(m, 0.1, Vector3(0, 1.52 + cos(a) * 0.36, sin(-a) * 0.36), mane, 8, Vector3(0.7, 1.2, 1.0))
	K.sphere(m, 0.09, Vector3(0, 1.78, 0.25), mane, 8, Vector3(1.0, 1.3, 0.7))
	# โซ่ตรวนห้อยจากมือขวา
	var metal := K.mat(Color(0.82, 0.85, 0.92), 0.2, 0.4, 0.5)
	var hand: Node3D = g.dangles[g.dangles.size() - 1]
	for i in 7:
		var rot := Vector3(PI / 2, 0, 0) if i % 2 == 0 else Vector3(0, 0, PI / 2)
		_ring(hand, 0.045, 0.075, Vector3(0.08, -0.66 - i * 0.11, 0.06), metal, rot)
	_ring(hand, 0.1, 0.14, Vector3(0.08, -1.5, 0.06), metal, Vector3(PI / 2, 0, 0))
	g.label_y = 2.75
	g.crown_y = 1.85


# ---------- ไป๋อู๋ฉาง / เฮยอู๋ฉาง (ยมทูตขาวดำ) ----------

## ชุดยาว หมวกกรวยสูงมีตัวอักษร ลิ้นยาวห้อย สีอ่อน = ขาว (ถือธงวิญญาณ) สีเข้ม = ดำ (ถือป้ายคำสั่ง)
static func _impermanence(g, c: Color, eye: Material, shine: Material, blush: Material) -> void:
	var m: Node3D = g.model
	g.float_height = 0.3
	g.label_y = 3.2
	var white := c.get_luminance() > 0.5
	var base := Color(0.97, 0.97, 1.0) if white else Color(0.2, 0.2, 0.27)
	var robe := K.mat(base.lerp(c, 0.2), 0.2, 0.7)
	var trim := K.mat(Color(0.75, 0.75, 0.85) if white else Color(0.45, 0.42, 0.55), 0.1, 0.7)
	var skin := K.mat(Color(1.0, 0.96, 0.96) if white else Color(0.66, 0.64, 0.78), 0.2, 0.7)
	var ink := K.mat(Color(0.9, 0.25, 0.3) if white else Color(1.0, 0.95, 0.85), 0.4, 0.6)
	var tongue := K.mat(Color(0.95, 0.3, 0.38), 0.4, 0.5)
	K.cyl(m, 0.3, 0.52, 1.2, Vector3(0, 0.6, 0), robe, 16)
	K.cyl(m, 0.53, 0.53, 0.07, Vector3(0, 0.04, 0), trim, 16)
	K.sphere(m, 0.36, Vector3(0, 1.2, 0), robe, 14, Vector3(1.25, 0.65, 1.0))
	K.cyl(m, 0.22, 0.24, 0.08, Vector3(0, 1.3, 0), trim, 12)
	for side in [-1.0, 1.0]:
		K.box(m, Vector3(0.05, 0.34, 0.03), Vector3(side * 0.07, 0.95, 0.3), trim, Vector3(-0.15, 0, side * 0.5))
	K.sphere(m, 0.34, Vector3(0, 1.62, 0), skin, 16)
	_face(m, Vector3(0, 1.65, 0.31), 0.13, eye, shine, blush)
	K.sphere(m, 0.06, Vector3(0, 1.5, 0.31), K.mat(Color(0.6, 0.22, 0.32)), 8, Vector3(1.3, 0.8, 0.6))
	var t := _dangle(g, Vector3(0, 1.5, 0.34))
	K.box(t, Vector3(0.11, 0.5, 0.035), Vector3(0, -0.25, 0.07), tongue)
	K.sphere(t, 0.06, Vector3(0, -0.5, 0.07), tongue, 8, Vector3(1, 0.8, 0.6))
	# หมวกกรวยสูง + ปีกหมวก + ตัวอักษรเรียงลงมา
	K.cyl(m, 0.11, 0.28, 0.95, Vector3(0, 2.3, -0.02), robe, 14)
	K.cyl(m, 0.36, 0.36, 0.06, Vector3(0, 1.84, -0.02), trim, 14)
	for i in 4:
		var y := 1.98 + i * 0.17
		var z := 0.28 - (y - 1.825) / 0.95 * 0.17 - 0.005
		K.box(m, Vector3(0.11, 0.025, 0.02), Vector3(0, y + 0.03, z), ink, Vector3(-0.19, 0, 0))
		K.box(m, Vector3(0.025, 0.1, 0.02), Vector3(0, y, z + 0.005), ink, Vector3(-0.19, 0, 0))
		K.box(m, Vector3(0.08, 0.02, 0.02), Vector3(0, y - 0.035, z + 0.007), ink, Vector3(-0.19, 0, 0))
	# แขนเสื้อยาว + ของในมือขวา
	for side in [-1.0, 1.0]:
		var d := _arm(g, side, Vector3(side * 0.36, 1.18, 0.02), 0.55, 0.1, robe, skin)
		if side < 0:
			continue
		if white:
			# ธงเรียกวิญญาณ: ไม้ยาวมีริ้วกระดาษขาวห้อย
			var paper := K.mat(Color(1.0, 1.0, 0.96), 0.4, 0.8)
			K.beam(d, Vector3(0.1, -0.9, 0.08), Vector3(0.1, 0.55, 0.08), 0.04, K.mat(Color(0.6, 0.42, 0.34)))
			for k in 4:
				K.box(d, Vector3(0.06, 0.45 - k * 0.05, 0.01), Vector3(0.0 + k * 0.07 - 0.1, 0.3, 0.08), paper, Vector3(0, 0, 0.05 * k))
			K.box(d, Vector3(0.3, 0.05, 0.03), Vector3(0.0, 0.55, 0.08), paper)
		else:
			# ป้ายคำสั่งไม้
			K.box(d, Vector3(0.22, 0.32, 0.04), Vector3(0.1, -0.7, 0.1), K.mat(Color(0.75, 0.55, 0.35)))
			K.box(d, Vector3(0.03, 0.2, 0.01), Vector3(0.1, -0.7, 0.125), K.mat(Color(0.9, 0.25, 0.3), 0.5))
	g.crown_y = 2.5


# ---------- พญายม (เหยียนหวัง) ----------

## ผู้พิพากษานรก หน้าแดง เคราดำ หมวกเหมี่ยนกวนมีสายลูกปัด ชุดขุนนาง ถือสมุดบัญชีกับพู่กัน
static func _yama(g, c: Color, eye: Material, shine: Material, blush: Material) -> void:
	var m: Node3D = g.model
	g.float_height = 0.15
	g.label_y = 2.7
	var robe := K.mat(c, 0.15, 0.7)
	var trim := K.mat(Color(1.0, 0.82, 0.4), 0.2, 0.5)
	var skin := K.mat(Color(0.96, 0.45, 0.4), 0.15, 0.7)
	var black := K.mat(Color(0.16, 0.14, 0.2), 0.0, 0.6)
	# ชุดขุนนางกว้าง + เข็มขัดหยก + บ่ากว้าง
	K.cyl(m, 0.36, 0.56, 1.0, Vector3(0, 0.5, 0), robe, 16)
	K.cyl(m, 0.57, 0.57, 0.07, Vector3(0, 0.04, 0), trim, 16)
	K.box(m, Vector3(0.24, 0.6, 0.04), Vector3(0, 0.45, 0.44), trim, Vector3(-0.2, 0, 0))
	K.cyl(m, 0.44, 0.44, 0.1, Vector3(0, 0.78, 0), K.gold(), 16)
	for x in [-0.2, 0.0, 0.2]:
		K.sphere(m, 0.05, Vector3(x, 0.78, 0.43), K.mat(Color(0.45, 0.9, 0.7), 0.8, 0.4), 6)
	K.sphere(m, 0.42, Vector3(0, 1.02, 0), robe, 16, Vector3(1.25, 0.6, 0.95))
	# หัวหน้าแดง + คิ้วหนา + หนวดเครายาว
	K.sphere(m, 0.42, Vector3(0, 1.48, 0.02), skin, 16)
	_face(m, Vector3(0, 1.55, 0.38), 0.15, eye, shine, blush)
	for side in [-1.0, 1.0]:
		K.box(m, Vector3(0.16, 0.05, 0.04), Vector3(side * 0.15, 1.67, 0.38), black, Vector3(0, 0, side * 0.25))
		K.sphere(m, 0.07, Vector3(side * 0.08, 1.38, 0.41), black, 8, Vector3(1.5, 0.5, 0.6))
		K.cyl(m, 0.08, 0.0, 0.32, Vector3(side * 0.16, 1.18, 0.32), black, 6, Vector3(0.2, 0, side * 0.25))
	K.cyl(m, 0.15, 0.0, 0.5, Vector3(0, 1.1, 0.36), black, 8, Vector3(0.25, 0, 0))
	# หมวกเหมี่ยนกวน: หมวกดำ + แผ่นราบด้านบน + สายลูกปัดห้อยหน้าหลัง + ปิ่นทอง
	K.cyl(m, 0.3, 0.32, 0.26, Vector3(0, 1.86, -0.02), black, 14)
	K.box(m, Vector3(0.66, 0.04, 0.8), Vector3(0, 2.0, 0.0), trim)
	K.box(m, Vector3(0.62, 0.05, 0.76), Vector3(0, 2.035, 0.0), black)
	K.beam(m, Vector3(-0.42, 1.86, -0.02), Vector3(0.42, 1.86, -0.02), 0.04, K.gold())
	var beads := [K.mat(Color(1.0, 0.4, 0.45), 0.6, 0.4), K.mat(Color(0.5, 0.95, 0.75), 0.6, 0.4), K.gold()]
	for z in [0.39, -0.39]:
		for i in 5:
			var x := -0.24 + i * 0.12
			for k in 3:
				K.sphere(m, 0.03, Vector3(x, 1.94 - k * 0.07, z), beads[(i + k) % 3], 6)
	# มือซ้ายถือสมุดบัญชีคนตาย มือขวาถือพู่กันแดง
	for side in [-1.0, 1.0]:
		var d := _dangle(g, Vector3(side * 0.5, 1.0, 0.05))
		K.cyl(d, 0.1, 0.2, 0.5, Vector3(side * 0.05, -0.23, 0), robe, 10, Vector3(0, 0, side * 0.2))
		K.sphere(d, 0.1, Vector3(side * 0.1, -0.5, 0.06), skin, 8)
		if side < 0:
			K.box(d, Vector3(0.32, 0.38, 0.08), Vector3(-0.1, -0.5, 0.18), K.mat(Color(0.3, 0.42, 0.7)))
			K.box(d, Vector3(0.28, 0.34, 0.09), Vector3(-0.08, -0.5, 0.18), K.mat(Color(1.0, 0.97, 0.88)))
			K.box(d, Vector3(0.08, 0.2, 0.01), Vector3(-0.1, -0.5, 0.225), trim)
		else:
			K.beam(d, Vector3(0.1, -0.42, 0.06), Vector3(0.14, -0.78, 0.3), 0.04, K.mat(Color(0.5, 0.32, 0.26)))
			K.cyl(d, 0.04, 0.0, 0.12, Vector3(0.145, -0.84, 0.34), K.mat(Color(0.95, 0.25, 0.3), 0.5), 6, Vector3(-0.85, 0, 0))
	g.crown_y = 1.9
