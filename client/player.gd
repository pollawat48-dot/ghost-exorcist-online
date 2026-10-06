extends Node3D
## ตัวละครผู้เล่น: คลิกเพื่อเดิน, คลิกผีเพื่อโจมตี, ใช้สกิล, อัปสเตตัส, สวมของ, เปลี่ยนคลาส
## ตรรกะใช้ pos (หน่วยเกมบนพื้นราบ) ส่วนโมเดล 3D ตามตำแหน่งนั้น
## ตอน M1 คำนวณในเครื่อง ภายหลังผลการต่อสู้จะมาจาก zone server

const K = preload("res://maps/props/mesh_kit.gd")
const Combat = preload("res://shared/combat/combat.gd")
const Progression = preload("res://shared/combat/progression.gd")
const Classes = preload("res://shared/data/classes.gd")
const Skills = preload("res://shared/data/skills.gd")
const ItemDB = preload("res://shared/data/items.gd")
const Quests = preload("res://shared/data/quests.gd")
const DamageText = preload("res://client/damage_text.gd")
const Effect = preload("res://client/effect.gd")

signal changed
signal message(text: String)
signal class_changed(class_id: String)

const SPEED := 140.0
const REGEN_INTERVAL := 3.0
const REPATH_INTERVAL := 0.4
const HERB_ITEM := "herb_potion"
const SP_ITEM := "nam_mon"
## ยาเลือด/ยามานาเรียงจากเล็กไปใหญ่ (กดปุ่มยาแล้วเลือกขวดที่เหมาะกับที่ขาดอยู่)
const HP_POTIONS := ["herb_potion", "ya_hom_thong"]
const SP_POTIONS := ["nam_mon", "nam_mon_yai"]
const POTION_COOLDOWN := 0.6
const SHOT_COLORS := {"neutral": Color(1, 0.95, 0.8), "holy": Color(0.6, 0.9, 1.0), "fire": Color(1.0, 0.55, 0.3)}

var player_name := "ศิษย์วัด"
var state := Progression.new_state()
var stats := {}
var hp := 0
var sp := 0
var inventory := {}
var pos := Vector2.ZERO
var bounds := Rect2()
var spawn_point := Vector2.ZERO
var ghosts: Node
var nav: Node3D  ## แผนที่ที่มี find_path()

var stick := Vector2.ZERO  ## ทิศจากจอยบนจอ (มือถือ) หรือคีย์บอร์ด ในหน่วยพื้นราบ ยาวไม่เกิน 1
var path := PackedVector2Array()
var path_index := 0
var moving := false
var repath_timer := 0.0
var attack_target: Node3D = null
var pending_skill := ""  ## สกิลที่รอเดินเข้าระยะก่อนร่าย
var attack_cooldown := 0.0
var skill_cd := {}  ## id -> วินาทีที่เหลือ
var guard_timer := 0.0  ## อาคมคงกระพัน
var guard_bonus := 0.0
var potion_cd := 0.0
var regen_timer := 0.0
var swing := 0.0
var levelup_fx := 0.0
var flash := 0.0
var walk_t := 0.0
var rng := RandomNumberGenerator.new()
var model: Node3D
var body: Node3D
var weapon: Node3D
var aura: Node3D
var name_label: Label3D
var levelup_beam: MeshInstance3D


func _ready() -> void:
	recalc()
	hp = stats["max_hp"]
	sp = stats["max_sp"]
	inventory[HERB_ITEM] = 5
	inventory[SP_ITEM] = 3
	_build_model()
	_build_fx()
	_sync(0.0)


## คำนวณค่าพลังใหม่ (หลังอัปสเตตัส สวมของ เปลี่ยนคลาส หรือบัฟหมด)
func recalc() -> void:
	stats = Progression.derive(state)
	if guard_timer > 0.0:
		stats["def"] = int(stats["def"] * (1.0 + guard_bonus))
	hp = mini(hp, stats["max_hp"])
	sp = mini(sp, stats["max_sp"])


func class_info() -> Dictionary:
	return Classes.CLASSES[state["class"]]


# ---------- รูปร่างตัวละคร (เปลี่ยนตามคลาส) ----------

