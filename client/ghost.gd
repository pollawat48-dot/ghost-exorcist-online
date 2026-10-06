extends Node3D
## ผีหนึ่งตัว: ลอยวน, ไล่ตีเมื่อถูกโจมตี (หรือเมื่อเห็นผู้เล่นถ้าเป็นผีดุ)
## ตรรกะใช้ pos (หน่วยเกมบนพื้นราบ) ส่วนโมเดล 3D ตามตำแหน่งนั้น
## ตอน M1 คำนวณในเครื่อง ภายหลังจะย้าย AI นี้ไปไว้ที่ zone server

const K = preload("res://maps/props/mesh_kit.gd")
const Combat = preload("res://shared/combat/combat.gd")
const GhostDB = preload("res://shared/data/ghosts.gd")
const DamageText = preload("res://client/damage_text.gd")
const Effect = preload("res://client/effect.gd")

signal died(ghost: Node3D)

const AGGRO_RADIUS := 150.0
const LEASH_RADIUS := 350.0

var ghost_id := ""
var data := {}
var hp := 0
var alive := true
var pos := Vector2.ZERO
var home := Vector2.ZERO
var player: Node3D
var target: Node3D = null
var returning := false
var attack_cooldown := 0.0
var wander_target := Vector2.ZERO
var wander_wait := 0.0
var flash := 0.0
var bob := 0.0
var rng := RandomNumberGenerator.new()
var model: Node3D
var dangles: Array[Node3D] = []
var base_scale := 1.0
var float_height := 1.25  ## ความสูงที่ลอยจากพื้น (เมตร)
var label_y := 2.15
var aoe_timer := 0.0
var crown_y := 0.0  ## ตำแหน่งมงกุฎบอสเหนือหัว (ตามรูปร่าง)


func setup(id: String, at: Vector2, player_ref: Node3D, seed_value: int) -> void:
	ghost_id = id
	data = GhostDB.GHOSTS[id]
	hp = data["hp"]
	pos = at
	home = at
	wander_target = at
	player = player_ref
	rng.seed = seed_value
	bob = rng.randf() * TAU


func _ready() -> void:
	position = K.to3d(pos)
	model = Node3D.new()
	add_child(model)
	var c: Color = data["color"]
	var eye := K.mat(Color(0.22, 0.12, 0.2), 0.0, 0.3, 0.0, false)
	var shine := K.mat(Color(1, 1, 1), 1.5, 0.3, 0.0, false)
	var blush := K.mat(Color(1.0, 0.55, 0.65), 0.4, 0.8, 0.0, false)
	var model_kind: String = data.get("model", "")
	if model_kind != "":
		_build_model(model_kind, c, eye, shine, blush)
	else:
		_build_by_id(c, eye, shine, blush)
	if is_boss() and model_kind != "":
		_build_queen_crown(Vector3(0, crown_y, 0))
	var light := OmniLight3D.new()
	light.light_color = c
	light.omni_range = 4.0
	light.light_energy = 0.0
	light.set_meta("base_energy", 1.6)
	light.add_to_group("night_light")
	model.add_child(light)
	base_scale = data.get("scale", 2.2 if is_boss() else 1.0)
	if is_boss():
		# บอสเรืองแสงตลอดเวลา ไม่ต้องรอกลางคืน
		var glow := OmniLight3D.new()
		glow.light_color = c
		glow.omni_range = 7.0
		glow.light_energy = 1.5
		glow.position.y = 1.0
		add_child(glow)
		K.label(self, "★ %s Lv.%d ★" % [data["name"], data["level"]], Vector3(0, label_y * base_scale * 0.95 + 0.6, 0), Color(1, 0.85, 0.4), 44)
	else:
		K.label(self, "%s Lv.%d" % [data["name"], data["level"]], Vector3(0, label_y, 0), Color(1, 0.88, 0.88), 34)
	_sync()


