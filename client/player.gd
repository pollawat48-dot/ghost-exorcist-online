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
const Crafting = preload("res://shared/data/crafting.gd")
const World = preload("res://shared/data/world.gd")
const Fishing = preload("res://shared/data/fishing.gd")
const DamageText = preload("res://client/damage_text.gd")
const BuffAura = preload("res://client/buff_aura.gd")
const Effect = preload("res://client/effect.gd")
const Avatar = preload("res://client/avatar.gd")
const Fashion = preload("res://shared/data/fashion.gd")
const Pet = preload("res://client/pet.gd")

signal changed
signal message(text: String)
signal class_changed(class_id: String)
signal open_refine(stone_id: String)  ## กดใช้หินตี+ จากกระเป๋า
signal party_cast(fields: Dictionary)  ## ใช้บัฟ/ฮีลปาร์ตี้ ให้ main ส่งต่อไปเพื่อนผ่านเซิร์ฟเวอร์
signal caught(item_id: String)  ## ตกปลาได้ของ
signal sfx(id: String)  ## ขอเล่นเสียง (main ส่งต่อให้ระบบเสียง)
signal died(by: String)  ## สลบ (HUD แสดงป้ายกลางจอ ให้กดปุ่มเกิดเอง)
signal respawned

const SPEED := 140.0
const REGEN_INTERVAL := 3.0
const REPATH_INTERVAL := 0.4
const HERB_ITEM := "herb_potion"
const SP_ITEM := "nam_mon"
## ยาเลือด/ยามานาเรียงจากเล็กไปใหญ่ (กดปุ่มยาแล้วเลือกขวดที่เหมาะกับที่ขาดอยู่)
const HP_POTIONS := ["herb_potion", "ya_hom_thong"]
const SP_POTIONS := ["nam_mon", "nam_mon_yai"]
const POTION_COOLDOWN := 0.6
const MINE_TIME := 2.0  ## วินาทีต่อการขุดหนึ่งครั้ง (มีหลอดขุดเหนือหัว) ระหว่างขุดผีทำร้ายไม่ได้
const MINE_REACH := 46.0
const BUFF_EFFECTS := ["atk", "def", "aspd", "speed", "sp_regen"]
const Protocol = preload("res://shared/net/protocol.gd")
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
var mine_target: Node3D = null  ## ก้อนหินแร่ที่กำลังเดินไปขุด/กำลังขุด
var buffs := {}  ## effect -> {"power", "time", "name", "from"} บัฟจากสกิลปาร์ตี้ (ตัวเองหรือเพื่อน)
var fishing := false  ## กำลังตกปลาแบบ AFK
var fish_spot := Vector2.ZERO  ## จุดในน้ำที่หย่อนเบ็ด
var fish_timer := 0.0
var fish_count := 0
var look := {}  ## หน้าตาที่เลือกตอนสร้างตัวละคร {"gender", "hair", "skin"}
var loaded := false  ## โหลดจากเซฟ (ไม่ต้องแจกของเริ่มต้น)
var mine_timer := 0.0
var regen_timer := 0.0
var swing := 0.0
var levelup_fx := 0.0
var buff_aura: Node3D  ## ออร่ารอบตัวตอนติดบัฟ
var _swing_side := 1.0
var flash := 0.0
var walk_t := 0.0
var rng := RandomNumberGenerator.new()
var model: Node3D
var body: Node3D
var weapon: Node3D
var aura: Node3D
var name_label: Label3D
var avatar: Node3D  ## โมเดลจิบิ (client/avatar.gd) ใช้ร่วมกับผู้เล่นคนอื่น
var pet: Node3D = null  ## สัตว์เลี้ยงที่ออกมาด้วย (client/pet.gd)
var dead_by := ""  ## ใครทำให้สลบ (โชว์บนป้ายตาย)


func _ready() -> void:
	recalc()
	if not loaded:
		# ตัวละครใหม่: เลือดเต็ม + ยาติดตัว
		hp = stats["max_hp"]
		sp = stats["max_sp"]
		inventory[HERB_ITEM] = 5
		inventory[SP_ITEM] = 3
	_build_model()
	_sync(0.0)
	_refresh_pet.call_deferred()


## คำนวณค่าพลังใหม่ (หลังอัปสเตตัส สวมของ เปลี่ยนคลาส หรือบัฟหมด)
func recalc() -> void:
	stats = Progression.derive(state)
	if guard_timer > 0.0:
		stats["def"] = int(stats["def"] * (1.0 + guard_bonus))
	if buffs.has("atk"):
		stats["atk"] = int(stats["atk"] * (1.0 + buffs["atk"]["power"]))
		stats["matk"] = int(stats["matk"] * (1.0 + buffs["atk"]["power"]))
	if buffs.has("def"):
		stats["def"] = int(stats["def"] * (1.0 + buffs["def"]["power"]))
	if buffs.has("aspd"):
		stats["attack_interval"] = stats["attack_interval"] / (1.0 + buffs["aspd"]["power"])
	hp = mini(hp, stats["max_hp"])
	sp = mini(sp, stats["max_sp"])


func class_info() -> Dictionary:
	return Classes.CLASSES[state["class"]]


# ---------- รูปร่างตัวละคร (เปลี่ยนตามคลาส หน้าตา และของสวมใส่) ----------

## สร้างโมเดลใหม่ (ตอนเริ่ม เปลี่ยนคลาส สวม/ถอดของ หรือตีบวกของที่สวมอยู่)
func _build_model() -> void:
	if avatar == null:
		avatar = Avatar.new()
		add_child(avatar)
		buff_aura = BuffAura.new()
		add_child(buff_aura)
	avatar.build(state["class"], look, look_items(), player_name)
	model = avatar.model
	body = avatar.body
	weapon = avatar.weapon
	aura = avatar.aura
	name_label = avatar.name_label
	avatar.set_fishing(fishing)


## ของที่มองเห็นบนตัว: ของสวมใส่ + แฟชั่น (คีย์ "f_<ช่อง>") ใช้ทั้งโมเดลตัวเองและส่งให้ผู้เล่นอื่นเห็น
func look_items() -> Dictionary:
	var out: Dictionary = state["equipment"].duplicate()
	for slot in state.get("fashion", {}):
		if slot != "pet":
			out["f_" + slot] = state["fashion"][slot]
	return out


## ขยับโมเดลให้ตรงกับตรรกะ: ตำแหน่ง, ทิศที่หัน, ท่าเดิน/ตี, เอฟเฟกต์
func _sync(delta: float) -> void:
	var prev := position
	position = K.to3d(pos)
	var move := Vector2(position.x - prev.x, position.z - prev.z)
	var facing := move
	if attack_target != null and is_instance_valid(attack_target):
		facing = attack_target.pos - pos
	elif fishing:
		facing = fish_spot - pos
	if avatar.fishing != fishing:
		avatar.set_fishing(fishing)
	avatar.dead = hp <= 0
	buff_aura.show_buffs(active_buff_fx() if hp > 0 else [])
	avatar.animate(delta, move.length() > 0.001, facing, swing, flash > 0.0, levelup_fx)
	if fishing and avatar.bobber != null:
		avatar.bobber.position.y = sin(fish_timer * 3.0) * 0.04 - (0.12 if fish_timer > fish_time() - 0.6 else 0.0)


