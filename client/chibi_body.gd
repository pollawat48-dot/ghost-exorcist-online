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
	for i in 2:
		var sgn := -1.0 if i == 0 else 1.0
		var hip := Node3D.new()
		hip.position = Vector3(sgn * HIP_X, HIP_Y, 0)
		add_child(hip)
		hips.append(hip)
		# ต้นขา: กางเกงขาสั้นทรงพอง
		K.capsule(hip, 0.082, THIGH + 0.1, Vector3(0, -THIGH * 0.45, 0), pants, Vector3.ZERO, Vector3(1.0, 1.0, 1.05))
		# ปลายขากางเกงบานนิดๆ
		K.cyl(hip, 0.088, 0.094, 0.045, Vector3(0, -THIGH + 0.02, 0), pants, 12)
		var knee := Node3D.new()
		knee.position = Vector3(0, -THIGH, 0)
		hip.add_child(knee)
		knees.append(knee)
		# หน้าแข้ง (ผิว) เรียวลงข้อเท้า
		K.capsule(knee, 0.058, SHIN + 0.08, Vector3(0, -SHIN * 0.5, 0), skin)
		var foot := Node3D.new()
		foot.position = Vector3(0, -SHIN, 0)
		knee.add_child(foot)
		feet.append(foot)
		# รองเท้าหัวมน ยื่นไปข้างหน้า + พื้นรองเท้า
		K.sphere(foot, 0.085, Vector3(0, -0.005, 0.035), shoe, 14, Vector3(0.95, 0.72, 1.4))
		var sole_mi := K.cyl(foot, 0.08, 0.08, 0.025, Vector3(0, -0.055, 0.035), sole, 14)
		sole_mi.scale = Vector3(0.95, 1.0, 1.4)
		# สายรัดข้อเท้า
		K.cyl(foot, 0.062, 0.062, 0.03, Vector3(0, 0.045, 0), K.mat(sash_c), 12)


# ---------- ลำตัว ----------

func _build_torso() -> void:
	torso = Node3D.new()
	torso.position.y = LIFT
	add_child(torso)
	var shirt := K.mat(shirt_c, 0.0, 0.8)
	var sash := K.mat(sash_c)
	var pants := K.mat(pants_c, 0.0, 0.85)
	# สะโพก (กางเกง)
	K.sphere(torso, 0.17, Vector3(0, HIP_Y - LIFT + 0.03, 0), pants, 16, Vector3(1.2, 0.75, 0.95))
	# ลำตัว: อกป้อมแบบเด็ก เอวเล็กกว่าอกนิดหน่อย
	K.capsule(torso, 0.17, 0.4, Vector3(0, 0.5, 0), shirt, Vector3.ZERO, Vector3(1.12, 1.0, 0.86), 16)
	# ชายเสื้อบานคลุมสะโพก
	var hem := K.cyl(torso, 0.19, 0.215, 0.1, Vector3(0, 0.38, 0), shirt, 16)
	hem.scale = Vector3(1.0, 1.0, 0.86)
	# ผ้าคาดเอว + ปมผูกด้านข้าง
	var belt := K.cyl(torso, 0.2, 0.2, 0.05, Vector3(0, 0.42, 0), sash, 16)
	belt.scale = Vector3(1.0, 1.0, 0.88)
	K.sphere(torso, 0.04, Vector3(0.13, 0.42, 0.14), sash, 8)
	K.box(torso, Vector3(0.05, 0.1, 0.02), Vector3(0.15, 0.36, 0.15), sash, Vector3(0.1, 0, 0.25))
	K.box(torso, Vector3(0.05, 0.08, 0.02), Vector3(0.1, 0.36, 0.16), sash, Vector3(0.1, 0, -0.2))
	# คอเสื้อป้ายแบบเสื้อไทย (ผ้าคาดเฉียงจากไหล่ซ้ายลงมา)
	var collar := K.mat(sash_c.lightened(0.25))
	K.beam(torso, Vector3(-0.1, 0.66, 0.1), Vector3(0.08, 0.46, 0.155), 0.035, collar)
	K.beam(torso, Vector3(0.1, 0.66, 0.1), Vector3(0.03, 0.6, 0.145), 0.03, collar)
	# คอ
	neck = Node3D.new()
	neck.position = Vector3(0, NECK_Y, 0)
	torso.add_child(neck)
	K.cyl(neck, 0.055, 0.065, 0.1, Vector3(0, 0.0, 0), K.mat(skin_c, 0.0, 0.7), 10)


