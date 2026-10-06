extends RefCounted
## ระบบช่วยเล่น (ออโต้): หาผีตี ใช้สกิล เก็บของ และกินยาเลือด/ยามานาเองตามที่ตั้งไว้
## สั่งงานผ่านคำสั่งเดียวกับที่ผู้เล่นใช้ (command_attack/command_move/use_skill) จึงย้ายไปฝั่งเซิร์ฟเวอร์ได้ง่าย
## ถ้าผู้เล่นบังคับเอง (แตะจอ/จอย) ออโต้จะหยุดรอสักครู่แล้วทำต่อ

const Skills = preload("res://shared/data/skills.gd")

const THINK_INTERVAL := 0.25
const HUNT_RADIUS := 560.0
const LOOT_RADIUS := 300.0
const LOOT_GIVE_UP := 6.0  ## เดินไปเก็บของไม่ถึงในกี่วินาทีให้ข้าม
const ROAM_GIVE_UP := 15.0
const MANUAL_PAUSE := 2.5

var main: Node3D
var enabled := false
var settings := {
	"hp_pct": 50,  ## ใช้ยาเลือดเมื่อ HP ต่ำกว่า %
	"sp_pct": 30,  ## ใช้ยามานาเมื่อ SP ต่ำกว่า %
	"use_hp": true,
	"use_sp": true,
	"use_skills": true,
	"loot": true,
	"boss": true,  ## สู้บอสด้วยหรือไม่
}
var pause_timer := 0.0
var think_timer := 0.0
var loot_target: Node3D = null
var loot_timer := 0.0
var roam_timer := 0.0
var roaming := false
var _skipped_drops := {}
var _rng := RandomNumberGenerator.new()


func _init(main_ref: Node3D) -> void:
	main = main_ref
	_rng.seed = 99


func set_enabled(on: bool) -> void:
	enabled = on
	pause_timer = 0.0
	loot_target = null
	roaming = false
	_skipped_drops.clear()


## ผู้เล่นบังคับเอง: พักออโต้ชั่วคราว
func pause(seconds: float = MANUAL_PAUSE) -> void:
	pause_timer = maxf(pause_timer, seconds)


func is_paused() -> bool:
	return pause_timer > 0.0


func tick(delta: float) -> void:
	if not enabled:
		return
	var p: Node3D = main.player
	if p.hp <= 0:
		return
	_drink(p)
	if pause_timer > 0.0:
		pause_timer -= delta
		return
	loot_timer += delta
	roam_timer += delta
	think_timer -= delta
	if think_timer > 0.0:
		return
	think_timer = THINK_INTERVAL
	_think(p)


## กินยาตามเกณฑ์ (ทำงานแม้ตอนผู้เล่นบังคับเอง)
func _drink(p: Node3D) -> void:
	if p.potion_cd > 0.0:
		return
	if settings["use_hp"] and p.hp * 100 < p.stats["max_hp"] * settings["hp_pct"] and p.pick_potion("hp") != "":
		p.use_potion("hp")
	elif settings["use_sp"] and p.sp * 100 < p.stats["max_sp"] * settings["sp_pct"] and p.pick_potion("sp") != "":
		p.use_potion("sp")


func _think(p: Node3D) -> void:
	# ผีที่ตายแล้วอาจถูกลบไปแล้ว ต้องเช็กก่อนเก็บใส่ตัวแปรแบบมีชนิด
	var current = p.attack_target
	var target: Node3D = null
	if is_instance_valid(current) and current.alive:
		target = current
	var attacker := _attacker(p)
	# มีผีกำลังตีเรา แต่เรากำลังตีตัวที่ไม่ได้สู้กลับ: หันไปสู้ตัวที่ตีเราก่อน
	if attacker != null and (target == null or target.target != p):
		target = attacker
	if target == null and settings["loot"]:
		if _go_loot(p):
			return
	if target == null:
		target = _pick_target(p)
	if target == null:
		_roam(p)
		return
	roaming = false
	loot_target = null
	if p.attack_target != target and p.pending_skill == "":
		p.command_attack(target)
	if settings["use_skills"]:
		_cast(p, target)


func _attacker(p: Node3D) -> Node3D:
	var best: Node3D = null
	var best_dist := INF
	for g in main.alive_ghosts():
		if g.target == p:
			var d: float = p.pos.distance_to(g.pos)
			if d < best_dist:
				best = g
				best_dist = d
	return best


