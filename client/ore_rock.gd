extends Node3D
## ก้อนหินแร่ในถ้ำ: คลิกเพื่อเดินไปขุด ขุดได้หลายครั้งแล้วหมด จากนั้นงอกใหม่
## แร่ที่ได้สุ่มตามระดับถ้ำ (World.roll_ore): สังกะสีบ่อยสุด เพชรยากสุด
## หินพิเศษ (หินหยกวิญญาณ, เฉพาะถ้ำจีน): ขุดได้มากครั้งกว่า และสุ่มแร่เหมือนถ้ำลึกกว่าเดิม World.SPECIAL_ROCK_BONUS ขั้น

const K = preload("res://maps/props/mesh_kit.gd")
const World = preload("res://shared/data/world.gd")
const ItemDB = preload("res://shared/data/items.gd")

const CHARGES := 4
const RESPAWN := 30.0
const CLICK_RADIUS := 34.0

var pos := Vector2.ZERO
var tier := 1
var charges := CHARGES
var respawn_timer := 0.0
var t := 0.0
var body: Node3D
var gems: Array[MeshInstance3D] = []
var special := false
var max_charges := CHARGES


func setup(at: Vector2, cave_tier: int, variant: int, is_special := false) -> void:
	pos = at
	special = is_special
	tier = cave_tier + (World.SPECIAL_ROCK_BONUS if special else 0)
	max_charges = CHARGES + (2 if special else 0)
	charges = max_charges
	t = variant * 0.7


func has_ore() -> bool:
	return charges > 0


## ขุดหนึ่งครั้ง: คืน id ของแร่ที่ได้ ("" ถ้าหินหมดแล้ว)
func mine(rng: RandomNumberGenerator) -> String:
	if charges <= 0:
		return ""
	charges -= 1
	if body != null:
		body.scale = Vector3.ONE * (0.75 + 0.25 * float(charges) / max_charges)
		body.visible = charges > 0
	if charges <= 0:
		respawn_timer = RESPAWN
	return World.roll_ore(tier, rng)


func tick(delta: float) -> void:
	if charges > 0:
		return
	respawn_timer -= delta
	if respawn_timer <= 0.0:
		charges = max_charges
		if body != null:
			body.scale = Vector3.ONE
			body.visible = true


func _ready() -> void:
	position = K.to3d(pos)
	body = Node3D.new()
	add_child(body)
	var stone := K.mat(Color(0.45, 0.82, 0.66), 0.6, 0.5) if special else K.mat(Color(0.62, 0.58, 0.68), 0.0, 0.9)
	K.sphere(body, 0.55, Vector3(0, 0.35, 0), stone, 7, Vector3(1.2, 0.85, 1.0))
	K.sphere(body, 0.38, Vector3(0.4, 0.25, 0.2), stone, 6, Vector3(1.0, 0.8, 1.1))
	K.sphere(body, 0.32, Vector3(-0.38, 0.22, -0.15), stone if special else K.mat(Color(0.55, 0.52, 0.62), 0.0, 0.9), 6)
	# ประกายแร่สีต่างๆ ฝังในหิน
	var colors := [ItemDB.ITEMS["ore_zinc"]["color"], ItemDB.ITEMS["ore_iron"]["color"], ItemDB.ITEMS["ore_gold"]["color"], ItemDB.ITEMS["ore_diamond"]["color"]]
	var spots := [Vector3(0.2, 0.62, 0.35), Vector3(-0.25, 0.5, 0.38), Vector3(0.5, 0.4, 0.4), Vector3(-0.05, 0.75, 0.0), Vector3(-0.45, 0.35, 0.15)]
	for i in spots.size():
		var c: Color = colors[i % 4] if i < 4 else colors[mini(tier, 3)]
		var g := K.sphere(body, 0.09, spots[i], K.mat(c, 1.6, 0.2, 0.3), 4, Vector3(1, 1.4, 1))
		gems.append(g)
	if special:
		# หินหยกวิญญาณ: ผลึกหยกงอกด้านบน เรืองแสงเขียว
		var jade := K.mat(Color(0.5, 1.0, 0.75), 2.2, 0.2, 0.2)
		for i in 3:
			var a := i * TAU / 3.0
			var c := K.cyl(body, 0.0, 0.12, 0.6, Vector3(cos(a) * 0.25, 0.95, sin(a) * 0.25), jade, 5)
			c.rotation = Vector3(sin(a) * 0.4, 0, -cos(a) * 0.4)
			gems.append(c)
		var glow := OmniLight3D.new()
		glow.light_color = Color(0.5, 1.0, 0.75)
		glow.omni_range = 3.5
		glow.light_energy = 1.4
		glow.position.y = 1.0
		add_child(glow)
	K.label(self, "หินหยกวิญญาณ ✦ หินพิเศษ" if special else "หินแร่ (คลิกเพื่อขุด)", Vector3(0, 1.6, 0), Color(0.6, 1.0, 0.8) if special else Color(1.0, 0.92, 0.7), 28)


func _process(delta: float) -> void:
	t += delta
	for i in gems.size():
		gems[i].rotation.y = t * 1.5 + i