func _build_by_id(c: Color, eye: Material, shine: Material, blush: Material) -> void:
	match ghost_id:
		"krasue_noi":
			_build_krasue(eye, shine, blush)
		"krasue_queen":
			_build_krasue(eye, shine, blush)
			_build_queen_crown(Vector3.ZERO)
		"phi_khamot":
			_build_khamot(eye, shine, blush)
		"phi_pop":
			_build_pop(eye, shine, blush)
		"phi_pret":
			_build_pret(eye, shine, blush)
		"pret_king":
			_build_pret(eye, shine, blush)
			_build_queen_crown(Vector3(0, 2.0, 0))
		"phi_takiang":
			# ผีตะเกียงตัวกลม หน้าตาง่วงๆ แก้มแดง
			K.cyl(model, 0.32, 0.36, 0.58, Vector3.ZERO, K.mat(Color(1.0, 0.82, 0.5), 1.4, 0.5), 14)
			K.cyl(model, 0.2, 0.38, 0.14, Vector3(0, 0.36, 0), K.mat(Color(0.86, 0.5, 0.42)), 14)
			K.cyl(model, 0.38, 0.26, 0.12, Vector3(0, -0.35, 0), K.mat(Color(0.86, 0.5, 0.42)), 14)
			K.sphere(model, 0.07, Vector3(0, 0.5, 0), K.mat(Color(0.86, 0.5, 0.42)), 8)
			var handle := TorusMesh.new()
			handle.inner_radius = 0.1
			handle.outer_radius = 0.13
			K.add(model, handle, Vector3(0, 0.6, 0), K.mat(Color(0.6, 0.42, 0.4)), Vector3(PI / 2, 0, 0))
			for x in [-0.13, 0.13]:
				K.sphere(model, 0.07, Vector3(x, 0.05, 0.33), eye, 10, Vector3(0.85, 1.15, 0.5))
				K.sphere(model, 0.025, Vector3(x + 0.025, 0.09, 0.37), shine, 6)
				K.sphere(model, 0.055, Vector3(x * 1.6, -0.06, 0.32), blush, 8, Vector3(1.2, 0.6, 0.4))
			K.sphere(model, 0.05, Vector3(0, -0.1, 0.34), K.mat(Color(0.85, 0.35, 0.4), 0.0, 0.8, 0.0, false), 8, Vector3(1.2, 0.8, 0.5))
		_:
			K.sphere(model, 0.3, Vector3.ZERO, K.mat(c, 1.0), 10)


func is_boss() -> bool:
	return data.get("boss", false)


func _build_krasue(eye: Material, shine: Material, blush: Material) -> void:
	# กระสือแบบน่ารัก: หัวกลมผมบ๊อบ ตาโตสีชมพูเรือง ไส้ห้อยเป็นริบบิ้นพาสเทล
	K.sphere(model, 0.34, Vector3.ZERO, K.mat(Color(1.0, 0.93, 0.9), 0.15, 0.6), 18)
	K.sphere(model, 0.37, Vector3(0, 0.13, -0.12), K.mat(Color(0.33, 0.24, 0.38), 0.0, 0.5), 18, Vector3(1.05, 0.8, 1.0))
	K.box(model, Vector3(0.62, 0.36, 0.1), Vector3(0, -0.12, -0.24), K.mat(Color(0.33, 0.24, 0.38)))
	for x in [-0.13, 0.13]:
		K.sphere(model, 0.085, Vector3(x, -0.03, 0.29), K.mat(Color(0.95, 0.35, 0.55), 1.2, 0.3, 0.0, false), 10, Vector3(0.85, 1.15, 0.5))
		K.sphere(model, 0.03, Vector3(x + 0.03, 0.03, 0.34), shine, 6)
		K.sphere(model, 0.06, Vector3(x * 1.6, -0.13, 0.26), blush, 8, Vector3(1.2, 0.6, 0.4))
	K.sphere(model, 0.035, Vector3(0, -0.16, 0.32), eye, 6, Vector3(1.2, 0.8, 0.6))
	var ribbon := [Color(1.0, 0.62, 0.72), Color(0.98, 0.78, 0.55), Color(0.86, 0.62, 0.92), Color(1.0, 0.62, 0.72)]
	for i in 4:
		var d := Node3D.new()
		d.position = Vector3(-0.12 + i * 0.08, -0.3, 0.02)
		model.add_child(d)
		K.cyl(d, 0.03, 0.04, 0.35 + (i % 2) * 0.12, Vector3(0, -0.18, 0), K.mat(ribbon[i], 0.6, 0.5), 6)
		K.sphere(d, 0.07, Vector3(0, -0.4 - (i % 2) * 0.1, 0), K.mat(ribbon[i], 0.9, 0.5), 8)
		dangles.append(d)


## ชฎาทองของบอส + ต่างหูอัญมณี (head = ตำแหน่งกลางหัว)
func _build_queen_crown(head: Vector3) -> void:
	K.cyl(model, 0.26, 0.3, 0.1, head + Vector3(0, 0.36, -0.04), K.gold(), 16)
	K.cyl(model, 0.13, 0.22, 0.18, head + Vector3(0, 0.5, -0.04), K.gold(), 14)
	K.cyl(model, 0.015, 0.12, 0.34, head + Vector3(0, 0.76, -0.04), K.gold(), 12)
	K.sphere(model, 0.05, head + Vector3(0, 0.38, 0.24), K.mat(Color(1.0, 0.3, 0.5), 2.0, 0.3, 0.0, false), 8)
	for x in [-0.33, 0.33]:
		K.sphere(model, 0.05, head + Vector3(x, -0.12, 0.05), K.mat(Color(0.5, 1.0, 0.8), 2.0, 0.3, 0.0, false), 8)