## บัฟที่ติดอยู่ (ไว้แสดงออร่ารอบตัว) อาคมคงกระพันนับเป็น "guard"
func active_buff_fx() -> Array:
	var out := []
	if guard_timer > 0.0:
		out.append("guard")
	for e in BUFF_EFFECTS:
		if buffs.has(e):
			out.append(e)
	return out


# ---------- คำสั่งจากผู้เล่น ----------

func command_move(dest: Vector2) -> void:
	fishing = false
	attack_target = null
	mine_target = null
	pending_skill = ""
	_set_path(Vector2(
		clampf(dest.x, bounds.position.x, bounds.end.x),
		clampf(dest.y, bounds.position.y, bounds.end.y)))


func command_attack(ghost: Node3D) -> void:
	fishing = false
	attack_target = ghost
	mine_target = null
	pending_skill = ""
	moving = false
	repath_timer = 0.0


func tick(delta: float) -> void:
	if pet != null:
		pet.tick(delta)
	if hp <= 0:
		if model != null:
			_sync(delta)
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
	_tick_buffs(delta)
	swing = maxf(0.0, swing - delta)
	levelup_fx = maxf(0.0, levelup_fx - delta)
	flash = maxf(0.0, flash - delta)
	_regen(delta)

	if attack_target != null and (not is_instance_valid(attack_target) or not attack_target.alive):
		attack_target = null
		pending_skill = ""
	if mine_target != null and (not is_instance_valid(mine_target) or not mine_target.has_ore()):
		mine_target = null
	if stick.length() > 0.15:
		fishing = false
		attack_target = null
		mine_target = null
		pending_skill = ""
		moving = false
		_walk_dir(stick.limit_length(1.0) * speed() * delta)
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
	elif mine_target != null:
		_tick_mining(delta)
	elif fishing:
		_tick_fishing(delta)
	elif moving:
		_follow_path(delta)
	if model != null:
		_sync(delta)


func _basic_attack(ghost: Node3D) -> void:
	swing = 0.2
	var kind: String = stats["attack"]
	sfx.emit({"ranged": "arrow", "magic": "magic"}.get(kind, "swing"))
	var stat := "matk" if kind == "magic" else "atk"
	var crit := _hit(ghost, stat, 1.0, "neutral")
	var parent := get_parent()
	var at: Vector3 = ghost.global_position + Vector3(0, 1.1, 0)
	match kind:
		"ranged":
			Effect.shot(parent, position + Vector3(0, 0.9, 0), at, "arrow", weapon_fx_color(Color(1.0, 0.9, 0.6)), crit)
		"magic":
			Effect.shot(parent, position + Vector3(0, 1.1, 0), at, "orb", weapon_fx_color(Color(0.85, 0.6, 1.0)), crit)
		_:
			# ฟันเป็นเสี้ยวพระจันทร์ผ่านตัวผี สลับทิศฟันซ้าย/ขวา
			var c := weapon_fx_color(Color(1.0, 0.95, 0.8))
			_swing_side = -_swing_side
			Effect.slash(parent, position + Vector3(0, 1.0, 0), _yaw_to(ghost.pos), c, 1.25 if crit else 1.05, _swing_side * rng.randf_range(0.25, 0.6))
			Effect.impact(parent, at, c, 1.0, crit)


## สีเอฟเฟกต์ตามอาวุธ: ตีบวก +4 ขึ้นไปใช้สีออร่าของขั้นตีบวก
func weapon_fx_color(base: Color) -> Color:
	var key: String = state["equipment"].get("weapon", "")
	var lv := ItemDB.refine_of(key) if key != "" else 0
	return Avatar.refine_color(lv) if lv >= 4 else base


## มุมหันจากตัวผู้เล่นไปจุดหมาย (ใช้หมุนรอยฟัน)
func _yaw_to(target_pos: Vector2) -> float:
	var d := target_pos - pos
	return atan2(-d.x, -d.y)


## ดาเมจใส่ผีหนึ่งตัว มีโอกาสคริติคอลตาม LUK
func _hit(ghost: Node3D, stat: String, power: float, element: String) -> bool:
	var crit: bool = rng.randf() < stats["crit"]
	var dmg := Combat.damage(stats[stat], ghost.data["def"], element, ghost.data["element"], rng, power * (1.5 if crit else 1.0))
	ghost.take_damage(dmg, self, crit)
	sfx.emit("crit" if crit else "hit")
	return crit


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


func speed() -> float:
	return SPEED * (1.0 + (buffs["speed"]["power"] if buffs.has("speed") else 0.0))


func _follow_path(delta: float) -> void:
	var step := speed() * delta
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
	if skill_level(id) == 1:
		_auto_slot(id)
	message.emit("%s เลเวล %d" % [Skills.SKILLS[id]["name"], skill_level(id)])
	changed.emit()
	return true


# ---------- ช่องสกิลรอบปุ่มโจมตี ----------
## state["skill_slots"]: ช่องละ "" (ว่าง) หรือ id สกิล ผู้เล่นลากสกิลจากหน้าต่างสกิลมาใส่/สลับ/ลากออกได้
const SKILL_SLOTS := 9


func skill_slots() -> Array:
	var slots: Array = state.get("skill_slots", [])
	while slots.size() < SKILL_SLOTS:
		slots.append("")
	state["skill_slots"] = slots
	return slots


## ใส่สกิลลงช่อง (สกิลเดิมที่อยู่ช่องอื่นย้ายมาแทน) id ว่าง = ล้างช่อง
func set_skill_slot(i: int, id: String) -> bool:
	var slots := skill_slots()
	if i < 0 or i >= SKILL_SLOTS or (id != "" and skill_level(id) <= 0):
		return false
	var old := slots.find(id) if id != "" else -1
	if old >= 0:
		slots[old] = slots[i]
	slots[i] = id
	changed.emit()
	return true


## สลับของสองช่อง (ลากจากช่องหนึ่งไปอีกช่อง)
func swap_skill_slots(a: int, b: int) -> void:
	var slots := skill_slots()
	if a < 0 or b < 0 or a >= SKILL_SLOTS or b >= SKILL_SLOTS:
		return
	var t: String = slots[a]
	slots[a] = slots[b]
	slots[b] = t
	changed.emit()