# ---------- แขน ----------

func _build_arms() -> void:
	var shirt := K.mat(shirt_c, 0.0, 0.8)
	var cuff := K.mat(sash_c.lightened(0.15))
	var skin := K.mat(skin_c, 0.0, 0.7)
	for i in 2:
		var sgn := -1.0 if i == 0 else 1.0
		var sh := Node3D.new()
		sh.position = Vector3(sgn * SHOULDER_X, SHOULDER_Y, 0)
		torso.add_child(sh)
		shoulders.append(sh)
		# หัวไหล่กลมๆ + แขนเสื้อสั้นทรงพอง
		K.sphere(sh, 0.075, Vector3.ZERO, shirt, 12)
		K.capsule(sh, 0.066, UPPER_ARM + 0.07, Vector3(0, -UPPER_ARM * 0.42, 0), shirt)
		K.cyl(sh, 0.07, 0.074, 0.03, Vector3(0, -UPPER_ARM * 0.8, 0), cuff, 12)
		var el := Node3D.new()
		el.position = Vector3(0, -UPPER_ARM, 0)
		sh.add_child(el)
		elbows.append(el)
		K.capsule(el, 0.05, FOREARM + 0.06, Vector3(0, -FOREARM * 0.5, 0), skin)
		var hand := Node3D.new()
		hand.position = Vector3(0, -FOREARM - 0.035, 0)
		el.add_child(hand)
		hands.append(hand)
		# มือกำหลวมๆ: ฝ่ามือกลม + นิ้วโป้ง
		K.sphere(hand, 0.062, Vector3.ZERO, skin, 12, Vector3(0.9, 1.05, 0.95))
		K.sphere(hand, 0.026, Vector3(-sgn * 0.0, 0.01, 0.05), skin, 8, Vector3(1.0, 1.3, 1.0))
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
	K.sphere(head, 0.3, Vector3(0, -0.12, 0.09), skin, 18, Vector3(1.17, 0.78, 0.92))
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
			# ขนตางอนสองเส้นที่หางตา
			K.box(e, Vector3(0.04, 0.016, 0.02), Vector3(x * 0.088, 0.1, -0.005), dark, Vector3(0, 0, x * 0.6))
		# แก้มแดง
		K.sphere(head, 0.06, Vector3(x * 0.245, -0.15, 0.305), blush, 10, Vector3(1.35, 0.65, 0.35))
	# จมูกจุดเล็ก + ปากยิ้มเปิด (สีชมพูเข้ม มีลิ้นด้านใน)
	K.sphere(head, 0.016, Vector3(0, -0.11, 0.395), K.mat(skin_c.darkened(0.15), 0.0, 0.7, 0.0, false), 6)
	var mouth := Node3D.new()
	mouth.position = Vector3(0, -0.19, 0.372)
	mouth.rotation.x = -0.3
	head.add_child(mouth)
	# ปากยิ้มเป็นเส้นโค้งรูปตัว U เล็กๆ
	var lip := K.mat(Color(0.5, 0.2, 0.24), 0.0, 0.6, 0.0, false)
	var pts := [Vector3(-0.042, 0.012, 0), Vector3(-0.018, -0.008, 0.004), Vector3(0.018, -0.008, 0.004), Vector3(0.042, 0.012, 0)]
	for i in pts.size() - 1:
		K.beam(mouth, pts[i], pts[i + 1], 0.016, lip)


