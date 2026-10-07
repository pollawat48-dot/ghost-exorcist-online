extends RefCounted
## เควสจาก NPC ใช้ร่วมกันทั้ง client และ zone server
## type: kill = ปราบผีให้ครบ, collect = หาของมาส่ง (ส่งแล้วของถูกหักออกจากกระเป๋า)
## giver = id ของ NPC, requires = ต้องทำเควสนี้จบก่อน, repeatable = รับซ้ำได้หลังส่ง
## เควสแผนที่ 3 ขึ้นไปไม่เขียนรางวัลเอง: ใส่ prize = "coins" (เงิน) / "potion" (ยา) / "gear" (ของสวมใส่)
## แล้ว reward() คำนวณจำนวนตามความเก่งของผีเป้าหมาย (เควสหาของใช้ source = ผีที่ดรอปของนั้น)
## สถานะในตัวละคร: state["quests"] = {id: จำนวนที่ปราบแล้ว}, state["quests_done"] = {id: จำนวนครั้งที่ส่ง}

const GhostDB = preload("res://shared/data/ghosts.gd")
const ItemDB = preload("res://shared/data/items.gd")
const Fashion = preload("res://shared/data/fashion.gd")

const QUESTS := {
	# ---- ครูใหญ่สำนัก: บททดสอบเปลี่ยนอาชีพ (ส่งแล้วจ่ายค่าครูเพื่อเลื่อนขั้นได้) ----
	"q_trial_1": {
		"giver": "khru_yai", "name": "บททดสอบศิษย์วัด", "type": "kill", "target": "phi_takiang", "count": 15,
		"min_level": 10, "requires": "", "repeatable": false, "trial": 1,
		"desc": "พิสูจน์ว่าเจ้าพร้อมเป็นผู้ปราบผีเต็มตัว ไปปราบผีตะเกียงในป่ากล้วยให้ได้ 15 ตัว",
		"reward": {"exp": 300, "coins": 0, "items": {}},
	},
	"q_trial_2": {
		"giver": "khru_yai", "name": "บททดสอบผู้กล้า: พญามัจจุราช", "type": "kill", "target": "matchurat", "count": 1,
		"min_level": 50, "requires": "q_trial_1", "repeatable": false, "trial": 2,
		"desc": "ผู้ที่จะเลื่อนขั้นต้องปราบบอสที่เก่งที่สุดในแผ่นดินไทยได้ จงปราบพญามัจจุราชแห่งยมโลก",
		"reward": {"exp": 5000, "coins": 0, "items": {}},
	},
	"q_trial_3": {
		"giver": "khru_yai", "name": "บททดสอบปรมาจารย์: พญายมราชเฟิงตู", "type": "kill", "target": "yan_wang", "count": 1,
		"min_level": 100, "requires": "q_trial_2", "repeatable": false, "trial": 3,
		"desc": "บททดสอบสุดท้าย ข้ามทะเลไปปราบพญายมราชแห่งเมืองผีเฟิงตูในแผ่นดินจีน แล้วกลับมารับตำแหน่งขั้นสูงสุด",
		"reward": {"exp": 30000, "coins": 0, "items": {}},
	},
	# ---- ครูฝึกสัตว์ (หมู่บ้านริมคลอง): บททดสอบก่อนพัฒนาร่างสัตว์เลี้ยง ----
	# pet_stage = ร่างที่จะพัฒนาไป รับได้เมื่อสัตว์เลี้ยงที่ออกมาอยู่ร่างก่อนหน้าและถึงเลเวล (Fashion.EVOLVE_LEVEL)
	# ส่งแล้วสัตว์เลี้ยงตัวนั้นได้สิทธิ์พัฒนาร่าง (pets[species]["trial"]) รับซ้ำได้สำหรับสัตว์เลี้ยงตัวอื่น
	"q_pet_1": {
		"giver": "khru_fuek_sat", "name": "บททดสอบคู่หู: ล่าผีกะ", "type": "kill", "target": "phi_ka", "count": 20,
		"min_level": 1, "requires": "", "repeatable": true, "pet_stage": 1,
		"desc": "สัตว์เลี้ยงจะพัฒนาร่างได้ต้องผ่านศึกจริงกับเจ้าของ พามันไปปราบผีกะที่ดอยผีปันน้ำ 20 ตน",
		"reward": {"exp": 3000, "coins": 0, "items": {}},
	},
	"q_pet_2": {
		"giver": "khru_fuek_sat", "name": "บททดสอบเทพอสูร: ปีศาจจิ้งจอก", "type": "kill", "target": "huli_jing", "count": 25,
		"min_level": 1, "requires": "", "repeatable": true, "pet_stage": 2,
		"desc": "ร่างสุดท้ายต้องใจกล้ากว่าผีทั้งปวง ข้ามทะเลพาสัตว์เลี้ยงไปปราบปีศาจจิ้งจอกที่ป่าไผ่หมอกมรกตในแผ่นดินจีน 25 ตน แล้วกลับมาหาครู",
		"reward": {"exp": 15000, "coins": 0, "items": {}},
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
		"min_level": 5, "requires": "q_krasue", "repeatable": false,
		"desc": "ผีตะเกียงในป่ากล้วยดุร้ายขึ้นทุกวัน ปราบให้ได้ 10 ตัว",
		"reward": {"exp": 600, "coins": 300, "items": {"nam_mon": 5}},
	},
	"q_shard": {
		"giver": "luang_ta", "name": "รวบรวมเศษวิญญาณ", "type": "collect", "target": "spirit_shard", "count": 10,
		"min_level": 4, "requires": "", "repeatable": true,
		"desc": "เศษวิญญาณใช้ทำพิธีส่งดวงวิญญาณ นำมาส่งได้เรื่อยๆ",
		"reward": {"exp": 120, "coins": 100, "items": {}},
	},
	"q_queen": {
		"giver": "luang_ta", "name": "ปราบนางพญากระสือ", "type": "kill", "target": "krasue_queen", "count": 1,
		"min_level": 12, "requires": "q_takiang", "repeatable": true,
		"desc": "เมื่อนางพญากระสือปรากฏตัว จงไปปราบให้ได้",
		"reward": {"exp": 2500, "coins": 1000, "items": {"ya_hom_thong": 5}},
	},
	# ---- ตาสัปเหร่อ (ป่าช้าวัดร้าง) ----
	"q_khamot": {
		"giver": "ta_sappare", "name": "ไฟผีโขมดกลางป่าช้า", "type": "kill", "target": "phi_khamot", "count": 12,
		"min_level": 9, "requires": "", "repeatable": false,
		"desc": "ดวงไฟโขมดล่อคนหลงทางเข้าป่าช้า ไปดับมันซะ 12 ดวง",
		"reward": {"exp": 1800, "coins": 500, "items": {"nam_mon": 5}},
	},
	"q_ember": {
		"giver": "ta_sappare", "name": "ประกายไฟโขมด", "type": "collect", "target": "khamot_ember", "count": 8,
		"min_level": 9, "requires": "q_khamot", "repeatable": true,
		"desc": "ตาจะเอาประกายไฟไปจุดตะเกียงนำทางวิญญาณ",
		"reward": {"exp": 900, "coins": 300, "items": {}},
	},
	"q_pop": {
		"giver": "ta_sappare", "name": "ผีปอบหิวโหย", "type": "kill", "target": "phi_pop", "count": 12,
		"min_level": 12, "requires": "q_khamot", "repeatable": false,
		"desc": "ผีปอบออกจากป่าไผ่มาไล่กินไก่ชาวบ้าน ปราบ 12 ตัว",
		"reward": {"exp": 4200, "coins": 900, "items": {"ya_hom_thong": 5}},
	},
	"q_shroud": {
		"giver": "ta_sappare", "name": "ผ้าห่อศพที่หายไป", "type": "collect", "target": "pha_ho_sop", "count": 10,
		"min_level": 12, "requires": "q_pop", "repeatable": true,
		"desc": "ผีปอบขโมยผ้าห่อศพไป ช่วยเอากลับมาคืน 10 ผืน",
		"reward": {"exp": 2600, "coins": 600, "items": {}},
	},
	"q_pret": {
		"giver": "ta_sappare", "name": "เปรตขอส่วนบุญ", "type": "kill", "target": "phi_pret", "count": 10,
		"min_level": 16, "requires": "q_pop", "repeatable": false,
		"desc": "เปรตตัวสูงออกมาส่งเสียงหวีดหวิวทั้งคืน ส่งพวกมันไปสู่สุคติ 10 ตน",
		"reward": {"exp": 9000, "coins": 1800, "items": {"mongkhon": 1}},
	},
	"q_pret_king": {
		"giver": "ta_sappare", "name": "พญาเปรตแห่งเมรุร้าง", "type": "kill", "target": "pret_king", "count": 1,
		"min_level": 20, "requires": "q_pret", "repeatable": true,
		"desc": "เจ้าแห่งเปรตทั้งหลายตื่นขึ้นแล้ว ใครปราบได้จะได้รางวัลงาม",
		"reward": {"exp": 20000, "coins": 5000, "items": {"nam_mon_yai": 5}},
	},
	# ---- พระธุดงค์ (กรุงเก่าร้าง) ----
	"q_tai_hong": {
		"giver": "phra_thudong", "name": "วิญญาณตายโหง", "type": "kill", "target": "phi_tai_hong", "count": 15,
		"min_level": 20, "requires": "", "repeatable": false, "prize": "potion",
		"desc": "ผีตายโหงยังวนเวียนอยู่ตามซากวัด ช่วยส่งพวกเขาไปสู่สุคติ 15 ดวง",
	},
	"q_prae": {
		"giver": "phra_thudong", "name": "ผ้าแพรถวายวัด", "type": "collect", "target": "pha_prae", "count": 12, "source": "phi_tai_hong",
		"min_level": 20, "requires": "q_tai_hong", "repeatable": true, "prize": "coins",
		"desc": "หลวงพ่อจะนำผ้าแพรไปห่มองค์พระ ขอ 12 ผืน",
	},
	"q_hua_khat": {
		"giver": "phra_thudong", "name": "ผีหัวขาดหาหัว", "type": "kill", "target": "phi_hua_khat", "count": 15,
		"min_level": 23, "requires": "q_tai_hong", "repeatable": false, "prize": "gear",
		"desc": "ผีหัวขาดเดินถือหัวไล่หลอกคนเดินทาง ปราบ 15 ตน",
	},
	"q_thahan": {
		"giver": "phra_thudong", "name": "กองทัพผีกรุงเก่า", "type": "kill", "target": "thahan_phi", "count": 15,
		"min_level": 26, "requires": "q_hua_khat", "repeatable": false, "prize": "coins",
		"desc": "ทหารผียังเฝ้ากำแพงเมืองไม่ยอมไปไหน ปลดปล่อยพวกเขา 15 นาย",
	},
	"q_lek_krung": {
		"giver": "phra_thudong", "name": "เศษเกราะในกรุ", "type": "collect", "target": "lek_krung", "count": 10, "source": "thahan_phi",
		"min_level": 26, "requires": "q_thahan", "repeatable": true, "prize": "potion",
		"desc": "เศษเกราะเก่าใช้ทำพิธีบังสุกุล นำมา 10 ชิ้น",
	},
	"q_khun_suek": {
		"giver": "phra_thudong", "name": "ขุนศึกผีกรุงเก่า", "type": "kill", "target": "khun_suek", "count": 1,
		"min_level": 30, "requires": "q_thahan", "repeatable": true, "prize": "gear",
		"desc": "ขุนศึกผีออกนำทัพผีแล้ว ปราบให้ได้แล้วกลับมารับรางวัล",
	},
	# ---- ปู่จันทร์หมอผีดอย (ดอยผีปันน้ำ) ----
	"q_ka": {
		"giver": "pu_chan", "name": "ไล่ผีกะ", "type": "kill", "target": "phi_ka", "count": 15,
		"min_level": 30, "requires": "", "repeatable": false, "prize": "potion",
		"desc": "ผีกะเข้าสิงหม้อดินชาวบ้าน ปราบ 15 ตัว",
	},
	"q_mo_din": {
		"giver": "pu_chan", "name": "หม้อดินผีกะ", "type": "collect", "target": "mo_din", "count": 12, "source": "phi_ka",
		"min_level": 30, "requires": "q_ka", "repeatable": true, "prize": "coins",
		"desc": "ปู่จะเอาหม้อดินไปฝังผนึก ขอ 12 ใบ",
	},
	"q_pong": {
		"giver": "pu_chan", "name": "ดับไฟผีโป่ง", "type": "kill", "target": "phi_pong", "count": 15,
		"min_level": 32, "requires": "q_ka", "repeatable": false, "prize": "gear",
		"desc": "ผีโป่งเรืองแสงล่อพรานเข้าป่าลึก ดับมัน 15 ดวง",
	},
	"q_nang_mai": {
		"giver": "pu_chan", "name": "นางไม้โกรธ", "type": "kill", "target": "nang_mai", "count": 15,
		"min_level": 35, "requires": "q_pong", "repeatable": false, "prize": "coins",
		"desc": "นางไม้ตะเคียนโกรธคนตัดไม้ สงบนางลง 15 ตน",
	},
	"q_bai": {
		"giver": "pu_chan", "name": "ใบตะเคียนทอง", "type": "collect", "target": "bai_takhian", "count": 10, "source": "nang_mai",
		"min_level": 35, "requires": "q_nang_mai", "repeatable": true, "prize": "potion",
		"desc": "ใบตะเคียนทองใช้ทำยาวิเศษ นำมา 10 ใบ",
	},
	"q_phrai_boss": {
		"giver": "pu_chan", "name": "พญาพรายเจ้าป่า", "type": "kill", "target": "phraya_phrai", "count": 1,
		"min_level": 36, "requires": "q_nang_mai", "repeatable": true, "prize": "gear",
		"desc": "เจ้าป่าตื่นแล้ว ใครปราบได้ปู่มีของดีให้",
	},
	# ---- ยายเฝ้าบึง (บึงนาคาบาดาล) ----
	"q_phrai_nam": {
		"giver": "yai_bueng", "name": "พรายน้ำดึงขา", "type": "kill", "target": "phrai_nam", "count": 15,
		"min_level": 37, "requires": "", "repeatable": false, "prize": "potion",
		"desc": "ผีพรายน้ำดึงขาคนพายเรือ ปราบ 15 ตน",
	},
	"q_sarai": {
		"giver": "yai_bueng", "name": "สาหร่ายพราย", "type": "collect", "target": "sarai_phrai", "count": 12, "source": "phrai_nam",
		"min_level": 37, "requires": "q_phrai_nam", "repeatable": true, "prize": "coins",
		"desc": "สาหร่ายพรายใช้ทำน้ำมนต์ ขอ 12 กำ",
	},
	"q_naga": {
		"giver": "yai_bueng", "name": "ผีนาคาเลื้อยขึ้นฝั่ง", "type": "kill", "target": "phi_naga", "count": 15,
		"min_level": 39, "requires": "q_phrai_nam", "repeatable": false, "prize": "gear",
		"desc": "ผีนาคาเลื้อยขึ้นมาไล่ฉกคน ปราบ 15 ตัว",
	},
	"q_kong_koi": {
		"giver": "yai_bueng", "name": "กองกอยกระโดดตัวเดียว", "type": "kill", "target": "kong_koi", "count": 15,
		"min_level": 42, "requires": "q_naga", "repeatable": false, "prize": "coins",
		"desc": "ผีกองกอยขาเดียวกระโดดไล่กินปลาในบึง ปราบ 15 ตัว",
	},
	"q_klet": {
		"giver": "yai_bueng", "name": "เกล็ดนาคศักดิ์สิทธิ์", "type": "collect", "target": "klet_nak", "count": 10, "source": "phi_naga",
		"min_level": 42, "requires": "q_kong_koi", "repeatable": true, "prize": "potion",
		"desc": "ยายจะเอาเกล็ดนาคไปทำเครื่องราง นำมา 10 เกล็ด",
	},
	"q_nak_boss": {
		"giver": "yai_bueng", "name": "พญานาคทมิฬ", "type": "kill", "target": "phaya_nak", "count": 1,
		"min_level": 44, "requires": "q_kong_koi", "repeatable": true, "prize": "gear",
		"desc": "พญานาคทมิฬโผล่จากบาดาล ปราบให้ได้",
	},
	# ---- พระมาลัย (ยมโลก) ----
	"q_asura": {
		"giver": "phra_malai", "name": "อสุรกายคลั่ง", "type": "kill", "target": "asurakai", "count": 15,
		"min_level": 44, "requires": "", "repeatable": false, "prize": "potion",
		"desc": "อสุรกายหนีจากขุมนรกขึ้นมา ปราบ 15 ตน",
	},
	"q_khiao": {
		"giver": "phra_malai", "name": "เขี้ยวอสุรกาย", "type": "collect", "target": "khiao_asura", "count": 12, "source": "asurakai",
		"min_level": 44, "requires": "q_asura", "repeatable": true, "prize": "coins",
		"desc": "นำเขี้ยวอสุรกายมาทำพิธีผนึก 12 เขี้ยว",
	},
	"q_yom": {
		"giver": "phra_malai", "name": "ยมทูตหลงทาง", "type": "kill", "target": "yomathut", "count": 15,
		"min_level": 46, "requires": "q_asura", "repeatable": false, "prize": "gear",
		"desc": "ยมทูตจับวิญญาณผิดตัว ช่วยปราบ 15 ตน",
	},
	"q_awe": {
		"giver": "phra_malai", "name": "เปรตอเวจี", "type": "kill", "target": "pret_awe", "count": 15,
		"min_level": 49, "requires": "q_yom", "repeatable": false, "prize": "coins",
		"desc": "เปรตอเวจีร้องหิวทั้งคืน ส่งพวกเขาไปสู่สุคติ 15 ตน",
	},
	"q_fai": {
		"giver": "phra_malai", "name": "ไฟอเวจี", "type": "collect", "target": "fai_awe", "count": 10, "source": "pret_awe",
		"min_level": 49, "requires": "q_awe", "repeatable": true, "prize": "potion",
		"desc": "ไฟอเวจีใช้จุดตะเกียงส่งวิญญาณ นำมา 10 ดวง",
	},
	"q_matchu": {
		"giver": "phra_malai", "name": "พญามัจจุราช", "type": "kill", "target": "matchurat", "count": 1,
		"min_level": 49, "requires": "q_awe", "repeatable": true, "prize": "gear",
		"desc": "บททดสอบสุดท้ายของผู้ปราบผี ปราบพญามัจจุราช",
	},
	# ---- ไต้ก๋งเรือสำเภา (หมู่บ้านริมคลอง): เควสขึ้นเรือไปประเทศจีน ต้อง Lv50 ทำครบ 3 ขั้นแล้วนั่งเรือข้ามไปได้ตลอด ----
	# boat = ส่งเควสนี้แล้วได้สิทธิ์ขึ้นเรือ (Quests.has_boat_pass)
	"q_boat_1": {
		"giver": "tai_kong", "name": "ไม้ตะเคียนต่อเรือสำเภา", "type": "collect", "target": "bai_takhian", "count": 25, "source": "nang_mai",
		"min_level": 50, "requires": "", "repeatable": false,
		"desc": "เรือสำเภาจะฝ่าคลื่นไปแผ่นดินจีนได้ต้องมีไม้ตะเคียนทองกันผี หาใบตะเคียนทองจากนางไม้ที่ดอยผีปันน้ำมา 25 ใบ",
		"reward": {"exp": 20000, "coins": 3000, "items": {"ya_thip": 10}},
	},
	"q_boat_2": {
		"giver": "tai_kong", "name": "ปราบผีพรายขวางน่านน้ำ", "type": "kill", "target": "phi_naga", "count": 60,
		"min_level": 50, "requires": "q_boat_1", "repeatable": false,
		"desc": "ผีนาคาที่บึงนาคาบาดาลคอยลากเรือลงก้นน้ำ ต้องปราบให้ได้ 60 ตนเส้นทางเดินเรือถึงจะปลอดภัย",
		"reward": {"exp": 30000, "coins": 4000, "items": {"nam_mon_thep": 10}},
	},
	"q_boat_3": {
		"giver": "tai_kong", "name": "บวงสรวงก่อนออกทะเล: พญานาคทมิฬ", "type": "kill", "target": "phaya_nak", "count": 1,
		"min_level": 50, "requires": "q_boat_2", "repeatable": false, "boat": true,
		"desc": "พญานาคทมิฬเฝ้าปากน้ำไม่ยอมให้เรือผ่าน ปราบมันให้ได้แล้วกลับมาบอกไต้ก๋ง เรือสำเภาจะพาเจ้าข้ามไปแผ่นดินจีน",
		"reward": {"exp": 40000, "coins": 6000, "items": {"hin_ti_3": 2}},
	},
	# ================= ประเทศจีน: รางวัลคิดตามความเก่งของผี (prize) =================
	# ---- เหล่าจาง หมอผีท่าเรือ (ท่าเรือเมืองเฉวียนโจว) ----
	"q_cn_jiangshi": {
		"giver": "lao_zhang", "name": "ศพกระโดดยามค่ำ", "type": "kill", "target": "jiangshi", "count": 25,
		"min_level": 55, "requires": "", "repeatable": false, "prize": "gear",
		"desc": "ยันต์บนหน้าผากเจียงซือหลุดหมดแล้ว พวกมันกระโดดไล่กัดคนทั้งท่าเรือ ช่วยปราบ 25 ตน",
	},
	"q_cn_fu": {
		"giver": "lao_zhang", "name": "เก็บยันต์เหลือง", "type": "collect", "target": "fu_huang", "count": 15, "source": "jiangshi",
		"min_level": 55, "requires": "q_cn_jiangshi", "repeatable": true, "prize": "potion",
		"desc": "ยันต์เหลืองที่ขาดแล้วเอามาเขียนใหม่ได้ หามาให้ 15 แผ่น",
	},
	"q_cn_shui": {
		"giver": "lao_zhang", "name": "ผีน้ำใต้ท่าเรือ", "type": "kill", "target": "shui_gui", "count": 25,
		"min_level": 57, "requires": "q_cn_jiangshi", "repeatable": false, "prize": "coins",
		"desc": "ชาวประมงหายไปทีละคน เพราะผีน้ำลากลงทะเล ปราบให้ได้ 25 ตน",
	},
	"q_cn_wang": {
		"giver": "lao_zhang", "name": "ราชาเจียงซือ", "type": "kill", "target": "jiangshi_wang", "count": 1,
		"min_level": 60, "requires": "q_cn_shui", "repeatable": true, "prize": "gear",
		"desc": "ราชาเจียงซือโผล่มาเมื่อไหร่ทั้งท่าเรือต้องปิดประตู จงปราบมัน",
	},
	# ---- นักพรตหญิงเซียนกู (ป่าไผ่หมอกมรกต) ----
	"q_cn_huli": {
		"giver": "xian_gu", "name": "จิ้งจอกหลอกคน", "type": "kill", "target": "huli_jing", "count": 25,
		"min_level": 60, "requires": "", "repeatable": false, "prize": "gear",
		"desc": "ปีศาจจิ้งจอกแปลงร่างเป็นสาวงามหลอกคนเดินป่า ปราบให้ได้ 25 ตน",
	},
	"q_cn_rope": {
		"giver": "xian_gu", "name": "ตัดเชือกแขวนคอ", "type": "collect", "target": "chueak_khwaen", "count": 15, "source": "diao_si_gui",
		"min_level": 63, "requires": "q_cn_huli", "repeatable": true, "prize": "potion",
		"desc": "เผาเชือกแขวนคอเก่าเสียวิญญาณจะได้ไปผุดไปเกิด หามา 15 เส้น",
	},
	"q_cn_nugui": {
		"giver": "xian_gu", "name": "ผีสาวชุดขาวร้องไห้", "type": "kill", "target": "nu_gui", "count": 25,
		"min_level": 66, "requires": "q_cn_huli", "repeatable": false, "prize": "coins",
		"desc": "เสียงร้องไห้ในป่าไผ่ทำให้คนเสียสติ ส่งผีสาวชุดขาวไปสู่สุคติ 25 ตน",
	},
	"q_cn_jiuwei": {
		"giver": "xian_gu", "name": "จิ้งจอกเก้าหาง", "type": "kill", "target": "jiuwei_hu", "count": 1,
		"min_level": 68, "requires": "q_cn_nugui", "repeatable": true, "prize": "gear",
		"desc": "จิ้งจอกพันปีที่มีเก้าหางเป็นต้นตอของปีศาจทั้งป่า จงปราบมัน",
	},
	# ---- นักพรตหลี่ (สุสานจักรพรรดิฉิน) ----
	"q_cn_bmy": {
		"giver": "dao_shi_li", "name": "กองทัพดินเผาคืนชีพ", "type": "kill", "target": "bingmayong", "count": 30,
		"min_level": 68, "requires": "", "repeatable": false, "prize": "gear",
		"desc": "ทหารดินเผานับพันลุกขึ้นเดินออกจากสุสาน ปราบให้ได้ 30 ตน",
	},
	"q_cn_skin": {
		"giver": "dao_shi_li", "name": "หนังวาดผี", "type": "collect", "target": "nang_wat_phi", "count": 15, "source": "hua_pi",
		"min_level": 71, "requires": "q_cn_bmy", "repeatable": true, "prize": "potion",
		"desc": "หนังที่ปีศาจใช้แปลงร่างต้องเอามาเผาทำลาย หามา 15 ผืน",
	},
	"q_cn_hanba": {
		"giver": "dao_shi_li", "name": "อสูรภัยแล้ง", "type": "kill", "target": "han_ba", "count": 25,
		"min_level": 74, "requires": "q_cn_bmy", "repeatable": false, "prize": "coins",
		"desc": "อสูรภัยแล้งไปที่ไหนแผ่นดินที่นั่นแห้งผาก ปราบ 25 ตน",
	},
	"q_cn_qin": {
		"giver": "dao_shi_li", "name": "จักรพรรดิผีฉิน", "type": "kill", "target": "qin_gui_di", "count": 1,
		"min_level": 76, "requires": "q_cn_hanba", "repeatable": true, "prize": "gear",
		"desc": "วิญญาณจักรพรรดิตื่นขึ้นมาบัญชาทัพดินเผา จงปราบให้สิ้น",
	},
	# ---- แม่ทัพหลิว (ด่านกำแพงเมืองจีน) ----
	"q_cn_wutou": {
		"giver": "liu_jiang_jun", "name": "ทหารไร้หัวเฝ้าด่าน", "type": "kill", "target": "wutou_bing", "count": 30,
		"min_level": 76, "requires": "", "repeatable": false, "prize": "gear",
		"desc": "ทหารที่ตายบนกำแพงยังเดินยามทั้งที่ไม่มีหัว ปลดปล่อยพวกเขา 30 ตน",
	},
	"q_cn_bowl": {
		"giver": "liu_jiang_jun", "name": "ชามข้าวของผีหิว", "type": "collect", "target": "cham_khao_taek", "count": 15, "source": "e_gui",
		"min_level": 79, "requires": "q_cn_wutou", "repeatable": true, "prize": "potion",
		"desc": "เอาชามข้าวแตกมาทำพิธีเลี้ยงผีหิว 15 ใบ",
	},
	"q_cn_bone": {
		"giver": "liu_jiang_jun", "name": "กองกระดูกเดินได้", "type": "kill", "target": "baigu_yao", "count": 30,
		"min_level": 82, "requires": "q_cn_wutou", "repeatable": false, "prize": "coins",
		"desc": "ปีศาจกระดูกโผล่จากใต้กำแพงทุกคืน ปราบ 30 ตน",
	},
	"q_cn_baigu": {
		"giver": "liu_jiang_jun", "name": "นางปีศาจกระดูกขาว", "type": "kill", "target": "baigu_jing", "count": 1,
		"min_level": 84, "requires": "q_cn_bone", "repeatable": true, "prize": "gear",
		"desc": "นางปีศาจกระดูกขาวแปลงร่างหลอกทหารยาม จงปราบนาง",
	},
	# ---- ยายเหมิ่งโพ (เมืองผีเฟิงตู) ----
	"q_cn_niutou": {
		"giver": "meng_po", "name": "โคเศียรอาละวาด", "type": "kill", "target": "niu_tou", "count": 30,
		"min_level": 84, "requires": "", "repeatable": false, "prize": "gear",
		"desc": "โคเศียรหนีออกจากนรกมาไล่จับคนเป็น ปราบ 30 ตน",
	},
	"q_cn_mane": {
		"giver": "meng_po", "name": "ขนแผงอาชาพักตร์", "type": "collect", "target": "khon_phaeng_ma", "count": 15, "source": "ma_mian",
		"min_level": 86, "requires": "q_cn_niutou", "repeatable": true, "prize": "potion",
		"desc": "ยายจะเอาขนแผงม้ามาถักเป็นเชือกผูกวิญญาณ หามา 15 กำ",
	},
	"q_cn_heibai": {
		"giver": "meng_po", "name": "ยมทูตขาวดำหลงทาง", "type": "kill", "target": "hei_bai", "count": 30,
		"min_level": 88, "requires": "q_cn_niutou", "repeatable": false, "prize": "coins",
		"desc": "ยมทูตขาวดำจับวิญญาณผิดตัวไปทั่วเมือง ปราบ 30 ตน",
	},
	"q_cn_yanwang": {
		"giver": "meng_po", "name": "พญายมราชเฟิงตู", "type": "kill", "target": "yan_wang", "count": 1,
		"min_level": 89, "requires": "q_cn_heibai", "repeatable": true, "prize": "gear",
		"desc": "ศึกสุดท้ายแห่งแผ่นดินจีน ปราบพญายมราชผู้ตัดสินวิญญาณ",
	},
}


