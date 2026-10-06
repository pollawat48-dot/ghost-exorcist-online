extends Node3D
## สัตว์เลี้ยงที่ออกมาเดินตามผู้เล่น (ใส่ในช่องแฟชั่น "สัตว์เลี้ยง") ช่วยตีผีและใช้สกิลเองอัตโนมัติ
## ความเก่งมาจากเลเวลและร่างของสัตว์เลี้ยง (shared/data/fashion.gd) ได้ EXP พร้อมเจ้าของ
## ผีไม่ตีสัตว์เลี้ยง (ดาเมจนับเป็นของเจ้าของ ผีจึงหันไปหาเจ้าของ)

const K = preload("res://maps/props/mesh_kit.gd")
const M = preload("res://maps/props/model_lib.gd")
const Critter = preload("res://maps/props/critter.gd")
const Fashion = preload("res://shared/data/fashion.gd")
const Combat = preload("res://shared/combat/combat.gd")
const Effect = preload("res://client/effect.gd")
const DamageText = preload("res://client/damage_text.gd")

const FOLLOW_OFFSET := Vector2(-38, 26)
const ASSIST_RADIUS := 260.0  ## ช่วยตีผีที่อยู่ใกล้เจ้าของในระยะนี้
const REACH := 34.0
const ATTACK_INTERVAL := 1.3
const TELEPORT_DIST := 420.0

var owner_player: Node3D
var species := "maa"
var pos := Vector2.ZERO
var target: Node3D = null
var attack_cd := 0.6
var skill_cd := 3.0
var rng := RandomNumberGenerator.new()
var model: Node3D
var visual: Node3D
var fx: Node3D
var label: Label3D
var _anim := ""
var _t := 0.0
var _stage := -1
var _hop := 0.0


func setup(p: Node3D, sp: String) -> void:
	owner_player = p
	species = sp
	pos = p.pos + FOLLOW_OFFSET
	rng.seed = hash(sp) + 99


func _ready() -> void:
	add_to_group("no_fade")
	rebuild()


func data() -> Dictionary:
	return Fashion.pet_data(owner_player.state, species)


func display_text() -> String:
	var d := data()
	return "Lv.%d %s" % [d["lv"], Fashion.pet_name(species, d["stage"])]


## สร้างโมเดลใหม่ (ตอนออกมา หรือพัฒนาร่าง)
func rebuild() -> void:
	var d := data()
	_stage = d["stage"]
	if visual != null:
		visual.queue_free()
	visual = Node3D.new()
	add_child(visual)
	var info: Array = Critter.KINDS[Fashion.PETS[species]["critter"]]
	var size: float = Fashion.PETS[species]["size"] * Fashion.STAGE_SCALE[_stage]
	model = M.spawn(visual, info[0], Vector3.ZERO, size)
	_anim = ""
	_play("idle")
	fx = Node3D.new()
	visual.add_child(fx)
	var c: Color = Fashion.STAGE_COLORS[_stage]
	if _stage >= 1:
		# ร่างที่ 2: วงแสงใต้เท้า + ลูกแก้วลอยรอบตัว
		var ring := TorusMesh.new()
		ring.inner_radius = 0.42 * Fashion.STAGE_SCALE[_stage]
		ring.outer_radius = 0.5 * Fashion.STAGE_SCALE[_stage]
		var mi := K.add(fx, ring, Vector3(0, 0.04, 0), K.mat(Color(c, 0.75), 2.2, 0.3, 0.0, false))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in 3:
			var a := i * TAU / 3.0
			var s := K.sphere(fx, 0.06, Vector3(cos(a) * 0.55, 0.5, sin(a) * 0.55), K.mat(c, 3.0, 0.3, 0.0, false), 6)
			s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _stage >= 2:
		# ร่างสุดท้าย: มงกุฎทองลอยเหนือหัว + ปีกแสงเล็กๆ
		var crown := Node3D.new()
		crown.position = Vector3(0, size + 0.3, 0)
		fx.add_child(crown)
		var halo := TorusMesh.new()
		halo.inner_radius = 0.16
		halo.outer_radius = 0.21
		K.add(crown, halo, Vector3.ZERO, K.mat(Color(1.0, 0.85, 0.35), 2.5, 0.3, 0.0, false))
		for sgn in [-1.0, 1.0]:
			var wing := K.sphere(fx, 0.22, Vector3(sgn * (size * 0.55 + 0.1), size * 0.75, -0.1), K.mat(Color(1.0, 0.85, 0.45, 0.85), 1.6, 0.3, 0.0, false), 8, Vector3(1.4, 0.7, 0.25))
			wing.rotation.z = sgn * 0.5
			wing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if label == null:
		label = K.label(self, "", Vector3(0, 1.0, 0), Color(1, 0.95, 0.75), 26)
	label.position.y = size + 0.55 + (0.35 if _stage >= 2 else 0.0)
	label.modulate = c.lerp(Color.WHITE, 0.4)
	label.text = display_text()
	position = K.to3d(pos)


func refresh_label() -> void:
	if label != null:
		label.text = display_text()


func _play(anim: String) -> void:
	if anim == _anim or model == null:
		return
	_anim = anim
	M.play(model, anim, 1.0)


