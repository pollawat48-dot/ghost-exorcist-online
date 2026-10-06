extends RefCounted
## เควสจาก NPC ใช้ร่วมกันทั้ง client และ zone server
## type: kill = ปราบผีให้ครบ, collect = หาของมาส่ง (ส่งแล้วของถูกหักออกจากกระเป๋า)
## giver = id ของ NPC, requires = ต้องทำเควสนี้จบก่อน, repeatable = รับซ้ำได้หลังส่ง
## สถานะในตัวละคร: state["quests"] = {id: จำนวนที่ปราบแล้ว}, state["quests_done"] = {id: จำนวนครั้งที่ส่ง}

const GhostDB = preload("res://shared/data/ghosts.gd")
const ItemDB = preload("res://shared/data/items.gd")

const QUESTS := {
	# ---- ครูใหญ่สำนัก: บททดสอบเปลี่ยนอาชีพ (ส่งแล้วจ่ายค่าครูเพื่อเลื่อนขั้นได้) ----
	"q_trial_1": {
		"giver": "khru_yai", "name": "บททดสอบศิษย์วัด", "type": "kill", "target": "phi_takiang", "count": 15,
		"min_level": 10, "requires": "", "repeatable": false, "trial": 1,
		"desc": "พิสูจน์ว่าเจ้าพร้อมเป็นผู้ปราบผีเต็มตัว ไปปราบผีตะเกียงในป่ากล้วยให้ได้ 15 ตัว",
		"reward": {"exp": 300, "coins": 0, "items": {}},
	},
	"q_trial_2": {
		"giver": "khru_yai", "name": "บททดสอบผู้กล้า: นางพญากระสือ", "type": "kill", "target": "krasue_queen", "count": 1,
		"min_level": 50, "requires": "q_trial_1", "repeatable": false, "trial": 2,
		"desc": "ผู้ที่จะเลื่อนขั้นต้องปราบบอสประจำถิ่นได้ด้วยตัวเอง จงปราบนางพญากระสือที่หมู่บ้านริมคลอง",
		"reward": {"exp": 5000, "coins": 0, "items": {}},
	},
	"q_trial_3": {
		"giver": "khru_yai", "name": "บททดสอบปรมาจารย์: พญาเปรต", "type": "kill", "target": "pret_king", "count": 1,
		"min_level": 100, "requires": "q_trial_2", "repeatable": false, "trial": 3,
		"desc": "บททดสอบสุดท้าย ปราบพญาเปรตแห่งป่าช้าวัดร้าง แล้วกลับมารับตำแหน่งขั้นสูงสุด",
		"reward": {"exp": 30000, "coins": 0, "items": {}},
	},
	# ---- หลวงตาเมือง (หมู่บ้านริมคลอง) ----
	"q_krasue": {
		"giver": "luang_ta", "name": "กระสือกวนทุ่งนา", "type": "kill", "target": "krasue_noi", "count": 8,
		"min_level": 1, "requires": "", "repeatable": false,
		"desc": "ผีกระสือน้อยออกมากินข้าวในนาของชาวบ้านทุกคืน ช่วยไล่ไปที",
		"reward": {"exp": 150, "coins": 120, "items": {"herb_potion": 3}},
	},
	"q_thread": {
		"giver": "luang_ta", "name": "ด้ายแดงผูกข้อมือ", "type": "collect", "target": "red_thread", "count": 5,
		"min_level": 2, "requires": "q_krasue", "repeatable": false,
		"desc": "หลวงตาจะทำสายสิญจน์แจกเด็กในหมู่บ้าน ขอด้ายแดงจากผีกระสือ 5 เส้น",
		"reward": {"exp": 220, "coins": 150, "items": {"saisin": 1}},
	},
	"q_takiang": {
		"giver": "luang_ta", "name": "ดับไฟผีตะเกียง", "type": "kill", "target": "phi_takiang", "count": 10,
		"min_level": 4, "requires": "q_krasue", "repeatable": false,
		"desc": "ผีตะเกียงในป่ากล้วยดุร้ายขึ้นทุกวัน ปราบให้ได้ 10 ตัว",
		"reward": {"exp": 600, "coins": 300, "items": {"nam_mon": 5}},
	},
	"q_shard": {
		"giver": "luang_ta", "name": "รวบรวมเศษวิญญาณ", "type": "collect", "target": "spirit_shard", "count": 10,
		"min_level": 3, "requires": "", "repeatable": true,
		"desc": "เศษวิญญาณใช้ทำพิธีส่งดวงวิญญาณ นำมาส่งได้เรื่อยๆ",
		"reward": {"exp": 120, "coins": 100, "items": {}},
	},
	"q_queen": {
		"giver": "luang_ta", "name": "ปราบนางพญากระสือ", "type": "kill", "target": "krasue_queen", "count": 1,
		"min_level": 15, "requires": "q_takiang", "repeatable": true,
		"desc": "เมื่อนางพญากระสือปรากฏตัว จงไปปราบให้ได้",
		"reward": {"exp": 2500, "coins": 1000, "items": {"ya_hom_thong": 5}},
	},
	# ---- ตาสัปเหร่อ (ป่าช้าวัดร้าง) ----
	"q_khamot": {
		"giver": "ta_sappare", "name": "ไฟผีโขมดกลางป่าช้า", "type": "kill", "target": "phi_khamot", "count": 12,
		"min_level": 10, "requires": "", "repeatable": false,
		"desc": "ดวงไฟโขมดล่อคนหลงทางเข้าป่าช้า ไปดับมันซะ 12 ดวง",
		"reward": {"exp": 1800, "coins": 500, "items": {"nam_mon": 5}},
	},
	"q_ember": {
		"giver": "ta_sappare", "name": "ประกายไฟโขมด", "type": "collect", "target": "khamot_ember", "count": 8,
		"min_level": 10, "requires": "q_khamot", "repeatable": true,
		"desc": "ตาจะเอาประกายไฟไปจุดตะเกียงนำทางวิญญาณ",
		"reward": {"exp": 900, "coins": 300, "items": {}},
	},
	"q_pop": {
		"giver": "ta_sappare", "name": "ผีปอบหิวโหย", "type": "kill", "target": "phi_pop", "count": 12,
		"min_level": 15, "requires": "q_khamot", "repeatable": false,
		"desc": "ผีปอบออกจากป่าไผ่มาไล่กินไก่ชาวบ้าน ปราบ 12 ตัว",
		"reward": {"exp": 4200, "coins": 900, "items": {"ya_hom_thong": 5}},
	},
	"q_shroud": {
		"giver": "ta_sappare", "name": "ผ้าห่อศพที่หายไป", "type": "collect", "target": "pha_ho_sop", "count": 10,
		"min_level": 15, "requires": "q_pop", "repeatable": true,
		"desc": "ผีปอบขโมยผ้าห่อศพไป ช่วยเอากลับมาคืน 10 ผืน",
		"reward": {"exp": 2600, "coins": 600, "items": {}},
	},
	"q_pret": {
		"giver": "ta_sappare", "name": "เปรตขอส่วนบุญ", "type": "kill", "target": "phi_pret", "count": 10,
		"min_level": 22, "requires": "q_pop", "repeatable": false,
		"desc": "เปรตตัวสูงออกมาส่งเสียงหวีดหวิวทั้งคืน ส่งพวกมันไปสู่สุคติ 10 ตน",
		"reward": {"exp": 9000, "coins": 1800, "items": {"mongkhon": 1}},
	},
	"q_pret_king": {
		"giver": "ta_sappare", "name": "พญาเปรตแห่งเมรุร้าง", "type": "kill", "target": "pret_king", "count": 1,
		"min_level": 30, "requires": "q_pret", "repeatable": true,
		"desc": "เจ้าแห่งเปรตทั้งหลายตื่นขึ้นแล้ว ใครปราบได้จะได้รางวัลงาม",
		"reward": {"exp": 20000, "coins": 5000, "items": {"nam_mon_yai": 5}},
	},
}