func _build_model() -> void:
	if model != null:
		model.queue_free()
	if name_label != null:
		name_label.queue_free()
	var look: Dictionary = class_info()["look"]
	var tier: int = class_info()["tier"]
	model = Node3D.new()
	add_child(model)
	body = Node3D.new()
	model.add_child(body)
	# ตัวจิบิ: หัวโต ตัวเล็ก ตาโตมีประกาย แก้มแดง
	var robe := K.mat(look["robe"], 0.0, 0.8)
	var sash := K.mat(look["sash"])
	var skin := K.mat(Color(1.0, 0.86, 0.74), 0.0, 0.7)
	var hair := K.mat(Color(0.36, 0.25, 0.24), 0.0, 0.6)
	var eye := K.mat(Color(0.2, 0.13, 0.16), 0.0, 0.3, 0.0, false)
	var shine := K.mat(Color(1, 1, 1), 1.5, 0.3, 0.0, false)
	var blush := K.mat(Color(1.0, 0.6, 0.65), 0.3, 0.8, 0.0, false)
	for x in [-0.1, 0.1]:
		K.sphere(body, 0.09, Vector3(x, 0.07, 0.03), K.mat(Color(0.62, 0.42, 0.36)), 8, Vector3(1, 0.7, 1.3))
	K.cyl(body, 0.17, 0.3, 0.55, Vector3(0, 0.38, 0), robe, 14)
	K.beam(body, Vector3(-0.18, 0.62, 0.14), Vector3(0.2, 0.3, 0.17), 0.07, sash)
	if tier >= 1:
		# ขั้น 1 ขึ้นไป: เข็มขัดและปกเสื้อ
		K.cyl(body, 0.27, 0.27, 0.07, Vector3(0, 0.33, 0), sash, 14)
		K.cyl(body, 0.2, 0.2, 0.06, Vector3(0, 0.64, 0), K.mat(look["sash"].lightened(0.3)), 14)
	if look["cape"]:
		K.box(body, Vector3(0.5, 0.6, 0.05), Vector3(0, 0.36, -0.26), K.mat(look["sash"].darkened(0.15)), Vector3(0.18, 0, 0))
	for x in [-0.27, 0.27]:
		K.sphere(body, 0.08, Vector3(x, 0.42, 0.04), skin, 8)
	var head := Node3D.new()
	head.position = Vector3(0, 1.0, 0)
	head.rotation.x = -0.25  # เงยหน้าเล็กน้อยให้เห็นหน้าจากกล้องมุมสูง
	body.add_child(head)
	K.sphere(head, 0.4, Vector3.ZERO, skin, 18)
	K.sphere(head, 0.41, Vector3(0, 0.15, -0.11), hair, 18, Vector3(1.0, 0.78, 1.0))
	for x in [-0.15, 0.15]:
		K.sphere(head, 0.095, Vector3(x, 0.0, 0.34), eye, 10, Vector3(0.85, 1.25, 0.5))
		K.sphere(head, 0.035, Vector3(x + 0.03, 0.06, 0.39), shine, 6)
		K.sphere(head, 0.065, Vector3(x * 1.55, -0.11, 0.32), blush, 8, Vector3(1.2, 0.6, 0.4))
	K.sphere(head, 0.03, Vector3(0, -0.15, 0.38), K.mat(Color(0.85, 0.4, 0.42), 0.0, 0.8, 0.0, false), 6, Vector3(1.4, 0.7, 0.6))
	_build_hat(head, look)
	weapon = Node3D.new()
	body.add_child(weapon)
	_build_weapon(look)
	aura = null
	if look["aura"]:
		aura = Node3D.new()
		model.add_child(aura)
		var torus := TorusMesh.new()
		torus.inner_radius = 0.6
		torus.outer_radius = 0.7
		var glow := K.mat(Color(look["sash"], 0.8), 2.5, 0.3, 0.0, false)
		K.add(aura, torus, Vector3(0, 0.05, 0), glow)
		for i in 3:
			var a := i * TAU / 3.0
			K.sphere(aura, 0.07, Vector3(cos(a) * 0.65, 0.6, sin(a) * 0.65), K.mat(look["sash"], 3.0, 0.3, 0.0, false), 6)
	name_label = K.label(self, player_name, Vector3(0, 2.15 + (0.2 if look["hat"] == "crown" else 0.0), 0), Color(1, 0.97, 0.88), 36)