## ผีโขมด: ดวงไฟสีฟ้าอมเขียว ตาโตใส มีเปลวไฟเล็กๆ ลุกบนหัวและหางไฟห้อย
func _build_khamot(eye: Material, shine: Material, blush: Material, tone: Color = Color(0.4, 0.95, 0.85)) -> void:
	var core := tone.lerp(Color.WHITE, 0.25)
	K.sphere(model, 0.32, Vector3.ZERO, K.mat(core, 1.6, 0.4), 16)
	K.sphere(model, 0.45, Vector3.ZERO, K.mat(Color(core, 0.25), 1.5, 0.5, 0.0, false), 14)
	for i in 3:
		var a := (i - 1) * 0.45
		K.cyl(model, 0.0, 0.13 - absf(a) * 0.08, 0.42 - absf(a) * 0.15, Vector3(sin(a) * 0.18, 0.4, -0.04), K.mat(tone.lerp(Color.WHITE, 0.5), 2.2, 0.4, 0.0, false), 8, Vector3(0, 0, -a))
	for x in [-0.12, 0.12]:
		K.sphere(model, 0.07, Vector3(x, 0.0, 0.28), eye, 10, Vector3(0.85, 1.2, 0.5))
		K.sphere(model, 0.025, Vector3(x + 0.025, 0.04, 0.32), shine, 6)
		K.sphere(model, 0.05, Vector3(x * 1.6, -0.1, 0.26), blush, 8, Vector3(1.2, 0.6, 0.4))
	for i in 3:
		var d := Node3D.new()
		d.position = Vector3(-0.1 + i * 0.1, -0.25, -0.05)
		model.add_child(d)
		K.cyl(d, 0.07 - i * 0.01, 0.0, 0.35, Vector3(0, -0.15, 0), K.mat(Color(tone, 0.8), 1.8, 0.4, 0.0, false), 6)
		dangles.append(d)


## ผีปอบ: ตัวกลมป้อมสีเขียวอ่อนแบบผ้าคลุม ผมยุ่ง ยิ้มกว้างมีเขี้ยวเล็ก แขนสั้นๆ
func _build_pop(eye: Material, shine: Material, blush: Material) -> void:
	float_height = 0.75
	var skin := K.mat(Color(0.74, 0.9, 0.7), 0.2, 0.7)
	K.sphere(model, 0.48, Vector3.ZERO, skin, 18, Vector3(1.0, 1.05, 0.95))
	K.cyl(model, 0.46, 0.5, 0.35, Vector3(0, -0.4, 0), skin, 16)
	for i in 6:
		var a := i * TAU / 6.0
		K.sphere(model, 0.13, Vector3(cos(a) * 0.42, -0.6, sin(a) * 0.42), skin, 8)
	var hair := K.mat(Color(0.3, 0.26, 0.36), 0.0, 0.6)
	for i in 7:
		var a := -1.2 + i * 0.4
		K.cyl(model, 0.0, 0.1, 0.32, Vector3(sin(a) * 0.3, 0.42 + cos(a) * 0.06, -0.12), hair, 6, Vector3(-0.3, 0, -a * 0.8))
	for x in [-0.17, 0.17]:
		K.sphere(model, 0.085, Vector3(x, 0.08, 0.42), eye, 10, Vector3(0.85, 1.1, 0.5))
		K.sphere(model, 0.03, Vector3(x + 0.03, 0.12, 0.47), shine, 6)
		K.sphere(model, 0.07, Vector3(x * 1.5, -0.06, 0.4), blush, 8, Vector3(1.2, 0.6, 0.4))
	K.sphere(model, 0.12, Vector3(0, -0.14, 0.42), K.mat(Color(0.75, 0.3, 0.38), 0.0, 0.8, 0.0, false), 10, Vector3(1.6, 0.7, 0.5))
	for x in [-0.07, 0.07]:
		K.cyl(model, 0.0, 0.03, 0.06, Vector3(x, -0.1, 0.48), K.mat(Color(1, 1, 1)), 6, Vector3(PI, 0, 0))
	for side in [-1.0, 1.0]:
		var d := Node3D.new()
		d.position = Vector3(side * 0.47, -0.1, 0.05)
		model.add_child(d)
		K.cyl(d, 0.07, 0.09, 0.3, Vector3(0, -0.12, 0), skin, 8, Vector3(0, 0, side * 0.4))
		dangles.append(d)


