extends Node3D
## ร่างตัวละครจิบิแบบใหม่ (สร้างเองทั้งหมดจากรูปทรงพื้นฐาน ไม่ใช้โมเดลสำเร็จรูป)
## สัดส่วนราว 2.6 หัว: หัวโต ตัวป้อม แขนขาสั้น มีข้อต่อ ไหล่-ศอก-ข้อมือ และ สะโพก-เข่า-ข้อเท้า
## ทุกข้อต่อเป็น Node3D แยก เพื่อให้ท่าเดิน ท่าตี ท่ายืนหายใจ ขยับได้ทีละส่วน
## หน้าหันไปทาง +z (เหมือนโมเดลเดิม) พื้นอยู่ที่ y = 0

const K = preload("res://maps/props/mesh_kit.gd")

## ตำแหน่งข้อต่อหลัก (เมตร)
## ลำตัวทั้งท่อนถูกยกขึ้นเท่านี้จากค่าตั้งต้น (ขาจึงยาวขึ้นโดยไม่ต้องแก้ตำแหน่งชิ้นส่วนบนตัว)
const LIFT := 0.05
const HIP_Y := 0.34 + LIFT
const HIP_X := 0.095
const THIGH := 0.165
const SHIN := 0.165
const SHOULDER_Y := 0.62
const SHOULDER_X := 0.2
const UPPER_ARM := 0.14
const FOREARM := 0.13
const NECK_Y := 0.7
const HEAD_R := 0.4
## ศูนย์กลางหัวอยู่สูงจากคอเท่านี้
const HEAD_UP := 0.35

## สีตา (ม่านตา) ตามสีผม: น้ำตาลอำพัน ดำ น้ำตาลแดง ชมพู ม่วงเงิน
const IRIS := [Color(0.62, 0.38, 0.22), Color(0.3, 0.26, 0.42), Color(0.72, 0.42, 0.24), Color(0.85, 0.42, 0.55), Color(0.5, 0.45, 0.78)]

var torso: Node3D  ## ลำตัว (หมุนเอียงตอนเดิน)
var head: Node3D  ## หัว (ศูนย์กลางหัวอยู่ที่ตำแหน่งนี้)
var neck: Node3D
var shoulders: Array[Node3D] = []  ## [ซ้าย, ขวา]
var elbows: Array[Node3D] = []
var hands: Array[Node3D] = []  ## จุดกลางฝ่ามือ (ใช้ติดอาวุธที่มือขวา)
var hips: Array[Node3D] = []
var knees: Array[Node3D] = []
var feet: Array[Node3D] = []

var female := false
var skin_c := Color(1.0, 0.86, 0.74)
var hair_c := Color(0.36, 0.25, 0.24)
var iris_c := Color(0.62, 0.38, 0.22)
var shirt_c := Color(0.98, 0.78, 0.5)
var sash_c := Color(0.95, 0.55, 0.25)
var pants_c := Color(0.55, 0.42, 0.4)
var shoe_c := Color(0.62, 0.42, 0.36)

## สัดส่วนที่ต่างกันระหว่างชาย/หญิง (ตั้งใน build)
var shoulder_x := SHOULDER_X
var hip_x := HIP_X
var arm_r := 0.05  ## รัศมีปลายแขน
var _t := 0.0


## look = {"gender": "m"/"f", "hair": index, "skin": index} แบบเดียวกับ avatar.gd
## colors = {"shirt", "sash", "pants", "shoe", "hair", "skin"} สีที่ใช้จริง
func build(look: Dictionary, colors: Dictionary) -> void:
	for c in get_children():
		c.queue_free()
	shoulders.clear()
	elbows.clear()
	hands.clear()
	hips.clear()
	knees.clear()
	feet.clear()
	female = str(look.get("gender", "m")) == "f"
	skin_c = colors.get("skin", skin_c)
	hair_c = colors.get("hair", hair_c)
	shirt_c = colors.get("shirt", shirt_c)
	sash_c = colors.get("sash", sash_c)
	pants_c = colors.get("pants", pants_c)
	shoe_c = colors.get("shoe", shoe_c)
	iris_c = IRIS[clampi(int(look.get("hair", 0)), 0, IRIS.size() - 1)]
	# ชาย: ไหล่กว้าง แขนหนา ยืนกางขา  หญิง: ไหล่แคบ แขนเรียว ยืนชิดขา
	shoulder_x = 0.215 if not female else 0.178
	hip_x = 0.1 if not female else 0.082
	arm_r = 0.054 if not female else 0.044
	_build_legs()
	_build_torso()
	_build_arms()
	_build_head()


