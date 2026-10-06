extends "res://maps/thailand/field_map.gd"
## ประเทศไทย แผนที่ 6: ยมโลก (ผีเลเวล 132–148 + บอสพญามัจจุราช Lv 150) แผนที่สุดท้าย
## ลานศาลยมบาลกลางแผนที่ กระทะทองแดง ต้นงิ้วหนาม บ่อไฟสีส้ม ท้องฟ้าแดงอมม่วง (ยังน่ารักแบบพาสเทล)

const COURT := Rect2(1150, 720, 700, 560)


func _init() -> void:
	map_id = "yom_lok"
	map_name = "ยมโลก"
	world_rect = Rect2(0, 0, 2800, 2000)
	field_rect = Rect2(520, 120, 2200, 1780)
	spawn_point = Vector2(260, 1000)
	seed_value = 6606
	gloom = 0.65
	firefly_color = Color(1.0, 0.55, 0.4)
	gloom_sky = Color(0.55, 0.3, 0.45)
	gloom_horizon = Color(0.95, 0.6, 0.6)
	gloom_fog = Color(0.75, 0.42, 0.5)
	theme = {
		"grass_a": Color(0.52, 0.4, 0.5), "grass_b": Color(0.64, 0.5, 0.58), "tint": Color(0.78, 0.45, 0.48),
		"patch": Color(0.55, 0.42, 0.46), "path": Color(0.82, 0.66, 0.62), "camp": Color(0.86, 0.76, 0.7),
		"plaza": Color(0.7, 0.6, 0.66), "water": Color(1.0, 0.58, 0.3),
	}
	tint_amount = 0.6
	plaza = COURT
	path_segs = [
		[Vector2(60, 1000), Vector2(1150, 1000)],
		[Vector2(1850, 1000), Vector2(2760, 1000)],
		[Vector2(800, 1000), Vector2(780, 450)],
		[Vector2(800, 1000), Vector2(820, 1550)],
		[Vector2(2200, 1000), Vector2(2250, 450)],
		[Vector2(2200, 1000), Vector2(2180, 1550)],
	]
	pond_prop = ""
	ponds = [[Vector2(1500, 420), 150.0], [Vector2(1500, 1620), 150.0], [Vector2(2550, 1600), 120.0]]
	patches = [
		[Vector2(760, 500), 230.0], [Vector2(800, 1500), 240.0], [Vector2(2250, 480), 240.0], [Vector2(2200, 1500), 240.0],
	]
	patch_props = [["ngiw_tree", 90.0], ["incense", 140.0]]
	landmarks = [
		["meru", Vector2(1500, 900)], ["cauldron", Vector2(1280, 1150)], ["cauldron", Vector2(1720, 1150)],
		["ruin_wall", Vector2(1250, 740), PI], ["ruin_wall", Vector2(1750, 740), PI],
		["cauldron", Vector2(760, 500)], ["cauldron", Vector2(2250, 1500)],
		["lantern", Vector2(1120, 940)], ["lantern", Vector2(1880, 940)], ["lantern", Vector2(1120, 1060)], ["lantern", Vector2(1880, 1060)],
	]
	scatters = [
		["ngiw_tree", Rect2(520, 120, 2200, 1780), 30], ["dead_tree", Rect2(520, 120, 2200, 1780), 20],
		["rock", Rect2(520, 120, 2200, 1780), 14], ["bush", Rect2(40, 120, 2700, 1780), 14],
	]
	border_kinds = ["ngiw_tree", "dead_tree", "rock"]
	border_weights = [0.4, 0.4, 0.2]
	decor = [
		["debris", Rect2(520, 120, 2200, 1780), 14], ["candles", COURT, 10], ["coffin", Rect2(520, 120, 2200, 1780), 6],
		["urn", Rect2(520, 120, 2200, 1780), 8],
	]
	grass_base = Color(0.5, 0.36, 0.46)
	grass_tip = Color(0.85, 0.55, 0.62)
	grass_count = 2200
	mist_color = Color(1.0, 0.7, 0.75, 0.14)
	cave_spot = Vector2(2580, 260)
	spawns = [
		{"id": "asurakai", "count": 4, "rect": Rect2(580, 330, 380, 360)},
		{"id": "asurakai", "count": 3, "rect": Rect2(580, 1320, 380, 380)},
		{"id": "yomathut", "count": 3, "rect": Rect2(2050, 300, 420, 380)},
		{"id": "yomathut", "count": 2, "rect": Rect2(1250, 1300, 500, 150)},
		{"id": "pret_awe", "count": 4, "rect": Rect2(2000, 1320, 420, 380)},
	]
	boss_id = "matchurat"
	boss_spawns = [
		{"name": "ลานศาลยมบาล", "pos": Vector2(1500, 1180)},
		{"name": "ดงงิ้วตะวันตก", "pos": Vector2(800, 1500)},
		{"name": "บ่อไฟตะวันออก", "pos": Vector2(2300, 1250)},
	]
	npcs = camp_npcs("phra_malai", "พระมาลัย", {"robe": Color(1.0, 0.72, 0.35), "sash": Color(1.0, 0.85, 0.45), "hat": "bald"},
		["ya_thip", "nam_mon_thep", "ya_hom_thong", "nam_mon_yai"])
	portals = gates("nong_naga", "บึงนาคาบาดาล", Vector2(2620, 1000), "", "")
