extends RefCounted
## ข้อมูลไอเทม ใช้ร่วมกันทั้ง client และ zone server
## type: etc = วัตถุดิบ, consumable = ใช้ได้, soul = ดวงวิญญาณสำหรับผนึก (ระบบผนึกมาใน M5), equip = ของสวมใส่
## ของสวมใส่: slot (weapon/armor/head/accessory), line = สายที่ใช้ได้ (any = ทุกสาย), bonus = ค่าที่เพิ่ม, rarity
## ยา: heal = เพิ่ม HP, sp = เพิ่ม SP (บวกอีก 10% ของค่าสูงสุด), buy = ราคาซื้อจากร้าน
## price = ราคาที่ร้านรับซื้อ (ของสวมใส่คิดตามความหายาก ยาขายคืนได้ 1/4 ของราคาซื้อ)

const SLOTS := ["weapon", "armor", "head", "accessory"]
const SLOT_NAMES := {"weapon": "อาวุธ", "armor": "ชุด", "head": "หมวก", "accessory": "เครื่องราง"}
const RARITY := {
	"common": {"name": "ธรรมดา", "color": Color(0.62, 0.58, 0.6), "price": 120},
	"rare": {"name": "หายาก", "color": Color(0.35, 0.6, 0.95), "price": 500},
	"epic": {"name": "ล้ำค่า", "color": Color(0.7, 0.4, 0.92), "price": 1800},
	"legendary": {"name": "ตำนาน", "color": Color(0.96, 0.66, 0.15), "price": 6000},
}
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

	# ---- อาวุธ ----
	"maipai_staff": {"name": "ไม้เท้าไผ่สีสุก", "type": "equip", "slot": "weapon", "line": "any", "rarity": "common", "bonus": {"atk": 6, "matk": 6}},
	"mitmo": {"name": "มีดหมอลงอาคม", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "rare", "bonus": {"atk": 18, "str": 2}},
	"khan_thanu": {"name": "ธนูไม้มะขาม", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "rare", "bonus": {"atk": 16, "dex": 2}},
	"khamphi_yant": {"name": "คัมภีร์ยันต์ใบลาน", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "rare", "bonus": {"matk": 18, "int": 2}},
	"dab_fafuen": {"name": "ดาบฟ้าฟื้น", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "legendary", "bonus": {"atk": 48, "str": 6, "agi": 3}},
	"thanu_ratri": {"name": "ธนูรัตติกาล", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "legendary", "bonus": {"atk": 44, "dex": 6, "agi": 3}},
	"khamphi_queen": {"name": "คัมภีร์นางพญา", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "legendary", "bonus": {"matk": 50, "int": 6, "dex": 3}},
	"dab_pa_cha": {"name": "ดาบหมอผีป่าช้า", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "epic", "bonus": {"atk": 32, "str": 4}},
	"na_mai_khamot": {"name": "หน้าไม้ไฟโขมด", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "epic", "bonus": {"atk": 30, "dex": 4}},
	"khamphi_khamot": {"name": "คัมภีร์ไฟโขมด", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "epic", "bonus": {"matk": 33, "int": 4}},
	# ---- ชุด ----
	"suea_yant": {"name": "เสื้อยันต์", "type": "equip", "slot": "armor", "line": "any", "rarity": "common", "bonus": {"def": 5}},
	"suea_kraphan": {"name": "เสื้อคงกระพัน", "type": "equip", "slot": "armor", "line": "any", "rarity": "rare", "bonus": {"def": 10, "vit": 2}},
	"jiwon_saksit": {"name": "จีวรศักดิ์สิทธิ์", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 18, "vit": 4, "int": 2}},
	"pha_yant_pret": {"name": "ผ้ายันต์พญาเปรต", "type": "equip", "slot": "armor", "line": "any", "rarity": "legendary", "bonus": {"def": 32, "vit": 7, "int": 3}},
	# ---- หมวก ----
	"pha_khat_hua": {"name": "ผ้าคาดหัวลงยันต์", "type": "equip", "slot": "head", "line": "any", "rarity": "common", "bonus": {"def": 2, "str": 1}},
	"mongkhon": {"name": "มงคลสวมหัว", "type": "equip", "slot": "head", "line": "any", "rarity": "rare", "bonus": {"def": 4, "int": 3}},
	"mongkut_queen": {"name": "มงกุฎนางพญา", "type": "equip", "slot": "head", "line": "any", "rarity": "epic", "bonus": {"def": 7, "luk": 4, "agi": 3}},
	# ---- เครื่องราง ----
	"saisin": {"name": "สายสิญจน์ข้อมือ", "type": "equip", "slot": "accessory", "line": "any", "rarity": "common", "bonus": {"vit": 2}},
	"takrut": {"name": "ตะกรุดโทน", "type": "equip", "slot": "accessory", "line": "any", "rarity": "rare", "bonus": {"luk": 4, "def": 2}},
	"phra_khrueang": {"name": "พระเครื่องหลวงปู่", "type": "equip", "slot": "accessory", "line": "any", "rarity": "rare", "bonus": {"vit": 3, "def": 3}},
	"khiao_queen": {"name": "เขี้ยวนางพญากระสือ", "type": "equip", "slot": "accessory", "line": "any", "rarity": "epic", "bonus": {"str": 3, "agi": 3, "vit": 3, "int": 3, "dex": 3, "luk": 3}},
	"prakham_pret": {"name": "ประคำพญาเปรต", "type": "equip", "slot": "accessory", "line": "any", "rarity": "legendary", "bonus": {"str": 5, "agi": 5, "vit": 5, "int": 5, "dex": 5, "luk": 5}},
}


static func color_of(item_id: String) -> Color:
	var item: Dictionary = ITEMS[item_id]
	if item["type"] == "equip":
		return RARITY[item["rarity"]]["color"]
	return item["color"]


## ราคาที่ร้านรับซื้อต่อชิ้น (0 = ขายไม่ได้)
static func sell_price(item_id: String) -> int:
	var item: Dictionary = ITEMS[item_id]
	match item["type"]:
		"equip":
			return RARITY[item["rarity"]]["price"]
		"consumable":
			return item.get("buy", 0) / 4
	return item.get("price", 0)


## คำอธิบายผลของยา เช่น "HP +180" หรือ "SP +30"
static func use_text(item_id: String) -> String:
	var item: Dictionary = ITEMS[item_id]
	var parts: Array[String] = []
	if item.has("heal"):
		parts.append("HP +%d" % item["heal"])
	if item.has("sp"):
		parts.append("SP +%d" % item["sp"])
	return " · ".join(parts) + " (+10% ของสูงสุด)"


## คำอธิบายค่าที่เพิ่ม เช่น "ATK +18 · STR +2"
static func bonus_text(item_id: String) -> String:
	var parts: Array[String] = []
	var bonus: Dictionary = ITEMS[item_id].get("bonus", {})
	for key in bonus:
		parts.append("%s +%d" % [STAT_NAMES[key], bonus[key]])
	return " · ".join(parts)
