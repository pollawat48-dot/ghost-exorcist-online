extends Node3D
## ตัวละครผู้เล่น (ศิษย์วัด): คลิกเพื่อเดิน, คลิกผีเพื่อโจมตี, สกิลโปรยน้ำมนต์
## ตรรกะใช้ pos (หน่วยเกมบนพื้นราบ) ส่วนโมเดล 3D ตามตำแหน่งนั้น
## ตอน M1 คำนวณในเครื่อง ภายหลังผลการต่อสู้จะมาจาก zone server

const K = preload("res://maps/props/mesh_kit.gd")
const Combat = preload("res://shared/combat/combat.gd")
const Progression = preload("res://shared/combat/progression.gd")
const ItemDB = preload("res://shared/data/items.gd")
const DamageText = preload("res://client/damage_text.gd")

signal changed
signal message(text: String)

const SPEED := 140.0
const ATTACK_RANGE := 40.0
const ATTACK_INTERVAL := 0.8
const SKILL_SP := 8
const SKILL_RADIUS := 90.0
const SKILL_POWER := 1.2
const SKILL_COOLDOWN := 2.0
const REGEN_INTERVAL := 3.0
const REPATH_INTERVAL := 0.4
const HERB_ITEM := "herb_potion"

var player_name := "ศิษย์วัด"
var state := {"level": 1, "exp": 0}
var stats := {}
var hp := 0
var sp := 0
var inventory := {}
var pos := Vector2.ZERO
var bounds := Rect2()
var spawn_point := Vector2.ZERO
var ghosts: Node
var nav: Node3D  ## แผนที่ที่มี find_path()

var path := PackedVector2Array()
var path_index := 0
var moving := false
var repath_timer := 0.0
var attack_target: Node3D = null
var attack_cooldown := 0.0
var skill_cooldown := 0.0
var regen_timer := 0.0
var swing := 0.0
var splash := 0.0
var levelup_fx := 0.0
var flash := 0.0
var walk_t := 0.0
var rng := RandomNumberGenerator.new()
var model: Node3D
var body: Node3D
var staff: Node3D
var splash_ring: MeshInstance3D
var levelup_beam: MeshInstance3D


func _ready() -> void:
	stats = Progression.stats_for_level(state["level"])
	hp = stats["max_hp"]
	sp = stats["max_sp"]
	inventory[HERB_ITEM] = 3
	_build_model()
	_sync(0.0)


func _build_model() -> void:
	model = Node3D.new()
	add_child(model)
	body = Node3D.new()
	model.add_child(body)
	var robe := K.mat(Color(0.95, 0.55, 0.12), 0.0, 0.8)
	var skin := K.mat(Color(0.93, 0.76, 0.6), 0.0, 0.7)
	K.cyl(body, 0.13, 0.11, 0.5, Vector3(-0.1, 0.25, 0), K.mat(Color(0.35, 0.2, 0.1)), 6)
	K.cyl(body, 0.13, 0.11, 0.5, Vector3(0.1, 0.25, 0), K.mat(Color(0.35, 0.2, 0.1)), 6)
	K.cyl(body, 0.24, 0.38, 0.85, Vector3(0, 0.75, 0), robe, 12)
	K.beam(body, Vector3(-0.22, 1.15, 0.12), Vector3(0.28, 0.55, 0.2), 0.1, K.mat(Color(0.75, 0.32, 0.05)))
	K.sphere(body, 0.24, Vector3(0, 1.38, 0), skin, 14)
	for x in [-0.08, 0.08]:
		K.sphere(body, 0.03, Vector3(x, 1.4, 0.21), K.mat(Color(0.05, 0.05, 0.05)), 6)
	K.sphere(body, 0.08, Vector3(0, 1.05, -0.3), robe, 6)
	staff = Node3D.new()
	staff.position = Vector3(0.32, 0.95, 0.05)
	body.add_child(staff)
	K.cyl(staff, 0.025, 0.025, 1.5, Vector3(0, 0.2, 0), K.mat(Color(0.5, 0.33, 0.15)), 6)
	K.sphere(staff, 0.07, Vector3(0, 0.98, 0), K.gold(), 8)
	K.label(self, player_name, Vector3(0, 2.05, 0), Color(1, 1, 0.8), 36)

	var ring := TorusMesh.new()
	ring.inner_radius = 0.9
	ring.outer_radius = 1.0
	splash_ring = MeshInstance3D.new()
	splash_ring.mesh = ring
	splash_ring.material_override = K.mat(Color(0.6, 0.9, 1.0, 0.8), 3.0, 0.2)
	splash_ring.visible = false
	add_child(splash_ring)

	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.6
	beam_mesh.bottom_radius = 0.9
	beam_mesh.height = 6.0
	levelup_beam = MeshInstance3D.new()
	levelup_beam.mesh = beam_mesh
	levelup_beam.position.y = 3.0
	levelup_beam.material_override = K.mat(Color(1, 0.9, 0.4, 0.35), 2.5, 0.5)
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
	staff.rotation.x = -sin((0.2 - swing) / 0.2 * PI) * 1.3 if swing > 0.0 else 0.0
	splash_ring.visible = splash > 0.0
	if splash > 0.0:
		var r := SKILL_RADIUS / 32.0 * (1.0 - splash / 0.4 * 0.6)
		splash_ring.scale = Vector3(r, 1, r)
		splash_ring.position.y = 0.3
	levelup_beam.visible = levelup_fx > 0.0
	if levelup_fx > 0.0:
		levelup_beam.scale = Vector3(1, levelup_fx / 1.2, 1)
	model.scale = Vector3.ONE * (1.08 if flash > 0.0 else 1.0)