func _build_hat(head: Node3D, look: Dictionary) -> void:
	var hair := K.mat(Color(0.36, 0.25, 0.24), 0.0, 0.6)
	match look["hat"]:
		"":
			K.sphere(head, 0.1, Vector3(0, 0.46, -0.12), hair, 10)
		"headband":
			var band := TorusMesh.new()
			band.inner_radius = 0.38
			band.outer_radius = 0.44
			K.add(head, band, Vector3(0, 0.14, -0.02), K.mat(look["sash"]), Vector3(-0.15, 0, 0))
			K.box(head, Vector3(0.06, 0.28, 0.04), Vector3(0.1, 0.0, -0.42), K.mat(look["sash"]), Vector3(0.3, 0, 0.3))
			K.box(head, Vector3(0.06, 0.24, 0.04), Vector3(-0.05, 0.0, -0.43), K.mat(look["sash"]), Vector3(0.3, 0, -0.2))
		"hat_wide":
			K.cyl(head, 0.05, 0.62, 0.26, Vector3(0, 0.42, -0.04), K.mat(Color(1.0, 0.86, 0.55)), 16)
			K.cyl(head, 0.32, 0.32, 0.05, Vector3(0, 0.33, -0.04), K.mat(look["sash"]), 16)
		"topknot":
			K.sphere(head, 0.14, Vector3(0, 0.5, -0.1), hair, 10)
			K.cyl(head, 0.015, 0.015, 0.4, Vector3(0, 0.55, -0.1), K.gold(), 4, Vector3(0, 0, PI / 2.0))
			K.sphere(head, 0.05, Vector3(0.2, 0.55, -0.1), K.mat(look["sash"]), 6)
		"hood":
			K.sphere(head, 0.46, Vector3(0, 0.08, -0.08), K.mat(look["robe"].darkened(0.15)), 18, Vector3(1.0, 1.0, 1.0))
			K.cyl(head, 0.01, 0.12, 0.25, Vector3(0, 0.55, -0.2), K.mat(look["robe"].darkened(0.15)), 8, Vector3(-0.6, 0, 0))
		"crown":
			# ชฎาทองแบบไทย ทรงสอบขึ้นเป็นยอดแหลม
			K.sphere(head, 0.1, Vector3(0, 0.46, -0.12), hair, 10)
			K.cyl(head, 0.3, 0.34, 0.12, Vector3(0, 0.36, -0.03), K.gold(), 16)
			K.cyl(head, 0.16, 0.26, 0.2, Vector3(0, 0.52, -0.03), K.gold(), 14)
			K.cyl(head, 0.02, 0.15, 0.36, Vector3(0, 0.79, -0.03), K.gold(), 12)
			K.sphere(head, 0.05, Vector3(0, 0.36, 0.31), K.mat(Color(1.0, 0.4, 0.5), 1.2), 6)


func _build_weapon(look: Dictionary) -> void:
	match look["weapon"]:
		"staff", "orb_staff":
			weapon.position = Vector3(0.3, 0.45, 0.06)
			K.cyl(weapon, 0.03, 0.03, 1.1, Vector3(0, 0.25, 0), K.mat(Color(0.78, 0.55, 0.38)), 6)
			if look["weapon"] == "orb_staff":
				K.sphere(weapon, 0.17, Vector3(0, 0.95, 0), K.mat(look["sash"], 2.5, 0.3, 0.0, false), 12)
				var ring := TorusMesh.new()
				ring.inner_radius = 0.2
				ring.outer_radius = 0.24
				K.add(weapon, ring, Vector3(0, 0.95, 0), K.gold(), Vector3(PI / 2.0, 0, 0))
			else:
				K.sphere(weapon, 0.09, Vector3(0, 0.85, 0), K.gold(), 10)
		"sword", "great_sword":
			var big: bool = look["weapon"] == "great_sword"
			var len := 1.0 if big else 0.75
			weapon.position = Vector3(0.3, 0.42, 0.1)
			K.cyl(weapon, 0.035, 0.035, 0.22, Vector3(0, -0.05, 0), K.mat(Color(0.6, 0.38, 0.32)), 6)
			K.box(weapon, Vector3(0.28, 0.06, 0.08), Vector3(0, 0.08, 0), K.gold())
			var blade := K.mat(Color(0.88, 0.92, 1.0), 1.0 if big else 0.0, 0.3)
			K.box(weapon, Vector3(0.09 if big else 0.07, len, 0.025), Vector3(0, 0.1 + len / 2.0, 0), blade)
			K.box(weapon, Vector3(0.05, 0.1, 0.025), Vector3(0, 0.14 + len, 0), blade, Vector3(0, 0, PI / 4.0))
		"bow", "great_bow":
			var big: bool = look["weapon"] == "great_bow"
			var h := 0.75 if big else 0.6
			weapon.position = Vector3(-0.32, 0.5, 0.08)
			var wood := K.mat(Color(0.5, 0.35, 0.55) if big else Color(0.75, 0.52, 0.36))
			var pts := [Vector3(0, -h, -0.05), Vector3(0, -h * 0.5, 0.12), Vector3(0, 0, 0.17), Vector3(0, h * 0.5, 0.12), Vector3(0, h, -0.05)]
			for i in 4:
				K.beam(weapon, pts[i], pts[i + 1], 0.05, wood)
			K.beam(weapon, pts[0], pts[4], 0.012, K.mat(Color(1, 1, 1), 0.0, 0.8, 0.0, false))
			if big:
				for tip in [pts[0], pts[4]]:
					K.sphere(weapon, 0.06, tip, K.mat(look["sash"], 3.0, 0.3, 0.0, false), 6)
			# กระบอกลูกธนูที่หลัง
			K.cyl(body, 0.08, 0.08, 0.45, Vector3(0.12, 0.6, -0.26), K.mat(Color(0.7, 0.5, 0.38)), 8, Vector3(0.3, 0, -0.3))
		"book":
			weapon.position = Vector3(0.38, 0.6, 0.12)
			K.box(weapon, Vector3(0.28, 0.06, 0.34), Vector3.ZERO, K.mat(Color(0.75, 0.3, 0.35)), Vector3(0.4, 0, 0))
			K.box(weapon, Vector3(0.24, 0.07, 0.3), Vector3(0, 0.01, 0), K.mat(Color(1.0, 0.96, 0.85)), Vector3(0.4, 0, 0))
			for i in 2:
				K.box(weapon, Vector3(0.1, 0.2, 0.01), Vector3(-0.1 + i * 0.2, 0.3, 0), K.mat(Color(1.0, 0.9, 0.5), 1.2, 0.5, 0.0, false), Vector3(0, 0, (i - 0.5) * 0.4))


