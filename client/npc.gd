extends Node3D
## NPC ตัวจิบิยืนประจำที่: ร้านค้า หรือคนให้เควส
## เหนือหัวมีป้ายบอกหน้าที่ และเครื่องหมาย ! (มีเควสให้รับ) / ? (มีเควสให้ส่ง)

const K = preload("res://maps/props/mesh_kit.gd")

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
		"farmer":
			# งอบสาน
			K.sphere(head, 0.39, Vector3(0, 0.14, -0.1), hair, 18, Vector3(1.0, 0.78, 1.0))
			K.cyl(head, 0.03, 0.62, 0.3, Vector3(0, 0.42, -0.04), K.mat(Color(0.92, 0.8, 0.55)), 16)
		_:
			K.sphere(head, 0.39, Vector3(0, 0.14, -0.1), hair, 18, Vector3(1.0, 0.78, 1.0))
	for x in [-0.14, 0.14]:
		# ตายิ้ม (โค้งปิด) ให้ดูใจดี
		K.box(head, Vector3(0.12, 0.035, 0.03), Vector3(x, -0.01, 0.35), eye)
		K.sphere(head, 0.06, Vector3(x * 1.55, -0.11, 0.31), blush, 8, Vector3(1.2, 0.6, 0.4))
	K.sphere(head, 0.03, Vector3(0, -0.15, 0.36), K.mat(Color(0.85, 0.4, 0.42), 0.0, 0.8, 0.0, false), 6, Vector3(1.4, 0.7, 0.6))
	if role() == "shop":
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
