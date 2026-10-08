extends "res://maps/thailand/field_map.gd"
## ประเทศจีน แผนที่ 5: เมืองผีเฟิงตู (ผีเลเวล 85–89 + บอสพญายมราช Lv 90) แผนที่สุดท้ายของจีน
## เมืองผีฟ้าหม่นม่วง: แม่น้ำไน่เหอสีเขียวผีไหลผ่านแนวเหนือ–ใต้ ข้ามด้วยสะพานหินซีด
## ประตูผีเฟิงตูเปิดเข้าลานศาลยมราช บ้านเรือนหลังคาดำแขวนโคมผีเขียวฟ้า กองกระดาษเงินกระดาษทองไหว้ผี
## ดอกพลับพลึงแดงขึ้นริมแม่น้ำ

const COURT := Rect2(1520, 680, 680, 640)
const RIVER_X := 1050.0
const BRIDGE := Rect2(RIVER_X - 150, 1000 - 34, 300, 68)


func _init() -> void:
	map_id = "china_fengdu"
	country = "ประเทศจีน"
	map_name = "เมืองผีเฟิงตู"
	world_rect = Rect2(0, 0, 2800, 2000)
	field_rect = Rect2(520, 120, 2200, 1780)
	spawn_point = Vector2(260, 1000)
	seed_value = 7505
	gloom = 0.7
	firefly_color = Color(0.55, 1.0, 0.85)
	gloom_sky = Color(0.3, 0.22, 0.44)
	gloom_horizon = Color(0.58, 0.44, 0.72)
	gloom_fog = Color(0.44, 0.34, 0.58)
	theme = {
		"grass_a": Color(0.33, 0.28, 0.42), "grass_b": Color(0.43, 0.36, 0.52), "tint": Color(0.42, 0.52, 0.64),
		"patch": Color(0.42, 0.36, 0.46), "path": Color(0.64, 0.58, 0.68), "camp": Color(0.72, 0.66, 0.72),
		"plaza": Color(0.52, 0.48, 0.6), "water": Color(0.3, 0.54, 0.52),
	}
	tint_amount = 0.5
	plaza = COURT
	camp_hall = "cn_pavilion"
	camp_lamp = "red_lantern"
	camp_shrine = "cn_shrine"
	path_segs = [
		[Vector2(60, 1000), Vector2(1520, 1000)],
		[Vector2(2200, 1000), Vector2(2760, 1000)],
		[Vector2(700, 1000), Vector2(720, 450)],
		[Vector2(700, 1000), Vector2(740, 1550)],
		[Vector2(1860, 680), Vector2(1850, 380)],
		[Vector2(1860, 1320), Vector2(1850, 1620)],
		[Vector2(2420, 1000), Vector2(2450, 450)],
		[Vector2(2420, 1000), Vector2(2440, 1500)],
	]
	# แม่น้ำไน่เหอ: วงกลมเรียงต่อกันเป็นสายน้ำคดเคี้ยวจากเหนือจรดใต้
	pond_prop = ""
	ponds = []
	for i in 21:
		ponds.append([Vector2(RIVER_X + sin(i * 0.6) * 40.0, i * 100.0), 112.0])
	patches = [
		[Vector2(700, 480), 220.0], [Vector2(740, 1520), 230.0], [Vector2(1850, 380), 200.0], [Vector2(1850, 1640), 200.0],
		[Vector2(2450, 460), 220.0], [Vector2(2440, 1500), 230.0],
	]
	patch_props = [["spider_lily", 70.0], ["paper_offerings", 220.0]]
	landmarks = [
		# สะพานไน่เหอข้ามแม่น้ำ
		["spirit_bridge", Vector2(RIVER_X, 1000)],
		# ประตูผีเข้าลานศาลยมราช
		["fengdu_gate", Vector2(1490, 1000), PI / 2.0],
		["stone_lion", Vector2(1430, 880)], ["stone_lion", Vector2(1430, 1120)],
		["incense_burner", Vector2(1860, 1000)], ["paper_offerings", Vector2(1760, 860)], ["paper_offerings", Vector2(1960, 1140)],
		["ghost_house", Vector2(1860, 780)], ["ghost_house", Vector2(1860, 1220), PI],
		["ghost_lantern", Vector2(1600, 760)], ["ghost_lantern", Vector2(2120, 760)],
		["ghost_lantern", Vector2(1600, 1240)], ["ghost_lantern", Vector2(2120, 1240)],
		# ถนนผีระหว่างแม่น้ำกับประตู
		["ghost_lantern", Vector2(1220, 930)], ["ghost_lantern", Vector2(1220, 1070)],
		["ghost_lantern", Vector2(860, 930)], ["ghost_lantern", Vector2(860, 1070)],
		["ghost_house", Vector2(1300, 780)], ["ghost_house", Vector2(1300, 1220), PI],
		# ตำหนักผีฝั่งตะวันออก
		["ghost_house", Vector2(2420, 790)], ["ghost_house", Vector2(2420, 1210), PI],
		["pagoda", Vector2(1850, 260)], ["stele", Vector2(1740, 470)], ["stele", Vector2(1960, 470)],
		["incense_burner", Vector2(2450, 1000)], ["ghost_lantern", Vector2(2300, 940)], ["ghost_lantern", Vector2(2580, 1060)],
		["paper_offerings", Vector2(600, 1200)], ["paper_offerings", Vector2(620, 800)],
	]
	scatters = [
		["dead_tree", Rect2(520, 120, 2200, 1780), 22], ["spider_lily", Rect2(880, 0, 340, 2000), 26],
		["ghost_lantern", Rect2(520, 120, 2200, 1780), 8], ["rock", Rect2(520, 120, 2200, 1780), 10],
		["ngiw_tree", Rect2(520, 120, 2200, 1780), 8], ["spider_lily", Rect2(520, 120, 2200, 1780), 20],
	]
	border_kinds = ["dead_tree", "karst_peak", "ngiw_tree"]
	border_weights = [0.4, 0.4, 0.2]
	decor = [
		["candles", COURT, 10], ["urn", Rect2(520, 120, 2200, 1780), 8], ["coffin", Rect2(520, 120, 2200, 1780), 5],
		["debris", Rect2(520, 120, 2200, 1780), 8], ["stones", Rect2(520, 120, 2200, 1780), 10],
	]
	critters = [["cat", Vector2(1860, 1000), 260.0, 2]]
	grass_base = Color(0.34, 0.28, 0.42)
	grass_tip = Color(0.62, 0.5, 0.74)
	grass_count = 2000
	mist_color = Color(0.75, 0.6, 0.95, 0.16)
	cave_spot = Vector2(2580, 1790)
	spawns = [
		{"id": "niu_tou", "count": 5, "rect": Rect2(560, 250, 360, 400)},
		{"id": "niu_tou", "count": 5, "rect": Rect2(560, 1320, 360, 400)},
		{"id": "ma_mian", "count": 5, "rect": Rect2(1240, 260, 440, 340)},
		{"id": "ma_mian", "count": 5, "rect": Rect2(1240, 1420, 440, 340)},
		{"id": "hei_bai", "count": 5, "rect": Rect2(2240, 260, 430, 400)},
		{"id": "hei_bai", "count": 4, "rect": Rect2(2240, 1300, 430, 380)},
	]
	boss_id = "yan_wang"
	boss_spawns = [
		{"name": "ลานศาลยมราช", "pos": Vector2(1860, 1100)},
		{"name": "ริมแม่น้ำไน่เหอ", "pos": Vector2(800, 680)},
		{"name": "ตำหนักผีตะวันออก", "pos": Vector2(2560, 1000)},
	]
	npcs = camp_npcs("meng_po", "ยายเหมิ่งโพ", {"robe": Color(0.58, 0.48, 0.64), "sash": Color(0.96, 0.62, 0.72), "hat": "bun"},
		["ya_thip", "nam_mon_thep", "ya_hom_thong", "nam_mon_yai"])
	portals = gates("china_wall", "ด่านกำแพงเมืองจีน", Vector2(2620, 1000), "", "")


## สะพานข้ามแม่น้ำเดินได้ (น้ำใต้สะพานยังวาดอยู่บนพื้น)
func is_water(p: Vector2) -> bool:
	if BRIDGE.has_point(p):
		return false
	return super.is_water(p)