## เปรต: ตัวสูงผอมสีม่วงอ่อน หัวเล็ก ปากจิ๋วเท่ารูเข็ม แขนยาวเรียวห้อยลงพื้น
func _build_pret(eye: Material, shine: Material, blush: Material, tone: Color = Color(0.78, 0.66, 1.0)) -> void:
	float_height = 0.15
	label_y = 3.6
	var skin := K.mat(tone.lerp(Color.WHITE, 0.25), 0.25, 0.7)
	var cloth := K.mat(Color(0.62, 0.58, 0.72), 0.0, 0.8)
	K.cyl(model, 0.12, 0.3, 1.0, Vector3(0, 0.5, 0), cloth, 12)
	K.cyl(model, 0.1, 0.13, 0.7, Vector3(0, 1.35, 0), skin, 10)
	K.cyl(model, 0.08, 0.08, 0.3, Vector3(0, 1.82, 0), skin, 8)
	K.sphere(model, 0.3, Vector3(0, 2.1, 0), skin, 16)
	var hair := K.mat(Color(0.86, 0.86, 0.94), 0.0, 0.6)
	for i in 5:
		var a := -0.8 + i * 0.4
		K.cyl(model, 0.0, 0.035, 0.25, Vector3(sin(a) * 0.2, 2.38, -0.05), hair, 4, Vector3(-0.2, 0, -a))
	for x in [-0.11, 0.11]:
		K.sphere(model, 0.06, Vector3(x, 2.12, 0.25), eye, 10, Vector3(0.85, 1.2, 0.5))
		K.sphere(model, 0.02, Vector3(x + 0.02, 2.15, 0.29), shine, 6)
		K.sphere(model, 0.045, Vector3(x * 1.6, 2.02, 0.24), blush, 8, Vector3(1.2, 0.6, 0.4))
	K.sphere(model, 0.025, Vector3(0, 1.98, 0.28), K.mat(Color(0.4, 0.2, 0.3), 0.0, 0.8, 0.0, false), 6)
	for side in [-1.0, 1.0]:
		var d := Node3D.new()
		d.position = Vector3(side * 0.16, 1.6, 0.0)
		model.add_child(d)
		K.cyl(d, 0.04, 0.05, 1.3, Vector3(side * 0.05, -0.65, 0), skin, 6, Vector3(0, 0, side * 0.08))
		K.sphere(d, 0.1, Vector3(side * 0.1, -1.35, 0), skin, 8, Vector3(1, 1.3, 0.8))
		dangles.append(d)


func _sync() -> void:
	position = K.to3d(pos)
	model.position.y = (float_height + sin(bob) * 0.12) * (1.6 if is_boss() and float_height > 1.0 else 1.0)
	for i in dangles.size():
		dangles[i].rotation.x = sin(bob * 1.3 + i) * 0.25
	model.scale = Vector3.ONE * base_scale * (1.15 if flash > 0.0 else 1.0)
	if target != null and is_instance_valid(target):
		var d: Vector2 = target.pos - pos
		if d.length() > 1.0:
			model.rotation.y = lerp_angle(model.rotation.y, atan2(d.x, d.y), 0.2)


func take_damage(amount: int, attacker: Node3D, crit: bool = false) -> void:
	if not alive:
		return
	hp -= amount
	flash = 0.15
	target = attacker
	returning = false
	var text_y := label_y * base_scale * 0.95 + 0.3
	if crit:
		DamageText.spawn(get_parent(), position + Vector3(0, text_y, 0), "%d!" % amount, Color(1, 0.85, 0.3))
	else:
		DamageText.spawn(get_parent(), position + Vector3(0, text_y, 0), str(amount), Color.WHITE)
	if hp <= 0:
		alive = false
		died.emit(self)
		queue_free()


func tick(delta: float) -> void:
	if not alive:
		return
	bob += delta * 3.0
	flash = maxf(0.0, flash - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)

	if returning and pos.distance_to(home) < 30.0:
		returning = false
	if target == null and not returning and data["aggressive"] and player.hp > 0 \
			and pos.distance_to(player.pos) < AGGRO_RADIUS:
		target = player
	if target != null and (not is_instance_valid(target) or target.hp <= 0 \
			or pos.distance_to(home) > LEASH_RADIUS):
		target = null
		returning = true
		wander_target = home

	if target != null and is_boss():
		# บอสปล่อยคลื่นวิญญาณเป็นวงกว้างเป็นระยะ
		aoe_timer -= delta
		if aoe_timer <= 0.0 and pos.distance_to(target.pos) < data["aoe_radius"]:
			aoe_timer = data["aoe_interval"]
			Effect.ring(get_parent(), position, data["aoe_radius"] / 32.0, Color(1.0, 0.4, 0.7))
			target.take_damage(Combat.damage(data["atk"], target.stats["def"], "neutral", "none", rng, data["aoe_power"]), data["name"])
	if target != null:
		if pos.distance_to(target.pos) > data["attack_range"]:
			pos = pos.move_toward(target.pos, data["speed"] * 1.3 * delta)
		elif attack_cooldown <= 0.0:
			attack_cooldown = data["attack_interval"]
			target.take_damage(Combat.damage(data["atk"], target.stats["def"], "neutral", "none", rng), data["name"])
	else:
		_wander(delta)
	if model != null:
		_sync()


