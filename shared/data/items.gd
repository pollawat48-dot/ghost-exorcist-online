extends RefCounted
## ข้อมูลไอเทม ใช้ร่วมกันทั้ง client และ zone server
## type: etc = วัตถุดิบ, consumable = ใช้ได้, soul = ดวงวิญญาณสำหรับผนึก (ระบบผนึกมาใน M5), equip = ของสวมใส่
##       ore = แร่จากการขุดในถ้ำ, refine = หินตี+ (กดใช้แล้วเปิดหน้าต่างตีบวก)
##       gacha = กาชาปอง (เปิดสุ่มของ), fashion = แฟชั่น/สัตว์เลี้ยง, fashion_refine = หินตี+ แฟชั่น
##       tool = คันเบ็ด, fish = ปลาจากลำธาร, amulet = พระเครื่อง (ใช้ตอนตีบวก เพิ่มโอกาสสำเร็จ refine_bonus)
## ของสวมใส่ที่ตีบวกแล้วเก็บในกระเป๋าด้วยคีย์ "<id>+<ระดับ>" เช่น "mitmo+3" (ใช้ base_id/refine_of แยก)
## ของสวมใส่: slot (weapon/armor/head/accessory), line = สายที่ใช้ได้ (any = ทุกสาย), bonus = ค่าที่เพิ่ม, rarity
## ยา: heal = เพิ่ม HP, sp = เพิ่ม SP (บวกอีก 10% ของค่าสูงสุด), buy = ราคาซื้อจากร้าน
## price = ราคาที่ร้านรับซื้อ (ของสวมใส่คิดตามความหายาก ยาขายคืนได้ 1/4 ของราคาซื้อ)
## ของสวมใส่ที่มี buy = ร้านอาวุธขาย

const SLOTS := ["weapon", "armor", "head", "accessory"]
const SLOT_NAMES := {"weapon": "อาวุธ", "armor": "ชุด", "head": "หมวก", "accessory": "เครื่องราง"}
const RARITY := {
	"common": {"name": "ธรรมดา", "color": Color(0.62, 0.58, 0.6), "price": 120},
	"rare": {"name": "หายาก", "color": Color(0.35, 0.6, 0.95), "price": 500},
	"epic": {"name": "ล้ำค่า", "color": Color(0.7, 0.4, 0.92), "price": 1800},
	"legendary": {"name": "ตำนาน", "color": Color(0.96, 0.66, 0.15), "price": 6000},
}
## ตีบวก: โอกาสสำเร็จเมื่อตีจาก +n ไป +n+1 (index = ระดับปัจจุบัน) ยิ่งสูงยิ่งยาก
const REFINE_MAX := 10
const REFINE_CHANCE := [1.0, 0.95, 0.9, 0.8, 0.7, 0.6, 0.5, 0.35, 0.25, 0.15]
## ตีจาก +7 ขึ้นไปถ้าล้มเหลวจะลดขั้น 1–2 ขั้น (ต่ำกว่านั้นล้มเหลวแค่เสียหินกับเงิน)
const REFINE_RISKY_FROM := 7
## ค่าพลังเพิ่มเป็นสัดส่วนของค่าเดิม ตามระดับ + (เพิ่มขึ้นเรื่อยๆ ยิ่งขั้นสูงยิ่งคุ้ม)
const REFINE_MULT := [0.0, 0.08, 0.16, 0.25, 0.35, 0.46, 0.58, 0.72, 0.9, 1.12, 1.4]
const STAT_NAMES := {"atk": "ATK", "matk": "MATK", "def": "DEF", "str": "STR", "agi": "AGI", "vit": "VIT", "int": "INT", "dex": "DEX", "luk": "LUK"}

