extends RefCounted
## เลเวล สเตตัส และค่าพลังของผู้เล่น ใช้ร่วมกันทั้ง client และ zone server
## ได้แต้มสเตตัส +1 ทุกเลเวล และแต้มสกิล +1 ทุก 3 เลเวล เลเวลตันที่ 150

const Classes = preload("res://shared/data/classes.gd")
const ItemDB = preload("res://shared/data/items.gd")
const Fashion = preload("res://shared/data/fashion.gd")

const MAX_LEVEL := 150
const STATS := ["str", "agi", "vit", "int", "dex", "luk"]
const STAT_NAMES := {
	"str": "STR พลัง", "agi": "AGI ว่องไว", "vit": "VIT อึด",
	"int": "INT ปัญญา", "dex": "DEX แม่นยำ", "luk": "LUK โชค",
}
const STAT_DESC := {
	"str": "เพิ่มพลังตีประชิด", "agi": "ตีเร็วขึ้น", "vit": "เพิ่ม HP และพลังป้องกัน",
	"int": "เพิ่มพลังเวทและ SP", "dex": "เพิ่มพลังยิงระยะไกล", "luk": "เพิ่มโอกาสคริติคอล",
}
const BASE_STAT := 5
const START_COINS := 200
const SKILL_POINT_EVERY := 3


## หลอด EXP ยาวขึ้นเรื่อยๆ ตามเลเวล (ยิ่งสูงยิ่งต้องเล่นนาน): เลเวล 10 ราว 1.1 พัน, 50 ราว 3.1 หมื่น, 90 ราว 1.2 แสน
static func exp_to_next(level: int) -> int:
	return int(round(20.0 * pow(level, 1.6) * (1.0 + level / 25.0)))


## สร้างข้อมูลตัวละครใหม่ (ศิษย์วัด เลเวล 1)
static func new_state() -> Dictionary:
	var base := {}
	for s in STATS:
		base[s] = BASE_STAT
	return {
		"level": 1, "exp": 0, "class": "novice",
		"base": base, "stat_points": 0, "skill_points": 0,
		"skills": {"holy_water": 1}, "equipment": {},
		"coins": START_COINS, "quests": {}, "quests_done": {},
		"visited": {}, "caves": [],
		"skill_slots": ["holy_water", "", "", "", "", "", "", "", ""],
		"fashion": {}, "pets": {}, "cc": Fashion.CC_START,
	}


## รวมค่าสเตตัสจากของสวมใส่ + แฟชั่น + สัตว์เลี้ยง
static func equipment_bonus(state: Dictionary) -> Dictionary:
	var total := Fashion.bonus(state)
	for slot in state["equipment"]:
		var bonus := ItemDB.bonus_of(state["equipment"][slot])
		for key in bonus:
			total[key] = total.get(key, 0) + bonus[key]
	return total


## ค่าพลังที่ใช้จริง: คำนวณจากเลเวล สเตตัส คลาส และของสวมใส่
static func derive(state: Dictionary) -> Dictionary:
	var level: int = state["level"]
	var cls: Dictionary = Classes.CLASSES[state["class"]]
	var bonus := equipment_bonus(state)
	var s := {}
	for key in STATS:
		s[key] = state["base"][key] + bonus.get(key, 0)
	var main_stat: int = s["dex"] if cls["attack"] == "ranged" else s["str"]
	return {
		"str": s["str"], "agi": s["agi"], "vit": s["vit"], "int": s["int"], "dex": s["dex"], "luk": s["luk"],
		"max_hp": int((60 + level * 12 + s["vit"] * 8) * cls["hp_mult"]),
		"max_sp": int((15 + level * 3 + s["int"] * 4) * cls["sp_mult"]),
		"atk": 6 + level + main_stat * 2 + bonus.get("atk", 0),
		"matk": 4 + level + s["int"] * 3 + bonus.get("matk", 0),
		"def": level / 2 + s["vit"] + bonus.get("def", 0),
		"attack_interval": clampf(1.0 - s["agi"] * 0.006, 0.35, 1.0) * cls["aspd"],
		"crit": minf(0.5, s["luk"] * 0.004),
		"attack": cls["attack"],
		"range": cls["range"],
	}


## เพิ่ม EXP ให้ state แล้วคืนจำนวนเลเวลที่อัป (แจกแต้มสเตตัส/สกิลให้ด้วย)
static func add_exp(state: Dictionary, amount: int) -> int:
	var gained := 0
	if state["level"] >= MAX_LEVEL:
		return 0
	state["exp"] += amount
	while state["level"] < MAX_LEVEL and state["exp"] >= exp_to_next(state["level"]):
		state["exp"] -= exp_to_next(state["level"])
		state["level"] += 1
		gained += 1
		if state.has("stat_points"):
			state["stat_points"] += 1
			if state["level"] % SKILL_POINT_EVERY == 0:
				state["skill_points"] += 1
	if state["level"] >= MAX_LEVEL:
		state["exp"] = 0
	return gained
