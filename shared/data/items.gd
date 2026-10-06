extends RefCounted
## ข้อมูลไอเทม ใช้ร่วมกันทั้ง client และ zone server
## type: etc = วัตถุดิบ, consumable = ใช้ได้, soul = ดวงวิญญาณสำหรับผนึก (ระบบผนึกมาใน M5), equip = ของสวมใส่
## ของสวมใส่: slot (weapon/armor/head/accessory), line = สายที่ใช้ได้ (any = ทุกสาย), bonus = ค่าที่เพิ่ม, rarity

const SLOTS := ["weapon", "armor", "head", "accessory"]
const SLOT_NAMES := {"weapon": "อาวุธ", "armor": "ชุด", "head": "หมวก", "accessory": "เครื่องราง"}
const RARITY := {
	"common": {"name": "ธรรมดา", "color": Color(0.62, 0.58, 0.6)},
	"rare": {"name": "หายาก", "color": Color(0.35, 0.6, 0.95)},
	"epic": {"name": "ล้ำค่า", "color": Color(0.7, 0.4, 0.92)},
	"legendary": {"name": "ตำนาน", "color": Color(0.96, 0.66, 0.15)},
}
const STAT_NAMES := {"atk": "ATK", "matk": "MATK", "def": "DEF", "str": "STR", "agi": "AGI", "vit": "VIT", "int": "INT", "dex": "DEX", "luk": "LUK"}

const ITEMS := {
	"herb_potion": {"name": "ยาหอมสมุนไพร", "type": "consumable", "heal": 45, "color": Color(0.4, 0.85, 0.4)},
	"spirit_shard": {"name": "เศษวิญญาณ", "type": "etc", "color": Color(0.7, 0.85, 1.0)},
	"red_thread": {"name": "ด้ายแดง", "type": "etc", "color": Color(0.9, 0.15, 0.2)},
	"lantern_oil": {"name": "น้ำมันตะเกียง", "type": "etc", "color": Color(0.95, 0.75, 0.3)},
	"soul_krasue": {"name": "ดวงวิญญาณผีกระสือ", "type": "soul", "color": Color(1.0, 0.4, 1.0)},
	"soul_takiang": {"name": "ดวงวิญญาณผีตะเกียง", "type": "soul", "color": Color(1.0, 0.4, 1.0)},
	"soul_queen": {"name": "ดวงวิญญาณนางพญากระสือ", "type": "soul", "color": Color(1.0, 0.3, 0.6)},

	# ---- อาวุธ ----
	"maipai_staff": {"name": "ไม้เท้าไผ่สีสุก", "type": "equip", "slot": "weapon", "line": "any", "rarity": "common", "bonus": {"atk": 6, "matk": 6}},
	"mitmo": {"name": "มีดหมอลงอาคม", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "rare", "bonus": {"atk": 18, "str": 2}},
	"khan_thanu": {"name": "ธนูไม้มะขาม", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "rare", "bonus": {"atk": 16, "dex": 2}},
	"khamphi_yant": {"name": "คัมภีร์ยันต์ใบลาน", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "rare", "bonus": {"matk": 18, "int": 2}},
	"dab_fafuen": {"name": "ดาบฟ้าฟื้น", "type": "equip", "slot": "weapon", "line": "melee", "rarity": "legendary", "bonus": {"atk": 48, "str": 6, "agi": 3}},
	"thanu_ratri": {"name": "ธนูรัตติกาล", "type": "equip", "slot": "weapon", "line": "ranged", "rarity": "legendary", "bonus": {"atk": 44, "dex": 6, "agi": 3}},
	"khamphi_queen": {"name": "คัมภีร์นางพญา", "type": "equip", "slot": "weapon", "line": "magic", "rarity": "legendary", "bonus": {"matk": 50, "int": 6, "dex": 3}},
	# ---- ชุด ----
	"suea_yant": {"name": "เสื้อยันต์", "type": "equip", "slot": "armor", "line": "any", "rarity": "common", "bonus": {"def": 5}},
	"suea_kraphan": {"name": "เสื้อคงกระพัน", "type": "equip", "slot": "armor", "line": "any", "rarity": "rare", "bonus": {"def": 10, "vit": 2}},
	"jiwon_saksit": {"name": "จีวรศักดิ์สิทธิ์", "type": "equip", "slot": "armor", "line": "any", "rarity": "epic", "bonus": {"def": 18, "vit": 4, "int": 2}},
	# ---- หมวก ----
	"pha_khat_hua": {"name": "ผ้าคาดหัวลงยันต์", "type": "equip", "slot": "head", "line": "any", "rarity": "common", "bonus": {"def": 2, "str": 1}},
	"mongkhon": {"name": "มงคลสวมหัว", "type": "equip", "slot": "head", "line": "any", "rarity": "rare", "bonus": {"def": 4, "int": 3}},
	"mongkut_queen": {"name": "มงกุฎนางพญา", "type": "equip", "slot": "head", "line": "any", "rarity": "epic", "bonus": {"def": 7, "luk": 4, "agi": 3}},
	# ---- เครื่องราง ----
	"saisin": {"name": "สายสิญจน์ข้อมือ", "type": "equip", "slot": "accessory", "line": "any", "rarity": "common", "bonus": {"vit": 2}},
	"takrut": {"name": "ตะกรุดโทน", "type": "equip", "slot": "accessory", "line": "any", "rarity": "rare", "bonus": {"luk": 4, "def": 2}},
	"phra_khrueang": {"name": "พระเครื่องหลวงปู่", "type": "equip", "slot": "accessory", "line": "any", "rarity": "rare", "bonus": {"vit": 3, "def": 3}},
	"khiao_queen": {"name": "เขี้ยวนางพญากระสือ", "type": "equip", "slot": "accessory", "line": "any", "rarity": "epic", "bonus": {"str": 3, "agi": 3, "vit": 3, "int": 3, "dex": 3, "luk": 3}},
}


static func color_of(item_id: String) -> Color:
	var item: Dictionary = ITEMS[item_id]
	if item["type"] == "equip":
		return RARITY[item["rarity"]]["color"]
	return item["color"]


## คำอธิบายค่าที่เพิ่ม เช่น "ATK +18 · STR +2"
static func bonus_text(item_id: String) -> String:
	var parts: Array[String] = []
	var bonus: Dictionary = ITEMS[item_id].get("bonus", {})
	for key in bonus:
		parts.append("%s +%d" % [STAT_NAMES[key], bonus[key]])
	return " · ".join(parts)
