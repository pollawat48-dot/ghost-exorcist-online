extends "res://maps/thailand/field_map.gd"
## ประเทศจีน แผนที่ 4: ด่านกำแพงเมืองจีน (ผีเลเวล 77–83 + บอสนางปีศาจกระดูกขาว Lv 86)
## ช่องเขาฤดูใบไม้ร่วง: กำแพงเมืองจีนพาดผ่านกลางแผนที่แนวเหนือ–ใต้ มีหอสังเกตการณ์เป็นระยะ
## ถนนลอดประตูด่านตรงกลาง (ทางเดียวที่ข้ามกำแพงได้) ฝั่งตะวันออกมีค่ายทหารร้างกับกำแพงอีกช่วง

const GATE := Vector2(1500, 1000)
const WALL_X := 1500.0


func _init() -> void:
	map_id = "china_wall"
	country = "ประเทศจีน"
	map_name = "ด่านกำแพงเมืองจีน"
	world_rect = Rect2(0, 0, 2800, 2000)
	field_rect = Rect2(520, 120, 2200, 1780)
	spawn_point = Vector2(260, 1000)
	seed_value = 7404
	gloom = 0.15
	firefly_color = Color(1.0, 0.8, 0.5)
	gloom_sky = Color(0.62, 0.68, 0.8)
	gloom_horizon = Color(0.96, 0.86, 0.76)
	gloom_fog = Color(0.88, 0.82, 0.8)
	theme = {
		"grass_a": Color(0.56, 0.66, 0.46), "grass_b": Color(0.7, 0.75, 0.5), "tint": Color(0.96, 0.7, 0.46),
		"patch": Color(0.74, 0.72, 0.68), "path": Color(0.85, 0.77, 0.66), "camp": Color(0.86, 0.8, 0.7),
		"plaza": Color(0.8, 0.76, 0.7), "water": Color(0.46, 0.72, 0.84),
	}
	tint_amount = 0.6
	camp_hall = "cn_pavilion"
	camp_lamp = "red_lantern"
	camp_shrine = "cn_shrine"
	path_segs = [
		[Vector2(60, 1000), Vector2(700, 980)],
		[Vector2(700, 980), Vector2(1200, 1000)],
		[Vector2(1200, 1000), Vector2(1800, 1000)],
		[Vector2(1800, 1000), Vector2(2300, 1040)],
		[Vector2(2300, 1040), Vector2(2760, 1000)],
		[Vector2(700, 980), Vector2(760, 520)],
		[Vector2(1200, 1000), Vector2(1150, 1450)],
		[Vector2(2300, 1040), Vector2(2350, 1480)],
		[Vector2(2300, 1040), Vector2(2380, 520)],
	]
	ponds = [[Vector2(1000, 620), 110.0], [Vector2(2000, 1600), 120.0]]
	patches = [
		[Vector2(760, 1500), 220.0], [Vector2(1900, 520), 220.0], [Vector2(2250, 1450), 230.0], [Vector2(850, 360), 160.0],
	]
	patch_props = [["rock", 110.0], ["boulder", 200.0]]
	landmarks = [
		# ประตูด่านกลางกำแพง (ถนนลอดผ่าน)
		["pass_gate", GATE, PI / 2.0],
		["red_lantern", Vector2(1380, 900)], ["red_lantern", Vector2(1380, 1100)],
		["red_lantern", Vector2(1620, 900)], ["red_lantern", Vector2(1620, 1100)],
		# หอสังเกตการณ์บนแนวกำแพง
		["watchtower", Vector2(WALL_X, 220)], ["watchtower", Vector2(WALL_X, 620)],
		["watchtower", Vector2(WALL_X, 1380)], ["watchtower", Vector2(WALL_X, 1780)],
		# ค่ายทหารร้างฝั่งตะวันออก
		["great_wall", Vector2(2150, 300)], ["watchtower", Vector2(2400, 300)],
		["chinese_house", Vector2(2050, 780)], ["chinese_house", Vector2(2560, 760)],
		["incense_burner", Vector2(2300, 640)], ["stele", Vector2(1900, 1190)],
		# ภูเขาหินในทุ่ง
		["karst_peak", Vector2(1150, 260)], ["karst_peak", Vector2(1180, 1720)], ["karst_peak", Vector2(2620, 1500)],
		["paifang", Vector2(900, 990), PI / 2.0],
	]
	# แนวกำแพงเหนือ–ใต้เชื่อมหอสังเกตการณ์ (เว้นช่องประตูด่าน)
	for y in [60.0, 420.0, 790.0, 1210.0, 1580.0, 1940.0]:
		landmarks.append(["great_wall_ns", Vector2(WALL_X, y)])
	scatters = [
		["chinese_pine", Rect2(520, 120, 2200, 1780), 34], ["plum_blossom", Rect2(520, 120, 900, 1780), 10],
		["rock", Rect2(520, 120, 2200, 1780), 16], ["bush", Rect2(40, 120, 2700, 1780), 20],
		["dead_tree", Rect2(1600, 120, 1100, 1780), 6],
	]
	border_kinds = ["karst_peak", "chinese_pine", "bush"]
	border_weights = [0.35, 0.45, 0.2]
	decor = [
		["boulder", Rect2(520, 120, 2200, 1780), 10], ["stones", Rect2(520, 120, 2200, 1780), 14],
		["stump", Rect2(520, 120, 2200, 1780), 8], ["flowers", Rect2(520, 120, 2200, 1780), 10],
		["debris", Rect2(1900, 200, 800, 700), 5], ["grass_plant", Rect2(40, 120, 2700, 1780), 14],
	]
	critters = [["monkey", Vector2(900, 1300), 300.0, 3], ["parrot", Vector2(2100, 1300), 300.0, 2], ["bunny", Vector2(800, 700), 220.0, 2]]
	grass_base = Color(0.5, 0.6, 0.4)
	grass_tip = Color(0.95, 0.76, 0.48)
	grass_count = 2600
	mist_color = Color(1.0, 0.97, 0.94, 0.16)
	cave_spot = Vector2(2580, 1770)
	spawns = [
		{"id": "wutou_bing", "count": 5, "rect": Rect2(580, 1250, 380, 420)},
		{"id": "wutou_bing", "count": 5, "rect": Rect2(1650, 330, 360, 330)},
		{"id": "e_gui", "count": 5, "rect": Rect2(1660, 1250, 420, 400)},
		{"id": "e_gui", "count": 4, "rect": Rect2(560, 280, 360, 360)},
		{"id": "baigu_yao", "count": 5, "rect": Rect2(2200, 1220, 440, 400)},
		{"id": "baigu_yao", "count": 5, "rect": Rect2(1000, 1180, 360, 380)},
	]
	boss_id = "baigu_jing"
	boss_spawns = [
		{"name": "หน้าประตูด่าน", "pos": Vector2(1720, 1000)},
		{"name": "หอสังเกตการณ์ร้าง", "pos": Vector2(2400, 460)},
		{"name": "ป่าใบไม้แดง", "pos": Vector2(820, 1460)},
	]
	npcs = camp_npcs("liu_jiang_jun", "แม่ทัพหลิว", {"robe": Color(0.78, 0.36, 0.36), "sash": Color(1.0, 0.8, 0.4), "hat": "headband"},
		["ya_thip", "nam_mon_thep", "ya_hom_thong", "nam_mon_yai"])
	portals = gates("china_tomb", "สุสานจักรพรรดิฉิน", Vector2(2620, 1000), "china_fengdu", "เมืองผีเฟิงตู (Lv 85+)")


## ไม่วางต้นไม้/หินทับแนวกำแพงและประตูด่าน
func _blocked(pos: Vector2, radius: float) -> bool:
	if absf(pos.x - WALL_X) < 70.0 + radius or pos.distance_to(GATE) < 170.0:
		return true
	return super._blocked(pos, radius)


func build_props() -> Node3D:
	super.build_props()
	# ตอม่อสองข้างของประตูด่าน (ประตูไม่มี footprint เอง เพราะถนนต้องลอดช่องกลางได้)
	_mark_solid(Rect2(GATE.x - 48, GATE.y - 118, 96, 66))
	_mark_solid(Rect2(GATE.x - 48, GATE.y + 52, 96, 66))
	return props_root
