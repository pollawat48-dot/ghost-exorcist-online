extends "res://maps/thailand/field_map.gd"
## ประเทศไทย: ลำธารใสเย็น (แผนที่ปลอดภัย ไม่มีผี) ไว้ตกปลาแบบ AFK
## ลำธารคดเคี้ยวไหลผ่านทางเหนือ มีท่าน้ำให้ยืนตกปลา บึงบัวทางใต้ ตาม่องขายคันเบ็ดและรับซื้อปลา
## ยืนริมน้ำแล้วกดตกปลา (หรือคลิกที่น้ำ) จะได้ปลาหรือพระเครื่องเรื่อยๆ

const STREAM_Y := 560.0  ## แนวกลางลำธาร
const STREAM_R := 95.0
const LOTUS_POND := Vector2(1900, 1520)


func _init() -> void:
	map_id = "lam_than"
	map_name = "ลำธารใสเย็น"
	fishing = true
	world_rect = Rect2(0, 0, 2800, 2000)
	field_rect = Rect2(520, 120, 2200, 1780)
	spawn_point = Vector2(260, 1000)
	seed_value = 7707
	gloom = 0.0
	firefly_color = Color(0.7, 1.0, 0.6)
	gloom_sky = Color(0.55, 0.62, 0.8)
	gloom_horizon = Color(0.85, 0.9, 0.95)
	gloom_fog = Color(0.7, 0.8, 0.85)
	theme = {
		"grass_a": Color(0.42, 0.68, 0.46), "grass_b": Color(0.58, 0.8, 0.52), "tint": Color(0.55, 0.78, 0.6),
		"patch": Color(0.78, 0.72, 0.55), "path": Color(0.9, 0.8, 0.62), "camp": Color(0.9, 0.82, 0.66),
		"plaza": Color(0.8, 0.8, 0.8), "water": Color(0.45, 0.78, 0.9),
	}
	tint_amount = 0.3
	path_segs = [
		[Vector2(60, 1000), Vector2(900, 1000)],
		[Vector2(900, 1000), Vector2(1500, 1060)],
		[Vector2(1500, 1060), Vector2(2400, 1000)],
		[Vector2(900, 1000), Vector2(940, stream_y(940.0) + STREAM_R + 20.0)],
		[Vector2(1500, 1060), Vector2(1560, stream_y(1560.0) + STREAM_R + 20.0)],
		[Vector2(2100, 1030), Vector2(2160, stream_y(2160.0) + STREAM_R + 20.0)],
		[Vector2(1500, 1060), Vector2(1700, 1330)],
	]
	# ลำธาร = วงน้ำต่อกันเป็นสาย (ให้ shader พื้นกับ is_water ใช้ร่วมกัน)
	var x := 560.0
	while x <= 2900.0:
		ponds.append([Vector2(x, stream_y(x)), STREAM_R + sin(x * 0.013) * 12.0])
		x += 115.0
	ponds.append([LOTUS_POND, 190.0])
	ponds.append([LOTUS_POND + Vector2(260, 60), 130.0])
	patches = [[Vector2(1180, 1450), 150.0]]
	patch_props = []
	landmarks = [
		["pier", Vector2(940, stream_y(940.0) + 70.0)], ["pier", Vector2(1560, stream_y(1560.0) + 70.0)],
		["pier", Vector2(2160, stream_y(2160.0) + 70.0)], ["boat", Vector2(1250, stream_y(1250.0))],
		["sala", Vector2(1180, 1420)], ["spirit_house", Vector2(2500, 1180)],
		["frangipani", Vector2(1040, 1180)], ["frangipani", Vector2(1960, 1200)],
	]
	scatters = [
		["bamboo", Rect2(520, 120, 2200, 260), 14], ["palm", Rect2(520, 820, 2200, 1080), 14],
		["banana", Rect2(520, 820, 2200, 1080), 10], ["rock", Rect2(520, 380, 2200, 420), 10],
		["bush", Rect2(40, 120, 2700, 1780), 26], ["frangipani", Rect2(520, 900, 2200, 1000), 6],
	]
	border_kinds = ["bamboo", "palm", "bush"]
	border_weights = [0.4, 0.3, 0.3]
	decor = [
		["flowers", Rect2(520, 820, 2200, 1080), 24], ["grass_plant", Rect2(40, 120, 2700, 1780), 20],
		["stones", Rect2(520, 380, 2200, 420), 10], ["mushrooms", Rect2(520, 120, 2200, 260), 6],
		["bucket", Rect2(700, 820, 1600, 160), 3],
	]
	critters = [["crab", Vector2(1300, 820), 300.0, 3], ["chick", Vector2(1180, 1300), 150.0, 3], ["dog", Vector2(800, 1000), 200.0, 1], ["cat", Vector2(1600, 1000), 200.0, 1]]
	grass_base = Color(0.42, 0.66, 0.46)
	grass_tip = Color(0.75, 0.9, 0.62)
	mist_color = Color(0.9, 0.98, 1.0, 0.0)
	spawns = []
	boss_id = ""
	npcs = [
		{"id": "ta_mong", "name": "ตาม่อง ร้านคันเบ็ด", "role": "shop", "sign": "ร้านเบ็ด", "pos": Vector2(780, 900),
			"look": {"robe": Color(0.55, 0.75, 0.9), "sash": Color(0.95, 0.75, 0.4), "hat": "farmer"},
			"stock": ["bet_mai", "bet_thong", "herb_potion", "nam_mon"]},
		{"id": "lam_than_warp", "name": "ร่างทรงนำทาง (วาร์ป)", "role": "warp", "pos": Vector2(470, 1010),
			"look": {"robe": Color(0.98, 0.95, 1.0), "sash": Color(0.55, 0.8, 1.0), "hat": "topknot"}},
	]
	portals = [{"pos": PORTAL_WEST, "to": "khlong_village", "to_pos": Vector2(550, 1560), "name": "หมู่บ้านริมคลอง"}]


static func stream_y(x: float) -> float:
	return STREAM_Y + sin(x / 320.0) * 120.0 + sin(x / 130.0) * 25.0