func _build_fx() -> void:
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.6
	beam_mesh.bottom_radius = 0.9
	beam_mesh.height = 6.0
	levelup_beam = MeshInstance3D.new()
	levelup_beam.mesh = beam_mesh
	levelup_beam.position.y = 3.0
	levelup_beam.material_override = K.mat(Color(1, 0.9, 0.5, 0.35), 2.5, 0.5, 0.0, false)
	levelup_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	levelup_beam.visible = false
	add_child(levelup_beam)


## ขยับโมเดลให้ตรงกับตรรกะ: ตำแหน่ง, ทิศที่หัน, ท่าเดิน/ตี, เอฟเฟกต์
func _sync(delta: float) -> void:
	var prev := position
	position = K.to3d(pos)
	var move := Vector2(position.x - prev.x, position.z - prev.z)
	var facing := move
	if attack_target != null and is_instance_valid(attack_target):
		facing = attack_target.pos - pos
	if facing.length() > 0.001:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(facing.x, facing.y), 0.3)
	if move.length() > 0.001:
		walk_t += delta * 10.0
		body.position.y = absf(sin(walk_t)) * 0.06
		body.rotation.z = sin(walk_t) * 0.04
	else:
		body.position.y = lerpf(body.position.y, 0.0, 0.3)
		body.rotation.z = 0.0
	weapon.rotation.x = -sin((0.2 - swing) / 0.2 * PI) * 1.3 if swing > 0.0 else 0.0
	if aura != null:
		aura.rotation.y += delta * 1.5
	levelup_beam.visible = levelup_fx > 0.0
	if levelup_fx > 0.0:
		levelup_beam.scale = Vector3(1, levelup_fx / 1.2, 1)
	model.scale = Vector3.ONE * (1.08 if flash > 0.0 else 1.0)


# ---------- คำสั่งจากผู้เล่น ----------

func command_move(dest: Vector2) -> void:
	attack_target = null
	pending_skill = ""
	_set_path(Vector2(
		clampf(dest.x, bounds.position.x, bounds.end.x),
		clampf(dest.y, bounds.position.y, bounds.end.y)))


func command_attack(ghost: Node3D) -> void:
	attack_target = ghost
	pending_skill = ""
	moving = false
	repath_timer = 0.0


func tick(delta: float) -> void:
	if hp <= 0:
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	potion_cd = maxf(0.0, potion_cd - delta)
	for id in skill_cd.keys():
		skill_cd[id] = maxf(0.0, skill_cd[id] - delta)
	if guard_timer > 0.0:
		guard_timer -= delta
		if guard_timer <= 0.0:
			recalc()
			message.emit("อาคมคงกระพันหมดฤทธิ์")
			changed.emit()
	swing = maxf(0.0, swing - delta)
	levelup_fx = maxf(0.0, levelup_fx - delta)
	flash = maxf(0.0, flash - delta)
	_regen(delta)

	if attack_target != null and (not is_instance_valid(attack_target) or not attack_target.alive):
		attack_target = null
		pending_skill = ""
	if stick.length() > 0.15:
		attack_target = null
		pending_skill = ""
		moving = false
		_walk_dir(stick.limit_length(1.0) * SPEED * delta)
	elif attack_target != null:
		var reach: float = stats["range"]
		if pending_skill != "":
			reach = maxf(Skills.SKILLS[pending_skill]["range"], 40.0)
		if pos.distance_to(attack_target.pos) > reach:
			repath_timer -= delta
			if repath_timer <= 0.0 or not moving:
				repath_timer = REPATH_INTERVAL
				_set_path(attack_target.pos)
			_follow_path(delta)
		elif pending_skill != "":
			moving = false
			# ถึงระยะแล้ว รอคูลดาวน์หมดก่อนร่าย
			if skill_cd.get(pending_skill, 0.0) <= 0.0:
				var id := pending_skill
				pending_skill = ""
				use_skill(id, attack_target)
		elif attack_cooldown <= 0.0:
			moving = false
			attack_cooldown = stats["attack_interval"]
			_basic_attack(attack_target)
	elif moving:
		_follow_path(delta)
	if model != null:
		_sync(delta)