func _wander(delta: float) -> void:
	if pos.distance_to(wander_target) < 4.0:
		wander_wait -= delta
		if wander_wait <= 0.0:
			wander_target = home + Vector2(rng.randf_range(-90, 90), rng.randf_range(-90, 90))
			wander_wait = rng.randf_range(1.0, 3.0)
	else:
		var speed: float = data["speed"] * (1.2 if returning else 0.5)
		pos = pos.move_toward(wander_target, speed * delta)


# ---------- รูปร่างผีแผนที่ 3–6 และถ้ำ (เลือกจาก data["model"]) ----------

func _build_model(kind: String, c: Color, eye: Material, shine: Material, blush: Material) -> void:
	match kind:
		"sheet":
			_build_sheet(c, eye, shine, blush)
		"headless":
			_build_headless(c, eye, shine, blush)
		"warrior":
			_build_sheet(c, eye, shine, blush)
			_build_helmet(c)
		"wisp":
			_build_khamot(eye, shine, blush, c)
		"tree_lady":
			_build_tree_lady(c, eye, shine, blush)
		"naga":
			_build_naga(c, eye, shine, blush)
		"koi":
			_build_koi(c, eye, shine, blush)
		"asura":
			_build_asura(c, eye, shine, blush)
		"reaper":
			_build_reaper(c, eye, shine, blush)
		"pret":
			_build_pret(eye, shine, blush, c)
			crown_y = 2.0
		"rock":
			_build_rock_spirit(c, eye, shine, blush)
		_:
			K.sphere(model, 0.3, Vector3.ZERO, K.mat(c, 1.0), 10)


func _face(y: float, z: float, spread: float, eye: Material, shine: Material, blush: Material, size: float = 1.0) -> void:
	for x in [-spread, spread]:
		K.sphere(model, 0.075 * size, Vector3(x, y, z), eye, 10, Vector3(0.85, 1.2, 0.5))
		K.sphere(model, 0.027 * size, Vector3(x + 0.025 * size, y + 0.04 * size, z + 0.04 * size), shine, 6)
		K.sphere(model, 0.055 * size, Vector3(x * 1.6, y - 0.1 * size, z - 0.02), blush, 8, Vector3(1.2, 0.6, 0.4))


## ผีผ้าคลุมแบบคลาสสิก: หัวกลม ชายผ้าเป็นคลื่น สีตามชนิดผี
func _build_sheet(c: Color, eye: Material, shine: Material, blush: Material) -> void:
	var cloth := K.mat(c.lerp(Color.WHITE, 0.55), 0.3, 0.7)
	K.sphere(model, 0.42, Vector3(0, 0.1, 0), cloth, 18, Vector3(1.0, 1.05, 1.0))
	K.cyl(model, 0.42, 0.5, 0.45, Vector3(0, -0.2, 0), cloth, 16)
	for i in 7:
		var a := i * TAU / 7.0
		K.sphere(model, 0.12, Vector3(cos(a) * 0.44, -0.45, sin(a) * 0.44), cloth, 8)
	_face(0.12, 0.38, 0.14, eye, shine, blush)
	K.sphere(model, 0.04, Vector3(0, -0.02, 0.41), K.mat(Color(0.5, 0.25, 0.35), 0.0, 0.8, 0.0, false), 6, Vector3(1.4, 1.0, 0.6))
	for side in [-1.0, 1.0]:
		var d := Node3D.new()
		d.position = Vector3(side * 0.42, 0.0, 0.05)
		model.add_child(d)
		K.cyl(d, 0.06, 0.1, 0.3, Vector3(0, -0.12, 0), cloth, 8, Vector3(0, 0, side * 0.5))
		dangles.append(d)
	crown_y = 0.25


## หมวกทหารโบราณทรงกรวยกับทวน
func _build_helmet(c: Color) -> void:
	var gold := K.gold()
	K.cyl(model, 0.02, 0.36, 0.45, Vector3(0, 0.62, 0), K.mat(c.darkened(0.3), 0.2, 0.5, 0.3), 12)
	K.cyl(model, 0.4, 0.4, 0.06, Vector3(0, 0.42, 0), gold, 14)
	K.beam(model, Vector3(0.55, -0.5, 0.15), Vector3(0.6, 1.2, 0.15), 0.05, K.mat(Color(0.6, 0.42, 0.34)))
	K.cyl(model, 0.0, 0.08, 0.3, Vector3(0.6, 1.35, 0.15), K.mat(Color(0.9, 0.92, 1.0), 0.5, 0.3), 6)
	crown_y = 0.75