func command_move(pos: Vector2) -> void:
	attack_target = null
	_set_path(Vector2(
		clampf(pos.x, bounds.position.x, bounds.end.x),
		clampf(pos.y, bounds.position.y, bounds.end.y)))


func command_attack(ghost: Node3D) -> void:
	attack_target = ghost
	moving = false
	repath_timer = 0.0


func tick(delta: float) -> void:
	if hp <= 0:
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	skill_cooldown = maxf(0.0, skill_cooldown - delta)
	swing = maxf(0.0, swing - delta)
	splash = maxf(0.0, splash - delta)
	levelup_fx = maxf(0.0, levelup_fx - delta)
	flash = maxf(0.0, flash - delta)
	_regen(delta)

	if attack_target != null and (not is_instance_valid(attack_target) or not attack_target.alive):
		attack_target = null
	if attack_target != null:
		if pos.distance_to(attack_target.pos) > ATTACK_RANGE:
			repath_timer -= delta
			if repath_timer <= 0.0 or not moving:
				repath_timer = REPATH_INTERVAL
				_set_path(attack_target.pos)
			_follow_path(delta)
		elif attack_cooldown <= 0.0:
			attack_cooldown = ATTACK_INTERVAL
			swing = 0.2
			var ghost := attack_target
			ghost.take_damage(Combat.damage(stats["atk"], ghost.data["def"], "neutral", ghost.data["element"], rng), self)
	elif moving:
		_follow_path(delta)
	if model != null:
		_sync(delta)


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


## สกิล 1: โปรยน้ำมนต์ — ดาเมจธาตุศักดิ์สิทธิ์รอบตัว แรงมากกับผีวิญญาณ
func cast_holy_water() -> bool:
	if hp <= 0 or skill_cooldown > 0.0:
		return false
	if sp < SKILL_SP:
		message.emit("SP ไม่พอสำหรับโปรยน้ำมนต์")
		return false
	sp -= SKILL_SP
	skill_cooldown = SKILL_COOLDOWN
	splash = 0.4
	var hit := 0
	for g in ghosts.get_children():
		if g.has_method("take_damage") and g.alive and pos.distance_to(g.pos) <= SKILL_RADIUS:
			g.take_damage(Combat.damage(stats["atk"], g.data["def"], "holy", g.data["element"], rng, SKILL_POWER), self)
			hit += 1
	message.emit("โปรยน้ำมนต์! โดนผี %d ตัว" % hit)
	changed.emit()
	return true


func use_herb() -> bool:
	if hp <= 0:
		return false
	if inventory.get(HERB_ITEM, 0) <= 0:
		message.emit("ไม่มี%sเหลือแล้ว" % ItemDB.ITEMS[HERB_ITEM]["name"])
		return false
	if hp >= stats["max_hp"]:
		return false
	_remove_item(HERB_ITEM)
	var heal: int = ItemDB.ITEMS[HERB_ITEM]["heal"]
	hp = mini(stats["max_hp"], hp + heal)
	DamageText.spawn(get_parent(), position + Vector3(0, 2.4, 0), "+%d" % heal, Color(0.4, 1, 0.4))
	changed.emit()
	return true


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


func gain_exp(amount: int) -> void:
	var ups := Progression.add_exp(state, amount)
	message.emit("+%d EXP" % amount)
	if ups > 0:
		stats = Progression.stats_for_level(state["level"])
		hp = stats["max_hp"]
		sp = stats["max_sp"]
		levelup_fx = 1.2
		message.emit("เลเวลอัป! ตอนนี้เลเวล %d" % state["level"])
	changed.emit()


func add_item(item_id: String, count: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + count
	var item: Dictionary = ItemDB.ITEMS[item_id]
	var note := " ✨ (ไว้ผนึกพลังในอนาคต)" if item["type"] == "soul" else ""
	message.emit("ได้รับ %s x%d%s" % [item["name"], count, note])
	changed.emit()


func _remove_item(item_id: String) -> void:
	inventory[item_id] -= 1
	if inventory[item_id] <= 0:
		inventory.erase(item_id)


func _revive() -> void:
	pos = spawn_point
	attack_target = null
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
	sp = mini(stats["max_sp"], sp + 1 + state["level"] / 4)
	if hp != old_hp or sp != old_sp:
		changed.emit()
