extends "res://maps/thailand/field_map.gd"
## ประเทศไทย แผนที่ 5: บึงนาคาบาดาล (ผีเลเวล 96–122 + บอสพญานาคทมิฬ Lv 135)
## บึงกว้างหลายแอ่ง มีบัว รูปปั้นนาคเฝ้าทาง ท่าน้ำ เรือ และต้นตาลริมบึง

func _init() -> void:
	map_id = "nong_naga"
	map_name = "บึงนาคาบาดาล"
	world_rect = Rect2(0, 0, 2800, 2000)
	field_rect = Rect2(520, 120, 2200, 1780)
	spawn_point = Vector2(260, 1000)
	seed_value = 5505
	gloom = 0.35
	firefly_color = Color(0.55, 1.0, 0.95)
	gloom_sky = Color(0.4, 0.6, 0.66)
	gloom_horizon = Color(0.72, 0.9, 0.88)
	gloom_fog = Color(0.55, 0.78, 0.78)
	theme = {
		"grass_a": Color(0.34, 0.58, 0.52), "grass_b": Color(0.48, 0.7, 0.58), "tint": Color(0.5, 0.72, 0.78),
		"patch": Color(0.62, 0.6, 0.5), "path": Color(0.82, 0.74, 0.6), "camp": Color(0.86, 0.78, 0.64),
		"plaza": Color(0.78, 0.8, 0.8), "water": Color(0.38, 0.7, 0.78),
	}
	tint_amount = 0.5
	path_segs = [
		[Vector2(60, 1000), Vector2(900, 1000)],
		[Vector2(900, 1000), Vector2(1400, 900)],
		[Vector2(1400, 900), Vector2(2000, 1060)],
		[Vector2(2000, 1060), Vector2(2760, 1000)],
		[Vector2(900, 1000), Vector2(880, 1500)],
		[Vector2(1400, 900), Vector2(1450, 420)],
		[Vector2(2000, 1060), Vector2(2100, 1550)],
	]
	ponds = [
		[Vector2(780, 520), 200.0], [Vector2(1150, 1450), 210.0], [Vector2(1850, 520), 230.0],
		[Vector2(1650, 1420), 170.0], [Vector2(2450, 650), 170.0], [Vector2(2500, 1500), 160.0],
	]
	patches = [[Vector2(1350, 650), 160.0], [Vector2(2250, 1250), 170.0]]
	patch_props = [["incense", 120.0]]
	landmarks = [
		["naga_statue", Vector2(880, 930)], ["naga_statue", Vector2(880, 1070)],
		["naga_statue", Vector2(1960, 990), PI], ["naga_statue", Vector2(2040, 1130), PI],
		["pier", Vector2(1150, 1210)], ["boat", Vector2(1100, 1330)], ["pier", Vector2(1850, 770)],
		["spirit_house", Vector2(1450, 360)], ["ruin_chedi", Vector2(1350, 640)],
	]
	scatters = [
		["palm", Rect2(520, 120, 2200, 1780), 26], ["banana", Rect2(520, 120, 2200, 1780), 14],
		["frangipani", Rect2(520, 120, 2200, 1780), 8], ["bush", Rect2(40, 120, 2700, 1780), 26],
	]
	border_kinds = ["palm", "banana", "bush"]
	border_weights = [0.4, 0.3, 0.3]
	decor = [["grass_plant", Rect2(40, 120, 2700, 1780), 24], ["stones", Rect2(520, 120, 2200, 1780), 12], ["flowers", Rect2(520, 120, 2200, 1780), 10]]
	critters = [["crab", Vector2(1150, 1150), 260.0, 3], ["crab", Vector2(2000, 800), 260.0, 3]]
	grass_base = Color(0.36, 0.56, 0.5)
	grass_tip = Color(0.62, 0.8, 0.68)
	mist_color = Color(0.8, 0.95, 0.95, 0.16)
	cave_spot = Vector2(2580, 260)
	spawns = [
		{"id": "phrai_nam", "count": 4, "rect": Rect2(560, 760, 300, 160)},
		{"id": "phrai_nam", "count": 3, "rect": Rect2(560, 1250, 340, 400)},
		{"id": "phi_naga", "count": 4, "rect": Rect2(1250, 1050, 450, 200)},
		{"id": "phi_naga", "count": 2, "rect": Rect2(1250, 450, 250, 300)},
		{"id": "kong_koi", "count": 3, "rect": Rect2(2150, 900, 450, 300)},
		{"id": "kong_koi", "count": 3, "rect": Rect2(2150, 1250, 200, 400)},
	]
	boss_id = "phaya_nak"
	boss_spawns = [
		{"name": "กลางบึงใหญ่", "pos": Vector2(1400, 1150)},
		{"name": "ท่าน้ำเหนือ", "pos": Vector2(1400, 500)},
		{"name": "ฝั่งบึงตะวันออก", "pos": Vector2(2250, 1100)},
	]
	npcs = camp_npcs("yai_bueng", "ยายเฝ้าบึง", {"robe": Color(0.5, 0.75, 0.7), "sash": Color(1.0, 0.75, 0.5), "hat": "bun"},
		["ya_hom_thong", "nam_mon_yai", "ya_thip", "nam_mon_thep"])
	npcs.append({"id": "chang_ngoen", "name": "ช่างเงินริมบึง", "role": "shop", "sign": "ร้านอาวุธ", "pos": Vector2(200, 1080),
		"look": {"robe": Color(0.75, 0.78, 0.9), "sash": Color(0.6, 0.8, 1.0), "hat": "farmer"},
		"stock": ["dab_ngoen", "thanu_ngoen", "khamphi_ngoen", "kraphan_ngoen", "muak_ngoen"]})
	portals = gates("doi_phi", "ดอยผีปันน้ำ", Vector2(2620, 1000), "yom_lok", "ยมโลก (Lv 132+)")
