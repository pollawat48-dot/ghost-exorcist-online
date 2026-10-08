extends "res://maps/thailand/field_map.gd"
## ประเทศไทย แผนที่ 3: กรุงเก่าร้าง (ผีเลเวล 21–28 + บอสขุนศึกผีกรุงเก่า Lv 34)
## ซากเมืองโบราณอิฐแดง: ลานวิหารร้างทางเหนือมีปรางค์สามองค์ เศียรพระในรากโพธิ์ เสาอิฐหักเรียงแถว

const PLAZA := Rect2(1050, 260, 820, 560)


func _init() -> void:
	map_id = "krung_kao"
	map_name = "กรุงเก่าร้าง"
	world_rect = Rect2(0, 0, 2800, 2000)
	field_rect = Rect2(520, 120, 2200, 1780)
	spawn_point = Vector2(260, 1000)
	seed_value = 3303
	gloom = 0.2
	firefly_color = Color(1.0, 0.85, 0.5)
	gloom_sky = Color(0.62, 0.5, 0.6)
	gloom_horizon = Color(0.95, 0.78, 0.7)
	gloom_fog = Color(0.8, 0.66, 0.62)
	theme = {
		"grass_a": Color(0.46, 0.62, 0.42), "grass_b": Color(0.6, 0.73, 0.5), "tint": Color(0.82, 0.64, 0.52),
		"patch": Color(0.84, 0.62, 0.54), "path": Color(0.88, 0.76, 0.62), "camp": Color(0.9, 0.8, 0.66),
		"plaza": Color(0.88, 0.64, 0.56), "water": Color(0.48, 0.74, 0.82),
	}
	tint_amount = 0.5
	plaza = PLAZA
	path_segs = [
		[Vector2(60, 1000), Vector2(800, 1000)],
		[Vector2(800, 1000), Vector2(1460, 960)],
		[Vector2(1460, 960), Vector2(2100, 1040)],
		[Vector2(2100, 1040), Vector2(2760, 1000)],
		[Vector2(1460, 960), Vector2(1460, 820)],
		[Vector2(800, 1000), Vector2(760, 1450)],
		[Vector2(2100, 1040), Vector2(2200, 1500)],
	]
	patches = [
		[Vector2(760, 560), 240.0], [Vector2(760, 1520), 260.0], [Vector2(1500, 1450), 260.0],
		[Vector2(2300, 560), 260.0], [Vector2(2260, 1520), 240.0],
	]
	patch_props = [["brick_pillar", 70.0], ["incense", 160.0]]
	landmarks = [
		["ruin_chedi", Vector2(1260, 430)], ["ruin_chedi", Vector2(1460, 400)], ["ruin_chedi", Vector2(1660, 430)],
		["buddha_head", Vector2(1150, 700)], ["bodhi", Vector2(1780, 700)],
		["ruin_wall", Vector2(1150, 300), PI], ["ruin_wall", Vector2(1760, 300), PI],
		["ruin_wall", Vector2(1120, 860)], ["ruin_wall", Vector2(1800, 860)],
		["buddha_head", Vector2(2400, 1300)], ["haunted_house", Vector2(620, 1350)],
	]
	for i in 6:
		landmarks.append(["brick_pillar", Vector2(1110 + i * 140, 540)])
	scatters = [
		["rain_tree", Rect2(520, 120, 2200, 1780), 14], ["mango", Rect2(520, 120, 2200, 1780), 12],
		["dead_tree", Rect2(520, 120, 2200, 1780), 10], ["bush", Rect2(40, 120, 2700, 1780), 28],
		["broken_fence", Rect2(520, 1100, 2200, 700), 6],
	]
	border_kinds = ["rain_tree", "mango", "bush"]
	border_weights = [0.35, 0.3, 0.35]
	decor = [
		["debris", Rect2(1050, 260, 820, 600), 5], ["stones", Rect2(520, 120, 2200, 1780), 14],
		["urn", PLAZA, 6], ["flowers", Rect2(520, 900, 2200, 1000), 12], ["grass_plant", Rect2(520, 120, 2200, 1780), 16],
	]
	# ลิงแห่งเมืองเก่า (แบบลพบุรี) วิ่งเล่นในลานวิหาร
	critters = [["monkey", Vector2(1460, 640), 300.0, 5], ["dog", Vector2(300, 1000), 140.0, 1]]
	grass_base = Color(0.45, 0.6, 0.4)
	grass_tip = Color(0.72, 0.8, 0.56)
	mist_color = Color(0.95, 0.85, 0.8, 0.1)
	cave_spot = Vector2(2560, 1720)
	spawns = [
		{"id": "phi_tai_hong", "count": 6, "rect": Rect2(580, 360, 380, 380)},
		{"id": "phi_tai_hong", "count": 5, "rect": Rect2(560, 1320, 400, 380)},
		{"id": "phi_hua_khat", "count": 6, "rect": Rect2(1300, 1250, 420, 420)},
		{"id": "phi_hua_khat", "count": 3, "rect": Rect2(1000, 1100, 300, 200)},
		{"id": "thahan_phi", "count": 5, "rect": Rect2(2100, 360, 420, 400)},
		{"id": "thahan_phi", "count": 5, "rect": Rect2(2060, 1320, 420, 400)},
	]
	boss_id = "khun_suek"
	boss_spawns = [
		{"name": "ลานวิหารร้าง", "pos": Vector2(1460, 660)},
		{"name": "ลานเสาอิฐทางใต้", "pos": Vector2(1500, 1450)},
		{"name": "ซากเมืองตะวันออก", "pos": Vector2(2300, 560)},
	]
	npcs = camp_npcs("phra_thudong", "พระธุดงค์", {"robe": Color(1.0, 0.66, 0.3), "sash": Color(0.95, 0.55, 0.25), "hat": "bald"},
		["ya_hom_thong", "nam_mon_yai", "ya_thip", "nam_mon_thep"])
	npcs.append({"id": "chang_dab", "name": "ช่างตีดาบกรุงเก่า", "role": "shop", "sign": "ร้านอาวุธ", "pos": Vector2(200, 1080),
		"look": {"robe": Color(0.7, 0.6, 0.55), "sash": Color(0.95, 0.6, 0.4), "hat": "farmer"},
		"stock": ["dab_lek", "thanu_khao", "khamphi_thong", "suea_so", "suea_kraphan", "mongkhon", "takrut"]})
	npcs.append({"id": "chang_lom_krung", "name": "ช่างหลอมแร่", "role": "smith", "pos": Vector2(300, 1190),
		"look": {"robe": Color(0.55, 0.52, 0.6), "sash": Color(1.0, 0.6, 0.35), "hat": "headband"}})
	portals = gates("pa_cha", "ป่าช้าวัดร้าง", Vector2(2620, 1000), "doi_phi", "ดอยผีปันน้ำ (Lv 30+)")
