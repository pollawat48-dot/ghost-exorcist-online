extends "res://maps/thailand/field_map.gd"
## ประเทศจีน แผนที่ 3: สุสานจักรพรรดิฉิน (ผีเลเวล 69–75 + บอสจักรพรรดิผีฉิน Lv 78)
## ที่ราบดินเหลืองฝุ่นตลบ: ทางศักดิ์สิทธิ์ (เสินเต้า) เรียงด้วยศิลาจารึกบนหลังเต่าและสิงโตหิน
## ทางเหนือเป็นเนินสุสานใหญ่ ทางใต้เป็นหลุมขุดค้นกองทัพทหารดินเผาเรียงแถว

const PIT := Rect2(1150, 1150, 700, 500)


func _init() -> void:
	map_id = "china_tomb"
	country = "ประเทศจีน"
	map_name = "สุสานจักรพรรดิฉิน"
	world_rect = Rect2(0, 0, 2800, 2000)
	field_rect = Rect2(520, 120, 2200, 1780)
	spawn_point = Vector2(260, 1000)
	seed_value = 7303
	gloom = 0.25
	firefly_color = Color(1.0, 0.8, 0.45)
	gloom_sky = Color(0.78, 0.64, 0.5)
	gloom_horizon = Color(0.96, 0.84, 0.66)
	gloom_fog = Color(0.88, 0.74, 0.58)
	theme = {
		"grass_a": Color(0.68, 0.66, 0.46), "grass_b": Color(0.78, 0.72, 0.52), "tint": Color(0.9, 0.72, 0.5),
		"patch": Color(0.84, 0.68, 0.52), "path": Color(0.88, 0.78, 0.64), "camp": Color(0.88, 0.8, 0.68),
		"plaza": Color(0.76, 0.6, 0.48), "water": Color(0.5, 0.7, 0.72),
	}
	tint_amount = 0.55
	plaza = PIT
	camp_hall = "cn_pavilion"
	camp_lamp = "red_lantern"
	camp_shrine = "cn_shrine"
	path_segs = [
		[Vector2(60, 1000), Vector2(1500, 1000)],
		[Vector2(1500, 1000), Vector2(2100, 1040)],
		[Vector2(2100, 1040), Vector2(2760, 1000)],
		[Vector2(1500, 1000), Vector2(1500, 600)],
		[Vector2(1500, 1000), Vector2(1500, 1160)],
		[Vector2(2100, 1040), Vector2(2380, 700)],
		[Vector2(760, 1000), Vector2(740, 1450)],
	]
	pond_prop = ""
	ponds = []
	patches = [
		[Vector2(720, 520), 230.0], [Vector2(720, 1500), 240.0], [Vector2(2250, 1480), 260.0], [Vector2(2300, 800), 200.0],
		[Vector2(1100, 450), 180.0],
	]
	patch_props = [["boulder", 160.0], ["dead_tree", 220.0]]
	landmarks = [
		# ประตูเข้าเขตสุสานกับทางศักดิ์สิทธิ์
		["paifang", Vector2(700, 1000), PI / 2.0],
		["stele", Vector2(880, 925)], ["stele", Vector2(880, 1075)], ["stele", Vector2(1060, 925)], ["stele", Vector2(1060, 1075)],
		["stone_lion", Vector2(1220, 930)], ["stone_lion", Vector2(1220, 1070)],
		["terracotta_statue", Vector2(1360, 905)], ["terracotta_statue", Vector2(1360, 1095), PI],
		# เนินสุสานจักรพรรดิทางเหนือ
		["tomb_mound", Vector2(1500, 380)], ["incense_burner", Vector2(1500, 560)],
		["stone_lion", Vector2(1430, 600)], ["stone_lion", Vector2(1570, 600)],
		["stele", Vector2(1310, 470)], ["stele", Vector2(1690, 470)],
		["red_lantern", Vector2(1420, 760)], ["red_lantern", Vector2(1580, 760)],
		["tomb_mound", Vector2(2440, 560)], ["stele", Vector2(2440, 700)],
		["tomb_mound", Vector2(820, 470)],
		# ศาลารับรองในเขตสุสาน
		["chinese_house", Vector2(1880, 820)], ["cn_shrine", Vector2(2220, 1240)],
	]
	# หลุมขุดค้น: ทหารดินเผาเรียงแถว 3x3
	for row in 3:
		for col in 3:
			landmarks.append(["terracotta_statue", Vector2(1250 + col * 250, 1260 + row * 140)])
	scatters = [
		["dead_tree", Rect2(520, 120, 2200, 1780), 16], ["chinese_pine", Rect2(520, 120, 2200, 1780), 12],
		["rock", Rect2(520, 120, 2200, 1780), 14], ["bush", Rect2(40, 120, 2700, 1780), 12],
		["stele", Rect2(1900, 120, 800, 1780), 4],
	]
	border_kinds = ["dead_tree", "chinese_pine", "rock", "karst_peak"]
	border_weights = [0.3, 0.3, 0.2, 0.2]
	decor = [
		["debris", Rect2(520, 120, 2200, 1780), 14], ["stones", Rect2(520, 120, 2200, 1780), 14],
		["urn", Rect2(1150, 1150, 700, 500), 6], ["boulder", Rect2(520, 120, 2200, 1780), 8],
		["grass_plant", Rect2(520, 120, 2200, 1780), 10],
	]
	critters = [["bunny", Vector2(2200, 1500), 260.0, 2], ["bunny", Vector2(800, 600), 200.0, 2], ["dog", Vector2(300, 1000), 140.0, 1]]
	grass_base = Color(0.6, 0.58, 0.4)
	grass_tip = Color(0.86, 0.8, 0.56)
	grass_count = 1500
	mist_color = Color(1.0, 0.88, 0.7, 0.12)
	cave_spot = Vector2(2560, 1720)
	spawns = [
		{"id": "bingmayong", "count": 6, "rect": Rect2(1170, 1170, 660, 460)},
		{"id": "bingmayong", "count": 4, "rect": Rect2(560, 1300, 380, 380)},
		{"id": "hua_pi", "count": 5, "rect": Rect2(560, 220, 400, 420)},
		{"id": "hua_pi", "count": 5, "rect": Rect2(1850, 230, 400, 380)},
		{"id": "han_ba", "count": 5, "rect": Rect2(2000, 1280, 450, 400)},
		{"id": "han_ba", "count": 4, "rect": Rect2(2250, 780, 420, 180)},
	]
	boss_id = "qin_gui_di"
	boss_spawns = [
		{"name": "หลุมกองทัพดินเผา", "pos": Vector2(1625, 1470)},
		{"name": "หน้าเนินสุสานจักรพรรดิ", "pos": Vector2(1500, 680)},
		{"name": "ทุ่งฝุ่นตะวันออก", "pos": Vector2(2250, 1100)},
	]
	npcs = camp_npcs("dao_shi_li", "นักพรตหลี่", {"robe": Color(0.38, 0.42, 0.62), "sash": Color(0.98, 0.82, 0.42), "hat": "topknot"},
		["ya_thip", "nam_mon_thep", "ya_hom_thong", "nam_mon_yai"])
	portals = gates("china_bamboo", "ป่าไผ่หมอกมรกต", Vector2(2620, 1000), "china_wall", "ด่านกำแพงเมืองจีน (Lv 77+)")
