extends RefCounted
## แฟชั่น สัตว์เลี้ยง กาชาปอง และเงิน CC ใช้ร่วมกันทั้ง client และ zone server
## แฟชั่นใส่แยกจากของสวมใส่ (state["fashion"][slot] = คีย์ไอเทม) ค่าพลังรวมเข้า Progression.derive
## สัตว์เลี้ยง: เลเวลเก็บใน state["pets"][species] = {"lv", "exp", "stage"} ได้ EXP พร้อมผู้เล่นตอนออกมาเดินด้วย
## กาชาปอง: ซื้อที่ร้าน CC ลูกละ GACHA_PRICE CC เปิดแล้วสุ่มตาม GACHA_TABLE (แฟชั่น/สัตว์เลี้ยงออกยาก)

const ItemDB = preload("res://shared/data/items.gd")

const SLOTS := ["costume", "hat", "wings", "pet"]
const SLOT_NAMES := {"costume": "ชุด", "hat": "หมวก", "wings": "ปีก", "pet": "สัตว์เลี้ยง"}

## ---- เงิน CC ----
## ตัวละครใหม่ได้ CC เริ่มต้น และได้เพิ่มจากการเลเวลอัป/ปราบบอส (ระบบเติมเงินจริงต้องต่อระบบชำระเงินภายหลัง)
const CC_START := 100
const CC_PER_LEVEL := 2
const CC_PER_BOSS := 10
const GACHA_ID := "gachapon"
const GACHA_PRICE := 10
const STONE_ID := "hin_ti_fashion"

## ---- ตีบวกแฟชั่น (ใช้หินตี+ แฟชั่น 1 ก้อนต่อครั้ง ไม่เสียเหรียญ) ----
const REFINE_MAX := 10
const REFINE_CHANCE := [0.95, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.22, 0.15]
## ตั้งแต่ +7 ถ้าพลาดลดลง 1 ขั้น
const REFINE_RISKY_FROM := 7

## ---- ตารางกาชา: weight รวม 100 = เปอร์เซ็นต์ ----
## แฟชั่นและสัตว์เลี้ยงรวมกัน 7% แบ่งในกลุ่มตามความหายาก (RARITY_WEIGHT)
const GACHA_TABLE := [
	{"item": "kluea_sek", "weight": 26.0, "count": [2, 4]},
	{"item": "ya_hom_thong", "weight": 12.0, "count": [3, 5]},
	{"item": "nam_mon_yai", "weight": 10.0, "count": [3, 5]},
	{"item": "ya_thip", "weight": 7.0, "count": [1, 3]},
	{"item": "nam_mon_thep", "weight": 6.0, "count": [1, 3]},
	{"item": "hin_ti_fashion", "weight": 26.0, "count": [1, 1]},
	{"item": "hin_ti_fashion", "weight": 6.0, "count": [3, 3]},
	{"item": "@fashion", "weight": 7.0, "count": [1, 1]},
]
const RARITY_WEIGHT := {"common": 10.0, "rare": 5.0, "epic": 2.0, "legendary": 0.6}