const ITEMS := {
	# ---- ยา (ร้านยาขาย) ----
	"herb_potion": {"name": "ยาหอมสมุนไพร", "type": "consumable", "heal": 45, "buy": 20, "icon": "herb", "color": Color(0.4, 0.85, 0.4)},
	"ya_hom_thong": {"name": "ยาหอมทอง", "type": "consumable", "heal": 180, "buy": 90, "icon": "herb", "color": Color(0.95, 0.75, 0.3)},
	"nam_mon": {"name": "น้ำมนต์ทิพย์", "type": "consumable", "sp": 30, "buy": 30, "icon": "water", "color": Color(0.5, 0.7, 1.0)},
	"nam_mon_yai": {"name": "น้ำมนต์ทิพย์ขวดใหญ่", "type": "consumable", "sp": 90, "buy": 110, "icon": "water", "color": Color(0.45, 0.5, 0.95)},
	# ---- ของจากผี (ขายร้านค้าได้ / ใช้ส่งเควส) ----
	"spirit_shard": {"name": "เศษวิญญาณ", "type": "etc", "price": 6, "color": Color(0.7, 0.85, 1.0)},
	"red_thread": {"name": "ด้ายแดง", "type": "etc", "price": 9, "color": Color(0.9, 0.15, 0.2)},
	"lantern_oil": {"name": "น้ำมันตะเกียง", "type": "etc", "price": 14, "color": Color(0.95, 0.75, 0.3)},
	"khamot_ember": {"name": "ประกายไฟโขมด", "type": "etc", "price": 26, "color": Color(0.45, 0.95, 0.85)},
	"pha_ho_sop": {"name": "เศษผ้าห่อศพ", "type": "etc", "price": 38, "color": Color(0.92, 0.9, 0.82)},
	"luk_prakham": {"name": "ลูกประคำเก่า", "type": "etc", "price": 55, "color": Color(0.62, 0.42, 0.36)},
	"soul_krasue": {"name": "ดวงวิญญาณผีกระสือ", "type": "soul", "price": 150, "color": Color(1.0, 0.4, 1.0)},
	"soul_takiang": {"name": "ดวงวิญญาณผีตะเกียง", "type": "soul", "price": 200, "color": Color(1.0, 0.4, 1.0)},
	"soul_queen": {"name": "ดวงวิญญาณนางพญากระสือ", "type": "soul", "price": 1500, "color": Color(1.0, 0.3, 0.6)},
	"soul_khamot": {"name": "ดวงวิญญาณผีโขมด", "type": "soul", "price": 400, "color": Color(0.4, 1.0, 0.9)},
	"soul_pop": {"name": "ดวงวิญญาณผีปอบ", "type": "soul", "price": 500, "color": Color(0.6, 0.9, 0.5)},
	"soul_pret": {"name": "ดวงวิญญาณเปรต", "type": "soul", "price": 650, "color": Color(0.75, 0.6, 1.0)},
	"soul_pret_king": {"name": "ดวงวิญญาณพญาเปรต", "type": "soul", "price": 4000, "color": Color(0.6, 0.4, 1.0)},

	# ---- ยาขวดใหญ่ (ร้านในแผนที่เลเวลสูง) ----
	"ya_thip": {"name": "ยาทิพย์โอสถ", "type": "consumable", "heal": 600, "buy": 300, "icon": "herb", "color": Color(1.0, 0.55, 0.6)},
	"nam_mon_thep": {"name": "น้ำมนต์เทพ", "type": "consumable", "sp": 250, "buy": 350, "icon": "water", "color": Color(0.7, 0.55, 1.0)},
	# ---- แร่ (ขุดในถ้ำ) เรียงจากหาง่ายไปหายาก ----
	"ore_zinc": {"name": "แร่สังกะสี", "type": "ore", "price": 10, "color": Color(0.72, 0.76, 0.8)},
	"ore_iron": {"name": "แร่เหล็ก", "type": "ore", "price": 30, "color": Color(0.62, 0.48, 0.42)},
	"ore_gold": {"name": "แร่ทอง", "type": "ore", "price": 120, "color": Color(1.0, 0.8, 0.3)},
	"ore_diamond": {"name": "เพชร", "type": "ore", "price": 600, "color": Color(0.6, 0.95, 1.0)},
	# ---- หินตี+ (หลอมที่ร้านหลอมแร่) refine_max = ตีได้ถึงขั้นนี้ ----
	"hin_ti_1": {"name": "หินตี+ ขั้นต้น", "type": "refine", "refine_max": 4, "price": 40, "color": Color(0.75, 0.8, 0.88)},
	"hin_ti_2": {"name": "หินตี+ ขั้นกลาง", "type": "refine", "refine_max": 7, "price": 250, "color": Color(1.0, 0.82, 0.4)},
	"hin_ti_3": {"name": "หินตี+ ขั้นสูง", "type": "refine", "refine_max": 10, "price": 1200, "color": Color(0.55, 0.9, 1.0)},
	# ---- ของจากผีแผนที่ 3–6 ----
	"pha_prae": {"name": "ผ้าแพรเก่า", "type": "etc", "price": 70, "color": Color(0.95, 0.6, 0.6)},
	"poi_phom": {"name": "ปอยผมผี", "type": "etc", "price": 85, "color": Color(0.35, 0.3, 0.4)},
	"lek_krung": {"name": "เศษเกราะกรุเก่า", "type": "etc", "price": 100, "color": Color(0.7, 0.62, 0.5)},
	"mo_din": {"name": "หม้อดินผีกะ", "type": "etc", "price": 120, "color": Color(0.8, 0.52, 0.38)},
	"fai_pong": {"name": "ไฟผีโป่ง", "type": "etc", "price": 140, "color": Color(0.65, 1.0, 0.5)},
	"bai_takhian": {"name": "ใบตะเคียนทอง", "type": "etc", "price": 165, "color": Color(0.55, 0.85, 0.4)},
	"sarai_phrai": {"name": "สาหร่ายพราย", "type": "etc", "price": 190, "color": Color(0.4, 0.85, 0.75)},
	"klet_nak": {"name": "เกล็ดนาค", "type": "etc", "price": 220, "color": Color(0.45, 0.75, 0.6)},
	"khon_kong_koi": {"name": "ขนกองกอย", "type": "etc", "price": 250, "color": Color(0.6, 0.45, 0.35)},
	"khiao_asura": {"name": "เขี้ยวอสุรกาย", "type": "etc", "price": 280, "color": Color(1.0, 0.95, 0.85)},
	"buang_yom": {"name": "เชือกบ่วงยมทูต", "type": "etc", "price": 320, "color": Color(0.45, 0.4, 0.55)},
	"fai_awe": {"name": "ไฟอเวจี", "type": "etc", "price": 360, "color": Color(1.0, 0.4, 0.3)},
	"soul_khun_suek": {"name": "ดวงวิญญาณขุนศึกผี", "type": "soul", "price": 8000, "color": Color(1.0, 0.75, 0.35)},
	"soul_phraya_phrai": {"name": "ดวงวิญญาณพญาพราย", "type": "soul", "price": 14000, "color": Color(0.5, 1.0, 0.6)},
	"soul_phaya_nak": {"name": "ดวงวิญญาณพญานาค", "type": "soul", "price": 24000, "color": Color(0.4, 0.9, 1.0)},
	"soul_matchurat": {"name": "ดวงวิญญาณพญามัจจุราช", "type": "soul", "price": 40000, "color": Color(1.0, 0.3, 0.35)},

	# ---- ตกปลาที่ลำธาร: คันเบ็ด (ร้านตาม่อง) ปลา (ขายได้) พระเครื่อง (เพิ่ม % ตีบวก) ----
	"bet_mai": {"name": "คันเบ็ดไม้ไผ่", "type": "tool", "buy": 300, "fish_time": 10.0, "luck": 1.0, "price": 75, "color": Color(0.82, 0.66, 0.4)},
	"bet_thong": {"name": "คันเบ็ดทองเหลือง", "type": "tool", "buy": 6000, "fish_time": 7.0, "luck": 1.6, "price": 1500, "color": Color(1.0, 0.78, 0.3)},
	"pla_siew": {"name": "ปลาซิว", "type": "fish", "price": 8, "color": Color(0.75, 0.82, 0.88)},
	"pla_nil": {"name": "ปลานิล", "type": "fish", "price": 25, "color": Color(0.55, 0.62, 0.7)},
	"pla_chon": {"name": "ปลาช่อน", "type": "fish", "price": 70, "color": Color(0.42, 0.45, 0.35)},
	"pla_buek": {"name": "ปลาบึก", "type": "fish", "price": 450, "color": Color(0.6, 0.66, 0.78)},
	"phra_din": {"name": "พระเครื่องดินเผา", "type": "amulet", "refine_bonus": 0.05, "price": 300, "color": Color(0.8, 0.5, 0.35)},
	"phra_phong": {"name": "พระเครื่องเนื้อผง", "type": "amulet", "refine_bonus": 0.1, "price": 1200, "color": Color(0.95, 0.92, 0.82)},
	"phra_thong": {"name": "พระเครื่องเนื้อทองคำ", "type": "amulet", "refine_bonus": 0.2, "price": 5000, "color": Color(1.0, 0.8, 0.25)},

	# ---- อาวุธ ----
	"maipai_staff": {"name": "ไม้เท้าไผ่สีสุก", "type": "equip", "slot": "weapon", "line": "any", "rarity": "common", "buy": 300, "bonus": {"atk": 6, "matk": 6}},
	"mitmo": {"name": "มีดหมอลงอาคม", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "rare", "buy": 1250, "bonus": {"atk": 15, "str": 2}},
	"khan_thanu": {"name": "ธนูไม้มะขาม", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "rare", "buy": 1250, "bonus": {"atk": 13, "dex": 2}},
	"khamphi_yant": {"name": "คัมภีร์ยันต์ใบลาน", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "rare", "buy": 1250, "bonus": {"matk": 15, "int": 2}},
	"dab_fafuen": {"name": "ดาบฟ้าฟื้น", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "legendary", "bonus": {"atk": 34, "str": 4, "agi": 2}},
	"thanu_ratri": {"name": "ธนูรัตติกาล", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "legendary", "bonus": {"atk": 31, "dex": 4, "agi": 2}},
	"khamphi_queen": {"name": "คัมภีร์นางพญา", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "legendary", "bonus": {"matk": 35, "int": 4, "dex": 2}},
	"dab_pa_cha": {"name": "ดาบหมอผีป่าช้า", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 26, "str": 3}},
	"na_mai_khamot": {"name": "หน้าไม้ไฟโขมด", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 24, "dex": 3}},
	"khamphi_khamot": {"name": "คัมภีร์ไฟโขมด", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 26, "int": 3}},
	# ---- ชุด ----
	"suea_yant": {"name": "เสื้อยันต์", "type": "equip", "slot": "armor", "line": "any", "rarity": "common", "buy": 250, "bonus": {"def": 5}},
	"suea_kraphan": {"name": "เสื้อคงกระพัน", "type": "equip", "slot": "armor", "line": "any", "rarity": "rare", "buy": 1250, "bonus": {"def": 9, "vit": 2}},
	"jiwon_saksit": {"name": "จีวรศักดิ์สิทธิ์", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 15, "vit": 3, "int": 2}},
	"pha_yant_pret": {"name": "ผ้ายันต์พญาเปรต", "type": "equip", "slot": "armor", "line": "any", "rarity": "legendary", "bonus": {"def": 23, "vit": 5, "int": 2}},
	# ---- หมวก ----
	"pha_khat_hua": {"name": "ผ้าคาดหัวลงยันต์", "type": "equip", "slot": "head", "line": "any", "rarity": "common", "buy": 200, "bonus": {"def": 2, "str": 1}},
	"mongkhon": {"name": "มงคลสวมหัว", "type": "equip", "slot": "head", "line": "any", "rarity": "rare", "buy": 1100, "bonus": {"def": 4, "int": 3}},
	"mongkut_queen": {"name": "มงกุฎนางพญา", "type": "equip", "slot": "head", "line": "any", "rarity": "epic", "bonus": {"def": 6, "luk": 3, "agi": 2}},
	# ---- เครื่องราง ----
	"saisin": {"name": "สายสิญจน์ข้อมือ", "type": "equip", "slot": "accessory", "line": "any", "rarity": "common", "buy": 200, "bonus": {"vit": 2}},
	"takrut": {"name": "ตะกรุดโทน", "type": "equip", "slot": "accessory", "line": "any", "rarity": "rare", "buy": 1100, "bonus": {"luk": 3, "def": 2}},
	"phra_khrueang": {"name": "พระเครื่องหลวงปู่", "type": "equip", "slot": "accessory", "line": "any", "rarity": "rare", "buy": 1150, "bonus": {"vit": 3, "def": 3}},
	"khiao_queen": {"name": "เขี้ยวนางพญากระสือ", "type": "equip", "slot": "accessory", "line": "any", "rarity": "epic", "bonus": {"str": 2, "agi": 2, "vit": 2, "int": 2, "dex": 2, "luk": 2}},
	"prakham_pret": {"name": "ประคำพญาเปรต", "type": "equip", "slot": "accessory", "line": "any", "rarity": "legendary", "bonus": {"str": 4, "agi": 4, "vit": 4, "int": 4, "dex": 4, "luk": 4}},
	# ======== ร้านอาวุธ ขั้น 2 (แคมป์กรุงเก่า) และขั้น 3 (แคมป์บึงนาคา) ========
	"dab_lek": {"name": "ดาบเหล็กน้ำพี้", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "rare", "buy": 4400, "bonus": {"atk": 22, "str": 2}},
	"thanu_khao": {"name": "ธนูเขาควาย", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "rare", "buy": 4400, "bonus": {"atk": 21, "dex": 2}},
	"khamphi_thong": {"name": "คัมภีร์ปกทอง", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "rare", "buy": 4400, "bonus": {"matk": 23, "int": 2}},
	"suea_so": {"name": "เสื้อเกราะโซ่", "type": "equip", "slot": "armor", "line": "any", "rarity": "rare", "buy": 3700, "bonus": {"def": 12, "vit": 2}},
	"dab_ngoen": {"name": "ดาบเงินยวง", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "rare", "buy": 11100, "bonus": {"atk": 29, "str": 2}},
	"thanu_ngoen": {"name": "ธนูเงินยวง", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "rare", "buy": 11100, "bonus": {"atk": 27, "dex": 2}},
	"khamphi_ngoen": {"name": "คัมภีร์เงินยวง", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "rare", "buy": 11100, "bonus": {"matk": 30, "int": 2}},
	"kraphan_ngoen": {"name": "เกราะเงินยวง", "type": "equip", "slot": "armor", "line": "any", "rarity": "rare", "buy": 9250, "bonus": {"def": 16, "vit": 2}},
	"muak_ngoen": {"name": "หมวกเงินยวง", "type": "equip", "slot": "head", "line": "any", "rarity": "rare", "buy": 5550, "bonus": {"def": 5, "vit": 1, "int": 1}},
	# ======== แผนที่ 3: กรุงเก่าร้าง ========
	"dab_krung": {"name": "ดาบกรุเก่า", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 36, "str": 4}},
	"thanu_krung": {"name": "ธนูทหารกรุง", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 33, "dex": 4}},
	"khoi_boran": {"name": "สมุดข่อยโบราณ", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 37, "int": 4}},
	"kraphan_krung": {"name": "เกราะนักรบกรุงเก่า", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 19, "vit": 4}},
	"muak_boran": {"name": "หมวกทหารโบราณ", "type": "equip", "slot": "head", "line": "any", "rarity": "rare", "bonus": {"def": 7, "str": 1, "vit": 1}},
	"waen_pirot": {"name": "แหวนพิรอดกรุ", "type": "equip", "slot": "accessory", "line": "any", "rarity": "rare", "bonus": {"luk": 3, "dex": 2}},
	"chada_khun": {"name": "ชฎาขุนศึก", "type": "equip", "slot": "head", "line": "any", "rarity": "legendary", "bonus": {"def": 10, "str": 3, "int": 3, "agi": 2}},
	"prajiat_khun": {"name": "ประเจียดขุนศึก", "type": "equip", "slot": "accessory", "line": "any", "rarity": "legendary", "bonus": {"str": 5, "agi": 5, "vit": 5, "int": 5, "dex": 5, "luk": 5}},
	# ======== แผนที่ 4: ดอยผีปันน้ำ ========
	"dab_chao_pa": {"name": "ดาบเจ้าป่า", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 42, "str": 4}},
	"thanu_doi": {"name": "ธนูไม้ดอย", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 39, "dex": 4}},
	"khamphi_nang_mai": {"name": "คัมภีร์นางไม้", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 43, "int": 4}},
	"chut_phran": {"name": "ชุดพรานดอย", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 21, "vit": 4, "agi": 2}},
	"khiao_saming": {"name": "เขี้ยวเสือสมิง", "type": "equip", "slot": "accessory", "line": "any", "rarity": "epic", "bonus": {"str": 3, "agi": 3, "dex": 3}},
	"dab_phrai": {"name": "ดาบพญาพราย", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "legendary", "bonus": {"atk": 58, "str": 6, "agi": 2}},
	"thanu_phrai": {"name": "ธนูพญาพราย", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "legendary", "bonus": {"atk": 55, "dex": 6, "agi": 2}},
	"khamphi_phrai": {"name": "คัมภีร์พญาพราย", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "legendary", "bonus": {"matk": 60, "int": 6, "dex": 2}},
	# ======== แผนที่ 5: บึงนาคาบาดาล ========
	"dab_naga": {"name": "ดาบเกล็ดนาค", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 47, "str": 4}},
	"thanu_naga": {"name": "ธนูนาคา", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 45, "dex": 4}},
	"khamphi_badan": {"name": "คัมภีร์บาดาล", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 48, "int": 4}},
	"kraphan_naga": {"name": "เกราะเกล็ดนาค", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 25, "vit": 4}},
	"mongkut_naki": {"name": "มงกุฎนาคี", "type": "equip", "slot": "head", "line": "any", "rarity": "epic", "bonus": {"def": 7, "int": 3, "luk": 3}},
	"kaeo_naga": {"name": "แก้วพญานาค", "type": "equip", "slot": "accessory", "line": "any", "rarity": "legendary", "bonus": {"str": 5, "agi": 5, "vit": 5, "int": 5, "dex": 5, "luk": 5}},
	"kraphan_thamin": {"name": "เกราะพญานาคทมิฬ", "type": "equip", "slot": "armor", "line": "any", "rarity": "legendary", "bonus": {"def": 36, "vit": 6, "str": 2}},
	# ======== แผนที่ 6: ยมโลก ========
	"dab_yom": {"name": "ดาบยมทูต", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 58, "str": 5}},
	"thanu_awe": {"name": "ธนูอเวจี", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 56, "dex": 5}},
	"khamphi_marana": {"name": "คัมภีร์มรณะ", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 60, "int": 5}},
	"chut_yom": {"name": "ชุดยมทูต", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 29, "vit": 5}},
	"dab_matchu": {"name": "ดาบมัจจุราช", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "legendary", "bonus": {"atk": 82, "str": 7, "agi": 3}},
	"thanu_matchu": {"name": "ธนูมัจจุราช", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "legendary", "bonus": {"atk": 78, "dex": 7, "agi": 3}},
	"khamphi_matchu": {"name": "คัมภีร์มัจจุราช", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "legendary", "bonus": {"matk": 86, "int": 7, "dex": 3}},
	"mongkut_matchu": {"name": "มงกุฎมัจจุราช", "type": "equip", "slot": "head", "line": "any", "rarity": "legendary", "bonus": {"def": 12, "str": 2, "vit": 2, "int": 2}},

	# ======== ประเทศจีน: ร้านอาวุธท่าเรือ (ของหายาก) ของจากผีจีน (ล้ำค่า) และบอสจีน (ตำนาน) ดรอปเฉพาะผีจีน ========
	"dab_jian_cn": {"name": "กระบี่เหล็กจีน", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "rare", "buy": 9000, "bonus": {"atk": 52, "str": 5}},
	"thanu_khao_pae": {"name": "ธนูเขาแพะภูเขา", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "rare", "buy": 9000, "bonus": {"atk": 48, "dex": 5}},
	"khamphi_muek_cn": {"name": "คัมภีร์หมึกจีน", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "rare", "buy": 9000, "bonus": {"matk": 55, "int": 5}},
	"kraphan_fai_cn": {"name": "เกราะผ้าฝ้ายบุนวม", "type": "equip", "slot": "armor", "line": "any", "rarity": "rare", "buy": 7500, "bonus": {"def": 24, "vit": 5}},
	"muak_pha_cn": {"name": "หมวกผ้าโพกจีน", "type": "equip", "slot": "head", "line": "any", "rarity": "rare", "buy": 5000, "bonus": {"def": 8, "int": 3, "luk": 3}},
	"fu_huang": {"name": "ยันต์เหลืองขาด", "type": "etc", "price": 190, "color": Color(1.0, 0.86, 0.3)},
	"hai_zao": {"name": "สาหร่ายทะเลผีพราย", "type": "etc", "price": 210, "color": Color(0.35, 0.7, 0.6)},
	"dao_kuangtung": {"name": "ดาบเหล็กกล้ากวางตุ้ง", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 63, "str": 8}},
	"thanu_samphao": {"name": "ธนูเรือสำเภา", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 59, "dex": 8}},
	"yan_jiangshi": {"name": "คัมภีร์ยันต์เหลือง", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 66, "int": 8}},
	"chut_dao_shi": {"name": "ชุดนักพรตเต๋า", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 29, "vit": 7}},
	"muak_khunnang_ching": {"name": "หมวกขุนนางชิง", "type": "equip", "slot": "head", "line": "any", "rarity": "epic", "bonus": {"def": 9, "int": 4, "luk": 4}},
	"dab_jiangshi_wang": {"name": "ดาบราชาเจียงซือ", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "legendary", "bonus": {"atk": 94, "str": 12, "agi": 6}},
	"thanu_jiangshi_wang": {"name": "ธนูราชาเจียงซือ", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "legendary", "bonus": {"atk": 90, "dex": 12, "agi": 6}},
	"khamphi_jiangshi_wang": {"name": "คัมภีร์ราชาเจียงซือ", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "legendary", "bonus": {"matk": 97, "int": 12, "dex": 6}},
	"luk_pat_yok_wang": {"name": "ลูกปัดหยกราชาเจียงซือ", "type": "equip", "slot": "accessory", "line": "any", "rarity": "legendary", "bonus": {"str": 9, "agi": 9, "vit": 9, "int": 9, "dex": 9, "luk": 9}},
	"soul_jiangshi_wang": {"name": "ดวงวิญญาณราชาเจียงซือ", "type": "soul", "price": 6000, "color": Color(0.6, 1.0, 0.7)},
	"khon_jingjok": {"name": "ขนจิ้งจอกปีศาจ", "type": "etc", "price": 240, "color": Color(1.0, 0.6, 0.3)},
	"chueak_khwaen": {"name": "เชือกแขวนคอเก่า", "type": "etc", "price": 260, "color": Color(0.75, 0.62, 0.48)},
	"pin_yok_rao": {"name": "ปิ่นปักผมหยกร้าว", "type": "etc", "price": 280, "color": Color(0.6, 0.95, 0.8)},
	"krabi_phai": {"name": "กระบี่ไผ่มรกต", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 70, "str": 9}},
	"thanu_phai_mok": {"name": "ธนูไผ่หมอก", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 66, "dex": 9}},
	"phat_khon_nok": {"name": "พัดขนนกเซียน", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 73, "int": 9}},
	"chut_mai_jingjok": {"name": "ชุดผ้าไหมจิ้งจอก", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 32, "vit": 8}},
	"pin_yok_sian": {"name": "ปิ่นหยกเซียน", "type": "equip", "slot": "accessory", "line": "any", "rarity": "epic", "bonus": {"str": 6, "agi": 6, "dex": 6}},
	"krabi_kao_hang": {"name": "กระบี่เก้าหาง", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "legendary", "bonus": {"atk": 105, "str": 14, "agi": 7}},
	"thanu_kao_hang": {"name": "ธนูเก้าหาง", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "legendary", "bonus": {"atk": 101, "dex": 14, "agi": 7}},
	"phat_kao_hang": {"name": "พัดเก้าหาง", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "legendary", "bonus": {"matk": 108, "int": 14, "dex": 7}},
	"mongkut_kao_hang": {"name": "มงกุฎจิ้งจอกเก้าหาง", "type": "equip", "slot": "head", "line": "any", "rarity": "legendary", "bonus": {"def": 17, "int": 10, "luk": 10}},
	"soul_jiuwei_hu": {"name": "ดวงวิญญาณจิ้งจอกเก้าหาง", "type": "soul", "price": 9000, "color": Color(1.0, 0.55, 0.3)},
	"set_din_phao": {"name": "เศษดินเผาโบราณ", "type": "etc", "price": 290, "color": Color(0.82, 0.55, 0.4)},
	"nang_wat_phi": {"name": "หนังวาดผี", "type": "etc", "price": 310, "color": Color(1.0, 0.82, 0.78)},
	"than_fai_haeng": {"name": "ถ่านไฟภัยแล้ง", "type": "etc", "price": 330, "color": Color(1.0, 0.4, 0.2)},
	"ngao_din_phao": {"name": "ง้าวทหารดินเผา", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 76, "str": 10}},
	"namai_qin": {"name": "หน้าไม้ราชวงศ์ฉิน", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 72, "dex": 10}},
	"tamra_phai_qin": {"name": "ตำราไม้ไผ่ฉิน", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 79, "int": 10}},
	"kraphan_din_phao": {"name": "เกราะดินเผาฉิน", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 36, "vit": 9}},
	"muak_thahan_qin": {"name": "หมวกทหารฉิน", "type": "equip", "slot": "head", "line": "any", "rarity": "epic", "bonus": {"def": 12, "int": 6, "luk": 6}},
	"krabi_qin": {"name": "กระบี่จักรพรรดิฉิน", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "legendary", "bonus": {"atk": 114, "str": 15, "agi": 7}},
	"namai_jakkraphat": {"name": "หน้าไม้จักรพรรดิ", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "legendary", "bonus": {"atk": 110, "dex": 15, "agi": 7}},
	"tra_yok_qin": {"name": "ตราหยกจักรพรรดิ", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "legendary", "bonus": {"matk": 117, "int": 15, "dex": 7}},
	"chalong_mangkon_dam": {"name": "ฉลองพระองค์มังกรดำ", "type": "equip", "slot": "armor", "line": "any", "rarity": "legendary", "bonus": {"def": 54, "vit": 18, "str": 5}},
	"soul_qin_gui_di": {"name": "ดวงวิญญาณจักรพรรดิผีฉิน", "type": "soul", "price": 13000, "color": Color(1.0, 0.8, 0.35)},
	"thong_suek_khat": {"name": "ธงศึกขาดวิ่น", "type": "etc", "price": 340, "color": Color(0.85, 0.3, 0.3)},
	"cham_khao_taek": {"name": "ชามข้าวแตก", "type": "etc", "price": 360, "color": Color(0.9, 0.9, 0.85)},
	"kraduk_khao": {"name": "กระดูกขาว", "type": "etc", "price": 380, "color": Color(0.98, 0.96, 0.9)},
	"dab_mae_thap": {"name": "ดาบแม่ทัพด่าน", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 84, "str": 11}},
	"thanu_yam_kamphaeng": {"name": "ธนูยามกำแพง", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 80, "dex": 11}},
	"khamphi_kamphaeng": {"name": "คัมภีร์อาคมกำแพง", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 87, "int": 11}},
	"kraphan_yam": {"name": "เกราะยามกำแพง", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 40, "vit": 10}},
	"rian_tra_dan": {"name": "เหรียญตราด่านเหนือ", "type": "equip", "slot": "accessory", "line": "any", "rarity": "epic", "bonus": {"str": 8, "agi": 8, "dex": 8}},
	"dab_kraduk_khao": {"name": "ดาบกระดูกขาว", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "legendary", "bonus": {"atk": 126, "str": 16, "agi": 8}},
	"thanu_kraduk_khao": {"name": "ธนูกระดูกขาว", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "legendary", "bonus": {"atk": 122, "dex": 16, "agi": 8}},
	"mai_thao_kraduk": {"name": "ไม้เท้ากระดูกขาว", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "legendary", "bonus": {"matk": 129, "int": 16, "dex": 8}},
	"soi_kalok_pisat": {"name": "สร้อยกะโหลกปีศาจ", "type": "equip", "slot": "accessory", "line": "any", "rarity": "legendary", "bonus": {"str": 13, "agi": 13, "vit": 13, "int": 13, "dex": 13, "luk": 13}},
	"soul_baigu_jing": {"name": "ดวงวิญญาณนางปีศาจกระดูกขาว", "type": "soul", "price": 17000, "color": Color(0.95, 0.95, 1.0)},
	"khao_kho": {"name": "เขาโคเศียร", "type": "etc", "price": 400, "color": Color(0.55, 0.4, 0.35)},
	"khon_phaeng_ma": {"name": "ขนแผงอาชา", "type": "etc", "price": 420, "color": Color(0.4, 0.32, 0.3)},
	"pai_yom_thut": {"name": "ป้ายยมทูตขาวดำ", "type": "etc", "price": 450, "color": Color(0.8, 0.8, 0.85)},
	"ngao_kho_sian": {"name": "ง้าวโคเศียร", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 92, "str": 12}},
	"thanu_acha": {"name": "ธนูอาชาพักตร์", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 88, "dex": 12}},
	"samut_banchi_winyan": {"name": "สมุดบัญชีวิญญาณ", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 95, "int": 12}},
	"chut_yomthut_khao_dam": {"name": "ชุดยมทูตขาวดำ", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 44, "vit": 11}},
	"muak_sung_yomthut": {"name": "หมวกสูงยมทูต", "type": "equip", "slot": "head", "line": "any", "rarity": "epic", "bonus": {"def": 14, "int": 7, "luk": 7}},
	"krabi_yomarat": {"name": "กระบี่พญายมราช", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "legendary", "bonus": {"atk": 138, "str": 18, "agi": 9}},
	"thanu_yomarat": {"name": "ธนูพญายมราช", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "legendary", "bonus": {"atk": 134, "dex": 18, "agi": 9}},
	"phu_kan_chi_chata": {"name": "พู่กันชี้ชะตา", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "legendary", "bonus": {"matk": 141, "int": 18, "dex": 9}},
	"mongkut_yomarat": {"name": "มงกุฎพญายมราช", "type": "equip", "slot": "head", "line": "any", "rarity": "legendary", "bonus": {"def": 23, "int": 14, "luk": 14}},
	"soul_yan_wang": {"name": "ดวงวิญญาณพญายมราช", "type": "soul", "price": 22000, "color": Color(1.0, 0.3, 0.3)},

	# ======== ร้าน CC: กาชาปอง และของที่สุ่มได้ (ดูตาราง shared/data/fashion.gd) ========
	"gachapon": {"name": "กาชาปองนำโชค", "type": "gacha", "price": 0, "color": Color(1.0, 0.7, 0.82)},
	"kluea_sek": {"name": "เกลือเสกไล่ผี", "type": "consumable", "buff": {"effect": "def", "power": 0.2, "duration": 90.0}, "buy": 0, "price": 15, "icon": "salt", "color": Color(0.95, 0.96, 1.0)},
	"hin_ti_fashion": {"name": "หินตี+ แฟชั่น", "type": "fashion_refine", "price": 0, "color": Color(1.0, 0.62, 0.86)},
	# ---- แฟชั่น: slot = costume (ชุด) / hat (หมวก) / wings (ปีก) / pet (สัตว์เลี้ยง) ใส่แยกจากของสวมใส่ ตีบวกด้วยหินตี+ แฟชั่น ----
	"f_chut_dek_wat": {"name": "ชุดเด็กวัดลายกนก", "type": "fashion", "slot": "costume", "rarity": "common", "bonus": {"vit": 2, "def": 3}, "tint": Color(1.0, 0.82, 0.55)},
	"f_chut_thai": {"name": "ชุดไทยจักรีพาสเทล", "type": "fashion", "slot": "costume", "rarity": "rare", "bonus": {"vit": 3, "int": 3, "def": 5}, "tint": Color(0.72, 0.84, 1.0)},
	"f_chut_nang_ram": {"name": "ชุดนางรำสไบทอง", "type": "fashion", "slot": "costume", "rarity": "epic", "bonus": {"agi": 4, "dex": 4, "def": 8}, "tint": Color(1.0, 0.62, 0.72)},
	"f_chut_thewada": {"name": "ชุดเทวดาสวรรค์", "type": "fashion", "slot": "costume", "rarity": "legendary", "bonus": {"str": 5, "int": 5, "vit": 5, "def": 12}, "tint": Color(1.0, 0.97, 0.88)},
	"f_hu_maeo": {"name": "ที่คาดหูแมวชมพู", "type": "fashion", "slot": "hat", "rarity": "common", "bonus": {"luk": 3}, "tint": Color(1.0, 0.72, 0.82)},
	"f_ngob": {"name": "งอบลายดอกไม้", "type": "fashion", "slot": "hat", "rarity": "rare", "bonus": {"vit": 2, "dex": 3, "def": 2}, "tint": Color(0.94, 0.82, 0.58)},
	"f_mongkut_mali": {"name": "มงกุฎดอกมะลิ", "type": "fashion", "slot": "hat", "rarity": "epic", "bonus": {"int": 4, "luk": 4}, "tint": Color(0.96, 1.0, 0.94)},
	"f_chada_thep": {"name": "ชฎาเทพธิดา", "type": "fashion", "slot": "hat", "rarity": "legendary", "bonus": {"str": 4, "int": 4, "luk": 5, "matk": 10}, "tint": Color(1.0, 0.84, 0.4)},
	"f_pik_khangkhao": {"name": "ปีกค้างคาวน้อย", "type": "fashion", "slot": "wings", "rarity": "common", "bonus": {"agi": 2, "atk": 3}, "tint": Color(0.62, 0.52, 0.78)},
	"f_pik_phisuea": {"name": "ปีกผีเสื้อพาสเทล", "type": "fashion", "slot": "wings", "rarity": "rare", "bonus": {"agi": 3, "dex": 3, "atk": 5}, "tint": Color(0.7, 0.9, 1.0)},
	"f_pik_nangfa": {"name": "ปีกนางฟ้า", "type": "fashion", "slot": "wings", "rarity": "epic", "bonus": {"int": 4, "matk": 12}, "tint": Color(1.0, 1.0, 1.0)},
	"f_pik_kinnari": {"name": "ปีกกินรีทองคำ", "type": "fashion", "slot": "wings", "rarity": "legendary", "bonus": {"agi": 5, "str": 5, "atk": 15, "matk": 15}, "tint": Color(1.0, 0.82, 0.38)},
	# ---- สัตว์เลี้ยง (ใส่ช่อง pet แล้วออกมาเดินตาม ช่วยสู้ ใช้สกิลเอง) ข้อมูลร่าง/สกิลอยู่ที่ fashion.gd PETS ----
	"pet_maa": {"name": "ลูกหมาบางแก้ว", "type": "fashion", "slot": "pet", "rarity": "common", "pet": "maa", "tint": Color(0.95, 0.8, 0.6)},
	"pet_maeo": {"name": "แมววิเชียรมาศ", "type": "fashion", "slot": "pet", "rarity": "rare", "pet": "maeo", "tint": Color(0.96, 0.9, 0.8)},
	"pet_krathai": {"name": "กระต่ายจันทร์", "type": "fashion", "slot": "pet", "rarity": "rare", "pet": "krathai", "tint": Color(1.0, 0.92, 0.95)},
	"pet_nok": {"name": "นกแก้วพูดได้", "type": "fashion", "slot": "pet", "rarity": "epic", "pet": "nok", "tint": Color(0.5, 0.88, 0.5)},
	"pet_chang": {"name": "ลูกช้างเผือก", "type": "fashion", "slot": "pet", "rarity": "legendary", "pet": "chang", "tint": Color(0.92, 0.9, 0.95)},
}