# ---------- ขา ----------

func _build_legs() -> void:
	var pants := K.mat(pants_c, 0.0, 0.85)
	var skin := K.mat(skin_c, 0.0, 0.7)
	var shoe := K.mat(shoe_c, 0.0, 0.75)
	var sole := K.mat(shoe_c.darkened(0.35), 0.0, 0.8)
	var sock := K.mat(Color(1.0, 0.98, 0.96), 0.0, 0.8)
	for i in 2:
		var sgn := -1.0 if i == 0 else 1.0
		var hip := Node3D.new()
		hip.position = Vector3(sgn * hip_x, HIP_Y, 0)
		add_child(hip)
		hips.append(hip)
		var knee := Node3D.new()
		knee.position = Vector3(0, -THIGH, 0)
		hip.add_child(knee)
		knees.append(knee)
		var foot := Node3D.new()
		foot.position = Vector3(0, -SHIN, 0)
		knee.add_child(foot)
		feet.append(foot)
		if female:
			# หญิง: ขาเรียว ต้นขาเป็นผิว (ซ่อนใต้กระโปรง) ถุงเท้ายาวถึงใต้เข่า รองเท้าแมรี่เจนมีสายคาด
			K.capsule(hip, 0.062, THIGH + 0.08, Vector3(0, -THIGH * 0.5, 0), skin)
			K.capsule(knee, 0.052, SHIN + 0.07, Vector3(0, -SHIN * 0.5, 0), skin)
			K.cyl(knee, 0.056, 0.05, SHIN * 0.75, Vector3(0, -SHIN * 0.55, 0), sock, 12)
			K.cyl(knee, 0.06, 0.06, 0.03, Vector3(0, -SHIN * 0.2, 0), K.mat(sash_c), 12)
			K.sphere(foot, 0.072, Vector3(0, -0.01, 0.03), shoe, 14, Vector3(0.9, 0.62, 1.35))
			var sole_f := K.cyl(foot, 0.068, 0.068, 0.022, Vector3(0, -0.052, 0.03), sole, 14)
			sole_f.scale = Vector3(0.9, 1.0, 1.35)
			K.box(foot, Vector3(0.13, 0.018, 0.03), Vector3(0, 0.02, 0.05), K.mat(shoe_c.darkened(0.2)))
			K.sphere(foot, 0.018, Vector3(sgn * 0.06, 0.02, 0.05), K.gold(), 6)
		else:
			# ชาย: กางเกงขาสั้นทรงพอง หน้าแข้งเป็นผิว รองเท้าผ้าใบหัวโต
			K.capsule(hip, 0.086, THIGH + 0.1, Vector3(0, -THIGH * 0.45, 0), pants, Vector3.ZERO, Vector3(1.0, 1.0, 1.05))
			K.cyl(hip, 0.092, 0.098, 0.045, Vector3(0, -THIGH + 0.02, 0), pants, 12)
			K.capsule(knee, 0.062, SHIN + 0.08, Vector3(0, -SHIN * 0.5, 0), skin)
			K.sphere(foot, 0.092, Vector3(0, -0.002, 0.04), shoe, 14, Vector3(1.0, 0.75, 1.45))
			var sole_m := K.cyl(foot, 0.088, 0.088, 0.03, Vector3(0, -0.055, 0.04), sole, 14)
			sole_m.scale = Vector3(1.0, 1.0, 1.45)
			# ข้อรองเท้าหุ้มข้อ + เชือกผูก
			K.cyl(foot, 0.07, 0.074, 0.06, Vector3(0, 0.04, 0), shoe, 12)
			K.cyl(foot, 0.072, 0.072, 0.02, Vector3(0, 0.07, 0), K.mat(sash_c), 12)
			K.box(foot, Vector3(0.06, 0.012, 0.03), Vector3(0, 0.035, 0.105), sock, Vector3(-0.5, 0, 0))


# ---------- ลำตัว ----------