## เรียนสกิลใหม่: ใส่ช่องว่างช่องแรกให้ก่อน (ลากย้ายทีหลังได้)
func _auto_slot(id: String) -> void:
	var slots := skill_slots()
	if id in slots:
		return
	var empty := slots.find("")
	if empty >= 0:
		slots[empty] = id


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
	sfx.emit({"buff": "buff", "party_buff": "buff", "heal": "heal", "party_heal": "heal"}.get(kind, {"fire": "fire", "holy": "holy"}.get(sk["element"], "magic")))
	var parent := get_parent()
	Effect.cast(parent, position, color, 1.1)
	match kind:
		"aoe_self":
			var r := Skills.radius(id, lv)
			var hit := _hit_area(pos, r, sk["stat"], power, sk["element"])
			_fx_aoe_self(sk, r / 32.0, color)
			message.emit("%s! โดนผี %d ตัว" % [sk["name"], hit])
		"single":
			var crit := _hit(target, sk["stat"], power, sk["element"])
			attack_target = target
			_fx_single(sk, target, color, crit)
		"aoe_target":
			var r := Skills.radius(id, lv)
			var center: Vector2 = target.pos
			var hit := _hit_area(center, r, sk["stat"], power, sk["element"])
			attack_target = target
			_fx_aoe_target(sk, K.to3d(center), r / 32.0, color)
			message.emit("%s! โดนผี %d ตัว" % [sk["name"], hit])
		"buff":
			guard_bonus = power
			guard_timer = sk["duration"]
			recalc()
			_fx_buff(BuffAura.color_of("guard"), 1.2)
			message.emit("%s! DEF เพิ่ม %d%%" % [sk["name"], int(power * 100)])
		"heal":
			var amount := int(stats["matk"] * power)
			hp = mini(stats["max_hp"], hp + amount)
			_fx_buff(Color(0.5, 1.0, 0.6), 1.2)
			DamageText.spawn(parent, position + Vector3(0, 2.4, 0), "+%d" % amount, Color(0.4, 1, 0.4))
		"party_buff":
			var duration: float = sk["duration"]
			apply_buff(sk["effect"], power, duration, sk["name"])
			_fx_buff(BuffAura.color_of(sk["effect"]), Protocol.BUFF_RANGE / 32.0)
			party_cast.emit({"t": "buff", "skill": id, "lv": lv, "power": power, "duration": duration, "effect": sk["effect"], "x": pos.x, "y": pos.y})
		"party_heal":
			var amount := int(stats["matk"] * power)
			receive_heal(amount)
			_fx_buff(Color(0.5, 1.0, 0.6), Protocol.BUFF_RANGE / 32.0)
			party_cast.emit({"t": "heal", "amount": amount, "x": pos.x, "y": pos.y})
	changed.emit()
	return true


# ---------- เอฟเฟกต์สกิล (ภาพอย่างเดียว) ----------

## สกิลรอบตัว: ดาบหมุนวน = ใบดาบหมุน, โปรยน้ำมนต์ = หยดน้ำกระจาย
func _fx_aoe_self(sk: Dictionary, r: float, c: Color) -> void:
	var parent := get_parent()
	var ground := Vector3(position.x, 0.05, position.z)
	if sk["icon"] == "storm":
		Effect.whirl(parent, position, maxf(1.2, r * 0.7), c.lerp(Color.WHITE, 0.2))
		Effect.burst(parent, position + Vector3(0, 0.9, 0), c, 26, 6.0, 0.07, 0.6, -3.0)
	else:
		Effect.burst(parent, position + Vector3(0, 1.0, 0), c, 34, 5.5, 0.09, 0.9, -9.0, true)
		Effect.flash(parent, position + Vector3(0, 1.0, 0), c, 1.2, 0.3)
	Effect.shockwave(parent, ground, r, c, 0.5)
	Effect.ring(parent, ground, r, c, 0.55)
	Effect.rune(parent, ground, r * 0.8, c, 0.6)


## สกิลเป้าเดียว: ประชิด = ฟันไขว้ + แสงวาบ, ไกล = ลูกธนู/ลูกพลังใหญ่ (ยิงซ้อน 3 ดอก, สกิลแรงมีฟ้าผ่าตาม)
func _fx_single(sk: Dictionary, g: Node3D, c: Color, crit: bool) -> void:
	var parent := get_parent()
	var at: Vector3 = g.global_position + Vector3(0, 1.1, 0)
	if sk["range"] <= 60.0:
		var yaw := _yaw_to(g.pos)
		Effect.slash(parent, position + Vector3(0, 1.0, 0), yaw, c, 1.5, 0.75, 0.32)
		Effect.slash(parent, position + Vector3(0, 1.0, 0), yaw, Color.WHITE.lerp(c, 0.5), 1.5, -0.75, 0.36)
		Effect.impact(parent, at, c, 1.8, crit)
		Effect.shockwave(parent, Vector3(at.x, 0.05, at.z), 1.4, c, 0.35)
		if sk["element"] == "holy":
			Effect.pillar(parent, Vector3(at.x, 0, at.z), 0.5, c)
		return
	var shot_kind := "arrow" if stats["attack"] == "ranged" else "orb"
	if sk["icon"] == "arrow":
		for dy in [0.7, 1.0, 1.3]:
			Effect.shot(parent, position + Vector3(0, dy, 0), at + Vector3(0, dy - 1.0, 0) * 0.4, shot_kind, c, true)
	else:
		Effect.shot(parent, position + Vector3(0, 1.0, 0), at, shot_kind, c, true)
	if sk["power"] >= 3.0:
		Effect.fall(parent, Vector3(at.x, 0.05, at.z), "bolt", c, 1.2, 0.2)
	if sk["element"] == "fire":
		Effect.explosion(parent, Vector3(at.x, 0.05, at.z), 1.3, c)


## สกิลวงกว้างที่เป้า: วงเวทบนพื้น แล้วแต่ละสกิลมีของตกจากฟ้าต่างกัน
func _fx_aoe_target(sk: Dictionary, center: Vector3, r: float, c: Color) -> void:
	var parent := get_parent()
	var ground := Vector3(center.x, 0.05, center.z)
	Effect.rune(parent, ground, r, c, 1.0)
	var spots := func(n: int) -> Array:
		var out := []
		for i in n:
			var a := rng.randf() * TAU
			var d := sqrt(rng.randf()) * r * 0.85
			out.append(ground + Vector3(cos(a) * d, 0, sin(a) * d))
		return out
	if sk["element"] == "fire":
		Effect.fall(parent, ground, "meteor", c, 1.6, 0.0, 0.35)
		for p in spots.call(3):
			Effect.fall(parent, p, "meteor", c, 0.8, rng.randf_range(0.1, 0.35), 0.3)
	elif sk["icon"] == "star":
		Effect.fall(parent, ground, "bolt", c, 1.5, 0.15)
		for p in spots.call(4):
			Effect.fall(parent, p, "bolt", c, 0.9, 0.2, rng.randf_range(0.15, 0.3))
		Effect.pillar(parent, Vector3(center.x, 0, center.z), r * 0.4, c)
		Effect.explosion(parent, ground, r, c)
	elif sk["icon"] == "storm":
		for p in spots.call(14):
			Effect.fall(parent, p, "arrow", c, 1.0, rng.randf_range(0.0, 0.45), 0.22)
		Effect.shockwave(parent, ground, r, c, 0.7)
	else:
		for p in spots.call(16):
			Effect.fall(parent, p, "drop", c, 1.0, rng.randf_range(0.0, 0.5), 0.3)
		Effect.pillar(parent, Vector3(center.x, 0, center.z), r * 0.3, c)
		Effect.shockwave(parent, ground, r, c, 0.7)