## ทำเควสขึ้นเรือครบแล้วหรือยัง (นั่งเรือสำเภาข้ามไปประเทศจีนได้)
static func has_boat_pass(state: Dictionary) -> bool:
	for id in QUESTS:
		if QUESTS[id].get("boat", false) and state["quests_done"].has(id):
			return true
	return false


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
		if q.has("pet_stage") and pet_lock(state, id) != "":
			return "active"  # ทำครบแล้วแต่ต้องพาสัตว์เลี้ยงตัวที่จะพัฒนามาส่งด้วย
		return "ready" if progress(state, inventory, id) >= q["count"] else "active"
	if state["quests_done"].has(id) and not q["repeatable"]:
		return "done"
	if state["level"] < q["min_level"]:
		return "locked"
	if q["requires"] != "" and not state["quests_done"].has(q["requires"]):
		return "locked"
	if q.has("pet_stage") and pet_lock(state, id) != "":
		return "locked"
	return "available"


## เควสพัฒนาร่าง: ต้องมีสัตว์เลี้ยงออกมา อยู่ร่างก่อนหน้า ถึงเลเวล และยังไม่เคยผ่านบททดสอบนี้
## คืนเหตุผลที่ยังรับ/ส่งไม่ได้ ("" = ได้)
static func pet_lock(state: Dictionary, id: String) -> String:
	var stage: int = QUESTS[id]["pet_stage"]
	var key: String = state.get("fashion", {}).get("pet", "")
	var sp := Fashion.pet_of(key)
	if sp == "":
		return "ต้องพาสัตว์เลี้ยงออกมาด้วย"
	var d := Fashion.pet_data(state, sp)
	if int(d.get("trial", 0)) >= stage and d["stage"] == stage - 1:
		return "ผ่านแล้ว พัฒนาร่างได้เลย"
	if d["stage"] != stage - 1:
		return "สำหรับสัตว์เลี้ยงร่างที่ %d Lv.%d ขึ้นไป" % [stage, Fashion.EVOLVE_LEVEL[stage - 1]]
	if d["lv"] < Fashion.EVOLVE_LEVEL[stage - 1]:
		return "สัตว์เลี้ยงต้อง Lv.%d" % Fashion.EVOLVE_LEVEL[stage - 1]
	return ""