func _basic_attack(ghost: Node3D) -> void:
	swing = 0.2
	var kind: String = stats["attack"]
	var stat := "matk" if kind == "magic" else "atk"
	_hit(ghost, stat, 1.0, "neutral")
	if kind == "ranged":
		Effect.shot(get_parent(), position + Vector3(0, 0.8, 0), ghost.global_position + Vector3(0, 1.2, 0), "arrow", SHOT_COLORS["neutral"])
	elif kind == "magic":
		Effect.shot(get_parent(), position + Vector3(0, 1.0, 0), ghost.global_position + Vector3(0, 1.2, 0), "orb", Color(0.85, 0.6, 1.0))


## ดาเมจใส่ผีหนึ่งตัว มีโอกาสคริติคอลตาม LUK
func _hit(ghost: Node3D, stat: String, power: float, element: String) -> void:
	var crit: bool = rng.randf() < stats["crit"]
	var dmg := Combat.damage(stats[stat], ghost.data["def"], element, ghost.data["element"], rng, power * (1.5 if crit else 1.0))
	ghost.take_damage(dmg, self, crit)


func _walk_dir(step: Vector2) -> void:
	for candidate in [pos + step, pos + Vector2(step.x, 0), pos + Vector2(0, step.y)]:
		var c: Vector2 = candidate
		c = Vector2(clampf(c.x, bounds.position.x, bounds.end.x), clampf(c.y, bounds.position.y, bounds.end.y))
		if nav == null or (nav.is_walkable(c) and not nav.is_water(c)):
			pos = c
			return


func _set_path(dest: Vector2) -> void:
	path = nav.find_path(pos, dest) if nav != null else PackedVector2Array([dest])
	path_index = 0
	moving = not path.is_empty()


func _follow_path(delta: float) -> void:
	var step := SPEED * delta
	while step > 0.0 and path_index < path.size():
		var waypoint := path[path_index]
		var d := pos.distance_to(waypoint)
		if d <= step:
			pos = waypoint
			step -= d
			path_index += 1
		else:
			pos = pos.move_toward(waypoint, step)
			step = 0.0
	if path_index >= path.size():
		moving = false


# ---------- สกิล ----------

func skill_level(id: String) -> int:
	return state["skills"].get(id, 0)


## สกิลที่คลาสนี้ (รวมคลาสก่อนหน้า) เรียนได้
func available_skills() -> Array[String]:
	return Skills.for_lineage(Classes.lineage(state["class"]))


## สกิลที่เรียนแล้ว เรียงตามลำดับในสาย (ใช้จัดลงแถบสกิล)
func learned_skills() -> Array[String]:
	var result: Array[String] = []
	for id in available_skills():
		if skill_level(id) > 0:
			result.append(id)
	return result


func learn_skill(id: String) -> bool:
	if not id in available_skills() or state["skill_points"] <= 0 or skill_level(id) >= Skills.MAX_LEVEL:
		return false
	state["skill_points"] -= 1
	state["skills"][id] = skill_level(id) + 1
	message.emit("%s เลเวล %d" % [Skills.SKILLS[id]["name"], skill_level(id)])
	changed.emit()
	return true


func skill_cooldown_ratio(id: String) -> float:
	var cd: float = Skills.SKILLS[id]["cooldown"]
	return clampf(skill_cd.get(id, 0.0) / cd, 0.0, 1.0)