## บัฟ/ฮีล: เสาแสงสีของบัฟ วงเวทกว้าง ประกายลอยขึ้น
func _fx_buff(c: Color, r: float) -> void:
	var parent := get_parent()
	var ground := Vector3(position.x, 0.05, position.z)
	Effect.pillar(parent, Vector3(position.x, 0, position.z), 0.9, c)
	Effect.rune(parent, ground, r, c, 0.9)
	Effect.ring(parent, ground, r, c, 0.6)
	Effect.burst(parent, position + Vector3(0, 0.3, 0), c, 26, 3.5, 0.07, 1.0, 2.0, true)


# ---------- บัฟปาร์ตี้ ----------

## รับบัฟ (จากตัวเองหรือเพื่อน) ถ้ามีบัฟชนิดเดียวกันอยู่แล้วใช้ค่าที่แรงกว่าและต่อเวลาใหม่
func apply_buff(effect: String, power: float, duration: float, buff_name: String, from: String = "") -> void:
	if not effect in BUFF_EFFECTS:
		return
	var old: Dictionary = buffs.get(effect, {})
	buffs[effect] = {"power": maxf(power, old.get("power", 0.0)), "time": maxf(duration, old.get("time", 0.0)), "name": buff_name, "from": from}
	recalc()
	if from != "":
		message.emit("%s ใช้%sให้คุณ (%s)" % [from, buff_name, buff_text(effect)])
		Effect.pillar(get_parent(), Vector3(position.x, 0, position.z), 0.8, BuffAura.color_of(effect))
		Effect.burst(get_parent(), position + Vector3(0, 0.3, 0), BuffAura.color_of(effect), 18, 3.0, 0.07, 0.9, 2.0, true)
		sfx.emit("buff")
	changed.emit()


func receive_heal(amount: int, from: String = "") -> void:
	if hp <= 0 or amount <= 0:
		return
	hp = mini(stats["max_hp"], hp + amount)
	DamageText.spawn(get_parent(), position + Vector3(0, 2.4, 0), "+%d" % amount, Color(0.4, 1, 0.4))
	if from != "":
		Effect.ring(get_parent(), position, 1.2, Color(0.5, 1.0, 0.6))
		sfx.emit("heal")
	changed.emit()


## ข้อความสั้นของบัฟ เช่น "ATK +30%"
func buff_text(effect: String) -> String:
	var p: float = buffs[effect]["power"] if buffs.has(effect) else 0.0
	match effect:
		"sp_regen":
			return "ฟื้น SP x%.1f" % (1.0 + p)
		"speed":
			return "เดินเร็ว +%d%%" % int(round(p * 100))
		"aspd":
			return "ตีเร็ว +%d%%" % int(round(p * 100))
	return "%s +%d%%" % [effect.to_upper(), int(round(p * 100))]


func _tick_buffs(delta: float) -> void:
	var expired: Array = []
	for effect in buffs:
		buffs[effect]["time"] -= delta
		if buffs[effect]["time"] <= 0.0:
			expired.append(effect)
	for effect in expired:
		message.emit("%sหมดฤทธิ์" % buffs[effect]["name"])
		buffs.erase(effect)
	if not expired.is_empty():
		recalc()
		changed.emit()


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


## เงื่อนไขเปลี่ยนอาชีพขั้นถัดไป: เลเวลถึง, ผ่านเควสบททดสอบของครูใหญ่, มีเงินค่าครูพอ
func class_change_status() -> Dictionary:
	var need := Classes.change_level(state["class"])
	if need < 0:
		return {}
	var trial := Classes.trial_for(state["class"])
	return {
		"level": need, "level_ok": state["level"] >= need,
		"quest": trial["quest"], "quest_ok": state["quests_done"].has(trial["quest"]),
		"fee": trial["fee"], "fee_ok": state["coins"] >= trial["fee"],
	}


func class_level_reached() -> bool:
	var st := class_change_status()
	return not st.is_empty() and st["level_ok"]


func can_change_class() -> bool:
	var st := class_change_status()
	return not st.is_empty() and st["level_ok"] and st["quest_ok"] and st["fee_ok"]


func change_class(class_id: String) -> bool:
	if not can_change_class() or not class_id in Classes.next_classes(state["class"]):
		return false
	var fee: int = class_change_status()["fee"]
	state["coins"] -= fee
	message.emit("จ่ายค่าครู %d เหรียญ" % fee)
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
	if not ItemDB.has(item_id):
		return false
	var item: Dictionary = ItemDB.info(item_id)
	if item.get("type", "") != "equip":
		return false
	return item["line"] == "any" or item["line"] == class_info()["line"]


func equip(item_id: String) -> bool:
	if inventory.get(item_id, 0) <= 0:
		return false
	if not can_equip(item_id):
		message.emit("คลาสนี้ใช้ %s ไม่ได้" % ItemDB.display_name(item_id))
		return false
	var slot: String = ItemDB.info(item_id)["slot"]
	if state["equipment"].has(slot):
		unequip(slot)
	_remove_item(item_id)
	state["equipment"][slot] = item_id
	recalc()
	if avatar != null:
		_build_model()
	message.emit("สวม %s" % ItemDB.display_name(item_id))
	changed.emit()
	return true


