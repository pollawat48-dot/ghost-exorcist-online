extends Node2D
## ตัวละครผู้เล่น (ศิษย์วัด): คลิกเพื่อเดิน, คลิกผีเพื่อโจมตี, สกิลโปรยน้ำมนต์
## ตอน M1 คำนวณในเครื่อง ภายหลังผลการต่อสู้จะมาจาก zone server

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
var bounds := Rect2()
var spawn_point := Vector2.ZERO
var ghosts: Node
var nav: Node2D  ## แผนที่ที่มี find_path()

var path := PackedVector2Array()
var path_index := 0
var moving := false
var repath_timer := 0.0
var attack_target: Node2D = null
var attack_cooldown := 0.0
var skill_cooldown := 0.0
var regen_timer := 0.0
var swing := 0.0
var splash := 0.0
var levelup_fx := 0.0
var flash := 0.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	stats = Progression.stats_for_level(state["level"])
	hp = stats["max_hp"]
	sp = stats["max_sp"]
	inventory[HERB_ITEM] = 3


func command_move(pos: Vector2) -> void:
	attack_target = null
	_set_path(Vector2(
		clampf(pos.x, bounds.position.x, bounds.end.x),
		clampf(pos.y, bounds.position.y, bounds.end.y)))


func command_attack(ghost: Node2D) -> void:
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
		if position.distance_to(attack_target.position) > ATTACK_RANGE:
			repath_timer -= delta
			if repath_timer <= 0.0 or not moving:
				repath_timer = REPATH_INTERVAL
				_set_path(attack_target.position)
			_follow_path(delta)
		elif attack_cooldown <= 0.0:
			attack_cooldown = ATTACK_INTERVAL
			swing = 0.2
			var ghost := attack_target
			ghost.take_damage(Combat.damage(stats["atk"], ghost.data["def"], "neutral", ghost.data["element"], rng), self)
	elif moving:
		_follow_path(delta)
	queue_redraw()


func _set_path(dest: Vector2) -> void:
	path = nav.find_path(position, dest) if nav != null else PackedVector2Array([dest])
	path_index = 0
	moving = not path.is_empty()


func _follow_path(delta: float) -> void:
	var step := SPEED * delta
	while step > 0.0 and path_index < path.size():
		var waypoint := path[path_index]
		var d := position.distance_to(waypoint)
		if d <= step:
			position = waypoint
			step -= d
			path_index += 1
		else:
			position = position.move_toward(waypoint, step)
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
		if g.has_method("take_damage") and g.alive and position.distance_to(g.position) <= SKILL_RADIUS:
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
	DamageText.spawn(get_parent(), position + Vector2(0, -36), "+%d" % heal, Color(0.4, 1, 0.4))
	changed.emit()
	return true


func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = maxi(0, hp - amount)
	flash = 0.15
	DamageText.spawn(get_parent(), position + Vector2(0, -36), str(amount), Color(1, 0.45, 0.45))
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
	position = spawn_point
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


func _draw() -> void:
	var body := Color.WHITE if flash > 0.0 else Color(0.95, 0.6, 0.15)
	draw_circle(Vector2(0, 14), 11.0, Color(0, 0, 0, 0.3))
	if splash > 0.0:
		var r := SKILL_RADIUS * (1.0 - splash / 0.4 * 0.5)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(0.6, 0.9, 1.0, splash * 2.0), 4.0)
	if levelup_fx > 0.0:
		draw_arc(Vector2(0, -4), 26.0 + (1.2 - levelup_fx) * 20.0, 0.0, TAU, 40, Color(1, 0.95, 0.4, levelup_fx), 3.0)
	# จีวร
	draw_colored_polygon(PackedVector2Array([Vector2(-11, 14), Vector2(11, 14), Vector2(7, -6), Vector2(-7, -6)]), body)
	draw_line(Vector2(-7, -4), Vector2(9, 12), Color(0.8, 0.4, 0.05), 3.0)
	# หัว
	draw_circle(Vector2(0, -13), 8.0, Color(0.95, 0.82, 0.68))
	draw_circle(Vector2(-3, -14), 1.3, Color.BLACK)
	draw_circle(Vector2(3, -14), 1.3, Color.BLACK)
	# ไม้เท้า/ลูกประคำตอนตี
	if swing > 0.0:
		var a := (0.2 - swing) / 0.2 * PI - PI / 2.0
		draw_line(Vector2(8, -4), Vector2(8, -4) + Vector2(cos(a), sin(a)) * 22.0, Color(0.55, 0.35, 0.15), 3.0)
	var font := ThemeDB.fallback_font
	draw_string_outline(font, Vector2(-60, 32), player_name, HORIZONTAL_ALIGNMENT_CENTER, 120, 12, 3, Color.BLACK)
	draw_string(font, Vector2(-60, 32), player_name, HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color(1, 1, 0.8))