## ใช้สกิล: ถ้าเป้าอยู่ไกลจะเดินเข้าไปก่อนแล้วร่ายเอง
func use_skill(id: String, target: Node3D = null) -> bool:
	if hp <= 0 or not Skills.SKILLS.has(id):
		return false
	var lv := skill_level(id)
	if lv <= 0:
		return false
	var sk: Dictionary = Skills.SKILLS[id]
	var cost := Skills.sp_cost(id, lv)
	if sp < cost:
		message.emit("SP ไม่พอสำหรับ%s" % sk["name"])
		return false
	var kind: String = sk["kind"]
	if kind == "single" or kind == "aoe_target":
		if target == null:
			target = attack_target
		if target == null or not is_instance_valid(target) or not target.alive:
			target = _nearest_ghost(maxf(sk["range"], 40.0) + 200.0)
		if target == null:
			message.emit("ไม่มีผีให้ใช้%s" % sk["name"])
			return false
		if pos.distance_to(target.pos) > maxf(sk["range"], 40.0):
			attack_target = target
			pending_skill = id
			moving = false
			repath_timer = 0.0
			return true
	if skill_cd.get(id, 0.0) > 0.0:
		return false
	sp -= cost
	skill_cd[id] = sk["cooldown"]
	swing = 0.2
	var power := Skills.power(id, lv)
	var color: Color = SHOT_COLORS.get(sk["element"], Color.WHITE)
	match kind:
		"aoe_self":
			var r := Skills.radius(id, lv)
			var hit := _hit_area(pos, r, sk["stat"], power, sk["element"])
			Effect.ring(get_parent(), position, r / 32.0, color)
			message.emit("%s! โดนผี %d ตัว" % [sk["name"], hit])
		"single":
			_hit(target, sk["stat"], power, sk["element"])
			attack_target = target
			var shot_kind := "arrow" if stats["attack"] == "ranged" else "orb"
			if sk["range"] > 60.0:
				Effect.shot(get_parent(), position + Vector3(0, 0.9, 0), target.global_position + Vector3(0, 1.2, 0), shot_kind, color)
			Effect.ring(get_parent(), target.global_position, 0.8, color, 0.3)
		"aoe_target":
			var r := Skills.radius(id, lv)
			var center: Vector2 = target.pos
			var hit := _hit_area(center, r, sk["stat"], power, sk["element"])
			attack_target = target
			Effect.pillar(get_parent(), K.to3d(center), 0.8, color)
			Effect.ring(get_parent(), K.to3d(center), r / 32.0, color)
			message.emit("%s! โดนผี %d ตัว" % [sk["name"], hit])
		"buff":
			guard_bonus = power
			guard_timer = sk["duration"]
			recalc()
			Effect.ring(get_parent(), position, 1.2, Color(1.0, 0.85, 0.4))
			message.emit("%s! DEF เพิ่ม %d%%" % [sk["name"], int(power * 100)])
		"heal":
			var amount := int(stats["matk"] * power)
			hp = mini(stats["max_hp"], hp + amount)
			Effect.ring(get_parent(), position, 1.2, Color(0.5, 1.0, 0.6))
			DamageText.spawn(get_parent(), position + Vector3(0, 2.4, 0), "+%d" % amount, Color(0.4, 1, 0.4))
	changed.emit()
	return true


func _hit_area(center: Vector2, r: float, stat: String, power: float, element: String) -> int:
	var hit := 0
	for g in ghosts.get_children():
		if g.has_method("take_damage") and g.alive and center.distance_to(g.pos) <= r:
			_hit(g, stat, power, element)
			hit += 1
	return hit


func _nearest_ghost(radius: float) -> Node3D:
	var best: Node3D = null
	var best_dist := radius
	for g in ghosts.get_children():
		if g.has_method("take_damage") and g.alive and pos.distance_to(g.pos) < best_dist:
			best = g
			best_dist = pos.distance_to(g.pos)
	return best


## สกิลแรกของศิษย์วัด (คงไว้ให้ปุ่มลัด/โค้ดเดิมเรียกได้)
func cast_holy_water() -> bool:
	return use_skill("holy_water")


# ---------- สเตตัส คลาส ของสวมใส่ ----------

func add_stat(key: String) -> bool:
	if state["stat_points"] <= 0 or not key in Progression.STATS:
		return false
	state["stat_points"] -= 1
	state["base"][key] += 1
	var old_max_hp: int = stats["max_hp"]
	var old_max_sp: int = stats["max_sp"]
	recalc()
	hp += maxi(0, stats["max_hp"] - old_max_hp)
	sp += maxi(0, stats["max_sp"] - old_max_sp)
	changed.emit()
	return true


func can_change_class() -> bool:
	var need := Classes.change_level(state["class"])
	return need > 0 and state["level"] >= need


func change_class(class_id: String) -> bool:
	if not can_change_class() or not class_id in Classes.next_classes(state["class"]):
		return false
	state["class"] = class_id
	# ของที่สายใหม่ใช้ไม่ได้ให้ถอดเก็บเข้ากระเป๋า
	for slot in state["equipment"].keys():
		if not can_equip(state["equipment"][slot]):
			unequip(slot)
	recalc()
	hp = stats["max_hp"]
	sp = stats["max_sp"]
	levelup_fx = 1.2
	_build_model()
	message.emit("เปลี่ยนคลาสเป็น %s แล้ว!" % class_info()["name"])
	class_changed.emit(class_id)
	changed.emit()
	return true