func unequip(slot: String) -> bool:
	if not state["equipment"].has(slot):
		return false
	var item_id: String = state["equipment"][slot]
	state["equipment"].erase(slot)
	inventory[item_id] = inventory.get(item_id, 0) + 1
	recalc()
	if avatar != null:
		_build_model()
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
	var item: Dictionary = ItemDB.info(item_id)
	if item["type"] in ["refine", "amulet"]:
		open_refine.emit(item_id if item["type"] == "refine" else "")
		return true
	if item["type"] == "fashion_refine":
		open_refine.emit("fashion")
		return true
	if item["type"] == "gacha":
		open_gacha(1)
		return true
	if item["type"] == "fashion":
		return wear_fashion(item_id)
	if item["type"] != "consumable":
		return false
	if item.has("buff"):
		var b: Dictionary = item["buff"]
		_remove_item(item_id)
		potion_cd = POTION_COOLDOWN
		apply_buff(b["effect"], b["power"], b["duration"], item["name"])
		Effect.ring(get_parent(), position, 1.4, Color(0.95, 0.97, 1.0))
		Effect.burst(get_parent(), position + Vector3(0, 1.2, 0), Color(0.95, 0.97, 1.0), 22, 3.0, 0.06, 0.8, -6.0, true)
		sfx.emit("buff")
		message.emit("โปรย%s! %s" % [item["name"], ItemDB.use_text(item_id)])
		changed.emit()
		return true
	var heal: int = item.get("heal", 0)
	var mana: int = item.get("sp", 0)
	if (heal == 0 or hp >= stats["max_hp"]) and (mana == 0 or sp >= stats["max_sp"]):
		return false
	_remove_item(item_id)
	potion_cd = POTION_COOLDOWN
	sfx.emit("potion")
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
	sfx.emit("coin")
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
	sfx.emit("coin")
	message.emit("ขาย %s x%d (+%d เหรียญ)" % [ItemDB.display_name(item_id), count, each * count])
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
	if q.has("pet_stage"):
		# ผ่านบททดสอบครูฝึกสัตว์: สัตว์เลี้ยงตัวที่ออกมาได้สิทธิ์พัฒนาร่าง
		Fashion.pet_data(state, pet_species())["trial"] = q["pet_stage"]
	var r := Quests.reward(id, class_info()["line"])
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


# ---------- ตีบวก หลอมแร่ ขุดแร่ วาร์ป ----------

## ของสวมใส่ที่ตีบวกได้: ในกระเป๋า (slot = "") และที่สวมอยู่ (slot = ช่อง)
func refinable_items() -> Array:
	var result := []
	for slot in ItemDB.SLOTS:
		if state["equipment"].has(slot):
			result.append({"key": state["equipment"][slot], "slot": slot})
	for key in inventory:
		if ItemDB.info(key)["type"] == "equip":
			result.append({"key": key, "slot": ""})
	return result


## หินตี+ ที่ใช้ตีจาก +level ได้ (หินขั้นสูงใช้ตีขั้นต่ำได้ด้วย)
func refine_stones_for(level: int) -> Array[String]:
	var result: Array[String] = []
	for id in ["hin_ti_1", "hin_ti_2", "hin_ti_3"]:
		if inventory.get(id, 0) > 0 and ItemDB.ITEMS[id]["refine_max"] >= level + 1:
			result.append(id)
	return result


## ตีบวกของหนึ่งชิ้น: ใช้หิน 1 ก้อน + เหรียญ ยิ่งขั้นสูงยิ่งแพงและติดยาก
## ตั้งแต่ +7 ขึ้นไป ถ้าพลาดจะลดขั้นลง 1–2 ขั้น
## คืน {"ok", "result": "success"/"fail"/"down"/"error", "key": คีย์ใหม่, "level"}
func refine(key: String, stone_id: String, slot: String = "", amulet: String = "") -> Dictionary:
	var err := {"ok": false, "result": "error", "key": key, "level": ItemDB.refine_of(key)}
	var owned: bool = state["equipment"].get(slot, "") == key if slot != "" else inventory.get(key, 0) > 0
	if not owned or not ItemDB.has(key) or ItemDB.info(key)["type"] != "equip":
		return err
	var lv := ItemDB.refine_of(key)
	if lv >= ItemDB.REFINE_MAX:
		message.emit("%s ตีถึง +%d สูงสุดแล้ว" % [ItemDB.display_name(key), ItemDB.REFINE_MAX])
		return err
	if not stone_id in refine_stones_for(lv):
		message.emit("ต้องใช้หินตี+ ที่ตีถึง +%d ได้" % (lv + 1))
		return err
	var fee := ItemDB.refine_fee(lv)
	if state["coins"] < fee:
		message.emit("เหรียญไม่พอ (ค่าตีบวก %d)" % fee)
		return err
	if amulet != "" and (inventory.get(amulet, 0) <= 0 or ItemDB.info(amulet)["type"] != "amulet"):
		amulet = ""
	_remove_item(stone_id)
	if amulet != "":
		_remove_item(amulet)
	state["coins"] -= fee
	var new_lv := lv
	var result := "fail"
	if rng.randf() < refine_chance(lv, amulet):
		new_lv = lv + 1
		result = "success"
	elif lv >= ItemDB.REFINE_RISKY_FROM:
		new_lv = maxi(0, lv - rng.randi_range(1, 2))
		result = "down"
	var base := ItemDB.base_id(key)
	var new_key := ItemDB.refined_key(base, new_lv)
	if slot != "":
		state["equipment"][slot] = new_key
		recalc()
		if avatar != null:
			_build_model()
	else:
		_remove_item(key)
		inventory[new_key] = inventory.get(new_key, 0) + 1
	match result:
		"success":
			levelup_fx = 0.6
			message.emit("ตีบวกสำเร็จ! ได้ %s" % ItemDB.display_name(new_key))
		"down":
			message.emit("ตีบวกล้มเหลว... %s ลดเหลือ +%d" % [ItemDB.info(base)["name"], new_lv])
		_:
			message.emit("ตีบวกล้มเหลว (ของยังอยู่ +%d เสียหินและเหรียญ)" % lv)
	sfx.emit({"success": "refine_ok", "down": "refine_down"}.get(result, "refine_fail"))
	changed.emit()
	return {"ok": result == "success", "result": result, "key": new_key, "level": new_lv}


## โอกาสตีบวกสำเร็จจาก +level (รวมพระเครื่องที่ใช้ ถ้ามี) สูงสุด 100%
func refine_chance(level: int, amulet: String = "") -> float:
	var bonus: float = ItemDB.info(amulet).get("refine_bonus", 0.0) if amulet != "" and ItemDB.has(amulet) else 0.0
	return minf(1.0, ItemDB.REFINE_CHANCE[level] + bonus)


## พระเครื่องในกระเป๋า (ใช้เพิ่มโอกาสตีบวก)
func amulets() -> Array[String]:
	var result: Array[String] = []
	for id in ["phra_din", "phra_phong", "phra_thong"]:
		if inventory.get(id, 0) > 0:
			result.append(id)
	return result


## หลอมแร่เป็นหินตี+ ที่ร้านหลอม
func craft(recipe_id: String, count: int = 1) -> bool:
	if count <= 0 or Crafting.max_craft(recipe_id, inventory, state["coins"]) < count:
		message.emit("แร่หรือเหรียญไม่พอสำหรับหลอม %s" % ItemDB.ITEMS[recipe_id]["name"])
		return false
	var r: Dictionary = Crafting.RECIPES[recipe_id]
	state["coins"] -= r["coins"] * count
	for ore in r["ores"]:
		for i in r["ores"][ore] * count:
			_remove_item(ore)
	inventory[recipe_id] = inventory.get(recipe_id, 0) + count
	message.emit("หลอม %s x%d สำเร็จ (-%d เหรียญ)" % [ItemDB.ITEMS[recipe_id]["name"], count, r["coins"] * count])
	changed.emit()
	return true