func _pick_target(p: Node3D) -> Node3D:
	var best: Node3D = null
	var best_score := INF
	for g in main.alive_ghosts():
		if g.is_boss() and not settings["boss"]:
			continue
		var d: float = p.pos.distance_to(g.pos)
		if d > HUNT_RADIUS:
			continue
		if main.map.is_water(g.pos):
			continue
		if d < best_score:
			best = g
			best_score = d
	return best


## เดินไปเก็บของที่ตกใกล้ๆ (ถ้าไปไม่ถึงในเวลาที่กำหนดจะข้ามชิ้นนั้น)
func _go_loot(p: Node3D) -> bool:
	if not is_instance_valid(loot_target) or loot_target.is_queued_for_deletion():
		loot_target = null
	if loot_target != null and loot_timer > LOOT_GIVE_UP:
		_skipped_drops[loot_target.get_instance_id()] = true
		loot_target = null
	if loot_target == null:
		var best_dist := LOOT_RADIUS
		for d in main.drops.get_children():
			if d.is_queued_for_deletion() or _skipped_drops.has(d.get_instance_id()):
				continue
			var dist: float = p.pos.distance_to(d.pos)
			if dist < best_dist:
				loot_target = d
				best_dist = dist
		if loot_target == null:
			return false
		loot_timer = 0.0
		roaming = false
		p.command_move(loot_target.pos)
	elif not p.moving:
		# เดินไปต่อไม่ได้ (ของตกทับสิ่งปลูกสร้าง) ข้ามชิ้นนี้ไป
		_skipped_drops[loot_target.get_instance_id()] = true
		loot_target = null
		return false
	return true


## ไม่มีผีใกล้ๆ: เดินไปจุดเกิดผีที่เหมาะกับเลเวล
func _roam(p: Node3D) -> void:
	if roaming and p.moving and roam_timer < ROAM_GIVE_UP:
		return
	var options: Array = []
	var level: int = p.state["level"]
	for s in main.map.spawns:
		var g_level: int = main.GhostDB.GHOSTS[s["id"]]["level"]
		if g_level <= level + 6:
			options.append(s)
	if options.is_empty():
		options = main.map.spawns
	if options.is_empty():
		return
	var area: Rect2 = options[_rng.randi() % options.size()]["rect"]
	var dest := Vector2(_rng.randf_range(area.position.x, area.end.x), _rng.randf_range(area.position.y, area.end.y))
	p.command_move(dest)
	roaming = true
	roam_timer = 0.0


## เลือกสกิลที่ใช้ได้ตอนนี้: บัฟก่อนสู้, ฮีลเมื่อเลือดน้อย, สกิลวงกว้างเมื่อผีรุม, ที่เหลือใช้สกิลแรงสุด
func _cast(p: Node3D, target: Node3D) -> void:
	if p.pending_skill != "":
		return
	var dist: float = p.pos.distance_to(target.pos)
	var learned: Array[String] = p.learned_skills()
	learned.reverse()
	for id in learned:
		var sk: Dictionary = Skills.SKILLS[id]
		var lv: int = p.skill_level(id)
		if p.skill_cd.get(id, 0.0) > 0.0 or p.sp < Skills.sp_cost(id, lv):
			continue
		match sk["kind"]:
			"buff":
				if p.guard_timer <= 0.0 and dist < 120.0:
					p.use_skill(id)
					return
			"heal":
				if p.hp * 100 < p.stats["max_hp"] * 60:
					p.use_skill(id)
					return
			"party_buff":
				if not p.buffs.has(sk["effect"]):
					p.use_skill(id)
					return
			"party_heal":
				if p.hp * 100 < p.stats["max_hp"] * 60:
					p.use_skill(id)
					return
			"aoe_self":
				if _count_near(p.pos, Skills.radius(id, lv)) >= 2 or (target.is_boss() and dist < Skills.radius(id, lv)):
					p.use_skill(id)
					return
			"single", "aoe_target":
				if dist <= maxf(sk["range"], 40.0) + 20.0:
					p.use_skill(id, target)
					return


func _count_near(center: Vector2, r: float) -> int:
	var n := 0
	for g in main.alive_ghosts():
		if center.distance_to(g.pos) <= r:
			n += 1
	return n