## คีย์ในกระเป๋า -> id ของไอเทม ("mitmo+3" -> "mitmo")
static func base_id(key: String) -> String:
	var i := key.find("+")
	return key if i < 0 else key.substr(0, i)


## ระดับตีบวกจากคีย์ ("mitmo+3" -> 3)
static func refine_of(key: String) -> int:
	var i := key.find("+")
	return 0 if i < 0 else int(key.substr(i + 1))


static func refined_key(id: String, level: int) -> String:
	return id if level <= 0 else "%s+%d" % [id, level]


## ข้อมูลไอเทมจากคีย์ในกระเป๋า (รองรับของที่ตีบวกแล้ว)
static func info(key: String) -> Dictionary:
	return ITEMS[base_id(key)]


static func has(key: String) -> bool:
	return ITEMS.has(base_id(key))


## ชื่อที่แสดง เช่น "+3 มีดหมอลงอาคม"
static func display_name(key: String) -> String:
	var lv := refine_of(key)
	var n: String = info(key)["name"]
	return n if lv <= 0 else "+%d %s" % [lv, n]


## ค่าพลังจริงของของสวมใส่ รวมผลตีบวก (ATK/MATK/DEF เพิ่มอย่างน้อย 2 ต่อขั้น)
static func bonus_of(key: String) -> Dictionary:
	var base: Dictionary = info(key).get("bonus", {})
	var lv := refine_of(key)
	if lv <= 0:
		return base
	var mult: float = REFINE_MULT[lv]
	var out := {}
	for k in base:
		var add := int(round(base[k] * mult))
		if k in ["atk", "matk", "def"]:
			add = maxi(add, lv * 2)
		out[k] = base[k] + add
	return out


