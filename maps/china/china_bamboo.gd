extends "res://maps/thailand/field_map.gd"
## ประเทศจีน แผนที่ 2: ป่าไผ่หมอกมรกต (ผีเลเวล 61–67 + บอสจิ้งจอกเก้าหาง Lv 70)
## ป่าไผ่เขียวมรกตหมอกลอยต่ำ ทางหินคดเคี้ยว ทางเหนือมีลานเจดีย์จีนล้อมกำแพงประตูวงพระจันทร์
## สระบัวมีสะพานโค้งราวแดงกับศาลาชมสวน ต้นเหมยบานสีชมพู ภูเขาหินปูนรอบขอบแผนที่

const COURT := Rect2(1200, 230, 500, 390)


func _init() -> void:
	map_id = "china_bamboo"
	country = "ประเทศจีน"
	map_name = "ป่าไผ่หมอกมรกต"
	world_rect = Rect2(0, 0, 2800, 2000)
	field_rect = Rect2(520, 120, 2200, 1780)
	spawn_point = Vector2(260, 1000)
	seed_value = 7202
	gloom = 0.25
	firefly_color = Color(0.7, 1.0, 0.75)
	gloom_sky = Color(0.6, 0.76, 0.72)
	gloom_horizon = Color(0.88, 0.96, 0.92)
	gloom_fog = Color(0.8, 0.92, 0.86)
	theme = {
		"grass_a": Color(0.38, 0.62, 0.48), "grass_b": Color(0.5, 0.75, 0.54), "tint": Color(0.62, 0.84, 0.74),
		"patch": Color(0.6, 0.68, 0.56), "path": Color(0.82, 0.8, 0.7), "camp": Color(0.86, 0.8, 0.68),
		"plaza": Color(0.8, 0.82, 0.78), "water": Color(0.46, 0.78, 0.76),
	}
	tint_amount = 0.45
	plaza = COURT
	camp_hall = "cn_pavilion"
	camp_lamp = "red_lantern"
	camp_shrine = "cn_shrine"
	path_segs = [
		[Vector2(60, 1000), Vector2(750, 1040)],
		[Vector2(750, 1040), Vector2(1400, 960)],
		[Vector2(1400, 960), Vector2(2000, 1060)],
		[Vector2(2000, 1060), Vector2(2760, 1000)],
		[Vector2(1400, 960), Vector2(1450, 620)],
		[Vector2(750, 1040), Vector2(1000, 640)],
		[Vector2(2000, 1060), Vector2(2050, 1300)],
		[Vector2(1400, 960), Vector2(1450, 1350)],
	]
	ponds = [[Vector2(1000, 470), 120.0], [Vector2(2060, 1500), 140.0]]
	patches = [
		[Vector2(720, 1480), 220.0], [Vector2(1450, 1480), 230.0], [Vector2(2300, 520), 240.0], [Vector2(720, 420), 190.0],
	]
	patch_props = [["taihu_rock", 200.0], ["spider_lily", 400.0]]
	landmarks = [
		# ลานเจดีย์จีนทางเหนือ
		["pagoda", Vector2(1450, 400)], ["incense_burner", Vector2(1450, 565)],
		["moon_gate", Vector2(1300, 640)], ["moon_gate", Vector2(1600, 640)],
		["stone_lion", Vector2(1395, 690)], ["stone_lion", Vector2(1505, 690)],
		["cn_pavilion", Vector2(1265, 330)], ["cn_shrine", Vector2(1640, 300)],
		["plum_blossom", Vector2(1260, 520)], ["plum_blossom", Vector2(1640, 520)], ["plum_blossom", Vector2(1660, 410)],
		["red_lantern", Vector2(1340, 780)], ["red_lantern", Vector2(1560, 780)],
		# สระบัวกับสะพานโค้งและศาลาชมสวน
		["arch_bridge", Vector2(1000, 470)], ["cn_pavilion", Vector2(1080, 670)],
		["plum_blossom", Vector2(840, 600)], ["plum_blossom", Vector2(1160, 330)], ["taihu_rock", Vector2(880, 340)],
		# ศาลเจ้าเล็กกับศิลาจารึกในป่า
		["cn_shrine", Vector2(1700, 1190)], ["stele", Vector2(2250, 1220)], ["cn_shrine", Vector2(820, 1220)],
		["paifang", Vector2(1880, 1042), PI / 2.0],
		["plum_blossom", Vector2(1960, 1320)], ["plum_blossom", Vector2(2200, 1350)],
	]
	scatters = [
		["bamboo_cn", Rect2(520, 120, 2200, 1780), 62], ["chinese_pine", Rect2(520, 120, 2200, 1780), 10],
		["plum_blossom", Rect2(520, 120, 2200, 1780), 10], ["taihu_rock", Rect2(520, 120, 2200, 1780), 6],
		["bush", Rect2(40, 120, 2700, 1780), 18],
	]
	border_kinds = ["bamboo_cn", "karst_peak", "chinese_pine"]
	border_weights = [0.5, 0.25, 0.25]
	decor = [
		["mushrooms", Rect2(520, 120, 2200, 1780), 14], ["stump", Rect2(520, 120, 2200, 1780), 8],
		["flowers", Rect2(520, 120, 2200, 1780), 12], ["grass_plant", Rect2(40, 120, 2700, 1780), 16],
		["stones", Rect2(520, 120, 2200, 1780), 10],
	]
	critters = [["bunny", Vector2(900, 1300), 260.0, 3], ["monkey", Vector2(2200, 700), 300.0, 3], ["parrot", Vector2(1450, 820), 300.0, 2]]
	grass_base = Color(0.36, 0.58, 0.44)
	grass_tip = Color(0.64, 0.84, 0.6)
	grass_count = 3000
	mist_color = Color(0.95, 1.0, 0.97, 0.24)
	cave_spot = Vector2(2560, 1720)
	spawns = [
		{"id": "huli_jing", "count": 5, "rect": Rect2(560, 240, 300, 420)},
		{"id": "huli_jing", "count": 5, "rect": Rect2(1240, 1260, 420, 400)},
		{"id": "diao_si_gui", "count": 5, "rect": Rect2(1950, 260, 440, 400)},
		{"id": "diao_si_gui", "count": 5, "rect": Rect2(580, 1290, 380, 400)},
		{"id": "nu_gui", "count": 5, "rect": Rect2(1880, 1320, 500, 400)},
		{"id": "nu_gui", "count": 4, "rect": Rect2(2330, 760, 340, 400)},
	]
	boss_id = "jiuwei_hu"
	boss_spawns = [
		{"name": "หน้าลานเจดีย์หมอก", "pos": Vector2(1450, 760)},
		{"name": "ริมสระบัว", "pos": Vector2(880, 760)},
		{"name": "ดงไผ่ตะวันออก", "pos": Vector2(2350, 1280)},
	]
	npcs = camp_npcs("xian_gu", "นักพรตหญิงเซียนกู", {"robe": Color(0.96, 0.96, 1.0), "sash": Color(0.55, 0.82, 0.72), "hat": "bun"},
		["ya_thip", "nam_mon_thep", "ya_hom_thong", "nam_mon_yai"])
	portals = gates("china_harbor", "ท่าเรือเมืองเฉวียนโจว", Vector2(2620, 1000), "china_tomb", "สุสานจักรพรรดิฉิน (Lv 69+)")