## เดินไปขุดหินแร่ในถ้ำ (ขุดต่อเนื่องจนหินหมด)
func command_mine(rock: Node3D) -> void:
	fishing = false
	attack_target = null
	pending_skill = ""
	mine_target = rock
	mine_timer = 0.0
	moving = false
	repath_timer = 0.0


func _tick_mining(delta: float) -> void:
	if pos.distance_to(mine_target.pos) > MINE_REACH:
		repath_timer -= delta
		if repath_timer <= 0.0 or not moving:
			repath_timer = REPATH_INTERVAL
			_set_path(mine_target.pos + (pos - mine_target.pos).limit_length(30.0))
		_follow_path(delta)
		return
	moving = false
	mine_timer += delta
	if swing <= 0.0:
		swing = 0.2
	if mine_timer >= MINE_TIME:
		mine_timer = 0.0
		var ore: String = mine_target.mine(rng)
		sfx.emit("mine")
		if ore != "":
			add_item(ore)
			sfx.emit("ore")
		if not mine_target.has_ore():
			message.emit("หินแร่ก้อนนี้หมดแล้ว")
			mine_target = null


## คันเบ็ดที่ดีที่สุดในกระเป๋า ("" = ไม่มี)
func best_rod() -> String:
	for id in Fishing.RODS:
		if inventory.get(id, 0) > 0:
			return id
	return ""


## เริ่มตกปลาแบบ AFK ที่จุดน้ำ spot (ต้องมีคันเบ็ด และยืนใกล้น้ำ) ตกไปเรื่อยๆ จนกว่าจะเดินหรือสั่งอย่างอื่น
func command_fish(spot: Vector2) -> bool:
	if best_rod() == "":
		message.emit("ต้องมีคันเบ็ดก่อน ซื้อได้ที่ร้านตาม่องริมลำธาร")
		return false
	if pos.distance_to(spot) > Fishing.REACH + 40.0:
		message.emit("ต้องยืนริมน้ำถึงจะตกปลาได้")
		return false
	attack_target = null
	mine_target = null
	pending_skill = ""
	moving = false
	path.clear()
	fishing = true
	fish_spot = spot
	fish_timer = 0.0
	message.emit("เริ่มตกปลา (ปล่อยไว้ได้เลย ปลาจะติดเบ็ดเองเรื่อยๆ)")
	sfx.emit("splash")
	return true


## เวลาต่อหนึ่งครั้งที่ปลาจะกินเบ็ด (คันเบ็ดดีขึ้นเร็วขึ้น)
func fish_time() -> float:
	var rod := best_rod()
	return ItemDB.ITEMS[rod]["fish_time"] if rod != "" else 10.0


func _tick_fishing(delta: float) -> void:
	var rod := best_rod()
	if rod == "":
		fishing = false
		return
	fish_timer += delta
	if fish_timer < fish_time():
		return
	fish_timer = 0.0
	var item := Fishing.roll(rng, ItemDB.ITEMS[rod]["luck"])
	fish_count += 1
	add_item(item)
	var rare: bool = ItemDB.ITEMS[item]["type"] == "amulet" or item == "pla_buek"
	DamageText.spawn(get_parent(), position + Vector3(0, 2.6, 0), ItemDB.ITEMS[item]["name"] + "!", Color(1.0, 0.85, 0.3) if rare else Color(0.6, 0.9, 1.0))
	sfx.emit("rare" if rare else "catch")
	caught.emit(item)


## ค่าวาร์ปไปแผนที่นั้น (แผนที่ที่ยังไม่เคยไปวาร์ปไม่ได้)
func warp_fee(map_id: String) -> int:
	return World.MAPS[map_id]["fee"]


func can_warp(map_id: String) -> bool:
	return state["visited"].has(map_id) and state["coins"] >= warp_fee(map_id)


func pay_warp(map_id: String) -> bool:
	if not state["visited"].has(map_id):
		message.emit("ต้องเดินทางไป%sด้วยตัวเองก่อนหนึ่งครั้ง" % World.map_name(map_id))
		return false
	if state["coins"] < warp_fee(map_id):
		message.emit("เหรียญไม่พอสำหรับค่าวาร์ป (%d)" % warp_fee(map_id))
		return false
	state["coins"] -= warp_fee(map_id)
	changed.emit()
	return true


# ---------- แฟชั่น (ชุด หมวก ปีก สัตว์เลี้ยง) แยกจากของสวมใส่ ----------

func fashion() -> Dictionary:
	if not state.has("fashion"):
		state["fashion"] = {}
	return state["fashion"]


func wear_fashion(key: String) -> bool:
	if inventory.get(key, 0) <= 0 or not Fashion.is_fashion(key):
		return false
	var slot := Fashion.slot_of(key)
	if fashion().has(slot):
		remove_fashion(slot, false)
	_remove_item(key)
	fashion()[slot] = key
	_after_fashion_change()
	message.emit("ใส่แฟชั่น %s" % ItemDB.display_name(key))
	sfx.emit("buff")
	changed.emit()
	return true


func remove_fashion(slot: String, notify: bool = true) -> bool:
	if not fashion().has(slot):
		return false
	var key: String = fashion()[slot]
	fashion().erase(slot)
	inventory[key] = inventory.get(key, 0) + 1
	if notify:
		_after_fashion_change()
		changed.emit()
	return true


func _after_fashion_change() -> void:
	var old_max: int = stats.get("max_hp", 0)
	recalc()
	hp = mini(stats["max_hp"], hp + maxi(0, stats["max_hp"] - old_max))
	if avatar != null:
		_build_model()
	_refresh_pet()


## แฟชั่นที่ตีบวกได้ (ไม่รวมสัตว์เลี้ยง): ที่ใส่อยู่ (slot = ช่อง) และในกระเป๋า (slot = "")
func fashion_refinable() -> Array:
	var result := []
	for slot in Fashion.SLOTS:
		if slot != "pet" and fashion().has(slot):
			result.append({"key": fashion()[slot], "slot": slot})
	for key in inventory:
		if Fashion.is_fashion(key) and Fashion.slot_of(key) != "pet":
			result.append({"key": key, "slot": ""})
	return result


