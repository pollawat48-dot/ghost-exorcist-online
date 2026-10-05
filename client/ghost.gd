extends Node2D
## ผีหนึ่งตัว: เดินวน, ไล่ตีเมื่อถูกโจมตี (หรือเมื่อเห็นผู้เล่นถ้าเป็นผีดุ)
## ตอน M1 คำนวณในเครื่อง ภายหลังจะย้าย AI นี้ไปไว้ที่ zone server

const Combat = preload("res://shared/combat/combat.gd")
const GhostDB = preload("res://shared/data/ghosts.gd")
const DamageText = preload("res://client/damage_text.gd")

signal died(ghost: Node2D)

const AGGRO_RADIUS := 150.0
const LEASH_RADIUS := 350.0

var ghost_id := ""
var data := {}
var hp := 0
var alive := true
var home := Vector2.ZERO
var player: Node2D
var target: Node2D = null
var returning := false
var attack_cooldown := 0.0
var wander_target := Vector2.ZERO
var wander_wait := 0.0
var flash := 0.0
var bob := 0.0
var rng := RandomNumberGenerator.new()


func setup(id: String, pos: Vector2, player_ref: Node2D, seed_value: int) -> void:
	ghost_id = id
	data = GhostDB.GHOSTS[id]
	hp = data["hp"]
	position = pos
	home = pos
	wander_target = pos
	player = player_ref
	rng.seed = seed_value
	bob = rng.randf() * TAU


func take_damage(amount: int, attacker: Node2D) -> void:
	if not alive:
		return
	hp -= amount
	flash = 0.15
	target = attacker
	returning = false
	DamageText.spawn(get_parent(), position + Vector2(0, -30), str(amount), Color.WHITE)
	if hp <= 0:
		alive = false
		died.emit(self)
		queue_free()
	queue_redraw()


func tick(delta: float) -> void:
	if not alive:
		return
	bob += delta * 3.0
	flash = maxf(0.0, flash - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)

	if returning and position.distance_to(home) < 30.0:
		returning = false
	if target == null and not returning and data["aggressive"] and player.hp > 0 \
			and position.distance_to(player.position) < AGGRO_RADIUS:
		target = player
	if target != null and (not is_instance_valid(target) or target.hp <= 0 \
			or position.distance_to(home) > LEASH_RADIUS):
		target = null
		returning = true
		wander_target = home

	if target != null:
		if position.distance_to(target.position) > data["attack_range"]:
			position = position.move_toward(target.position, data["speed"] * 1.3 * delta)
		elif attack_cooldown <= 0.0:
			attack_cooldown = data["attack_interval"]
			target.take_damage(Combat.damage(data["atk"], target.stats["def"], "neutral", "none", rng))
	else:
		_wander(delta)
	queue_redraw()


func _wander(delta: float) -> void:
	if position.distance_to(wander_target) < 4.0:
		wander_wait -= delta
		if wander_wait <= 0.0:
			wander_target = home + Vector2(rng.randf_range(-90, 90), rng.randf_range(-90, 90))
			wander_wait = rng.randf_range(1.0, 3.0)
	else:
		var speed: float = data["speed"] * (1.2 if returning else 0.5)
		position = position.move_toward(wander_target, speed * delta)


func _draw() -> void:
	var y := sin(bob) * 3.0
	var c: Color = Color.WHITE if flash > 0.0 else data["color"]
	draw_circle(Vector2(0, 16), 9.0, Color(0, 0, 0, 0.25))
	draw_circle(Vector2(0, y), 20.0, Color(c, 0.18))
	match ghost_id:
		"krasue_noi":
			# หัวลอยได้ มีไส้ห้อยระย้า
			for i in 3:
				draw_line(Vector2(-4 + i * 4, y + 6), Vector2(-6 + i * 6, y + 18 + i % 2 * 3), Color(0.8, 0.1, 0.2), 2.0)
			draw_circle(Vector2(0, y - 3), 11.0, Color(0.1, 0.05, 0.1))
			draw_circle(Vector2(0, y), 8.0, Color.WHITE if flash > 0.0 else Color(0.95, 0.9, 0.85))
			draw_circle(Vector2(-3, y - 1), 1.6, Color(0.9, 0, 0))
			draw_circle(Vector2(3, y - 1), 1.6, Color(0.9, 0, 0))
		"phi_takiang":
			# ตะเกียงเรืองแสงมีตา
			draw_rect(Rect2(-9, y - 12, 18, 22), c)
			draw_rect(Rect2(-6, y - 16, 12, 4), Color(0.25, 0.15, 0.1))
			draw_rect(Rect2(-6, y + 10, 12, 3), Color(0.25, 0.15, 0.1))
			draw_circle(Vector2(-3, y - 3), 2.0, Color.BLACK)
			draw_circle(Vector2(3, y - 3), 2.0, Color.BLACK)
			draw_line(Vector2(-3, y + 4), Vector2(3, y + 4), Color.BLACK, 1.5)
		_:
			draw_circle(Vector2(0, y), 10.0, c)

	var font := ThemeDB.fallback_font
	draw_string_outline(font, Vector2(-60, y - 30), data["name"], HORIZONTAL_ALIGNMENT_CENTER, 120, 12, 3, Color.BLACK)
	draw_string(font, Vector2(-60, y - 30), data["name"], HORIZONTAL_ALIGNMENT_CENTER, 120, 12, Color(1, 0.9, 0.9))
	if hp < data["hp"]:
		draw_rect(Rect2(-16, y - 24, 32, 4), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-16, y - 24, 32.0 * hp / data["hp"], 4), Color(0.9, 0.2, 0.2))
