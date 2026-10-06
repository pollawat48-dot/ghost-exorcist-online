extends RefCounted
## เควสจาก NPC ใช้ร่วมกันทั้ง client และ zone server
## type: kill = ปราบผีให้ครบ, collect = หาของมาส่ง (ส่งแล้วของถูกหักออกจากกระเป๋า)
## giver = id ของ NPC, requires = ต้องทำเควสนี้จบก่อน, repeatable = รับซ้ำได้หลังส่ง
## เควสแผนที่ 3 ขึ้นไปไม่เขียนรางวัลเอง: ใส่ prize = "coins" (เงิน) / "potion" (ยา) / "gear" (ของสวมใส่)
## แล้ว reward() คำนวณจำนวนตามความเก่งของผีเป้าหมาย (เควสหาของใช้ source = ผีที่ดรอปของนั้น)
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
	# ---- พระธุดงค์ (กรุงเก่าร้าง) ----
	"q_tai_hong": {
		"giver": "phra_thudong", "name": "วิญญาณตายโหง", "type": "kill", "target": "phi_tai_hong", "count": 15,
		"min_level": 30, "requires": "", "repeatable": false, "prize": "potion",
		"desc": "ผีตายโหงยังวนเวียนอยู่ตามซากวัด ช่วยส่งพวกเขาไปสู่สุคติ 15 ดวง",
	},
	"q_prae": {
		"giver": "phra_thudong", "name": "ผ้าแพรถวายวัด", "type": "collect", "target": "pha_prae", "count": 12, "source": "phi_tai_hong",
		"min_level": 30, "requires": "q_tai_hong", "repeatable": true, "prize": "coins",
		"desc": "หลวงพ่อจะนำผ้าแพรไปห่มองค์พระ ขอ 12 ผืน",
	},
	"q_hua_khat": {
		"giver": "phra_thudong", "name": "ผีหัวขาดหาหัว", "type": "kill", "target": "phi_hua_khat", "count": 15,
		"min_level": 38, "requires": "q_tai_hong", "repeatable": false, "prize": "gear",
		"desc": "ผีหัวขาดเดินถือหัวไล่หลอกคนเดินทาง ปราบ 15 ตน",
	},
	"q_thahan": {
		"giver": "phra_thudong", "name": "กองทัพผีกรุงเก่า", "type": "kill", "target": "thahan_phi", "count": 15,
		"min_level": 46, "requires": "q_hua_khat", "repeatable": false, "prize": "coins",
		"desc": "ทหารผียังเฝ้ากำแพงเมืองไม่ยอมไปไหน ปลดปล่อยพวกเขา 15 นาย",
	},
	"q_lek_krung": {
		"giver": "phra_thudong", "name": "เศษเกราะในกรุ", "type": "collect", "target": "lek_krung", "count": 10, "source": "thahan_phi",
		"min_level": 46, "requires": "q_thahan", "repeatable": true, "prize": "potion",
		"desc": "เศษเกราะเก่าใช้ทำพิธีบังสุกุล นำมา 10 ชิ้น",
	},
	"q_khun_suek": {
		"giver": "phra_thudong", "name": "ขุนศึกผีกรุงเก่า", "type": "kill", "target": "khun_suek", "count": 1,
		"min_level": 60, "requires": "q_thahan", "repeatable": true, "prize": "gear",
		"desc": "ขุนศึกผีออกนำทัพผีแล้ว ปราบให้ได้แล้วกลับมารับรางวัล",
	},
	# ---- ปู่จันทร์หมอผีดอย (ดอยผีปันน้ำ) ----
	"q_ka": {
		"giver": "pu_chan", "name": "ไล่ผีกะ", "type": "kill", "target": "phi_ka", "count": 15,
		"min_level": 60, "requires": "", "repeatable": false, "prize": "potion",
		"desc": "ผีกะเข้าสิงหม้อดินชาวบ้าน ปราบ 15 ตัว",
	},
	"q_mo_din": {
		"giver": "pu_chan", "name": "หม้อดินผีกะ", "type": "collect", "target": "mo_din", "count": 12, "source": "phi_ka",
		"min_level": 60, "requires": "q_ka", "repeatable": true, "prize": "coins",
		"desc": "ปู่จะเอาหม้อดินไปฝังผนึก ขอ 12 ใบ",
	},
	"q_pong": {
		"giver": "pu_chan", "name": "ดับไฟผีโป่ง", "type": "kill", "target": "phi_pong", "count": 15,
		"min_level": 70, "requires": "q_ka", "repeatable": false, "prize": "gear",
		"desc": "ผีโป่งเรืองแสงล่อพรานเข้าป่าลึก ดับมัน 15 ดวง",
	},
	"q_nang_mai": {
		"giver": "pu_chan", "name": "นางไม้โกรธ", "type": "kill", "target": "nang_mai", "count": 15,
		"min_level": 80, "requires": "q_pong", "repeatable": false, "prize": "coins",
		"desc": "นางไม้ตะเคียนโกรธคนตัดไม้ สงบนางลง 15 ตน",
	},
	"q_bai": {
		"giver": "pu_chan", "name": "ใบตะเคียนทอง", "type": "collect", "target": "bai_takhian", "count": 10, "source": "nang_mai",
		"min_level": 80, "requires": "q_nang_mai", "repeatable": true, "prize": "potion",
		"desc": "ใบตะเคียนทองใช้ทำยาวิเศษ นำมา 10 ใบ",
	},
	"q_phrai_boss": {
		"giver": "pu_chan", "name": "พญาพรายเจ้าป่า", "type": "kill", "target": "phraya_phrai", "count": 1,
		"min_level": 90, "requires": "q_nang_mai", "repeatable": true, "prize": "gear",
		"desc": "เจ้าป่าตื่นแล้ว ใครปราบได้ปู่มีของดีให้",
	},
	# ---- ยายเฝ้าบึง (บึงนาคาบาดาล) ----
	"q_phrai_nam": {
		"giver": "yai_bueng", "name": "พรายน้ำดึงขา", "type": "kill", "target": "phrai_nam", "count": 15,
		"min_level": 94, "requires": "", "repeatable": false, "prize": "potion",
		"desc": "ผีพรายน้ำดึงขาคนพายเรือ ปราบ 15 ตน",
	},
	"q_sarai": {
		"giver": "yai_bueng", "name": "สาหร่ายพราย", "type": "collect", "target": "sarai_phrai", "count": 12, "source": "phrai_nam",
		"min_level": 94, "requires": "q_phrai_nam", "repeatable": true, "prize": "coins",
		"desc": "สาหร่ายพรายใช้ทำน้ำมนต์ ขอ 12 กำ",
	},
	"q_naga": {
		"giver": "yai_bueng", "name": "ผีนาคาเลื้อยขึ้นฝั่ง", "type": "kill", "target": "phi_naga", "count": 15,
		"min_level": 105, "requires": "q_phrai_nam", "repeatable": false, "prize": "gear",
		"desc": "ผีนาคาเลื้อยขึ้นมาไล่ฉกคน ปราบ 15 ตัว",
	},
	"q_kong_koi": {
		"giver": "yai_bueng", "name": "กองกอยกระโดดตัวเดียว", "type": "kill", "target": "kong_koi", "count": 15,
		"min_level": 118, "requires": "q_naga", "repeatable": false, "prize": "coins",
		"desc": "ผีกองกอยขาเดียวกระโดดไล่กินปลาในบึง ปราบ 15 ตัว",
	},
	"q_klet": {
		"giver": "yai_bueng", "name": "เกล็ดนาคศักดิ์สิทธิ์", "type": "collect", "target": "klet_nak", "count": 10, "source": "phi_naga",
		"min_level": 118, "requires": "q_kong_koi", "repeatable": true, "prize": "potion",
		"desc": "ยายจะเอาเกล็ดนาคไปทำเครื่องราง นำมา 10 เกล็ด",
	},
	"q_nak_boss": {
		"giver": "yai_bueng", "name": "พญานาคทมิฬ", "type": "kill", "target": "phaya_nak", "count": 1,
		"min_level": 125, "requires": "q_kong_koi", "repeatable": true, "prize": "gear",
		"desc": "พญานาคทมิฬโผล่จากบาดาล ปราบให้ได้",
	},
	# ---- พระมาลัย (ยมโลก) ----
	"q_asura": {
		"giver": "phra_malai", "name": "อสุรกายคลั่ง", "type": "kill", "target": "asurakai", "count": 15,
		"min_level": 128, "requires": "", "repeatable": false, "prize": "potion",
		"desc": "อสุรกายหนีจากขุมนรกขึ้นมา ปราบ 15 ตน",
	},
	"q_khiao": {
		"giver": "phra_malai", "name": "เขี้ยวอสุรกาย", "type": "collect", "target": "khiao_asura", "count": 12, "source": "asurakai",
		"min_level": 128, "requires": "q_asura", "repeatable": true, "prize": "coins",
		"desc": "นำเขี้ยวอสุรกายมาทำพิธีผนึก 12 เขี้ยว",
	},
	"q_yom": {
		"giver": "phra_malai", "name": "ยมทูตหลงทาง", "type": "kill", "target": "yomathut", "count": 15,
		"min_level": 136, "requires": "q_asura", "repeatable": false, "prize": "gear",
		"desc": "ยมทูตจับวิญญาณผิดตัว ช่วยปราบ 15 ตน",
	},
	"q_awe": {
		"giver": "phra_malai", "name": "เปรตอเวจี", "type": "kill", "target": "pret_awe", "count": 15,
		"min_level": 144, "requires": "q_yom", "repeatable": false, "prize": "coins",
		"desc": "เปรตอเวจีร้องหิวทั้งคืน ส่งพวกเขาไปสู่สุคติ 15 ตน",
	},
	"q_fai": {
		"giver": "phra_malai", "name": "ไฟอเวจี", "type": "collect", "target": "fai_awe", "count": 10, "source": "pret_awe",
		"min_level": 144, "requires": "q_awe", "repeatable": true, "prize": "potion",
		"desc": "ไฟอเวจีใช้จุดตะเกียงส่งวิญญาณ นำมา 10 ดวง",
	},
	"q_matchu": {
		"giver": "phra_malai", "name": "พญามัจจุราช", "type": "kill", "target": "matchurat", "count": 1,
		"min_level": 145, "requires": "q_awe", "repeatable": true, "prize": "gear",
		"desc": "บททดสอบสุดท้ายของผู้ปราบผี ปราบพญามัจจุราช",
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


const PRIZE_NAMES := {"coins": "เงิน", "potion": "ยา", "gear": "ของสวมใส่"}
const RARITY_RANK := {"common": 0, "rare": 1, "epic": 2, "legendary": 3}


## รางวัลของเควส (line = สายของผู้เล่น ใช้เลือกของสวมใส่ที่ใช้ได้)
## เควสที่มี prize: EXP/เงิน/จำนวนยา คิดจาก EXP และเหรียญของผีเป้าหมาย x จำนวน ยิ่งผีเก่งยิ่งได้มาก
static func reward(id: String, line: String = "any") -> Dictionary:
	var q: Dictionary = QUESTS[id]
	if q.has("reward"):
		return q["reward"]
	var src: String = q["target"] if q["type"] == "kill" else q["source"]
	var g: Dictionary = GhostDB.GHOSTS[src]
	var boss: bool = g.get("boss", false)
	var n: int = q["count"]
	var lv: int = g["level"]
	var exp := int(g["exp"] * n * (0.6 if boss else (1.2 if q["type"] == "kill" else 0.9)))
	var coins := int(g["coins"] * n * (0.5 if boss else 2.0))
	var items := {}
	match q["prize"]:
		"coins":
			coins *= 3
		"potion":
			var hp_id := "ya_hom_thong" if lv < 60 else "ya_thip"
			var sp_id := "nam_mon_yai" if lv < 60 else "nam_mon_thep"
			var amount := clampi(n / 2 + lv / 15, 4, 20) * (3 if boss else 1)
			items[hp_id] = amount
			items[sp_id] = maxi(2, amount / 2)
		"gear":
			var gear := gear_for(src, line)
			if gear != "":
				items[gear] = 1
	return {"exp": exp, "coins": coins, "items": items}


## ของสวมใส่รางวัล: จากของที่ผีตัวนั้นดรอป เลือกที่สายผู้เล่นใช้ได้ (เน้นอาวุธ)
## ผีธรรมดาให้ของระดับต่ำสุดในตาราง บอสให้ของระดับล้ำค่า (ของตำนานต้องลุ้นดรอปเอง)
static func gear_for(ghost_id: String, line: String) -> String:
	var g: Dictionary = GhostDB.GHOSTS[ghost_id]
	var boss: bool = g.get("boss", false)
	var best := ""
	var best_score := INF
	for d in g["drops"]:
		var item: Dictionary = ItemDB.ITEMS[d["item"]]
		if item["type"] != "equip" or not (item["line"] == "any" or item["line"] == line or line == "any"):
			continue
		var rank: int = RARITY_RANK[item["rarity"]]
		if boss and rank > 2:
			continue
		var score := float(-rank if boss else rank) * 10.0 - (1.0 if item["slot"] == "weapon" and item["line"] == line else 0.0)
		if score < best_score:
			best = d["item"]
			best_score = score
	return best


static func reward_text(id: String, line: String = "any") -> String:
	var r := reward(id, line)
	var parts: Array[String] = ["EXP %d" % r["exp"]]
	if r["coins"] > 0:
		parts.append("%d เหรียญ" % r["coins"])
	if QUESTS[id].has("trial"):
		parts.append("สิทธิ์เปลี่ยนอาชีพขั้น %d" % QUESTS[id]["trial"])
	for item in r["items"]:
		parts.append("%s x%d" % [ItemDB.ITEMS[item]["name"], r["items"][item]])
	return " · ".join(parts)