## ข้อความบอกว่าทำไมเควสยังล็อก
static func lock_text(state: Dictionary, id: String) -> String:
	var q: Dictionary = QUESTS[id]
	if state["level"] < q["min_level"]:
		return "ต้องเลเวล %d" % q["min_level"]
	if q["requires"] != "" and not state["quests_done"].has(q["requires"]):
		return "ต้องทำ \"%s\" ก่อน" % QUESTS[q["requires"]]["name"]
	if q.has("pet_stage"):
		return pet_lock(state, id)
	return ""


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
	# ตีผีไม่ได้เงินแล้ว เควสจึงเป็นแหล่งเงินหลัก: คิดตามเลเวลผีเป้าหมาย
	var coins := int((4.0 + lv * 1.5) * n * (10.0 if boss else 2.5))
	var items := {}
	match q["prize"]:
		"coins":
			coins *= 3
		"potion":
			var hp_id := "ya_hom_thong" if lv < 40 else "ya_thip"
			var sp_id := "nam_mon_yai" if lv < 40 else "nam_mon_thep"
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
	if QUESTS[id].has("pet_stage"):
		parts.append("สิทธิ์พัฒนาสัตว์เลี้ยงเป็นร่างที่ %d" % (QUESTS[id]["pet_stage"] + 1))
	if QUESTS[id].get("boat", false):
		parts.append("สิทธิ์ขึ้นเรือสำเภาไปประเทศจีน")
	for item in r["items"]:
		parts.append("%s x%d" % [ItemDB.ITEMS[item]["name"], r["items"][item]])
	return " · ".join(parts)
