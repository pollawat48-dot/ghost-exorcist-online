extends Node3D
## NPC ตัวจิบิยืนประจำที่: ร้านค้า หรือคนให้เควส
## เหนือหัวมีป้ายบอกหน้าที่ และเครื่องหมาย ! (มีเควสให้รับ) / ? (มีเควสให้ส่ง)

const K = preload("res://maps/props/mesh_kit.gd")
const M = preload("res://maps/props/model_lib.gd")

const TALK_RADIUS := 70.0

var data := {}
var pos := Vector2.ZERO
var t := 0.0
var body: Node3D
var marker: Label3D
var marker_state := ""


func setup(entry: Dictionary) -> void:
	data = entry
	pos = entry["pos"]


func npc_id() -> String:
	return data["id"]


func role() -> String:
	return data["role"]


func _ready() -> void:
	position = K.to3d(pos)
	body = Node3D.new()
	add_child(body)
	var look: Dictionary = data["look"]
	var robe := K.mat(look["robe"], 0.0, 0.8)
	var sash := K.mat(look["sash"])
	var skin := K.mat(Color(1.0, 0.86, 0.74), 0.0, 0.7)
	var hair := K.mat(Color(0.86, 0.86, 0.9) if look["hat"] in ["bun", "bald", "topknot"] else Color(0.36, 0.25, 0.24), 0.0, 0.6)
	var eye := K.mat(Color(0.2, 0.13, 0.16), 0.0, 0.3, 0.0, false)
	var blush := K.mat(Color(1.0, 0.6, 0.65), 0.3, 0.8, 0.0, false)
	# ตัว: ชุดยาวทรงระฆัง (คนแก่ใจดี ตัวเตี้ยกว่าผู้เล่นนิดหน่อย)
	for x in [-0.1, 0.1]:
		K.sphere(body, 0.09, Vector3(x, 0.07, 0.03), K.mat(Color(0.62, 0.42, 0.36)), 8, Vector3(1, 0.7, 1.3))
	K.cyl(body, 0.18, 0.34, 0.6, Vector3(0, 0.38, 0), robe, 14)
	K.beam(body, Vector3(-0.2, 0.64, 0.14), Vector3(0.22, 0.3, 0.18), 0.07, sash)
	for x in [-0.28, 0.28]:
		K.sphere(body, 0.08, Vector3(x, 0.45, 0.06), skin, 8)
	var head := Node3D.new()
	head.position = Vector3(0, 1.02, 0)
	head.rotation.x = -0.2
	body.add_child(head)
	K.sphere(head, 0.38, Vector3.ZERO, skin, 18)
	match look["hat"]:
		"bald":
			# หลวงตาหัวโล้น คิ้วขาว
			for x in [-0.15, 0.15]:
				K.box(head, Vector3(0.12, 0.03, 0.03), Vector3(x, 0.1, 0.35), K.mat(Color(0.95, 0.95, 0.95)))
		"bun":
			# ยายผมมวยสีเทา ปักปิ่น
			K.sphere(head, 0.39, Vector3(0, 0.14, -0.1), hair, 18, Vector3(1.0, 0.78, 1.0))
			K.sphere(head, 0.15, Vector3(0, 0.36, -0.28), hair, 10)
			K.cyl(head, 0.015, 0.015, 0.4, Vector3(0, 0.38, -0.28), K.gold(), 4, Vector3(0, 0, PI / 2.5))
		"topknot":
			# ครูใหญ่: มวยผมจุก ปักปิ่นทอง หนวดขาว
			K.sphere(head, 0.39, Vector3(0, 0.14, -0.1), hair, 18, Vector3(1.0, 0.78, 1.0))
			K.sphere(head, 0.14, Vector3(0, 0.48, -0.1), hair, 10)
			K.cyl(head, 0.015, 0.015, 0.42, Vector3(0, 0.52, -0.1), K.gold(), 4, Vector3(0, 0, PI / 2.0))
			K.sphere(head, 0.1, Vector3(0, -0.28, 0.28), K.mat(Color(0.96, 0.96, 0.96)), 8, Vector3(1.0, 1.4, 0.6))
		"headband":
			# ผ้าโพกหัวแบบช่างตีเหล็ก/หมอผีดอย
			K.sphere(head, 0.39, Vector3(0, 0.14, -0.1), hair, 18, Vector3(1.0, 0.78, 1.0))
			var band := TorusMesh.new()
			band.inner_radius = 0.36
			band.outer_radius = 0.43
			K.add(head, band, Vector3(0, 0.16, -0.03), sash, Vector3(-0.15, 0, 0))
		"farmer":
			# งอบสาน
			K.sphere(head, 0.39, Vector3(0, 0.14, -0.1), hair, 18, Vector3(1.0, 0.78, 1.0))
			K.cyl(head, 0.03, 0.62, 0.3, Vector3(0, 0.42, -0.04), K.mat(Color(0.92, 0.8, 0.55)), 16)
		"chinese":
			# หมวกกะโหลกจีนทรงกลม (กวาปี้เม่า) ขอบสีผ้าคาดเอว จุกแดงบนยอด เปียยาวด้านหลัง
			K.sphere(head, 0.39, Vector3(0, 0.14, -0.1), hair, 18, Vector3(1.0, 0.78, 1.0))
			K.sphere(head, 0.4, Vector3(0, 0.2, -0.06), K.mat(Color(0.22, 0.18, 0.26)), 18, Vector3(1.0, 0.62, 1.0))
			var rim := TorusMesh.new()
			rim.inner_radius = 0.36
			rim.outer_radius = 0.42
			K.add(head, rim, Vector3(0, 0.2, -0.05), sash, Vector3(-0.12, 0, 0))
			K.sphere(head, 0.07, Vector3(0, 0.46, -0.08), K.mat(Color(0.95, 0.3, 0.32)), 8)
			K.beam(head, Vector3(0, 0.0, -0.36), Vector3(0, -0.6, -0.42), 0.07, hair)
		_:
			K.sphere(head, 0.39, Vector3(0, 0.14, -0.1), hair, 18, Vector3(1.0, 0.78, 1.0))
	for x in [-0.14, 0.14]:
		# ตายิ้ม (โค้งปิด) ให้ดูใจดี
		K.box(head, Vector3(0.12, 0.035, 0.03), Vector3(x, -0.01, 0.35), eye)
		K.sphere(head, 0.06, Vector3(x * 1.55, -0.11, 0.31), blush, 8, Vector3(1.2, 0.6, 0.4))
	K.sphere(head, 0.03, Vector3(0, -0.15, 0.36), K.mat(Color(0.85, 0.4, 0.42), 0.0, 0.8, 0.0, false), 6, Vector3(1.4, 0.7, 0.6))
	if role() == "smith":
		# เตาหลอมกับทั่งตีเหล็กข้างตัว
		K.cyl(self, 0.45, 0.55, 0.9, Vector3(1.0, 0.45, 0.0), K.mat(Color(0.7, 0.55, 0.5)), 10)
		K.cyl(self, 0.32, 0.32, 0.05, Vector3(1.0, 0.92, 0.0), K.mat(Color(1.0, 0.55, 0.25), 2.5, 0.4, 0.0, false), 10)
		K.box(self, Vector3(0.5, 0.3, 0.25), Vector3(-0.8, 0.45, 0.2), K.mat(Color(0.45, 0.45, 0.52), 0.0, 0.4, 0.5))
		K.box(self, Vector3(0.2, 0.3, 0.2), Vector3(-0.8, 0.15, 0.2), K.mat(Color(0.55, 0.42, 0.36)))
		var fire := OmniLight3D.new()
		fire.position = Vector3(1.0, 1.3, 0.2)
		fire.light_color = Color(1.0, 0.6, 0.3)
		fire.omni_range = 3.5
		fire.light_energy = 1.2
		add_child(fire)
	elif role() == "warp":
		# วงแหวนลอยรอบตัวร่างทรง
		var ring := TorusMesh.new()
		ring.inner_radius = 0.75
		ring.outer_radius = 0.82
		K.add(self, ring, Vector3(0, 0.08, 0), K.mat(Color(0.6, 0.85, 1.0), 2.5, 0.3, 0.0, false))
	if role() == "shop" and data.get("sign", "") == "ร้านอาวุธ":
		# ชั้นวางอาวุธ: ดาบ ธนู คัมภีร์
		K.box(self, Vector3(1.1, 0.08, 0.5), Vector3(0.95, 0.5, 0.1), K.mat(Color(0.75, 0.55, 0.42)))
		for x in [0.5, 1.4]:
			K.box(self, Vector3(0.08, 0.5, 0.4), Vector3(x, 0.25, 0.1), K.mat(Color(0.62, 0.45, 0.36)))
		K.box(self, Vector3(0.06, 0.9, 0.03), Vector3(0.7, 1.0, 0.1), K.mat(Color(0.88, 0.92, 1.0), 0.6, 0.3), Vector3(0, 0, 0.15))
		K.box(self, Vector3(0.25, 0.05, 0.08), Vector3(0.75, 0.6, 0.1), K.gold())
		K.box(self, Vector3(0.3, 0.06, 0.36), Vector3(1.15, 0.57, 0.1), K.mat(Color(0.75, 0.3, 0.35)))
		K.beam(self, Vector3(1.4, 0.55, 0.0), Vector3(1.35, 1.35, 0.0), 0.04, K.mat(Color(0.75, 0.52, 0.36)))
	elif role() == "shop":
		# แผงยาเล็กๆ ข้างตัว มีขวดยาสีพาสเทล
		K.box(self, Vector3(1.1, 0.55, 0.6), Vector3(0.95, 0.28, 0.1), K.mat(Color(0.86, 0.64, 0.48)))
		K.box(self, Vector3(1.2, 0.06, 0.7), Vector3(0.95, 0.58, 0.1), K.mat(Color(1.0, 0.86, 0.84)))
		var colors := [Color(0.5, 0.88, 0.5), Color(0.55, 0.72, 1.0), Color(1.0, 0.78, 0.35), Color(0.62, 0.55, 1.0)]
		for i in 4:
			var x := 0.6 + i * 0.23
			K.cyl(self, 0.07, 0.08, 0.2, Vector3(x, 0.71, 0.15), K.mat(colors[i], 0.4, 0.4), 8)
			K.sphere(self, 0.04, Vector3(x, 0.84, 0.15), K.mat(Color(0.86, 0.64, 0.48)), 6)
		# ร่มกระดาษสีชมพู
		K.cyl(self, 0.03, 0.03, 2.2, Vector3(1.4, 1.1, -0.15), K.mat(Color(0.6, 0.42, 0.34)), 6)
		K.cyl(self, 0.02, 1.0, 0.4, Vector3(1.4, 2.25, -0.15), K.mat(Color(1.0, 0.7, 0.75)), 16)
	elif role() == "pet":
		# ครูฝึกสัตว์: ลูกหมากับแมวนั่งข้างตัว ชามอาหาร และห่วงฝึกกระโดด
		for e in [["cube-pets/animal-dog", Vector3(0.95, 0, 0.35), 0.5, -0.6], ["cube-pets/animal-cat", Vector3(-0.9, 0, 0.4), 0.45, 0.7]]:
			var pet := M.spawn(self, e[0], e[1], e[2], e[3])
			if pet != null:
				M.play(pet, "idle", 1.0)
		K.cyl(self, 0.2, 0.15, 0.1, Vector3(0.45, 0.05, 0.75), K.mat(Color(0.55, 0.75, 1.0)), 12)
		K.sphere(self, 0.15, Vector3(0.45, 0.1, 0.75), K.mat(Color(0.85, 0.6, 0.4)), 8, Vector3(1, 0.4, 1))
		var hoop := TorusMesh.new()
		hoop.inner_radius = 0.38
		hoop.outer_radius = 0.45
		var h := K.add(self, hoop, Vector3(1.55, 0.6, -0.2), K.mat(Color(1.0, 0.6, 0.7)))
		h.rotation.x = PI / 2
		h.rotation.z = 0.3
		for x in [1.2, 1.9]:
			K.cyl(self, 0.03, 0.03, 0.6, Vector3(x, 0.3, -0.2 + (x - 1.55) * 0.3), K.mat(Color(0.75, 0.55, 0.42)), 6)
	elif role() == "boat":
		# นายท้ายเรือ: ท่าไม้เล็กๆ กับเรือสำเภาจอดข้างตัว ถือพาย
		K.box(self, Vector3(1.6, 0.12, 2.6), Vector3(1.5, 0.12, 0.2), K.mat(Color(0.72, 0.55, 0.4)))
		for z in [-0.9, 0.9]:
			K.cyl(self, 0.07, 0.07, 0.5, Vector3(2.2, -0.1, z), K.mat(Color(0.5, 0.38, 0.3)), 6)
		K.sphere(self, 0.95, Vector3(3.6, 0.35, 0.2), K.mat(Color(0.62, 0.42, 0.32)), 14, Vector3(1.0, 0.5, 2.3))
		K.box(self, Vector3(0.9, 0.5, 1.0), Vector3(3.6, 0.8, 0.2), K.mat(Color(0.78, 0.6, 0.45)))
		K.cyl(self, 0.06, 0.06, 3.2, Vector3(3.6, 2.2, 0.2), K.mat(Color(0.55, 0.4, 0.32)), 6)
		K.box(self, Vector3(0.05, 1.8, 1.5), Vector3(3.6, 2.4, 0.2), K.mat(Color(0.98, 0.84, 0.6)))
		K.box(self, Vector3(0.06, 0.45, 0.3), Vector3(3.6, 3.7, 0.2), K.mat(Color(0.95, 0.4, 0.4)))
		K.beam(self, Vector3(0.35, 0.2, 0.3), Vector3(0.6, 1.5, -0.1), 0.05, K.mat(Color(0.7, 0.52, 0.38)))
	K.label(self, data["name"], Vector3(0, 2.05, 0), Color(0.75, 1.0, 0.8), 34)
	marker = K.label(self, "", Vector3(0, 2.7, 0), Color(1.0, 0.85, 0.3), 90)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.6)
	light.omni_range = 4.0
	light.light_energy = 0.0
	light.position = Vector3(0, 1.8, 0.8)
	light.set_meta("base_energy", 1.2)
	light.add_to_group("night_light")
	add_child(light)