func _build_torso() -> void:
	torso = Node3D.new()
	torso.position.y = LIFT
	add_child(torso)
	var shirt := K.mat(shirt_c, 0.0, 0.8)
	var sash := K.mat(sash_c)
	var pants := K.mat(pants_c, 0.0, 0.85)
	var collar := K.mat(sash_c.lightened(0.25))
	if female:
		# หญิง: ตัวเรียว เอวคอด กระโปรงบานจีบรอบตัว
		K.capsule(torso, 0.15, 0.36, Vector3(0, 0.52, 0), shirt, Vector3.ZERO, Vector3(1.05, 1.0, 0.82), 16)
		K.sphere(torso, 0.13, Vector3(0, 0.44, 0), shirt, 14, Vector3(1.0, 0.7, 0.8))
		var skirt := K.cyl(torso, 0.15, 0.27, 0.2, Vector3(0, 0.33, 0), K.mat(pants_c.lightened(0.15), 0.0, 0.8), 18)
		skirt.scale = Vector3(1.0, 1.0, 0.92)
		# จีบกระโปรง: แถบสีเข้มเป็นริ้วๆ รอบชาย
		for k in 10:
			var a := k * TAU / 10.0
			var pleat := K.box(torso, Vector3(0.025, 0.18, 0.012), Vector3(sin(a) * 0.21, 0.33, cos(a) * 0.195), K.mat(pants_c.darkened(0.05)))
			pleat.rotation = Vector3(-0.5 * cos(a) * 0.55, a, 0.5 * sin(a) * 0.55)
		# ขอบชายกระโปรงลูกไม้สีขาว
		var lace := K.cyl(torso, 0.275, 0.285, 0.03, Vector3(0, 0.235, 0), K.mat(Color(1.0, 0.98, 0.96)), 18)
		lace.scale = Vector3(1.0, 1.0, 0.92)
		# ผ้าคาดเอวผูกโบใหญ่ด้านหลัง
		var belt := K.cyl(torso, 0.162, 0.162, 0.05, Vector3(0, 0.43, 0), sash, 16)
		belt.scale = Vector3(1.0, 1.0, 0.85)
		for x in [-1.0, 1.0]:
			K.sphere(torso, 0.07, Vector3(x * 0.075, 0.45, -0.16), sash, 10, Vector3(1.3, 0.8, 0.45))
			K.box(torso, Vector3(0.05, 0.16, 0.02), Vector3(x * 0.04, 0.35, -0.165), sash, Vector3(0.15, 0, x * 0.2))
		K.sphere(torso, 0.035, Vector3(0, 0.44, -0.165), K.mat(sash_c.lightened(0.2)), 8)
		# ปกเสื้อกลมแบบปกบัว + โบเล็กที่คอ
		for x in [-1.0, 1.0]:
			K.sphere(torso, 0.07, Vector3(x * 0.06, 0.655, 0.09), collar, 10, Vector3(1.2, 0.35, 0.9))
		K.sphere(torso, 0.03, Vector3(0, 0.64, 0.13), sash, 8)
		for x in [-1.0, 1.0]:
			K.sphere(torso, 0.03, Vector3(x * 0.035, 0.64, 0.125), sash, 8, Vector3(1.3, 0.8, 0.5))
	else:
		# ชาย: อกกว้าง ทรงสี่เหลี่ยมมน เสื้อคลุมทับสะโพก กางเกงขาสั้น
		K.sphere(torso, 0.17, Vector3(0, HIP_Y - LIFT + 0.03, 0), pants, 16, Vector3(1.25, 0.75, 0.95))
		K.capsule(torso, 0.18, 0.4, Vector3(0, 0.51, 0), shirt, Vector3.ZERO, Vector3(1.2, 1.0, 0.86), 16)
		var hem := K.cyl(torso, 0.205, 0.225, 0.1, Vector3(0, 0.38, 0), shirt, 16)
		hem.scale = Vector3(1.0, 1.0, 0.86)
		var belt := K.cyl(torso, 0.212, 0.212, 0.055, Vector3(0, 0.42, 0), sash, 16)
		belt.scale = Vector3(1.0, 1.0, 0.88)
		# ปมผ้าคาดเอวผูกข้างตัว ชายผ้าห้อย
		K.sphere(torso, 0.045, Vector3(0.14, 0.42, 0.14), sash, 8)
		K.box(torso, Vector3(0.055, 0.12, 0.02), Vector3(0.16, 0.35, 0.155), sash, Vector3(0.1, 0, 0.25))
		K.box(torso, Vector3(0.05, 0.09, 0.02), Vector3(0.11, 0.355, 0.165), sash, Vector3(0.1, 0, -0.2))
		# คอเสื้อป้ายแบบเสื้อไทย
		K.beam(torso, Vector3(-0.1, 0.67, 0.1), Vector3(0.08, 0.46, 0.165), 0.038, collar)
		K.beam(torso, Vector3(0.1, 0.67, 0.1), Vector3(0.03, 0.6, 0.155), 0.032, collar)
	# คอ
	neck = Node3D.new()
	neck.position = Vector3(0, NECK_Y, 0)
	torso.add_child(neck)
	var nr := 0.06 if not female else 0.048
	K.cyl(neck, nr, nr + 0.01, 0.1, Vector3(0, 0.0, 0), K.mat(skin_c, 0.0, 0.7), 10)