## ---- สัตว์เลี้ยง ----
## critter = ชนิดโมเดลใน maps/props/critter.gd, size = ขนาดร่างแรก, names = ชื่อแต่ละร่าง (ร่างแรก + พัฒนาได้อีก 2 ขั้น)
## skill: kind = bite (ตีเป้าเดียวแรง) / combo (ตีรัวหลายที) / aoe (กระแทกรอบตัว) / heal (ฮีลเจ้าของ) / holy (เวทศักดิ์สิทธิ์ใส่เป้า+รอบๆ)
const PETS := {
	"maa": {"item": "pet_maa", "critter": "dog", "size": 0.55, "names": ["ลูกหมาบางแก้ว", "หมาบางแก้วผู้พิทักษ์", "เทพสุนัขบางแก้ว"],
		"atk": 1.0, "speed": 1.0, "skill": {"name": "งับวิญญาณ", "kind": "bite", "power": 2.4, "cooldown": 6.0}},
	"maeo": {"item": "pet_maeo", "critter": "cat", "size": 0.5, "names": ["แมววิเชียรมาศ", "แมวมงคลเก้าชีวิต", "พญาแมวมาศ"],
		"atk": 1.05, "speed": 1.1, "skill": {"name": "ข่วนเงาสามคม", "kind": "combo", "power": 1.0, "hits": 3, "cooldown": 7.0}},
	"krathai": {"item": "pet_krathai", "critter": "bunny", "size": 0.45, "names": ["กระต่ายจันทร์", "กระต่ายแสงจันทร์", "เทพกระต่ายพระจันทร์"],
		"atk": 0.8, "speed": 1.15, "skill": {"name": "ยาวิเศษจากดวงจันทร์", "kind": "heal", "power": 0.12, "cooldown": 9.0}},
	"nok": {"item": "pet_nok", "critter": "parrot", "size": 0.45, "names": ["นกแก้วพูดได้", "นกแก้วร่ายมนต์", "พญาวิหคมนตรา"],
		"atk": 1.0, "speed": 1.2, "skill": {"name": "สวดไล่ผี", "kind": "holy", "power": 1.8, "radius": 70.0, "cooldown": 8.0}},
	"chang": {"item": "pet_chang", "critter": "elephant", "size": 0.36, "names": ["ลูกช้างเผือก", "ช้างเผือกคู่บารมี", "เอราวัณน้อย"],
		"atk": 1.25, "speed": 0.9, "skill": {"name": "กระทืบธรณี", "kind": "aoe", "power": 2.0, "radius": 80.0, "cooldown": 8.0}},
}
const PET_MAX_LEVEL := 100
## เลเวลที่ต้องถึงก่อนพัฒนาร่าง และค่าพัฒนา (เหรียญ) ร่าง 1 -> 2 -> 3
const EVOLVE_LEVEL := [30, 60]
const EVOLVE_FEE := [3000, 20000]
## ร่างที่สูงขึ้นเก่งขึ้น (คูณพลังโจมตี) และตัวใหญ่ขึ้น
const STAGE_MULT := [1.0, 1.5, 2.2]
const STAGE_SCALE := [1.0, 1.25, 1.5]
const STAGE_COLORS := [Color(1.0, 0.9, 0.6), Color(0.35, 0.7, 1.0), Color(1.0, 0.62, 0.12)]


static func is_fashion(key: String) -> bool:
	return ItemDB.has(key) and ItemDB.info(key)["type"] == "fashion"


static func slot_of(key: String) -> String:
	return ItemDB.info(key).get("slot", "") if is_fashion(key) else ""


static func pet_of(key: String) -> String:
	return ItemDB.info(key).get("pet", "") if is_fashion(key) else ""


## ข้อมูลเลเวลของสัตว์เลี้ยง (ยังไม่เคยมี = เลเวล 1 ร่างแรก)
static func pet_data(state: Dictionary, species: String) -> Dictionary:
	var pets: Dictionary = state.get("pets", {})
	if not pets.has(species):
		pets[species] = {"lv": 1, "exp": 0, "stage": 0}
		state["pets"] = pets
	return pets[species]


static func pet_name(species: String, stage: int) -> String:
	return PETS[species]["names"][clampi(stage, 0, 2)]


static func pet_exp_to_next(lv: int) -> int:
	return int(round(16.0 * pow(lv, 1.55)))


## พลังโจมตีของสัตว์เลี้ยง: ขึ้นกับเลเวล ร่าง และชนิด
static func pet_atk(species: String, lv: int, stage: int) -> int:
	return int((10 + lv * 4) * STAGE_MULT[clampi(stage, 0, 2)] * PETS[species]["atk"])