## ผีหัวขาด: ตัวสวมเสื้อคอกลม ไม่มีหัว ถือหัวยิ้มแฉ่งไว้ข้างตัว
func _build_headless(c: Color, eye: Material, shine: Material, blush: Material) -> void:
	float_height = 0.35
	label_y = 2.1
	var robe := K.mat(c, 0.2, 0.7)
	var skin := K.mat(Color(0.92, 0.88, 1.0), 0.3, 0.7)
	K.cyl(model, 0.2, 0.38, 0.9, Vector3(0, 0.45, 0), robe, 14)
	K.cyl(model, 0.16, 0.16, 0.08, Vector3(0, 0.94, 0), K.mat(Color(0.85, 0.4, 0.5), 0.5, 0.6), 10)
	for i in 3:
		K.sphere(model, 0.05, Vector3(-0.05 + i * 0.05, 1.02 + i * 0.06, 0), K.mat(Color(0.75, 0.7, 1.0, 0.7), 1.5, 0.4, 0.0, false), 6)
	var hand := Node3D.new()
	hand.position = Vector3(0.42, 0.55, 0.15)
	model.add_child(hand)
	K.beam(model, Vector3(0.18, 0.75, 0.0), Vector3(0.4, 0.45, 0.12), 0.08, robe)
	K.sphere(hand, 0.28, Vector3.ZERO, skin, 14)
	K.sphere(hand, 0.29, Vector3(0, 0.1, -0.08), K.mat(Color(0.3, 0.26, 0.36)), 14, Vector3(1.0, 0.7, 1.0))
	for x in [-0.09, 0.09]:
		K.sphere(hand, 0.05, Vector3(x, 0.0, 0.24), eye, 8, Vector3(0.85, 1.2, 0.5))
		K.sphere(hand, 0.04, Vector3(x * 1.7, -0.08, 0.22), blush, 6, Vector3(1.2, 0.6, 0.4))
	K.sphere(hand, 0.05, Vector3(0, -0.1, 0.26), K.mat(Color(0.6, 0.25, 0.35)), 6, Vector3(1.4, 0.8, 0.6))
	dangles.append(hand)
	crown_y = 1.0


## นางไม้: ชุดสไบสีเขียวทรงระฆัง ผมยาวสลวย มงกุฎใบไม้
func _build_tree_lady(c: Color, eye: Material, shine: Material, blush: Material) -> void:
	float_height = 0.3
	label_y = 2.6
	var dress := K.mat(c, 0.3, 0.7)
	var skin := K.mat(Color(1.0, 0.9, 0.82), 0.1, 0.7)
	var hair := K.mat(Color(0.25, 0.32, 0.26), 0.0, 0.6)
	K.cyl(model, 0.18, 0.6, 1.1, Vector3(0, 0.55, 0), dress, 16)
	K.cyl(model, 0.15, 0.2, 0.35, Vector3(0, 1.25, 0), K.mat(c.lightened(0.3)), 12)
	K.sphere(model, 0.34, Vector3(0, 1.72, 0), skin, 16)
	K.sphere(model, 0.36, Vector3(0, 1.82, -0.1), hair, 16, Vector3(1.0, 0.9, 1.0))
	K.box(model, Vector3(0.6, 0.9, 0.12), Vector3(0, 1.35, -0.28), hair)
	for i in 6:
		var a := -1.0 + i * 0.4
		K.sphere(model, 0.09, Vector3(sin(a) * 0.32, 2.05 + cos(a) * 0.05, -0.05), K.mat(Color(0.5, 0.85, 0.45), 0.5), 6, Vector3(1.4, 0.6, 0.8))
	for x in [-0.12, 0.12]:
		K.sphere(model, 0.06, Vector3(x, 1.72, 0.29), eye, 10, Vector3(0.85, 1.2, 0.5))
		K.sphere(model, 0.022, Vector3(x + 0.02, 1.76, 0.33), shine, 6)
		K.sphere(model, 0.045, Vector3(x * 1.6, 1.62, 0.28), blush, 8, Vector3(1.2, 0.6, 0.4))
	for side in [-1.0, 1.0]:
		var d := Node3D.new()
		d.position = Vector3(side * 0.22, 1.3, 0.05)
		model.add_child(d)
		K.cyl(d, 0.05, 0.06, 0.55, Vector3(side * 0.1, -0.25, 0), skin, 6, Vector3(0, 0, side * 0.35))
		dangles.append(d)
	crown_y = 1.85