# ---------- แขน ----------

func _build_arms() -> void:
	var shirt := K.mat(shirt_c, 0.0, 0.8)
	var cuff := K.mat(sash_c.lightened(0.15))
	var skin := K.mat(skin_c, 0.0, 0.7)
	for i in 2:
		var sgn := -1.0 if i == 0 else 1.0
		var sh := Node3D.new()
		sh.position = Vector3(sgn * shoulder_x, SHOULDER_Y - (0.015 if female else 0.0), 0)
		torso.add_child(sh)
		shoulders.append(sh)
		# หัวไหล่กลมๆ + แขนเสื้อสั้นทรงพอง
		if female:
			# แขนเสื้อพองแบบตุ๊กตา (puff sleeve) ขอบลูกไม้
			K.sphere(sh, 0.085, Vector3(0, -0.035, 0), shirt, 12, Vector3(1.0, 1.05, 1.0))
			K.cyl(sh, 0.062, 0.066, 0.025, Vector3(0, -0.105, 0), K.mat(Color(1.0, 0.98, 0.96)), 12)
			K.capsule(sh, arm_r + 0.004, UPPER_ARM + 0.05, Vector3(0, -UPPER_ARM * 0.55, 0), K.mat(skin_c, 0.0, 0.7))
		else:
			K.sphere(sh, 0.082, Vector3.ZERO, shirt, 12)
			K.capsule(sh, 0.072, UPPER_ARM + 0.07, Vector3(0, -UPPER_ARM * 0.42, 0), shirt)
			K.cyl(sh, 0.076, 0.08, 0.03, Vector3(0, -UPPER_ARM * 0.8, 0), cuff, 12)
		var el := Node3D.new()
		el.position = Vector3(0, -UPPER_ARM, 0)
		sh.add_child(el)
		elbows.append(el)
		K.capsule(el, arm_r, FOREARM + 0.06, Vector3(0, -FOREARM * 0.5, 0), skin)
		var hand := Node3D.new()
		hand.position = Vector3(0, -FOREARM - 0.035, 0)
		el.add_child(hand)
		hands.append(hand)
		# มือกำหลวมๆ: ฝ่ามือกลม + นิ้วโป้ง
		var hr := 0.066 if not female else 0.054
		K.sphere(hand, hr, Vector3.ZERO, skin, 12, Vector3(0.9, 1.05, 0.95))
		K.sphere(hand, hr * 0.42, Vector3(0.0, 0.01, hr * 0.8), skin, 8, Vector3(1.0, 1.3, 1.0))
		if not female:
			# สายรัดข้อมือผ้า (ชาย)
			K.cyl(el, arm_r + 0.006, arm_r + 0.006, 0.03, Vector3(0, -FOREARM + 0.01, 0), cuff, 10)
	pose_rest()


# ---------- หัว ----------

func _build_head() -> void:
	head = Node3D.new()
	head.position = Vector3(0, HEAD_UP, 0)
	neck.add_child(head)
	var skin := K.mat(skin_c, 0.0, 0.7)
	var hair := K.mat(hair_c, 0.0, 0.6)
	# กะโหลกกลม + แก้มป่องด้านล่าง
	K.sphere(head, HEAD_R, Vector3.ZERO, skin, 24, Vector3(1.0, 0.94, 0.96))
	var cheek := K.sphere(head, 0.3, Vector3(0, -0.12, 0.09), skin, 18, Vector3(1.17, 0.78, 0.92))
	# แก้มป่องไม่ทอดเงาทับหน้าตัวเอง (เคยเกิดเป็นเส้นดำใต้จมูก)
	cheek.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# หู
	for x in [-1.0, 1.0]:
		K.sphere(head, 0.07, Vector3(x * 0.385, -0.03, 0.0), skin, 10, Vector3(0.5, 1.0, 0.8))
		K.sphere(head, 0.035, Vector3(x * 0.4, -0.03, 0.01), K.mat(skin_c.darkened(0.12)), 6, Vector3(0.4, 0.8, 0.6))
	_build_face()
	_build_hair(hair)