## ผม: ฐานผมครอบหัว + หน้าม้าเป็นปอยๆ + ปอยข้างแก้ม + ผมชี้บนหัว
func _build_hair(hair: Material) -> void:
	# ฐานผมด้านบนและด้านหลัง (เปิดหน้าผาก)
	K.sphere(head, 0.425, Vector3(0, 0.06, -0.045), hair, 22, Vector3(1.03, 0.97, 1.02))
	# หน้าม้า: ปอยแหลมแนบหน้าผาก ปลายชี้ลงมาถึงคิ้ว
	var bangs := [[-0.3, 0.17, 0.35], [-0.16, 0.2, 0.12], [0.0, 0.21, -0.05], [0.15, 0.2, -0.18], [0.29, 0.17, -0.38]]
	for b in bangs:
		var p := Node3D.new()
		var a: float = b[0] * 1.3
		p.position = Vector3(sin(a) * 0.37, b[1], cos(a) * 0.37 - 0.03)
		p.rotation = Vector3(-0.22, a, b[2])
		head.add_child(p)
		K.sphere(p, 0.085, Vector3(0, 0.0, 0.0), hair, 12, Vector3(1.0, 1.3, 0.42))
		var tip := K.cyl(p, 0.05, 0.0, 0.1, Vector3(0, -0.13, 0.005), hair, 8)
		tip.scale = Vector3(1.0, 1.0, 0.45)
	# ปอยข้างแก้มทั้งสองข้าง ยาวลงมาถึงขากรรไกร
	for x in [-1.0, 1.0]:
		var s := Node3D.new()
		s.position = Vector3(x * 0.36, 0.0, 0.12)
		s.rotation = Vector3(0.15, 0, x * 0.12)
		head.add_child(s)
		K.sphere(s, 0.09, Vector3(0, 0.0, 0), hair, 10, Vector3(0.75, 1.6, 0.8))
		K.cyl(s, 0.06, 0.0, 0.14, Vector3(0, -0.19, 0.01), hair, 8)
		if female:
			# ผู้หญิง: ปอยข้างยาวลงมาถึงไหล่
			K.capsule(s, 0.05, 0.3, Vector3(0, -0.29, -0.03), hair, Vector3(0, 0, -x * 0.08), Vector3(0.9, 1.0, 0.5))
			var end := K.cyl(s, 0.045, 0.0, 0.1, Vector3(-x * 0.012, -0.48, -0.03), hair, 8)
			end.scale = Vector3(1.0, 1.0, 0.5)
	# เส้นผมนูนบนกลางหัว ไล่จากหน้าผากไปท้ายทอย ให้ผมมีลอน ไม่เรียบเป็นลูกบอล
	for a in [-0.5, -0.17, 0.17, 0.5]:
		var st := Node3D.new()
		st.rotation = Vector3(0, a, 0)
		head.add_child(st)
		K.capsule(st, 0.06, 0.42, Vector3(0, 0.36, -0.06), hair, Vector3(PI / 2.0 + 0.35, 0, 0), Vector3(1.0, 1.0, 0.6))
	# ผมชี้บนหัว (อาโฮเกะ)
	var ah := Node3D.new()
	ah.position = Vector3(0.02, 0.4, 0.02)
	ah.rotation = Vector3(0.5, 0, -0.25)
	head.add_child(ah)
	K.cyl(ah, 0.0, 0.035, 0.16, Vector3(0, 0.08, 0), hair, 6)
	K.cyl(ah, 0.0, 0.025, 0.1, Vector3(0.03, 0.15, 0.04), hair, 6, Vector3(1.2, 0, -0.4))
	if female:
		# ผมยาวด้านหลังถึงกลางหลัง + ปลายผมงอนออก
		K.sphere(head, 0.36, Vector3(0, -0.18, -0.2), hair, 18, Vector3(1.15, 1.25, 0.75))
		K.sphere(head, 0.25, Vector3(0, -0.5, -0.24), hair, 14, Vector3(1.25, 1.0, 0.6))
		for x in [-1.0, 1.0]:
			K.cyl(head, 0.08, 0.0, 0.16, Vector3(x * 0.2, -0.68, -0.25), hair, 8, Vector3(0, 0, x * 0.5))
	else:
		# ผมท้ายทอยสั้นเป็นปอยๆ
		for x in [-0.16, 0.0, 0.16]:
			K.cyl(head, 0.07, 0.0, 0.14, Vector3(x, -0.3, -0.3), hair, 8, Vector3(-0.5, 0, x * 2.0))


# ---------- ท่าทาง ----------

## ท่ายืนปกติ: แขนกางออกนิดๆ ศอกงอไปข้างหน้า
func pose_rest() -> void:
	for i in shoulders.size():
		var sgn := -1.0 if i == 0 else 1.0
		shoulders[i].rotation = Vector3(0.08, 0, sgn * 0.2)
		elbows[i].rotation = Vector3(-0.35, 0, -sgn * 0.08)
	for i in hips.size():
		hips[i].rotation = Vector3.ZERO
		knees[i].rotation = Vector3.ZERO
		feet[i].rotation = Vector3.ZERO


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
			shoulders[i].rotation.z = sgn * (0.2 + sin(breathe * 2.2) * 0.02)