func speed() -> float:
	return owner_player.speed() * 1.15 * Fashion.PETS[species]["speed"]


## ทุกเฟรม (player.tick เรียก): เดินตาม เลือกเป้า ตี ใช้สกิล
func tick(delta: float) -> void:
	_t += delta
	attack_cd = maxf(0.0, attack_cd - delta)
	skill_cd = maxf(0.0, skill_cd - delta)
	_hop = maxf(0.0, _hop - delta)
	if data()["stage"] != _stage:
		rebuild()
	if pos.distance_to(owner_player.pos) > TELEPORT_DIST:
		pos = owner_player.pos + FOLLOW_OFFSET
		target = null
	if owner_player.hp <= 0:
		target = null
	else:
		_pick_target()
	var moving := false
	if target != null:
		var d := pos.distance_to(target.pos)
		if d > REACH:
			moving = _move_to(target.pos, delta)
		else:
			_face(target.pos - pos)
			if skill_cd <= 0.0 and (Fashion.PETS[species]["skill"]["kind"] != "heal" or owner_player.hp < owner_player.stats["max_hp"] * 0.85):
				_use_skill()
			elif attack_cd <= 0.0:
				attack_cd = ATTACK_INTERVAL
				_hop = 0.25
				_hit(target, 1.0, "neutral")
	else:
		var home: Vector2 = owner_player.pos + FOLLOW_OFFSET
		if pos.distance_to(home) > 24.0:
			moving = _move_to(home, delta)
		if skill_cd <= 0.0 and Fashion.PETS[species]["skill"]["kind"] == "heal" and owner_player.hp > 0 \
				and owner_player.hp < owner_player.stats["max_hp"] * 0.7:
			_use_skill()
	_play("walk" if moving else "idle")
	position = K.to3d(pos)
	if visual != null:
		visual.position.y = sin(_hop / 0.25 * PI) * 0.25 if _hop > 0.0 else 0.0
	if fx != null:
		fx.rotation.y += delta * 1.6


func _pick_target() -> void:
	if target != null and (not is_instance_valid(target) or not target.alive \
			or target.pos.distance_to(owner_player.pos) > ASSIST_RADIUS + 80.0):
		target = null
	var own = owner_player.attack_target
	if own != null and is_instance_valid(own) and own.alive:
		target = own
		return
	if target != null:
		return
	# ผีที่กำลังไล่ตีเจ้าของ
	var best: Node3D = null
	var best_d := ASSIST_RADIUS
	for g in owner_player.ghosts.get_children():
		if g.has_method("take_damage") and g.alive and g.target == owner_player:
			var d: float = g.pos.distance_to(owner_player.pos)
			if d < best_d:
				best = g
				best_d = d
	target = best


func _move_to(dest: Vector2, delta: float) -> bool:
	var to := dest - pos
	var step := speed() * delta
	if to.length() <= step:
		pos = dest
		return false
	pos += to.normalized() * step
	_face(to)
	return true


func _face(dir: Vector2) -> void:
	if dir.length() > 0.001 and visual != null:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(dir.x, dir.y), 0.3)


func atk() -> int:
	var d := data()
	return Fashion.pet_atk(species, d["lv"], d["stage"])


func _hit(g: Node3D, power: float, element: String) -> void:
	if g == null or not is_instance_valid(g) or not g.alive:
		return
	var dmg := Combat.damage(atk(), g.data["def"], element, g.data["element"], rng, power)
	g.take_damage(dmg, owner_player, false)


func _use_skill() -> void:
	var sk: Dictionary = Fashion.PETS[species]["skill"]
	skill_cd = sk["cooldown"]
	_hop = 0.25
	var c: Color = Fashion.STAGE_COLORS[data()["stage"]]
	var parent := get_parent()
	DamageText.spawn(parent, position + Vector3(0, 1.6, 0), sk["name"] + "!", c.lerp(Color(1, 0.6, 0.8), 0.3))
	match sk["kind"]:
		"bite":
			_hit(target, sk["power"], "neutral")
			Effect.ring(parent, target.global_position, 0.7, c, 0.3)
		"combo":
			for i in int(sk["hits"]):
				_hit(target, sk["power"], "neutral")
			Effect.ring(parent, target.global_position, 0.6, c, 0.3)
		"aoe", "holy":
			var center: Vector2 = pos if sk["kind"] == "aoe" else target.pos
			var element := "holy" if sk["kind"] == "holy" else "neutral"
			for g in owner_player.ghosts.get_children():
				if g.has_method("take_damage") and g.alive and g.pos.distance_to(center) <= sk["radius"]:
					_hit(g, sk["power"], element)
			if sk["kind"] == "holy":
				Effect.pillar(parent, K.to3d(center), 0.7, Color(0.7, 0.92, 1.0))
			Effect.ring(parent, K.to3d(center), sk["radius"] / 32.0, c)
		"heal":
			var amount := int(owner_player.stats["max_hp"] * sk["power"] * Fashion.STAGE_MULT[data()["stage"]])
			owner_player.receive_heal(amount)
			Effect.ring(parent, owner_player.position, 1.1, Color(0.6, 1.0, 0.7))