## ผีนาคา: ลำตัวงูขดเป็นวง ชูหัวกลมมีแผงหงอน
func _build_naga(c: Color, eye: Material, shine: Material, blush: Material) -> void:
	float_height = 0.25
	label_y = 2.3
	var scale_mat := K.mat(c, 0.25, 0.6)
	var belly := K.mat(Color(1.0, 0.92, 0.7))
	for i in 7:
		var a := i * 0.9
		K.sphere(model, 0.26 - i * 0.015, Vector3(cos(a) * 0.4, 0.1 + i * 0.04, sin(a) * 0.4 - 0.1), scale_mat, 10)
	K.cyl(model, 0.18, 0.24, 0.8, Vector3(0, 0.75, 0.2), scale_mat, 10, Vector3(0.2, 0, 0))
	K.sphere(model, 0.34, Vector3(0, 1.3, 0.3), scale_mat, 14, Vector3(1.1, 0.95, 1.0))
	K.box(model, Vector3(0.2, 0.5, 0.05), Vector3(0, 0.75, 0.42), belly, Vector3(0.2, 0, 0))
	for i in 5:
		var a := -0.9 + i * 0.45
		K.cyl(model, 0.02, 0.1, 0.45, Vector3(sin(a) * 0.32, 1.6, 0.18), K.gold(), 6, Vector3(-0.3, 0, -a))
	_face_at(Vector3(0, 1.3, 0.6), 0.12, eye, shine, blush)
	crown_y = 1.35


func _face_at(center: Vector3, spread: float, eye: Material, shine: Material, blush: Material) -> void:
	for x in [-spread, spread]:
		K.sphere(model, 0.07, center + Vector3(x, 0, 0), eye, 10, Vector3(0.85, 1.2, 0.5))
		K.sphere(model, 0.025, center + Vector3(x + 0.025, 0.04, 0.04), shine, 6)
		K.sphere(model, 0.05, center + Vector3(x * 1.6, -0.1, -0.02), blush, 8, Vector3(1.2, 0.6, 0.4))


## ผีกองกอย: ก้อนขนฟูขาเดียว กระโดดดึ๋งๆ
func _build_koi(c: Color, eye: Material, shine: Material, blush: Material) -> void:
	float_height = 0.55
	var fur := K.mat(c, 0.1, 0.9)
	K.sphere(model, 0.45, Vector3.ZERO, fur, 14)
	for i in 12:
		var a := i * TAU / 12.0
		K.sphere(model, 0.14, Vector3(cos(a) * 0.4, sin(i * 1.3) * 0.25, sin(a) * 0.4), fur, 6)
	K.cyl(model, 0.07, 0.08, 0.45, Vector3(0, -0.6, 0), K.mat(c.darkened(0.25)), 8)
	K.sphere(model, 0.13, Vector3(0, -0.85, 0.06), K.mat(c.darkened(0.25)), 8, Vector3(1.0, 0.5, 1.5))
	_face(0.05, 0.42, 0.14, eye, shine, blush, 1.1)
	for x in [-0.25, 0.25]:
		K.cyl(model, 0.0, 0.07, 0.25, Vector3(x, 0.45, 0), K.mat(c.darkened(0.2)), 6, Vector3(0, 0, -x))
	crown_y = 0.3


## อสุรกาย: ตัวใหญ่ล่ำ มีเขาสองข้าง เขี้ยวเล็กๆ แต่ตาโตน่ารัก
func _build_asura(c: Color, eye: Material, shine: Material, blush: Material) -> void:
	float_height = 0.15
	label_y = 2.7
	var skin := K.mat(c, 0.15, 0.7)
	var cloth := K.mat(Color(0.95, 0.8, 0.4))
	K.sphere(model, 0.6, Vector3(0, 0.75, 0), skin, 16, Vector3(1.1, 1.0, 0.9))
	K.cyl(model, 0.55, 0.6, 0.3, Vector3(0, 0.3, 0), cloth, 14)
	for x in [-0.25, 0.25]:
		K.cyl(model, 0.14, 0.16, 0.35, Vector3(x, 0.08, 0), skin, 8)
	K.sphere(model, 0.42, Vector3(0, 1.55, 0.05), skin, 16)
	for side in [-1.0, 1.0]:
		K.cyl(model, 0.0, 0.1, 0.35, Vector3(side * 0.28, 1.95, 0), K.mat(Color(1.0, 0.95, 0.85)), 8, Vector3(0, 0, -side * 0.5))
		var d := Node3D.new()
		d.position = Vector3(side * 0.62, 1.0, 0.05)
		model.add_child(d)
		K.cyl(d, 0.12, 0.15, 0.6, Vector3(side * 0.05, -0.28, 0), skin, 8, Vector3(0, 0, side * 0.2))
		K.sphere(d, 0.16, Vector3(side * 0.1, -0.62, 0), skin, 8)
		dangles.append(d)
	for x in [-0.15, 0.15]:
		K.sphere(model, 0.085, Vector3(x, 1.58, 0.38), eye, 10, Vector3(0.85, 1.2, 0.5))
		K.sphere(model, 0.03, Vector3(x + 0.03, 1.63, 0.43), shine, 6)
		K.sphere(model, 0.06, Vector3(x * 1.6, 1.46, 0.36), blush, 8, Vector3(1.2, 0.6, 0.4))
		K.cyl(model, 0.0, 0.03, 0.08, Vector3(x * 0.5, 1.38, 0.42), K.mat(Color(1, 1, 1)), 6, Vector3(PI, 0, 0))
	crown_y = 1.85


