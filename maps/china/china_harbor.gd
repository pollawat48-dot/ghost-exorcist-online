extends "res://maps/thailand/field_map.gd"
## ประเทศจีน แผนที่ 1: ท่าเรือเมืองเฉวียนโจว (ผีเลเวล 55–58 + บอสราชาเจียงซือ Lv 62)
## เมืองท่าริมทะเลสดใส: ฝั่งตะวันตกเป็นทะเลกับท่าเทียบเรือ เรือสำเภาจอดในอ่าวเหนือ/ใต้
## ถนนสายหลักลอดซุ้มไผฟางเข้าลานตลาด มีแผงขายของ สายโคมแดงขึงข้ามถนน
## ทางแยกเหนือไปศาลเจ้าแม่ทับทิม (เจดีย์จีน) ฝั่งตะวันออกมีบึงน้ำที่ผีน้ำซุ่มอยู่
## ไม่มีประตูฝั่งตะวันตก (เป็นทะเล) กลับเมืองไทยต้องคุยกับนายท้ายเรือสำเภาที่ท่าเรือ

const WATER_SHADER = preload("res://maps/thailand/water.gdshader")
const MARKET := Rect2(820, 820, 400, 340)


func _init() -> void:
	map_id = "china_harbor"
	country = "ประเทศจีน"
	map_name = "ท่าเรือเมืองเฉวียนโจว"
	world_rect = Rect2(0, 0, 2800, 2000)
	field_rect = Rect2(520, 120, 2200, 1780)
	spawn_point = Vector2(260, 1000)
	seed_value = 7101
	gloom = 0.0
	firefly_color = Color(1.0, 0.85, 0.5)
	theme = {
		"grass_a": Color(0.52, 0.74, 0.52), "grass_b": Color(0.66, 0.82, 0.56), "tint": Color(0.95, 0.86, 0.64),
		"patch": Color(0.93, 0.85, 0.68), "path": Color(0.88, 0.8, 0.72), "camp": Color(0.9, 0.84, 0.72),
		"plaza": Color(0.88, 0.8, 0.76), "water": Color(0.42, 0.75, 0.9),
	}
	tint_amount = 0.35
	plaza = MARKET
	camp_hall = "cn_pavilion"
	camp_lamp = "red_lantern"
	camp_shrine = "cn_shrine"
	path_segs = [
		[Vector2(60, 1000), Vector2(700, 1000)],
		[Vector2(700, 1000), Vector2(1300, 975)],
		[Vector2(1300, 975), Vector2(1900, 1040)],
		[Vector2(1900, 1040), Vector2(2760, 1000)],
		[Vector2(1300, 975), Vector2(1350, 560)],
		[Vector2(1000, 990), Vector2(990, 1500)],
		[Vector2(1900, 1040), Vector2(2000, 1450)],
		[Vector2(300, 980), Vector2(160, 720)],
	]
	# ทะเลฝั่งตะวันตก (แนววงกลมเรียงกันเป็นชายฝั่ง) + อ่าวเหนือ/ใต้ + บึงน้ำในเมือง
	pond_prop = ""
	ponds = []
	for i in 11:
		ponds.append([Vector2(-200, i * 200.0), 250.0])
	ponds.append([Vector2(300, 460), 250.0])
	ponds.append([Vector2(300, 1580), 250.0])
	ponds.append([Vector2(2240, 1500), 150.0])
	ponds.append([Vector2(2090, 430), 110.0])
	patches = [
		[Vector2(720, 1460), 200.0], [Vector2(1700, 560), 190.0], [Vector2(2450, 800), 210.0], [Vector2(620, 620), 150.0],
	]
	patch_props = [["crate", 120.0], ["barrel", 140.0]]
	landmarks = [
		# ประตูเมืองกับลานตลาด
		["paifang", Vector2(640, 1000), PI / 2.0],
		["market_stall", Vector2(880, 860)], ["market_stall", Vector2(1010, 860)], ["market_stall", Vector2(1140, 860)],
		["market_stall", Vector2(880, 1120), PI], ["market_stall", Vector2(1010, 1120), PI], ["market_stall", Vector2(1140, 1120), PI],
		["lantern_string", Vector2(780, 1000), PI / 2.0], ["lantern_string", Vector2(1240, 978), PI / 2.0],
		["lantern_string", Vector2(1600, 1008), PI / 2.0], ["lantern_string", Vector2(2150, 1028), PI / 2.0],
		# ศาลเจ้าแม่ทับทิมทางเหนือ
		["pagoda", Vector2(1360, 380)], ["incense_burner", Vector2(1352, 518)],
		["stone_lion", Vector2(1285, 570)], ["stone_lion", Vector2(1420, 570)],
		["paifang", Vector2(1343, 690)],
		["red_lantern", Vector2(1270, 800)], ["red_lantern", Vector2(1420, 800)],
		# บ้านเรือนและร้านค้าริมถนน
		["chinese_house", Vector2(650, 790)], ["chinese_house", Vector2(650, 1210), PI],
		["chinese_house", Vector2(1470, 810)], ["chinese_house", Vector2(1680, 840)],
		["chinese_house", Vector2(1480, 1200), PI], ["chinese_house", Vector2(1700, 1210), PI],
		["chinese_house", Vector2(2380, 1190), PI], ["chinese_house", Vector2(2400, 820)],
		# โกดังทางใต้
		["chinese_house", Vector2(1140, 1380)], ["chinese_house", Vector2(1150, 1620), PI],
		["red_lantern", Vector2(1040, 1300)], ["red_lantern", Vector2(940, 1300)],
		# ท่าเรือและเรือสำเภา
		["dock", Vector2(552, 460), PI], ["dock", Vector2(552, 1580), PI],
		["dock", Vector2(40, 880), PI], ["dock", Vector2(40, 1120), PI],
		["junk_boat", Vector2(270, 360), 0.25], ["junk_boat", Vector2(250, 1690), -0.2],
		["junk_boat", Vector2(-160, 1000), 0.0], ["junk_boat", Vector2(-420, 620), 0.6], ["junk_boat", Vector2(-400, 1460), -0.5],
		["fish_rack", Vector2(620, 690)], ["fish_rack", Vector2(600, 1300)],
		# บัวในบึง
		["lotus", Vector2(2200, 1450)], ["lotus", Vector2(2290, 1560)], ["lotus", Vector2(2170, 1580)], ["lotus", Vector2(2080, 400)],
	]
	scatters = [
		["chinese_pine", Rect2(520, 120, 2200, 1780), 22], ["plum_blossom", Rect2(520, 120, 2200, 1780), 16],
		["bush", Rect2(520, 120, 2200, 1780), 22], ["taihu_rock", Rect2(1500, 120, 1200, 1780), 6],
		["bamboo_cn", Rect2(2300, 120, 420, 1780), 8],
	]
	border_kinds = ["chinese_pine", "bush", "plum_blossom", "bamboo_cn"]
	border_weights = [0.4, 0.3, 0.15, 0.15]
	decor = [
		["crate", Rect2(560, 560, 260, 240), 3], ["barrel", Rect2(560, 1250, 260, 200), 3],
		["flowers", Rect2(520, 120, 2200, 1780), 14], ["grass_plant", Rect2(520, 120, 2200, 1780), 14],
		["stones", Rect2(520, 120, 2200, 1780), 8],
	]
	critters = [
		["crab", Vector2(130, 700), 110.0, 3], ["crab", Vector2(140, 1300), 110.0, 2],
		["villager", Vector2(1010, 990), 260.0, 5], ["cat", Vector2(1000, 1000), 200.0, 2],
		["chick", Vector2(1100, 1450), 160.0, 3], ["dog", Vector2(300, 1000), 140.0, 1],
	]
	grass_base = Color(0.48, 0.68, 0.46)
	grass_tip = Color(0.76, 0.86, 0.6)
	grass_count = 2600
	mist_color = Color(1.0, 1.0, 1.0, 0.07)
	cave_spot = Vector2(2560, 300)
	spawns = [
		{"id": "jiangshi", "count": 5, "rect": Rect2(580, 1300, 340, 380)},
		{"id": "jiangshi", "count": 5, "rect": Rect2(1450, 1270, 400, 360)},
		{"id": "jiangshi", "count": 5, "rect": Rect2(2250, 640, 420, 300)},
		{"id": "shui_gui", "count": 5, "rect": Rect2(2000, 1290, 480, 420)},
		{"id": "shui_gui", "count": 5, "rect": Rect2(1880, 260, 420, 320)},
		{"id": "shui_gui", "count": 4, "rect": Rect2(580, 260, 280, 380)},
	]
	boss_id = "jiangshi_wang"
	boss_spawns = [
		{"name": "ตรอกโกดังใต้", "pos": Vector2(1650, 1450)},
		{"name": "ลานศาลเจ้าแม่ทับทิม", "pos": Vector2(1220, 640)},
		{"name": "ริมบึงตะวันออก", "pos": Vector2(2300, 1240)},
	]
	npcs = camp_npcs("lao_zhang", "เหล่าจาง หมอผีท่าเรือ", {"robe": Color(0.45, 0.5, 0.72), "sash": Color(0.95, 0.45, 0.42), "hat": "chinese"},
		["ya_thip", "nam_mon_thep", "ya_hom_thong", "nam_mon_yai"])
	npcs.append({"id": "chuan_zhang_cn", "name": "นายท้ายเรือสำเภา (กลับเมืองไทย)", "role": "boat", "pos": Vector2(80, 640),
		"look": {"robe": Color(0.4, 0.55, 0.75), "sash": Color(1.0, 0.75, 0.4), "hat": "farmer"}})
	npcs.append({"id": "china_harbor_gear", "name": "ช่างตีดาบเฉวียนโจว", "role": "shop", "sign": "ร้านอาวุธ", "pos": Vector2(200, 1080),
		"look": {"robe": Color(0.62, 0.42, 0.42), "sash": Color(1.0, 0.72, 0.4), "hat": "chinese"},
		"stock": ["dab_jian_cn", "thanu_khao_pae", "khamphi_muek_cn", "kraphan_fai_cn", "muak_pha_cn"]})
	# ฝั่งตะวันตกเป็นทะเล: มีแค่ประตูตะวันออกไปป่าไผ่
	portals = [{"pos": PORTAL_EAST, "to": "china_bamboo", "to_pos": Vector2(260, 1000), "name": "ป่าไผ่หมอกมรกต (Lv 61+)"}]


## ผืนทะเลนอกขอบแผนที่ฝั่งตะวันตก ต่อจากชายฝั่งบนพื้น
func _build_ground() -> void:
	super._build_ground()
	var h := world_rect.size.y * K.S + 400.0
	var plane := PlaneMesh.new()
	plane.size = Vector2(300.0, h)
	var sea := MeshInstance3D.new()
	sea.name = "Sea"
	sea.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	mat.set_shader_parameter("deep_color", Color(0.36, 0.66, 0.86))
	mat.set_shader_parameter("shallow_color", Color(0.56, 0.84, 0.95))
	sea.material_override = mat
	sea.position = Vector3(-150.0 + 0.5, -0.04, world_rect.size.y * K.S / 2.0)
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sea)


## ไม่ปลูกต้นไม้ริมทะเล (ขอบตะวันตก)
func _border_ring(kinds: Array, weights: Array, skip: Callable = Callable()) -> void:
	super._border_ring(kinds, weights, func(p: Vector2) -> bool: return p.x < 140.0)