func can_equip(item_id: String) -> bool:
	var item: Dictionary = ItemDB.ITEMS.get(item_id, {})
	if item.get("type", "") != "equip":
		return false
	return item["line"] == "any" or item["line"] == class_info()["line"]


func equip(item_id: String) -> bool:
	if inventory.get(item_id, 0) <= 0:
		return false
	if not can_equip(item_id):
		message.emit("คลาสนี้ใช้ %s ไม่ได้" % ItemDB.ITEMS[item_id]["name"])
		return false
	var slot: String = ItemDB.ITEMS[item_id]["slot"]
	if state["equipment"].has(slot):
		unequip(slot)
	_remove_item(item_id)
	state["equipment"][slot] = item_id
	recalc()
	message.emit("สวม %s" % ItemDB.ITEMS[item_id]["name"])
	changed.emit()
	return true


func unequip(slot: String) -> bool:
	if not state["equipment"].has(slot):
		return false
	var item_id: String = state["equipment"][slot]
	state["equipment"].erase(slot)
	inventory[item_id] = inventory.get(item_id, 0) + 1
	recalc()
	changed.emit()
	return true


# ---------- ไอเทม ความเสียหาย เลเวล ----------

## ยาเลือดขวดที่เหมาะ: ขาดเลือดเยอะใช้ขวดใหญ่ ขาดน้อยใช้ขวดเล็ก (ถ้ามี)
func pick_potion(kind: String) -> String:
	var list: Array = HP_POTIONS if kind == "hp" else SP_POTIONS
	var missing: int = (stats["max_hp"] - hp) if kind == "hp" else (stats["max_sp"] - sp)
	var key := "heal" if kind == "hp" else "sp"
	var best := ""
	for id in list:
		if inventory.get(id, 0) <= 0:
			continue
		if best == "" or ItemDB.ITEMS[best][key] < missing * 0.6:
			best = id
	return best


func potion_count(kind: String) -> int:
	var n := 0
	for id in (HP_POTIONS if kind == "hp" else SP_POTIONS):
		n += inventory.get(id, 0)
	return n


func use_potion(kind: String) -> bool:
	var id := pick_potion(kind)
	if id == "":
		message.emit("ไม่มี%sเหลือแล้ว" % ("ยาเพิ่มเลือด" if kind == "hp" else "น้ำมนต์เพิ่ม SP"))
		return false
	return use_item(id)


func use_herb() -> bool:
	return use_potion("hp")


## ใช้ยา: เพิ่ม HP/SP ตามขวด +10% ของค่าสูงสุด
func use_item(item_id: String) -> bool:
	if hp <= 0 or inventory.get(item_id, 0) <= 0 or potion_cd > 0.0:
		return false
	var item: Dictionary = ItemDB.ITEMS[item_id]
	if item["type"] != "consumable":
		return false
	var heal: int = item.get("heal", 0)
	var mana: int = item.get("sp", 0)
	if (heal == 0 or hp >= stats["max_hp"]) and (mana == 0 or sp >= stats["max_sp"]):
		return false
	_remove_item(item_id)
	potion_cd = POTION_COOLDOWN
	if heal > 0:
		heal += stats["max_hp"] / 10
		hp = mini(stats["max_hp"], hp + heal)
		DamageText.spawn(get_parent(), position + Vector3(0, 2.4, 0), "+%d" % heal, Color(0.4, 1, 0.4))
	if mana > 0:
		mana += stats["max_sp"] / 10
		sp = mini(stats["max_sp"], sp + mana)
		DamageText.spawn(get_parent(), position + Vector3(0, 2.0, 0), "+%d SP" % mana, Color(0.5, 0.75, 1.0))
	changed.emit()
	return true


# ---------- เงิน ร้านค้า ----------

func coins() -> int:
	return state["coins"]


func buy(item_id: String, count: int = 1) -> bool:
	var price: int = ItemDB.ITEMS[item_id].get("buy", 0) * count
	if price <= 0 or count <= 0:
		return false
	if state["coins"] < price:
		message.emit("เหรียญไม่พอ (ต้องใช้ %d)" % price)
		return false
	state["coins"] -= price
	inventory[item_id] = inventory.get(item_id, 0) + count
	message.emit("ซื้อ %s x%d (-%d เหรียญ)" % [ItemDB.ITEMS[item_id]["name"], count, price])
	changed.emit()
	return true