## ยมทูต: คลุมฮู้ดม่วงเข้ม หน้ากลมน่ารักในฮู้ด ถือบ่วงบาศ
func _build_reaper(c: Color, eye: Material, shine: Material, blush: Material) -> void:
	float_height = 0.5
	label_y = 2.5
	var robe := K.mat(c, 0.2, 0.75)
	K.cyl(model, 0.22, 0.55, 1.1, Vector3(0, 0.3, 0), robe, 14)
	K.sphere(model, 0.44, Vector3(0, 1.05, 0), robe, 16)
	K.cyl(model, 0.02, 0.18, 0.4, Vector3(0, 1.55, -0.15), robe, 8, Vector3(-0.6, 0, 0))
	K.sphere(model, 0.32, Vector3(0, 1.02, 0.18), K.mat(Color(0.95, 0.92, 1.0), 0.3, 0.7), 14)
	for x in [-0.11, 0.11]:
		K.sphere(model, 0.065, Vector3(x, 1.04, 0.45), eye, 10, Vector3(0.85, 1.2, 0.5))
		K.sphere(model, 0.024, Vector3(x + 0.02, 1.08, 0.49), shine, 6)
		K.sphere(model, 0.045, Vector3(x * 1.6, 0.94, 0.44), blush, 8, Vector3(1.2, 0.6, 0.4))
	var hand := Node3D.new()
	hand.position = Vector3(0.5, 0.6, 0.1)
	model.add_child(hand)
	var loop := TorusMesh.new()
	loop.inner_radius = 0.2
	loop.outer_radius = 0.25
	K.add(hand, loop, Vector3(0, -0.3, 0), K.mat(Color(0.95, 0.85, 0.5), 0.8))
	K.beam(hand, Vector3.ZERO, Vector3(0, -0.1, 0), 0.04, K.mat(Color(0.95, 0.85, 0.5), 0.8))
	dangles.append(hand)
	crown_y = 1.4


## ผีหินในถ้ำ: ก้อนหินกลมๆ มีแร่เรืองแสงฝังตัว ตาเรืองแสงสีตามถ้ำ
func _build_rock_spirit(c: Color, eye: Material, shine: Material, blush: Material) -> void:
	float_height = 0.55
	var stone := K.mat(Color(0.6, 0.57, 0.66), 0.0, 0.9)
	K.sphere(model, 0.5, Vector3.ZERO, stone, 8, Vector3(1.1, 1.0, 1.0))
	K.sphere(model, 0.3, Vector3(0.35, 0.3, -0.1), stone, 6)
	K.sphere(model, 0.25, Vector3(-0.35, 0.28, -0.05), stone, 6)
	for i in 5:
		var a := i * 1.3
		K.sphere(model, 0.08, Vector3(cos(a) * 0.42, sin(a * 1.7) * 0.3, sin(a) * 0.3 - 0.1), K.mat(c, 2.0, 0.2, 0.3), 4, Vector3(1, 1.5, 1))
	for x in [-0.15, 0.15]:
		K.sphere(model, 0.08, Vector3(x, 0.05, 0.45), K.mat(c, 2.5, 0.3, 0.0, false), 10, Vector3(0.85, 1.2, 0.5))
		K.sphere(model, 0.06, Vector3(x * 1.6, -0.08, 0.43), blush, 8, Vector3(1.2, 0.6, 0.4))
	for side in [-1.0, 1.0]:
		var d := Node3D.new()
		d.position = Vector3(side * 0.5, -0.1, 0.1)
		model.add_child(d)
		K.sphere(d, 0.16, Vector3(side * 0.08, -0.15, 0), stone, 6)
		dangles.append(d)
	crown_y = 0.3