static func for_giver(npc_id: String) -> Array[String]:
	var result: Array[String] = []
	for id in QUESTS:
		if QUESTS[id]["giver"] == npc_id:
			result.append(id)
	return result


## "locked" = ยังรับไม่ได้, "available" = รับได้, "active" = กำลังทำ, "ready" = ส่งได้, "done" = จบแล้ว
static func status(state: Dictionary, inventory: Dictionary, id: String) -> String:
	var q: Dictionary = QUESTS[id]
	if state["quests"].has(id):
		return "ready" if progress(state, inventory, id) >= q["count"] else "active"
	if state["quests_done"].has(id) and not q["repeatable"]:
		return "done"
	if state["level"] < q["min_level"]:
		return "locked"
	if q["requires"] != "" and not state["quests_done"].has(q["requires"]):
		return "locked"
	return "available"


static func progress(state: Dictionary, inventory: Dictionary, id: String) -> int:
	var q: Dictionary = QUESTS[id]
	if q["type"] == "collect":
		return mini(inventory.get(q["target"], 0), q["count"])
	return mini(state["quests"].get(id, 0), q["count"])


static func target_name(id: String) -> String:
	var q: Dictionary = QUESTS[id]
	if q["type"] == "collect":
		return ItemDB.ITEMS[q["target"]]["name"]
	return GhostDB.GHOSTS[q["target"]]["name"]


## ข้อความเป้าหมาย เช่น "ปราบผีกระสือน้อย 3/8" หรือ "หาด้ายแดง 2/5"
static func goal_text(state: Dictionary, inventory: Dictionary, id: String) -> String:
	var q: Dictionary = QUESTS[id]
	var verb := "หา" if q["type"] == "collect" else "ปราบ"
	return "%s%s %d/%d" % [verb, target_name(id), progress(state, inventory, id), q["count"]]


static func reward_text(id: String) -> String:
	var r: Dictionary = QUESTS[id]["reward"]
	var parts: Array[String] = ["EXP %d" % r["exp"]]
	if r["coins"] > 0:
		parts.append("%d เหรียญ" % r["coins"])
	if QUESTS[id].has("trial"):
		parts.append("สิทธิ์เปลี่ยนอาชีพขั้น %d" % QUESTS[id]["trial"])
	for item in r["items"]:
		parts.append("%s x%d" % [ItemDB.ITEMS[item]["name"], r["items"][item]])
	return " · ".join(parts)
