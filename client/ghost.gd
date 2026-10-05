extends Node3D
## ผีหนึ่งตัว: ลอยวน, ไล่ตีเมื่อถูกโจมตี (หรือเมื่อเห็นผู้เล่นถ้าเป็นผีดุ)
## ตรรกะใช้ pos (หน่วยเกมบนพื้นราบ) ส่วนโมเดล 3D ตามตำแหน่งนั้น
## ตอน M1 คำนวณในเครื่อง ภายหลังจะย้าย AI นี้ไปไว้ที่ zone server

const K = preload("res://maps/props/mesh_kit.gd")
const Combat = preload("res://shared/combat/combat.gd")
const GhostDB = preload("res://shared/data/ghosts.gd")
const DamageText = preload("res://client/damage_text.gd")

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
	match ghost_id:
		"krasue_noi":
			# หัวลอยได้ ผมดำยาว ตาแดง มีไส้ห้อยระย้า
			K.sphere(model, 0.26, Vector3.ZERO, K.mat(Color(0.95, 0.88, 0.82), 0.25, 0.6), 14)
			K.sphere(model, 0.29, Vector3(0, 0.08, -0.12), K.mat(Color(0.06, 0.03, 0.06), 0.0, 0.4), 14, Vector3(1.05, 1.0, 0.9))
			K.box(model, Vector3(0.52, 0.5, 0.08), Vector3(0, -0.22, -0.2), K.mat(Color(0.06, 0.03, 0.06)))
			for x in [-0.09, 0.09]:
				K.sphere(model, 0.045, Vector3(x, 0.02, 0.23), K.mat(Color(1, 0.05, 0.05), 4.0), 6)
			K.box(model, Vector3(0.1, 0.02, 0.02), Vector3(0, -0.11, 0.24), K.mat(Color(0.5, 0.05, 0.08)))
			for i in 4:
				var d := Node3D.new()
				d.position = Vector3(-0.1 + i * 0.07, -0.2, 0.02)
				model.add_child(d)
				K.cyl(d, 0.025, 0.035, 0.45 + (i % 2) * 0.15, Vector3(0, -0.25, 0), K.mat(Color(0.75, 0.08, 0.15), 0.8, 0.4), 6)
				K.sphere(d, 0.06, Vector3(0, -0.5 - (i % 2) * 0.12, 0), K.mat(Color(0.85, 0.15, 0.25), 1.2, 0.4), 6)
				dangles.append(d)
		"phi_takiang":
			# ตะเกียงเรืองแสงมีหน้าตา
			K.cyl(model, 0.26, 0.3, 0.55, Vector3.ZERO, K.mat(c, 2.2, 0.5), 8)
			K.cyl(model, 0.18, 0.32, 0.12, Vector3(0, 0.34, 0), K.mat(Color(0.25, 0.15, 0.1)), 8)
			K.cyl(model, 0.32, 0.22, 0.1, Vector3(0, -0.32, 0), K.mat(Color(0.25, 0.15, 0.1)), 8)
			K.cyl(model, 0.03, 0.03, 0.25, Vector3(0, 0.5, 0), K.mat(Color(0.2, 0.2, 0.2)), 4)
			for x in [-0.1, 0.1]:
				K.sphere(model, 0.05, Vector3(x, 0.06, 0.27), K.mat(Color(0.05, 0.02, 0.02)), 6)
			K.box(model, Vector3(0.14, 0.04, 0.02), Vector3(0, -0.08, 0.29), K.mat(Color(0.05, 0.02, 0.02)))
		_:
			K.sphere(model, 0.3, Vector3.ZERO, K.mat(c, 1.0), 10)
	var light := OmniLight3D.new()
	light.light_color = c
	light.omni_range = 4.0
	light.light_energy = 0.0
	light.set_meta("base_energy", 1.6)
	light.add_to_group("night_light")
	model.add_child(light)
	K.label(self, data["name"], Vector3(0, 2.15, 0), Color(1, 0.88, 0.88), 34)
	_sync()


func _sync() -> void:
	position = K.to3d(pos)
	model.position.y = 1.25 + sin(bob) * 0.12
	for i in dangles.size():
		dangles[i].rotation.x = sin(bob * 1.3 + i) * 0.25
	model.scale = Vector3.ONE * (1.15 if flash > 0.0 else 1.0)
	if target != null and is_instance_valid(target):
		var d: Vector2 = target.pos - pos
		if d.length() > 1.0:
			model.rotation.y = lerp_angle(model.rotation.y, atan2(d.x, d.y), 0.2)


func take_damage(amount: int, attacker: Node3D) -> void:
	if not alive:
		return
	hp -= amount
	flash = 0.15
	target = attacker
	returning = false
	DamageText.spawn(get_parent(), position + Vector3(0, 2.0, 0), str(amount), Color.WHITE)
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

	if target != null:
		if pos.distance_to(target.pos) > data["attack_range"]:
			pos = pos.move_toward(target.pos, data["speed"] * 1.3 * delta)
		elif attack_cooldown <= 0.0:
			attack_cooldown = data["attack_interval"]
			target.take_damage(Combat.damage(data["atk"], target.stats["def"], "neutral", "none", rng))
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