## เครื่องหมายเหนือหัว: "!" มีเควสใหม่, "?" มีเควสให้ส่ง, ร้านค้าแสดงรูปถุงเงิน
func set_marker(state: String) -> void:
	marker_state = state
	if marker == null:
		return
	marker.font_size = 90
	match state:
		"ready":
			marker.text = "?"
			marker.modulate = Color(0.55, 1.0, 0.6)
		"available":
			marker.text = "!"
			marker.modulate = Color(1.0, 0.85, 0.3)
		"class":
			marker.text = "เปลี่ยนอาชีพ"
			marker.font_size = 40
			marker.modulate = Color(0.85, 0.75, 1.0)
		"pet":
			marker.text = "พัฒนาร่างสัตว์เลี้ยง"
			marker.font_size = 36
			marker.modulate = Color(0.6, 0.95, 1.0)
		"boat":
			marker.text = "เรือข้ามประเทศ"
			marker.font_size = 38
			marker.modulate = Color(0.6, 0.85, 1.0)
		"shop":
			marker.text = "ร้านค้า"
			marker.font_size = 40
			marker.modulate = Color(1.0, 0.78, 0.85)
		_:
			marker.text = ""


func _process(delta: float) -> void:
	t += delta
	if body != null:
		body.position.y = absf(sin(t * 1.5)) * 0.03
	if marker != null:
		marker.position.y = 2.7 + sin(t * 3.0) * 0.08