func _build_face() -> void:
	var dark := K.mat(Color(0.22, 0.13, 0.15), 0.0, 0.4, 0.0, false)
	var iris := K.mat(iris_c, 0.15, 0.4, 0.0, false)
	var iris_lo := K.mat(iris_c.lightened(0.35), 0.35, 0.4, 0.0, false)
	var shine := K.mat(Color(1, 1, 1), 1.6, 0.3, 0.0, false)
	var blush := K.mat(Color(1.0, 0.62, 0.66, 0.75), 0.25, 0.8, 0.0, false)
	for x in [-1.0, 1.0]:
		var e := Node3D.new()
		e.position = Vector3(x * 0.15, -0.035, 0.345)
		e.rotation = Vector3(0.05, x * 0.36, 0)
		head.add_child(e)
		# ตาโตทรงไข่: ขอบเข้ม > ม่านตา > ม่านตาส่วนล่างสว่าง > รูม่านตา > ประกาย 2 จุด
		# ผู้ชายตาเรียวคมกว่า (เตี้ยลง) ผู้หญิงตาโตกลมกว่า
		var ey := 1.1 if female else 0.86
		e.scale = Vector3(1.0 if female else 1.04, ey, 1.0)
		K.sphere(e, 0.088, Vector3.ZERO, dark, 14, Vector3(0.82, 1.18, 0.32))
		K.sphere(e, 0.07, Vector3(0, -0.012, 0.012), iris, 14, Vector3(0.82, 1.12, 0.3))
		K.sphere(e, 0.045, Vector3(0, -0.04, 0.02), iris_lo, 10, Vector3(1.0, 0.8, 0.3))
		K.sphere(e, 0.032, Vector3(0, 0.0, 0.024), dark, 10, Vector3(0.9, 1.15, 0.3))
		K.sphere(e, 0.03, Vector3(-x * 0.025, 0.04, 0.03), shine, 8)
		K.sphere(e, 0.013, Vector3(x * 0.022, -0.045, 0.03), shine, 6)
		# เส้นขอบตาบน (หนาและงอนที่หางตา)
		K.box(e, Vector3(0.13, 0.02, 0.03), Vector3(0.0, 0.094, 0.0), dark, Vector3(0, 0, -x * 0.1))
		K.box(e, Vector3(0.04, 0.018, 0.025), Vector3(x * 0.072, 0.08, -0.005), dark, Vector3(0, 0, -x * 0.5))
		if female:
			# ขนตางอนสามเส้นที่หางตา + ขนตาล่างเส้นเล็ก
			K.box(e, Vector3(0.045, 0.016, 0.02), Vector3(x * 0.09, 0.105, -0.005), dark, Vector3(0, 0, x * 0.6))
			K.box(e, Vector3(0.04, 0.014, 0.02), Vector3(x * 0.1, 0.075, -0.008), dark, Vector3(0, 0, x * 0.25))
			K.box(e, Vector3(0.03, 0.01, 0.02), Vector3(x * 0.05, -0.092, 0.0), dark, Vector3(0, 0, x * 0.35))
		else:
			# คิ้วหนาเข้ม ปลายคิ้วยกขึ้นนิดๆ ดูมั่นใจ
			var brow := K.mat(hair_c.darkened(0.35), 0.0, 0.6, 0.0, false)
			K.box(head, Vector3(0.12, 0.03, 0.03), Vector3(x * 0.15, 0.1, 0.36), brow, Vector3(0, x * 0.36, -x * 0.18))
		# แก้มแดง (ผู้หญิงแดงชัดกว่า)
		var bl := blush if not female else K.mat(Color(1.0, 0.5, 0.6, 0.85), 0.35, 0.8, 0.0, false)
		var bs := 0.06 if not female else 0.07
		K.sphere(head, bs, Vector3(x * 0.245, -0.15, 0.305), bl, 10, Vector3(1.35, 0.65, 0.35))
	# จมูกจุดเล็ก + ปากยิ้มเปิด (สีชมพูเข้ม มีลิ้นด้านใน)
	var nose := K.sphere(head, 0.016, Vector3(0, -0.11, 0.395), K.mat(skin_c.darkened(0.15), 0.0, 0.7, 0.0, false), 6)
	# ไม่ให้จมูกทอดเงาเป็นเส้นยาวลงมาบนหน้า
	nose.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mouth := Node3D.new()
	mouth.position = Vector3(0, -0.19, 0.372)
	mouth.rotation.x = -0.3
	head.add_child(mouth)
	# ปากยิ้มเป็นเส้นโค้งรูปตัว U เล็กๆ
	var lip := K.mat(Color(0.5, 0.2, 0.24), 0.0, 0.6, 0.0, false)
	if female:
		# ปากเล็กสีชมพู ยิ้มอ่อนๆ
		var pink := K.mat(Color(0.93, 0.42, 0.5), 0.1, 0.5, 0.0, false)
		K.sphere(mouth, 0.026, Vector3(0, -0.004, 0.0), pink, 10, Vector3(1.2, 0.6, 0.4))
		var pts := [Vector3(-0.03, 0.008, 0.006), Vector3(-0.012, -0.004, 0.01), Vector3(0.012, -0.004, 0.01), Vector3(0.03, 0.008, 0.006)]
		for i in pts.size() - 1:
			K.beam(mouth, pts[i], pts[i + 1], 0.012, lip)
	else:
		# ยิ้มกว้างมั่นใจ ยกมุมปากข้างหนึ่งขึ้น
		var pts := [Vector3(-0.06, 0.016, 0), Vector3(-0.03, -0.01, 0.004), Vector3(0.0, -0.016, 0.006), Vector3(0.03, -0.01, 0.004), Vector3(0.062, 0.024, 0)]
		for i in pts.size() - 1:
			K.beam(mouth, pts[i], pts[i + 1], 0.018, lip)