func sell(item_id: String, count: int = 1) -> bool:
	count = mini(count, inventory.get(item_id, 0))
	var each := ItemDB.sell_price(item_id)
	if count <= 0 or each <= 0:
		return false
	for i in count:
		_remove_item(item_id)
	state["coins"] += each * count
	message.emit("ขาย %s x%d (+%d เหรียญ)" % [ItemDB.ITEMS[item_id]["name"], count, each * count])
	changed.emit()
	return true


# ---------- เควส ----------

func quest_status(id: String) -> String:
	return Quests.status(state, inventory, id)


func active_quests() -> Array:
	return state["quests"].keys()


func accept_quest(id: String) -> bool:
	if quest_status(id) != "available":
		return false
	state["quests"][id] = 0
	message.emit("รับเควส: %s" % Quests.QUESTS[id]["name"])
	changed.emit()
	return true


func abandon_quest(id: String) -> void:
	state["quests"].erase(id)
	changed.emit()


func complete_quest(id: String) -> bool:
	if quest_status(id) != "ready":
		return false
	var q: Dictionary = Quests.QUESTS[id]
	if q["type"] == "collect":
		for i in q["count"]:
			_remove_item(q["target"])
	state["quests"].erase(id)
	state["quests_done"][id] = state["quests_done"].get(id, 0) + 1
	var r: Dictionary = q["reward"]
	state["coins"] += r["coins"]
	message.emit("ส่งเควส %s สำเร็จ! +%d เหรียญ" % [q["name"], r["coins"]])
	for item in r["items"]:
		add_item(item, r["items"][item])
	gain_exp(r["exp"])
	return true


## ปราบผีได้: รับ EXP + เหรียญ และนับเควสที่เกี่ยวข้อง
func reward_kill(ghost_id: String, exp_amount: int, coin_amount: int) -> void:
	state["coins"] += coin_amount
	for id in state["quests"]:
		var q: Dictionary = Quests.QUESTS[id]
		if q["type"] == "kill" and q["target"] == ghost_id and state["quests"][id] < q["count"]:
			state["quests"][id] += 1
			if state["quests"][id] == q["count"]:
				message.emit("เควส %s ครบแล้ว! กลับไปส่งได้" % q["name"])
	gain_exp(exp_amount, coin_amount)


func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = maxi(0, hp - amount)
	flash = 0.15
	DamageText.spawn(get_parent(), position + Vector3(0, 2.4, 0), str(amount), Color(1, 0.45, 0.45))
	if hp == 0:
		message.emit("คุณสลบไป... ฟื้นคืนที่วัด")
		_revive()
	changed.emit()


func gain_exp(amount: int, coin_amount: int = 0) -> void:
	var ups := Progression.add_exp(state, amount)
	message.emit("+%d EXP · +%d เหรียญ" % [amount, coin_amount] if coin_amount > 0 else "+%d EXP" % amount)
	if ups > 0:
		recalc()
		hp = stats["max_hp"]
		sp = stats["max_sp"]
		levelup_fx = 1.2
		message.emit("เลเวลอัป! ตอนนี้เลเวล %d (แต้มสเตตัส %d)" % [state["level"], state["stat_points"]])
		if can_change_class():
			message.emit("ถึงเลเวลเปลี่ยนคลาสแล้ว! เปิดหน้าต่างตัวละครเพื่อเลื่อนขั้น")
	changed.emit()


func add_item(item_id: String, count: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + count
	var item: Dictionary = ItemDB.ITEMS[item_id]
	var note := ""
	if item["type"] == "soul":
		note = " ✨ (ไว้ผนึกพลังในอนาคต)"
	elif item["type"] == "equip":
		note = " [%s] %s" % [ItemDB.RARITY[item["rarity"]]["name"], ItemDB.bonus_text(item_id)]
	message.emit("ได้รับ %s x%d%s" % [item["name"], count, note])
	changed.emit()


func _remove_item(item_id: String) -> void:
	inventory[item_id] -= 1
	if inventory[item_id] <= 0:
		inventory.erase(item_id)


func _revive() -> void:
	pos = spawn_point
	attack_target = null
	pending_skill = ""
	moving = false
	path.clear()
	hp = stats["max_hp"]
	sp = stats["max_sp"]


func _regen(delta: float) -> void:
	regen_timer += delta
	if regen_timer < REGEN_INTERVAL:
		return
	regen_timer -= REGEN_INTERVAL
	var old_hp := hp
	var old_sp := sp
	hp = mini(stats["max_hp"], hp + maxi(1, stats["max_hp"] / 40))
	sp = mini(stats["max_sp"], sp + 1 + state["level"] / 4 + stats["int"] / 10)
	if hp != old_hp or sp != old_sp:
		changed.emit()