## ค่าสเตตัสเล็กๆ ที่สัตว์เลี้ยงให้เจ้าของ (โตตามเลเวล)
static func pet_bonus(species: String, lv: int, stage: int) -> Dictionary:
	var n := lv / 10 + stage * 2
	if n <= 0:
		return {}
	match PETS[species]["skill"]["kind"]:
		"heal":
			return {"vit": n, "int": n}
		"holy":
			return {"int": n, "dex": n}
		"aoe":
			return {"vit": n, "str": n}
	return {"str": n, "agi": n}


## เพิ่ม EXP ให้สัตว์เลี้ยง คืนจำนวนเลเวลที่อัป
static func add_pet_exp(data: Dictionary, amount: int) -> int:
	var ups := 0
	if data["lv"] >= PET_MAX_LEVEL:
		return 0
	data["exp"] += amount
	while data["lv"] < PET_MAX_LEVEL and data["exp"] >= pet_exp_to_next(data["lv"]):
		data["exp"] -= pet_exp_to_next(data["lv"])
		data["lv"] += 1
		ups += 1
	if data["lv"] >= PET_MAX_LEVEL:
		data["exp"] = 0
	return ups


## ค่าพลังรวมจากแฟชั่นที่ใส่อยู่ (รวมผลตีบวก) + สัตว์เลี้ยงที่ออกมาด้วย
static func bonus(state: Dictionary) -> Dictionary:
	var total := {}
	var worn: Dictionary = state.get("fashion", {})
	for slot in worn:
		var key: String = worn[slot]
		if not ItemDB.has(key):
			continue
		var b: Dictionary = ItemDB.bonus_of(key)
		var species := pet_of(key)
		if species != "" and PETS.has(species):
			var d := pet_data(state, species)
			b = pet_bonus(species, d["lv"], d["stage"])
		for k in b:
			total[k] = total.get(k, 0) + b[k]
	return total


## สุ่มของจากกาชาหนึ่งลูก คืน {"item", "count"}
static func roll_gacha(rng: RandomNumberGenerator) -> Dictionary:
	var total := 0.0
	for e in GACHA_TABLE:
		total += e["weight"]
	var r := rng.randf() * total
	for e in GACHA_TABLE:
		r -= e["weight"]
		if r <= 0.0:
			if e["item"] == "@fashion":
				return {"item": roll_fashion(rng), "count": 1}
			return {"item": e["item"], "count": rng.randi_range(e["count"][0], e["count"][1])}
	return {"item": "kluea_sek", "count": 2}


## สุ่มแฟชั่นหนึ่งชิ้นตามความหายาก
static func roll_fashion(rng: RandomNumberGenerator) -> String:
	var pool := fashion_pool()
	var total := 0.0
	for id in pool:
		total += RARITY_WEIGHT[ItemDB.ITEMS[id]["rarity"]]
	var r := rng.randf() * total
	for id in pool:
		r -= RARITY_WEIGHT[ItemDB.ITEMS[id]["rarity"]]
		if r <= 0.0:
			return id
	return pool[0]


static func fashion_pool() -> Array[String]:
	var out: Array[String] = []
	for id in ItemDB.ITEMS:
		if ItemDB.ITEMS[id]["type"] == "fashion":
			out.append(id)
	return out


## โอกาสได้ชิ้นนี้จากกาชาหนึ่งลูก (ไว้แสดงในร้าน)
static func fashion_chance(id: String) -> float:
	var fashion_weight := 0.0
	var total := 0.0
	for e in GACHA_TABLE:
		total += e["weight"]
		if e["item"] == "@fashion":
			fashion_weight += e["weight"]
	var sum := 0.0
	for f in fashion_pool():
		sum += RARITY_WEIGHT[ItemDB.ITEMS[f]["rarity"]]
	return fashion_weight / total * RARITY_WEIGHT[ItemDB.ITEMS[id]["rarity"]] / sum