## ผม: หนังศีรษะเป็นฐาน แล้วคลุมด้วยปอยผมเรียวที่ไหลจากขวัญกลางหัวลงมาตามผิวหัว (แบบผมอนิเมะ)
## ปอยแต่ละเส้นสร้างด้วย _lock วางเป็นวงรอบขวัญ ให้เส้นขอบการ์ตูนแบ่งปอยชัดๆ
const CAP_C := Vector3(0, 0.06, -0.045)
const CAP_R := 0.42
## ทิศขวัญ (จุดที่ผมแตกออก) อยู่บนหัวค่อนไปด้านหลัง
const CROWN := Vector3(0, 0.958, -0.287)


func _build_hair(hair: Material) -> void:
	# หนังศีรษะ (ปอยผมจะคลุมทับ)
	K.sphere(head, CAP_R, CAP_C, hair, 22, Vector3(1.02, 0.97, 1.02))
	if female:
		_hair_female(hair)
	else:
		_hair_male(hair)
	# ผมชี้บนหัว (อาโฮเกะ)
	var ah := Node3D.new()
	ah.position = CAP_C + CROWN * (CAP_R - 0.01) + Vector3(0, 0, 0.08)
	ah.rotation = Vector3(PI - 0.3, 0, 0.25)
	head.add_child(ah)
	_lock(ah, hair, 0.22, 0.035, 22.0, -2.0, 0.5)


## ผู้ชาย: ปอยหนาสั้น ปลายดีดออกเป็นหนามแหลม หน้าม้าจบเหนือคิ้ว จอนสั้นแค่หู
func _hair_male(hair: Material) -> void:
	# วงใน: ปอยหลักไหลจากขวัญลงทุกทิศ ด้านหน้าเป็นหน้าม้า ด้านข้างถึงหู ด้านหลังถึงท้ายทอย
	_ring(hair, 0.3, 13, func(phi): return 0.52 if absf(phi) < 0.5 else (0.46 if absf(phi) < 1.9 else 0.5), 0.12, 1.1, -0.3, 0.42, 0.0)
	# วงนอกด้านหลังและข้าง: ปอยสั้นปลายดีดออก ทำทรงผมหนาฟู
	_ring(hair, 1.0, 9, func(phi): return 0.32, 0.11, 1.0, -1.2, 0.45, 1.5)