## ค่าตีบวกจาก +level ไป +level+1 (เหรียญ)
static func refine_fee(level: int) -> int:
	return 100 * (level + 1) * (level + 1)


static func color_of(item_id: String) -> Color:
	var item: Dictionary = info(item_id)
	if item["type"] in ["equip", "fashion"]:
		return RARITY[item["rarity"]]["color"]
	return item["color"]


## ราคาที่ร้านรับซื้อต่อชิ้น (0 = ขายไม่ได้)
static func sell_price(item_id: String) -> int:
	var item: Dictionary = info(item_id)
	match item["type"]:
		"equip":
			return int(RARITY[item["rarity"]]["price"] * (1.0 + refine_of(item_id) * 0.4))
		"consumable":
			return item.get("buy", 0) / 4
	return item.get("price", 0)


## คำอธิบายผลของยา เช่น "HP +180" หรือ "SP +30"
static func use_text(item_id: String) -> String:
	var item: Dictionary = info(item_id)
	var parts: Array[String] = []
	if item.has("heal"):
		parts.append("HP +%d" % item["heal"])
	if item.has("sp"):
		parts.append("SP +%d" % item["sp"])
	if item.has("buff"):
		var b: Dictionary = item["buff"]
		return "%s +%d%% %d วินาที" % [STAT_NAMES.get(b["effect"], b["effect"]), int(round(b["power"] * 100)), int(b["duration"])]
	return " · ".join(parts) + " (+10% ของสูงสุด)"


## คำอธิบายค่าที่เพิ่ม เช่น "ATK +18 · STR +2"
static func bonus_text(item_id: String) -> String:
	var parts: Array[String] = []
	var bonus := bonus_of(item_id)
	for key in bonus:
		parts.append("%s +%d" % [STAT_NAMES[key], bonus[key]])
	return " · ".join(parts)
