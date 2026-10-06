extends "res://maps/thailand/field_map.gd"
## ประเทศไทย แผนที่ 4: ดอยผีปันน้ำ (ผีเลเวล 62–85 + บอสพญาพรายเจ้าป่า Lv 100)
## ป่าสนบนดอยมีหมอกขาว ก้อนหินใหญ่ ศาลผีบ้านผีเรือน กระท่อมชาวดอย และแอ่งน้ำซับ

func _init() -> void:
	map_id = "doi_phi"
	map_name = "ดอยผีปันน้ำ"
	world_rect = Rect2(0, 0, 2800, 2000)
	field_rect = Rect2(520, 120, 2200, 1780)
	spawn_point = Vector2(260, 1000)
	seed_value = 4404
	gloom = 0.3
	firefly_color = Color(0.7, 1.0, 0.55)
	gloom_sky = Color(0.55, 0.66, 0.72)
	gloom_horizon = Color(0.88, 0.92, 0.94)
	gloom_fog = Color(0.82, 0.88, 0.9)
	theme = {
		"grass_a": Color(0.36, 0.58, 0.46), "grass_b": Color(0.5, 0.7, 0.5), "tint": Color(0.6, 0.76, 0.82),
		"patch": Color(0.66, 0.62, 0.58), "path": Color(0.8, 0.68, 0.56), "camp": Color(0.86, 0.76, 0.62),
		"plaza": Color(0.7, 0.7, 0.72), "water": Color(0.5, 0.78, 0.86),
	}
	tint_amount = 0.45
	path_segs = [
		[Vector2(60, 1000), Vector2(760, 960)],
		[Vector2(760, 960), Vector2(1350, 1080)],
		[Vector2(1350, 1080), Vector2(1950, 940)],
		[Vector2(1950, 940), Vector2(2760, 1000)],
		[Vector2(760, 960), Vector2(820, 520)],
		[Vector2(1350, 1080), Vector2(1300, 1550)],
		[Vector2(1950, 940), Vector2(2050, 500)],
	]
	ponds = [[Vector2(1700, 1450), 150.0], [Vector2(1050, 520), 110.0]]
	patches = [
		[Vector2(700, 1450), 230.0], [Vector2(1650, 520), 230.0], [Vector2(2350, 1480), 250.0], [Vector2(2380, 520), 220.0],
	]
	patch_props = [["rock", 80.0], ["spirit_house", 260.0]]
	landmarks = [
		["rice_hut", Vector2(980, 1300)], ["rice_hut", Vector2(1150, 1350)], ["spirit_house", Vector2(1450, 800)],
		["rain_tree", Vector2(1500, 1200)], ["haunted_house", Vector2(2150, 1250)],
	]
	scatters = [
		["pine", Rect2(520, 120, 2200, 1780), 70], ["rock", Rect2(520, 120, 2200, 1780), 18],
		["bamboo", Rect2(2400, 120, 360, 1760), 10], ["bush", Rect2(40, 120, 2700, 1780), 26],
		["dead_tree", Rect2(520, 120, 2200, 1780), 6],
	]
	border_kinds = ["pine", "bamboo", "bush"]
	border_weights = [0.6, 0.15, 0.25]
	grass_base = Color(0.38, 0.56, 0.44)
	grass_tip = Color(0.66, 0.8, 0.62)
	grass_count = 3200
	mist_color = Color(0.95, 0.97, 1.0, 0.2)
	cave_spot = Vector2(2560, 300)
	spawns = [
		{"id": "phi_ka", "count": 4, "rect": Rect2(560, 1300, 360, 360)},
		{"id": "phi_ka", "count": 3, "rect": Rect2(600, 300, 360, 300)},
		{"id": "phi_pong", "count": 4, "rect": Rect2(1450, 340, 420, 360)},
		{"id": "phi_pong", "count": 2, "rect": Rect2(1100, 1150, 300, 250)},
		{"id": "nang_mai", "count": 3, "rect": Rect2(2150, 1300, 420, 380)},
		{"id": "nang_mai", "count": 3, "rect": Rect2(2180, 360, 380, 340)},
	]
	boss_id = "phraya_phrai"
	boss_spawns = [
		{"name": "ป่าสนกลางดอย", "pos": Vector2(1650, 700)},
		{"name": "ริมน้ำซับ", "pos": Vector2(1500, 1550)},
		{"name": "ยอดดอยตะวันออก", "pos": Vector2(2400, 1000)},
	]
	npcs = camp_npcs("pu_chan", "ปู่จันทร์หมอผีดอย", {"robe": Color(0.45, 0.42, 0.6), "sash": Color(0.95, 0.4, 0.45), "hat": "headband"},
		["ya_hom_thong", "nam_mon_yai", "ya_thip", "nam_mon_thep"])
	portals = gates("krung_kao", "กรุงเก่าร้าง", Vector2(2620, 1000), "nong_naga", "บึงนาคาบาดาล (Lv 96+)")