## ผู้หญิง: หน้าม้าบางยาวถึงเหนือตา ปอยข้างแก้มยาวถึงอก ผมด้านหลังยาวถึงกลางหลัง + โบว์
func _hair_female(hair: Material) -> void:
	# วงใน: หน้าม้าและผมคลุมหัว เรียบลู่ตามหัว ปลายงอเข้า
	_ring(hair, 0.3, 14, func(phi): return 0.6 if absf(phi) < 0.6 else 0.62, 0.11, 0.95, 0.75, 0.38, 0.0, 0.01)
	# ผมยาวด้านหลัง: ปอยเรียวห้อยจากท้ายทอยลงถึงกลางหลัง ปลายงอนออกนิดๆ
	K.sphere(head, 0.34, Vector3(0, -0.15, -0.2), hair, 18, Vector3(1.12, 1.2, 0.72))
	for i in 7:
		var a := (i - 3) * 0.3
		var n := Node3D.new()
		n.position = Vector3(sin(a) * 0.38, 0.0, -cos(a) * 0.36 - 0.05)
		n.rotation = Vector3(0.12, a, -a * 0.12)
		head.add_child(n)
		_lock(n, hair, 0.82 - absf(i - 3) * 0.05, 0.13, 0.4, -1.6, 0.45)
	# ปอยข้างแก้ม: สองปอยต่อข้าง ห้อยลงมาถึงอก ปลายม้วนเข้าหาหน้า
	for x in [-1.0, 1.0]:
		for j in 2:
			var n := Node3D.new()
			n.position = Vector3(x * (0.37 + j * 0.03), 0.1, 0.16 - j * 0.12)
			n.rotation = Vector3(-0.05, 0, x * (0.08 + j * 0.08))
			head.add_child(n)
			_lock(n, hair, 0.55, 0.085, 0.0, -2.5, 0.5, -x * 0.3)
	# โบว์ใหญ่สีเดียวกับผ้าคาด ติดผมด้านซ้ายบน + กิ๊บสีทอง
	var bow_m := K.mat(sash_c, 0.0, 0.6)
	var bw := Node3D.new()
	bw.position = Vector3(-0.34, 0.36, 0.1)
	bw.rotation = Vector3(0.2, -0.6, 0.5)
	head.add_child(bw)
	for x in [-1.0, 1.0]:
		K.sphere(bw, 0.075, Vector3(x * 0.075, 0, 0), bow_m, 10, Vector3(1.2, 0.85, 0.5))
		K.cyl(bw, 0.025, 0.0, 0.1, Vector3(x * 0.03, -0.07, -0.01), bow_m, 6, Vector3(0, 0, x * 0.4))
	K.sphere(bw, 0.035, Vector3(0, 0, 0.02), K.mat(sash_c.darkened(0.15)), 8)
	K.sphere(head, 0.03, Vector3(0.27, 0.25, 0.32), K.gold(), 6, Vector3(1.0, 1.0, 0.5))


## วงปอยผมรอบขวัญ: theta = มุมห่างจากขวัญ (เรเดียน), count = จำนวนปอย
## length_of(phi) = ความยาวปอยตามทิศ (phi = 0 คือด้านหน้า, ±PI คือด้านหลัง)
## k0..k1 = ความโค้งตามหัวจากโคนถึงปลาย (1 = แนบหัวพอดี, ติดลบ = ดีดออก)
## min_phi = ข้ามทิศที่ |phi| น้อยกว่านี้ (เว้นด้านหน้า), lift = ยกโคนให้ลอยจากหัว
func _ring(hair: Material, theta: float, count: int, length_of: Callable, width: float, k0: float, k1: float, flat: float, min_phi: float, lift := 0.0) -> void:
	var u := (Vector3(0, 0, 1) - CROWN * CROWN.z).normalized()
	var v := CROWN.cross(u)
	for i in count:
		var phi := -PI + (i + 0.5) * TAU / count
		if absf(phi) < min_phi:
			continue
		var n := (CROWN * cos(theta) + (u * cos(phi) + v * sin(phi)) * sin(theta)).normalized()
		var t := (n * CROWN.dot(n) - CROWN).normalized()
		if theta < 0.1:
			t = (u * cos(phi) + v * sin(phi))
		var node := Node3D.new()
		node.position = CAP_C + n * (CAP_R + lift)
		var y := -t
		node.basis = Basis(y.cross(n), y, n)
		head.add_child(node)
		_lock(node, hair, length_of.call(phi), width, k0 / CAP_R, k1 / CAP_R, flat)


static var _lock_meshes := {}


## ปอยผมเรียวโค้งเป็นชิ้นเดียว (ผิวเรียบ ไม่เป็นข้อๆ): ชี้ไปตามแกน -y ของ base
## k0..k1 = ความโค้งรอบแกน x จากโคนถึงปลาย (เรเดียนต่อเมตร, บวก = โค้งเข้าหาหัว/แกน -z)
## sweep = มุมปัดไปด้านข้างรวมทั้งเส้น, flat = ความแบน (หนา/กว้าง)
func _lock(base: Node3D, hair: Material, length: float, width: float, k0: float, k1: float, flat: float, sweep := 0.0) -> MeshInstance3D:
	var key := "%.3f|%.3f|%.2f|%.2f|%.2f|%.2f" % [length, width, k0, k1, flat, sweep]
	if not _lock_meshes.has(key):
		_lock_meshes[key] = _make_lock_mesh(length, width, k0, k1, flat, sweep)
	return K.add(base, _lock_meshes[key], Vector3.ZERO, hair)