## ตีบวกแฟชั่นด้วยหินตี+ แฟชั่น 1 ก้อน (ไม่เสียเหรียญ) ตั้งแต่ +7 พลาดแล้วลด 1 ขั้น
## คืน {"ok", "result": "success"/"fail"/"down"/"error", "key", "level"}
func refine_fashion(key: String, slot: String = "") -> Dictionary:
	var err := {"ok": false, "result": "error", "key": key, "level": ItemDB.refine_of(key)}
	var owned: bool = fashion().get(slot, "") == key if slot != "" else inventory.get(key, 0) > 0
	if not owned or not Fashion.is_fashion(key) or Fashion.slot_of(key) == "pet":
		return err
	var lv := ItemDB.refine_of(key)
	if lv >= Fashion.REFINE_MAX:
		message.emit("%s ตีถึง +%d สูงสุดแล้ว" % [ItemDB.display_name(key), Fashion.REFINE_MAX])
		return err
	if inventory.get(Fashion.STONE_ID, 0) <= 0:
		message.emit("ต้องมีหินตี+ แฟชั่น (สุ่มได้จากกาชาปอง)")
		return err
	_remove_item(Fashion.STONE_ID)
	var new_lv := lv
	var result := "fail"
	if rng.randf() < Fashion.REFINE_CHANCE[lv]:
		new_lv = lv + 1
		result = "success"
	elif lv >= Fashion.REFINE_RISKY_FROM:
		new_lv = lv - 1
		result = "down"
	var new_key := ItemDB.refined_key(ItemDB.base_id(key), new_lv)
	if slot != "":
		fashion()[slot] = new_key
		_after_fashion_change()
	else:
		_remove_item(key)
		inventory[new_key] = inventory.get(new_key, 0) + 1
	match result:
		"success":
			levelup_fx = 0.6
			message.emit("ตีบวกแฟชั่นสำเร็จ! ได้ %s" % ItemDB.display_name(new_key))
		"down":
			message.emit("ตีบวกแฟชั่นล้มเหลว... ลดเหลือ +%d" % new_lv)
		_:
			message.emit("ตีบวกแฟชั่นล้มเหลว (ยังอยู่ +%d)" % lv)
	sfx.emit({"success": "refine_ok", "down": "refine_down"}.get(result, "refine_fail"))
	changed.emit()
	return {"ok": result == "success", "result": result, "key": new_key, "level": new_lv}


# ---------- เงิน CC และกาชาปอง ----------

func cc() -> int:
	return int(state.get("cc", 0))


func add_cc(amount: int, why: String = "") -> void:
	if amount <= 0:
		return
	state["cc"] = cc() + amount
	message.emit("+%d CC%s" % [amount, (" (" + why + ")") if why != "" else ""])
	changed.emit()


## ซื้อกาชาปองที่ร้าน CC (ลูกละ Fashion.GACHA_PRICE)
func buy_gacha(count: int = 1) -> bool:
	var price := Fashion.GACHA_PRICE * count
	if count <= 0:
		return false
	if cc() < price:
		message.emit("CC ไม่พอ (ต้องใช้ %d CC)" % price)
		return false
	state["cc"] = cc() - price
	inventory[Fashion.GACHA_ID] = inventory.get(Fashion.GACHA_ID, 0) + count
	sfx.emit("coin")
	message.emit("ซื้อกาชาปอง x%d (-%d CC)" % [count, price])
	changed.emit()
	return true


## เปิดกาชาปองในกระเป๋า คืนรายการ [{"item", "count"}] ที่ได้
func open_gacha(count: int = 1) -> Array:
	var got := []
	count = mini(count, inventory.get(Fashion.GACHA_ID, 0))
	for i in count:
		_remove_item(Fashion.GACHA_ID)
		var r := Fashion.roll_gacha(rng)
		inventory[r["item"]] = inventory.get(r["item"], 0) + r["count"]
		got.append(r)
		var rare: bool = ItemDB.info(r["item"])["type"] == "fashion"
		message.emit("%sกาชาได้ %s x%d" % ["✨ " if rare else "", ItemDB.display_name(r["item"]), r["count"]])
		if rare:
			levelup_fx = 1.0
	if not got.is_empty():
		sfx.emit("rare" if got.any(func(r): return ItemDB.info(r["item"])["type"] == "fashion") else "pickup")
		changed.emit()
	return got


# ---------- สัตว์เลี้ยง ----------

func pet_species() -> String:
	return Fashion.pet_of(fashion().get("pet", ""))


## ให้สัตว์เลี้ยงออกมา/เก็บกลับ ตามช่องแฟชั่น "pet"
func _refresh_pet() -> void:
	var sp := pet_species()
	if pet != null and (sp == "" or pet.species != sp):
		pet.queue_free()
		pet = null
	if sp != "" and pet == null and get_parent() != null:
		pet = Pet.new()
		pet.setup(self, sp)
		get_parent().add_child(pet)


## สัตว์เลี้ยงที่ออกมาด้วยได้ EXP เท่ากับเจ้าของ
func _pet_exp(amount: int) -> void:
	var sp := pet_species()
	if sp == "" or amount <= 0:
		return
	var d := Fashion.pet_data(state, sp)
	var ups := Fashion.add_pet_exp(d, amount)
	if ups > 0:
		recalc()
		message.emit("%s เลเวลอัป! ตอนนี้ Lv.%d" % [Fashion.pet_name(sp, d["stage"]), d["lv"]])
	if pet != null:
		pet.refresh_label()


func can_evolve_pet() -> bool:
	var sp := pet_species()
	if sp == "":
		return false
	var d := Fashion.pet_data(state, sp)
	return d["stage"] < 2 and d["lv"] >= Fashion.EVOLVE_LEVEL[d["stage"]] and pet_trial_passed() \
		and state["coins"] >= Fashion.EVOLVE_FEE[d["stage"]]


## สัตว์เลี้ยงที่ออกมาผ่านบททดสอบของครูฝึกสัตว์สำหรับร่างถัดไปแล้วหรือยัง
func pet_trial_passed() -> bool:
	var sp := pet_species()
	if sp == "":
		return false
	var d := Fashion.pet_data(state, sp)
	return int(d.get("trial", 0)) >= d["stage"] + 1


## id เควสบททดสอบของครูฝึกสัตว์สำหรับร่างถัดไปของสัตว์เลี้ยงที่ออกมา ("" = ไม่มี)
func pet_trial_quest() -> String:
	var sp := pet_species()
	if sp == "":
		return ""
	var stage: int = Fashion.pet_data(state, sp)["stage"] + 1
	for id in Quests.for_giver("khru_fuek_sat"):
		if Quests.QUESTS[id]["pet_stage"] == stage:
			return id
	return ""


