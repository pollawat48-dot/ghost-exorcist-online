extends RefCounted
## ข้อมูลไอเทม ใช้ร่วมกันทั้ง client และ zone server
## type: etc = วัตถุดิบ, consumable = ใช้ได้, soul = ดวงวิญญาณสำหรับผนึก (ระบบผนึกมาใน M5), equip = ของสวมใส่
##       ore = แร่จากการขุดในถ้ำ, refine = หินตี+ (กดใช้แล้วเปิดหน้าต่างตีบวก)
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

	# ---- อาวุธ ----
	"maipai_staff": {"name": "ไม้เท้าไผ่สีสุก", "type": "equip", "slot": "weapon", "line": "any", "rarity": "common", "buy": 300, "bonus": {"atk": 6, "matk": 6}},
	"mitmo": {"name": "มีดหมอลงอาคม", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "rare", "buy": 1500, "bonus": {"atk": 18, "str": 2}},
	"khan_thanu": {"name": "ธนูไม้มะขาม", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "rare", "buy": 1500, "bonus": {"atk": 16, "dex": 2}},
	"khamphi_yant": {"name": "คัมภีร์ยันต์ใบลาน", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "rare", "buy": 1500, "bonus": {"matk": 18, "int": 2}},
	"dab_fafuen": {"name": "ดาบฟ้าฟื้น", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "legendary", "bonus": {"atk": 48, "str": 6, "agi": 3}},
	"thanu_ratri": {"name": "ธนูรัตติกาล", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "legendary", "bonus": {"atk": 44, "dex": 6, "agi": 3}},
	"khamphi_queen": {"name": "คัมภีร์นางพญา", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "legendary", "bonus": {"matk": 50, "int": 6, "dex": 3}},
	"dab_pa_cha": {"name": "ดาบหมอผีป่าช้า", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 32, "str": 4}},
	"na_mai_khamot": {"name": "หน้าไม้ไฟโขมด", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 30, "dex": 4}},
	"khamphi_khamot": {"name": "คัมภีร์ไฟโขมด", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 33, "int": 4}},
	# ---- ชุด ----
	"suea_yant": {"name": "เสื้อยันต์", "type": "equip", "slot": "armor", "line": "any", "rarity": "common", "buy": 250, "bonus": {"def": 5}},
	"suea_kraphan": {"name": "เสื้อคงกระพัน", "type": "equip", "slot": "armor", "line": "any", "rarity": "rare", "buy": 1400, "bonus": {"def": 10, "vit": 2}},
	"jiwon_saksit": {"name": "จีวรศักดิ์สิทธิ์", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 18, "vit": 4, "int": 2}},
	"pha_yant_pret": {"name": "ผ้ายันต์พญาเปรต", "type": "equip", "slot": "armor", "line": "any", "rarity": "legendary", "bonus": {"def": 32, "vit": 7, "int": 3}},
	# ---- หมวก ----
	"pha_khat_hua": {"name": "ผ้าคาดหัวลงยันต์", "type": "equip", "slot": "head", "line": "any", "rarity": "common", "buy": 200, "bonus": {"def": 2, "str": 1}},
	"mongkhon": {"name": "มงคลสวมหัว", "type": "equip", "slot": "head", "line": "any", "rarity": "rare", "buy": 1200, "bonus": {"def": 4, "int": 3}},
	"mongkut_queen": {"name": "มงกุฎนางพญา", "type": "equip", "slot": "head", "line": "any", "rarity": "epic", "bonus": {"def": 7, "luk": 4, "agi": 3}},
	# ---- เครื่องราง ----
	"saisin": {"name": "สายสิญจน์ข้อมือ", "type": "equip", "slot": "accessory", "line": "any", "rarity": "common", "buy": 200, "bonus": {"vit": 2}},
	"takrut": {"name": "ตะกรุดโทน", "type": "equip", "slot": "accessory", "line": "any", "rarity": "rare", "buy": 1300, "bonus": {"luk": 4, "def": 2}},
	"phra_khrueang": {"name": "พระเครื่องหลวงปู่", "type": "equip", "slot": "accessory", "line": "any", "rarity": "rare", "buy": 1300, "bonus": {"vit": 3, "def": 3}},
	"khiao_queen": {"name": "เขี้ยวนางพญากระสือ", "type": "equip", "slot": "accessory", "line": "any", "rarity": "epic", "bonus": {"str": 3, "agi": 3, "vit": 3, "int": 3, "dex": 3, "luk": 3}},
	"prakham_pret": {"name": "ประคำพญาเปรต", "type": "equip", "slot": "accessory", "line": "any", "rarity": "legendary", "bonus": {"str": 5, "agi": 5, "vit": 5, "int": 5, "dex": 5, "luk": 5}},
	# ======== ร้านอาวุธ ขั้น 2 (แคมป์กรุงเก่า) และขั้น 3 (แคมป์บึงนาคา) ========
	"dab_lek": {"name": "ดาบเหล็กน้ำพี้", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "rare", "buy": 6000, "bonus": {"atk": 30, "str": 3}},
	"thanu_khao": {"name": "ธนูเขาควาย", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "rare", "buy": 6000, "bonus": {"atk": 28, "dex": 3}},
	"khamphi_thong": {"name": "คัมภีร์ปกทอง", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "rare", "buy": 6000, "bonus": {"matk": 31, "int": 3}},
	"suea_so": {"name": "เสื้อเกราะโซ่", "type": "equip", "slot": "armor", "line": "any", "rarity": "rare", "buy": 5000, "bonus": {"def": 17, "vit": 3}},
	"dab_ngoen": {"name": "ดาบเงินยวง", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "rare", "buy": 24000, "bonus": {"atk": 62, "str": 5}},
	"thanu_ngoen": {"name": "ธนูเงินยวง", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "rare", "buy": 24000, "bonus": {"atk": 58, "dex": 5}},
	"khamphi_ngoen": {"name": "คัมภีร์เงินยวง", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "rare", "buy": 24000, "bonus": {"matk": 64, "int": 5}},
	"kraphan_ngoen": {"name": "เกราะเงินยวง", "type": "equip", "slot": "armor", "line": "any", "rarity": "rare", "buy": 20000, "bonus": {"def": 34, "vit": 5}},
	"muak_ngoen": {"name": "หมวกเงินยวง", "type": "equip", "slot": "head", "line": "any", "rarity": "rare", "buy": 12000, "bonus": {"def": 11, "vit": 2, "int": 2}},
	# ======== แผนที่ 3: กรุงเก่าร้าง ========
	"dab_krung": {"name": "ดาบกรุเก่า", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 52, "str": 6}},
	"thanu_krung": {"name": "ธนูทหารกรุง", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 48, "dex": 6}},
	"khoi_boran": {"name": "สมุดข่อยโบราณ", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 54, "int": 6}},
	"kraphan_krung": {"name": "เกราะนักรบกรุงเก่า", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 28, "vit": 6}},
	"muak_boran": {"name": "หมวกทหารโบราณ", "type": "equip", "slot": "head", "line": "any", "rarity": "rare", "bonus": {"def": 9, "str": 2, "vit": 2}},
	"waen_pirot": {"name": "แหวนพิรอดกรุ", "type": "equip", "slot": "accessory", "line": "any", "rarity": "rare", "bonus": {"luk": 5, "dex": 3}},
	"chada_khun": {"name": "ชฎาขุนศึก", "type": "equip", "slot": "head", "line": "any", "rarity": "legendary", "bonus": {"def": 18, "str": 5, "int": 5, "agi": 4}},
	"prajiat_khun": {"name": "ประเจียดขุนศึก", "type": "equip", "slot": "accessory", "line": "any", "rarity": "legendary", "bonus": {"str": 8, "agi": 8, "vit": 8, "int": 8, "dex": 8, "luk": 8}},
	# ======== แผนที่ 4: ดอยผีปันน้ำ ========
	"dab_chao_pa": {"name": "ดาบเจ้าป่า", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 78, "str": 8}},
	"thanu_doi": {"name": "ธนูไม้ดอย", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 74, "dex": 8}},
	"khamphi_nang_mai": {"name": "คัมภีร์นางไม้", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 80, "int": 8}},
	"chut_phran": {"name": "ชุดพรานดอย", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 40, "vit": 8, "agi": 3}},
	"khiao_saming": {"name": "เขี้ยวเสือสมิง", "type": "equip", "slot": "accessory", "line": "any", "rarity": "epic", "bonus": {"str": 6, "agi": 6, "dex": 6}},
	"dab_phrai": {"name": "ดาบพญาพราย", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "legendary", "bonus": {"atk": 120, "str": 12, "agi": 5}},
	"thanu_phrai": {"name": "ธนูพญาพราย", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "legendary", "bonus": {"atk": 114, "dex": 12, "agi": 5}},
	"khamphi_phrai": {"name": "คัมภีร์พญาพราย", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "legendary", "bonus": {"matk": 124, "int": 12, "dex": 5}},
	# ======== แผนที่ 5: บึงนาคาบาดาล ========
	"dab_naga": {"name": "ดาบเกล็ดนาค", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 105, "str": 10}},
	"thanu_naga": {"name": "ธนูนาคา", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 100, "dex": 10}},
	"khamphi_badan": {"name": "คัมภีร์บาดาล", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 108, "int": 10}},
	"kraphan_naga": {"name": "เกราะเกล็ดนาค", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 56, "vit": 10}},
	"mongkut_naki": {"name": "มงกุฎนาคี", "type": "equip", "slot": "head", "line": "any", "rarity": "epic", "bonus": {"def": 16, "int": 6, "luk": 6}},
	"kaeo_naga": {"name": "แก้วพญานาค", "type": "equip", "slot": "accessory", "line": "any", "rarity": "legendary", "bonus": {"str": 12, "agi": 12, "vit": 12, "int": 12, "dex": 12, "luk": 12}},
	"kraphan_thamin": {"name": "เกราะพญานาคทมิฬ", "type": "equip", "slot": "armor", "line": "any", "rarity": "legendary", "bonus": {"def": 85, "vit": 14, "str": 5}},
	# ======== แผนที่ 6: ยมโลก ========
	"dab_yom": {"name": "ดาบยมทูต", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 140, "str": 13}},
	"thanu_awe": {"name": "ธนูอเวจี", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 134, "dex": 13}},
	"khamphi_marana": {"name": "คัมภีร์มรณะ", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 145, "int": 13}},
	"chut_yom": {"name": "ชุดยมทูต", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 70, "vit": 12}},
	"dab_matchu": {"name": "ดาบมัจจุราช", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "legendary", "bonus": {"atk": 200, "str": 18, "agi": 8}},
	"thanu_matchu": {"name": "ธนูมัจจุราช", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "legendary", "bonus": {"atk": 190, "dex": 18, "agi": 8}},
	"khamphi_matchu": {"name": "คัมภีร์มัจจุราช", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "legendary", "bonus": {"matk": 210, "int": 18, "dex": 8}},
	"mongkut_matchu": {"name": "มงกุฎมัจจุราช", "type": "equip", "slot": "head", "line": "any", "rarity": "legendary", "bonus": {"def": 30, "str": 6, "vit": 6, "int": 6}},
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
	if item["type"] == "equip":
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
	return " · ".join(parts) + " (+10% ของสูงสุด)"


## คำอธิบายค่าที่เพิ่ม เช่น "ATK +18 · STR +2"
static func bonus_text(item_id: String) -> String:
	var parts: Array[String] = []
	var bonus := bonus_of(item_id)
	for key in bonus:
		parts.append("%s +%d" % [STAT_NAMES[key], bonus[key]])
	return " · ".join(parts)