static func _make_lock_mesh(length: float, width: float, k0: float, k1: float, flat: float, sweep: float) -> ArrayMesh:
	const RINGS := 12
	const SIDES := 10
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# เดินตามแนวกระดูกปอยผม หมุนกรอบทีละช่วงตามความโค้ง
	var frame := Basis.IDENTITY
	var p := Vector3.ZERO
	var ds := length / RINGS
	var rings := []
	for i in RINGS + 1:
		var t := float(i) / RINGS
		# ความกว้าง: โคนมน กว้างสุดช่วงต้น แล้วเรียวแหลมที่ปลาย
		var w := width * (0.75 + 0.25 * sin(minf(t * 5.0, 1.0) * PI / 2.0)) * pow(1.0 - t, 0.85)
		if i == 0:
			w = width * 0.55
		var ring := []
		for j in SIDES:
			var a := TAU * j / SIDES
			ring.append(p + frame.x * cos(a) * w + frame.z * sin(a) * w * flat)
		rings.append(ring)
		var k := lerpf(k0, k1, t)
		frame = frame.rotated(frame.x, k * ds).rotated(frame.z, sweep / RINGS)
		p += -frame.y * ds
	# ปิดโคนด้วยจุดยอดยื่นขึ้นเล็กน้อย
	var root := Vector3(0, width * 0.35, 0)
	for j in SIDES:
		var j2 := (j + 1) % SIDES
		st.add_vertex(root)
		st.add_vertex(rings[0][j])
		st.add_vertex(rings[0][j2])
	for i in RINGS:
		for j in SIDES:
			var j2 := (j + 1) % SIDES
			var a: Vector3 = rings[i][j]
			var b: Vector3 = rings[i][j2]
			var c: Vector3 = rings[i + 1][j]
			var d: Vector3 = rings[i + 1][j2]
			# Godot ใช้ด้านหน้าแบบตามเข็มนาฬิกา
			st.add_vertex(a)
			st.add_vertex(c)
			st.add_vertex(b)
			st.add_vertex(b)
			st.add_vertex(c)
			st.add_vertex(d)
	st.generate_normals()
	return st.commit()


# ---------- ท่าทาง ----------

## ท่ายืนปกติ: แขนกางออกนิดๆ ศอกงอไปข้างหน้า
func pose_rest() -> void:
	for i in shoulders.size():
		var sgn := -1.0 if i == 0 else 1.0
		# ผู้ชายกางแขนกว้างกว่า ผู้หญิงแขนแนบตัว
		shoulders[i].rotation = Vector3(0.08, 0, sgn * (0.13 if female else 0.26))
		elbows[i].rotation = Vector3(-0.35 if not female else -0.5, 0, -sgn * 0.08)
	for i in hips.size():
		var sgn := -1.0 if i == 0 else 1.0
		# ผู้ชายยืนขากาง ผู้หญิงยืนชิดปลายเท้าเข้าหากันนิดๆ
		hips[i].rotation = Vector3(0, 0, sgn * (0.0 if female else 0.06))
		knees[i].rotation = Vector3.ZERO
		feet[i].rotation = Vector3(0, (sgn * 0.25) if female else (-sgn * 0.1), 0)


## ท่ารายเฟรม: phase = เฟสการก้าวเท้า (เรเดียน), moving = กำลังเดิน, breathe = เวลาสะสมไว้ทำท่าหายใจ
func animate_pose(phase: float, moving: bool, breathe: float) -> void:
	if torso == null:
		return
	pose_rest()
	if moving:
		var s := sin(phase)
		for i in 2:
			var sgn := -1.0 if i == 0 else 1.0
			# ขาสลับก้าว เข่างอตอนยกขา
			hips[i].rotation.x = s * sgn * 0.6
			knees[i].rotation.x = maxf(0.0, -s * sgn) * 0.9
			feet[i].rotation.x = -hips[i].rotation.x * 0.5 - knees[i].rotation.x * 0.3
			# แขนแกว่งสวนขา
			shoulders[i].rotation.x = -s * sgn * 0.55 + 0.08
		torso.rotation.y = s * 0.08
		torso.position.y = LIFT + absf(cos(phase)) * 0.025
		head.rotation.z = -s * 0.04
	else:
		torso.rotation.y = 0.0
		torso.position.y = LIFT + sin(breathe * 2.2) * 0.006
		torso.scale = Vector3(1.0 + sin(breathe * 2.2) * 0.008, 1.0, 1.0)
		head.rotation.z = sin(breathe * 1.1) * 0.03
		for i in 2:
			var sgn := -1.0 if i == 0 else 1.0
			shoulders[i].rotation.z = sgn * ((0.13 if female else 0.26) + sin(breathe * 2.2) * 0.02)