## พัฒนาร่างสัตว์เลี้ยงที่ออกมาอยู่ (ได้อีก 2 ขั้น) ต้องถึงเลเวลและจ่ายเหรียญ
func evolve_pet() -> bool:
	var sp := pet_species()
	if sp == "":
		return false
	var d := Fashion.pet_data(state, sp)
	if d["stage"] >= 2:
		message.emit("พัฒนาร่างครบแล้ว")
		return false
	var need: int = Fashion.EVOLVE_LEVEL[d["stage"]]
	var fee: int = Fashion.EVOLVE_FEE[d["stage"]]
	if d["lv"] < need:
		message.emit("สัตว์เลี้ยงต้องถึง Lv.%d ก่อนพัฒนาร่าง" % need)
		return false
	if not pet_trial_passed():
		message.emit("ต้องผ่านบททดสอบของครูฝึกสัตว์ (หมู่บ้านริมคลอง) ก่อน")
		return false
	if state["coins"] < fee:
		message.emit("เหรียญไม่พอ (ค่าพัฒนาร่าง %d)" % fee)
		return false
	state["coins"] -= fee
	d["stage"] += 1
	recalc()
	if pet != null:
		pet.rebuild()
		Effect.pillar(get_parent(), pet.position, 0.8, Fashion.STAGE_COLORS[d["stage"]])
	levelup_fx = 1.2
	sfx.emit("levelup")
	message.emit("พัฒนาร่างสำเร็จ! กลายเป็น %s" % Fashion.pet_name(sp, d["stage"]))
	changed.emit()
	return true


# ---------- บันทึก/โหลดตัวละคร (เซิร์ฟเวอร์หรือเครื่องตัวเองสำหรับ guest) ----------

func save_data() -> Dictionary:
	return {"state": state.duplicate(true), "inventory": inventory.duplicate(), "hp": hp, "sp": sp}


## โหลดข้อมูลที่บันทึกไว้ (ข้อมูลว่าง = ตัวละครใหม่ ใช้ค่าเริ่มต้น)
func apply_save(data: Dictionary) -> void:
	if data.get("state") is Dictionary:
		loaded = true
		var had_slots: bool = data["state"].has("skill_slots")
		var fresh := Progression.new_state()
		for key in fresh:
			if not data["state"].has(key):
				data["state"][key] = fresh[key]
		state = data["state"]
		if not Classes.CLASSES.has(state["class"]):
			state["class"] = "novice"
		if not had_slots:
			# เซฟเก่าก่อนมีช่องสกิล: ใส่สกิลที่เรียนไว้ให้ตามลำดับ
			for id in learned_skills():
				_auto_slot(id)
	if data.get("inventory") is Dictionary:
		inventory = data["inventory"]
	for key in inventory.keys():
		if not ItemDB.has(key):
			inventory.erase(key)
	recalc()
	hp = clampi(int(data.get("hp", stats["max_hp"])), 1, stats["max_hp"])
	sp = clampi(int(data.get("sp", stats["max_sp"])), 0, stats["max_sp"])


## กำลังขุดแร่อยู่ (ยืนถึงหินแล้ว) ระหว่างนี้ผีทำร้ายไม่ได้
func is_mining() -> bool:
	return mine_target != null and is_instance_valid(mine_target) and pos.distance_to(mine_target.pos) <= MINE_REACH


## ความคืบหน้าการขุดครั้งนี้ 0–1 (หลอดเหนือหัว)
func mine_progress() -> float:
	return clampf(mine_timer / MINE_TIME, 0.0, 1.0)


func take_damage(amount: int, by: String = "") -> void:
	if hp <= 0:
		return
	if is_mining():
		DamageText.spawn(get_parent(), position + Vector3(0, 2.4, 0), "กันได้", Color(0.75, 0.85, 1.0))
		return
	hp = maxi(0, hp - amount)
	flash = 0.15
	sfx.emit("hurt")
	DamageText.spawn(get_parent(), position + Vector3(0, 2.4, 0), str(amount), Color(1, 0.45, 0.45))
	if hp == 0:
		_die(by)
	changed.emit()


## สลบ: หยุดทุกอย่าง นอนลงกับพื้น รอผู้เล่นกดปุ่มเกิดเอง
func _die(by: String) -> void:
	dead_by = by
	attack_target = null
	mine_target = null
	pending_skill = ""
	fishing = false
	moving = false
	path.clear()
	message.emit("คุณสลบไป%s... กดปุ่มเกิดใหม่เพื่อฟื้นที่จุดเกิด" % ((" เพราะ" + by) if by != "" else ""))
	died.emit(by)


func is_dead() -> bool:
	return hp <= 0


## กดปุ่มเกิดใหม่: ฟื้นที่จุดเกิดของแผนที่ HP/SP เต็ม
func respawn() -> bool:
	if hp > 0:
		return false
	_revive()
	dead_by = ""
	levelup_fx = 0.6
	if pet != null:
		pet.pos = pos + Pet.FOLLOW_OFFSET
	message.emit("ฟื้นคืนสติแล้ว")
	respawned.emit()
	changed.emit()
	return true


func gain_exp(amount: int, coin_amount: int = 0) -> void:
	var ups := Progression.add_exp(state, amount)
	_pet_exp(amount)
	if amount > 0:
		message.emit("+%d EXP · +%d เหรียญ" % [amount, coin_amount] if coin_amount > 0 else "+%d EXP" % amount)
	elif coin_amount > 0:
		message.emit("+%d เหรียญ" % coin_amount)
	if ups > 0:
		recalc()
		hp = stats["max_hp"]
		sp = stats["max_sp"]
		levelup_fx = 1.2
		sfx.emit("levelup")
		message.emit("เลเวลอัป! ตอนนี้เลเวล %d (แต้มสเตตัส %d)" % [state["level"], state["stat_points"]])
		add_cc(Fashion.CC_PER_LEVEL * ups, "เลเวลอัป")
		if class_level_reached() and state["level"] - ups < class_change_status()["level"]:
			message.emit("ถึงเลเวลเปลี่ยนอาชีพแล้ว! ไปคุยกับครูใหญ่สำนักหน้าโบสถ์เพื่อรับบททดสอบ")
	changed.emit()


func add_item(item_id: String, count: int = 1) -> void:
	inventory[item_id] = inventory.get(item_id, 0) + count
	var item: Dictionary = ItemDB.info(item_id)
	var note := ""
	if item["type"] == "soul":
		note = " ✨ (ไว้ผนึกพลังในอนาคต)"
	elif item["type"] == "equip" or (item["type"] == "fashion" and item.has("bonus")):
		note = " [%s] %s" % [ItemDB.RARITY[item["rarity"]]["name"], ItemDB.bonus_text(item_id)]
	message.emit("ได้รับ %s x%d%s" % [ItemDB.display_name(item_id), count, note])
	changed.emit()


func _remove_item(item_id: String) -> void:
	inventory[item_id] -= 1
	if inventory[item_id] <= 0:
		inventory.erase(item_id)


func _revive() -> void:
	pos = spawn_point
	attack_target = null
	mine_target = null
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
	var sp_gain: int = 1 + state["level"] / 4 + stats["int"] / 10
	if buffs.has("sp_regen"):
		sp_gain = int(round(sp_gain * (1.0 + buffs["sp_regen"]["power"])))
	sp = mini(stats["max_sp"], sp + sp_gain)
	if hp != old_hp or sp != old_sp:
		changed.emit()
