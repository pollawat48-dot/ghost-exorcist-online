extends RefCounted
## สกิลทั้งหมด เรียน/อัปด้วยแต้มสกิล (ได้ +1 ทุก 3 เลเวล) สูงสุดเลเวล 5 ต่อสกิล
## kind: single = เป้าเดียว, aoe_self = รอบตัว, aoe_target = รอบเป้าหมาย, buff = เพิ่มพลังตัวเอง, heal = รักษาตัวเอง
##       party_buff = บัฟตัวเองและเพื่อนในปาร์ตี้ที่อยู่ใกล้ (effect: atk/def/aspd/speed/sp_regen เพิ่มเป็นสัดส่วน power)
##       party_heal = ฮีลตัวเองและเพื่อนในปาร์ตี้ที่อยู่ใกล้ (MATK x power)
## stat: atk = พลังโจมตีกายภาพ (STR หรือ DEX ตามสาย), matk = พลังเวท (INT)
## power/radius/sp เป็นค่าที่เลเวล 1 และเพิ่มตาม *_per_lv

const MAX_LEVEL := 5

const SKILLS := {
	"holy_water": {
		"name": "โปรยน้ำมนต์", "class": "novice", "icon": "water", "kind": "aoe_self", "stat": "atk",
		"element": "holy", "power": 1.2, "power_per_lv": 0.2, "radius": 90.0, "radius_per_lv": 6.0,
		"sp": 8, "sp_per_lv": 1, "cooldown": 2.0, "range": 0.0,
		"desc": "สาดน้ำมนต์รอบตัว แรงมากกับผีวิญญาณ",
	},
	# ---- สายประชิด ----
	"fan_khatha": {
		"name": "ฟันคาถา", "class": "nak_rob", "icon": "slash", "kind": "single", "stat": "atk",
		"element": "holy", "power": 1.8, "power_per_lv": 0.3, "sp": 10, "sp_per_lv": 1, "cooldown": 1.5, "range": 50.0,
		"desc": "ฟันดาบลงอาคมใส่ผีหนึ่งตัวอย่างแรง",
	},
	"kong_kraphan": {
		"name": "อาคมคงกระพัน", "class": "nak_rob", "icon": "shield", "kind": "buff", "stat": "atk",
		"element": "neutral", "power": 0.15, "power_per_lv": 0.1, "duration": 20.0, "sp": 15, "sp_per_lv": 2, "cooldown": 25.0, "range": 0.0,
		"desc": "หนังเหนียว เพิ่มพลังป้องกันชั่วคราว",
	},
	"dab_wian": {
		"name": "ดาบหมุนวน", "class": "nak_dab", "icon": "storm", "kind": "aoe_self", "stat": "atk",
		"element": "neutral", "power": 1.5, "power_per_lv": 0.25, "radius": 100.0, "radius_per_lv": 5.0,
		"sp": 18, "sp_per_lv": 2, "cooldown": 4.0, "range": 0.0,
		"desc": "หมุนดาบฟันผีทุกตัวรอบตัว",
	},
	"dab_fa_fuen": {
		"name": "ดาบฟ้าฟื้น", "class": "khun_phaen", "icon": "star", "kind": "aoe_target", "stat": "atk",
		"element": "holy", "power": 3.0, "power_per_lv": 0.5, "radius": 120.0, "radius_per_lv": 8.0,
		"sp": 40, "sp_per_lv": 4, "cooldown": 10.0, "range": 60.0,
		"desc": "สุดยอดวิชา ฟาดดาบเรียกสายฟ้าศักดิ์สิทธิ์",
	},
	"plook_kamlang": {
		"name": "ปลุกพลังกล้า", "class": "nak_rob", "icon": "sword_one", "kind": "party_buff", "effect": "atk", "stat": "atk",
		"element": "neutral", "power": 0.1, "power_per_lv": 0.05, "duration": 60.0, "sp": 20, "sp_per_lv": 2, "cooldown": 30.0, "range": 0.0,
		"desc": "ตะโกนปลุกใจ ตัวเองและเพื่อนในปาร์ตี้ตีแรงขึ้น (สูงสุด +30%)",
	},
	"kraw_yant": {
		"name": "เกราะยันต์หมู่", "class": "nak_dab", "icon": "shield", "kind": "party_buff", "effect": "def", "stat": "atk",
		"element": "neutral", "power": 0.15, "power_per_lv": 0.05, "duration": 60.0, "sp": 25, "sp_per_lv": 2, "cooldown": 35.0, "range": 0.0,
		"desc": "ลงยันต์กันภัยให้ทั้งปาร์ตี้ พลังป้องกันเพิ่ม (สูงสุด +35%)",
	},
	# ---- สายระยะไกล ----
	"ying_son": {
		"name": "ยิงซ้อน", "class": "phran", "icon": "arrow", "kind": "single", "stat": "atk",
		"element": "neutral", "power": 1.8, "power_per_lv": 0.3, "sp": 9, "sp_per_lv": 1, "cooldown": 1.2, "range": 240.0,
		"desc": "ยิงธนูสองดอกติดกันใส่ผีหนึ่งตัว",
	},
	"tan_nammon": {
		"name": "ศรน้ำมนต์", "class": "phran", "icon": "water", "kind": "single", "stat": "atk",
		"element": "holy", "power": 1.5, "power_per_lv": 0.3, "sp": 12, "sp_per_lv": 1, "cooldown": 2.0, "range": 240.0,
		"desc": "ลูกธนูชุบน้ำมนต์ แรงมากกับผีวิญญาณ",
	},
	"fon_thanu": {
		"name": "ฝนธนู", "class": "phran_ratri", "icon": "storm", "kind": "aoe_target", "stat": "atk",
		"element": "neutral", "power": 1.4, "power_per_lv": 0.25, "radius": 110.0, "radius_per_lv": 6.0,
		"sp": 20, "sp_per_lv": 2, "cooldown": 5.0, "range": 250.0,
		"desc": "ยิงธนูขึ้นฟ้าให้ตกลงมาเป็นห่าฝน",
	},
	"ngao_sanghan": {
		"name": "เงาสังหาร", "class": "mue_prab", "icon": "star", "kind": "single", "stat": "atk",
		"element": "holy", "power": 4.0, "power_per_lv": 0.6, "sp": 35, "sp_per_lv": 3, "cooldown": 8.0, "range": 270.0,
		"desc": "ลูกธนูเงาที่ไม่เคยพลาดเป้า",
	},
	"ta_thip": {
		"name": "ตาทิพย์", "class": "phran", "icon": "star", "kind": "party_buff", "effect": "aspd", "stat": "atk",
		"element": "neutral", "power": 0.08, "power_per_lv": 0.04, "duration": 60.0, "sp": 18, "sp_per_lv": 2, "cooldown": 30.0, "range": 0.0,
		"desc": "เปิดตาทิพย์ให้ทั้งปาร์ตี้ ตีเร็วขึ้น (สูงสุด +24%)",
	},
	"lom_phat": {
		"name": "ลมพัดไว", "class": "phran_ratri", "icon": "storm", "kind": "party_buff", "effect": "speed", "stat": "atk",
		"element": "neutral", "power": 0.15, "power_per_lv": 0.05, "duration": 60.0, "sp": 18, "sp_per_lv": 2, "cooldown": 30.0, "range": 0.0,
		"desc": "เรียกลมหนุนส่ง ทั้งปาร์ตี้เดินเร็วขึ้น (สูงสุด +35%)",
	},
	# ---- สายเวท ----
	"yant_ploeng": {
		"name": "ยันต์เพลิง", "class": "mo_phi", "icon": "fire", "kind": "single", "stat": "matk",
		"element": "fire", "power": 2.0, "power_per_lv": 0.35, "sp": 12, "sp_per_lv": 1, "cooldown": 1.5, "range": 200.0,
		"desc": "ปายันต์ลุกเป็นไฟใส่ผีหนึ่งตัว",
	},
	"fon_nammon": {
		"name": "ฝนน้ำมนต์", "class": "mo_phi", "icon": "water", "kind": "aoe_target", "stat": "matk",
		"element": "holy", "power": 1.3, "power_per_lv": 0.25, "radius": 100.0, "radius_per_lv": 6.0,
		"sp": 18, "sp_per_lv": 2, "cooldown": 3.0, "range": 200.0,
		"desc": "เรียกฝนน้ำมนต์ตกใส่ผีเป็นวงกว้าง",
	},
	"mon_fuen_kai": {
		"name": "มนต์ฟื้นกาย", "class": "ajarn_yant", "icon": "heal", "kind": "heal", "stat": "matk",
		"element": "holy", "power": 1.5, "power_per_lv": 0.4, "sp": 20, "sp_per_lv": 2, "cooldown": 6.0, "range": 0.0,
		"desc": "เป่ามนต์รักษาบาดแผลตัวเอง",
	},
	"nam_mon_chalom": {
		"name": "น้ำมนต์ชโลมหมู่", "class": "mo_phi", "icon": "heal", "kind": "party_heal", "stat": "matk",
		"element": "holy", "power": 1.0, "power_per_lv": 0.3, "sp": 25, "sp_per_lv": 3, "cooldown": 8.0, "range": 0.0,
		"desc": "พรมน้ำมนต์ฮีลตัวเองและทุกคนในปาร์ตี้ที่อยู่ใกล้",
	},
	"samathi": {
		"name": "สมาธิแก่กล้า", "class": "ajarn_yant", "icon": "water", "kind": "party_buff", "effect": "sp_regen", "stat": "matk",
		"element": "neutral", "power": 0.5, "power_per_lv": 0.25, "duration": 60.0, "sp": 20, "sp_per_lv": 2, "cooldown": 40.0, "range": 0.0,
		"desc": "นำสวดภาวนา ทั้งปาร์ตี้ฟื้น SP เร็วขึ้น (สูงสุด x2.5)",
	},
	"maha_akkhi": {
		"name": "มหาอัคคีเวทย์", "class": "jom_khamang", "icon": "fire", "kind": "aoe_target", "stat": "matk",
		"element": "fire", "power": 3.5, "power_per_lv": 0.5, "radius": 150.0, "radius_per_lv": 8.0,
		"sp": 45, "sp_per_lv": 4, "cooldown": 10.0, "range": 230.0,
		"desc": "เพลิงเวทย์ลุกท่วมทุกสิ่งในวงกว้าง",
	},
}


static func power(id: String, lv: int) -> float:
	return SKILLS[id]["power"] + SKILLS[id]["power_per_lv"] * (lv - 1)


static func radius(id: String, lv: int) -> float:
	return SKILLS[id].get("radius", 0.0) + SKILLS[id].get("radius_per_lv", 0.0) * (lv - 1)


static func sp_cost(id: String, lv: int) -> int:
	return SKILLS[id]["sp"] + SKILLS[id]["sp_per_lv"] * (lv - 1)


## สกิลของคลาสในสายนี้ เรียงตามขั้นคลาส
static func for_lineage(lineage: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for cls in lineage:
		for id in SKILLS:
			if SKILLS[id]["class"] == cls:
				result.append(id)
	return result


## บัฟ/ฮีลที่ส่งผลถึงเพื่อนในปาร์ตี้
static func is_party(id: String) -> bool:
	return SKILLS[id]["kind"] in ["party_buff", "party_heal"]
