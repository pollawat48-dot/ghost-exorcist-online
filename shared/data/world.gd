extends RefCounted
## ข้อมูลแผนที่ทั้งโลก: ชื่อ ช่วงเลเวล ค่าวาร์ป และแผนที่ที่สุ่มให้มีถ้ำ
## ใช้ร่วมกันทั้ง client และ zone server (ตัว scene ของแผนที่อยู่ใน maps/)

## เรียงตามลำดับการเดินทาง: แต่ละแผนที่มีประตูไปแผนที่ถัดไปทางตะวันออก
const MAPS := {
	"khlong_village": {"name": "หมู่บ้านริมคลอง", "levels": "1–10", "boss": "krasue_queen", "fee": 50},
	"pa_cha": {"name": "ป่าช้าวัดร้าง", "levels": "12–26", "boss": "pret_king", "fee": 200},
	"krung_kao": {"name": "กรุงเก่าร้าง", "levels": "32–50", "boss": "khun_suek", "fee": 600},
	"doi_phi": {"name": "ดอยผีปันน้ำ", "levels": "62–85", "boss": "phraya_phrai", "fee": 1500},
	"nong_naga": {"name": "บึงนาคาบาดาล", "levels": "96–122", "boss": "phaya_nak", "fee": 3000},
	"yom_lok": {"name": "ยมโลก", "levels": "132–148", "boss": "matchurat", "fee": 6000},
	## แผนที่ปลอดภัย (ไม่มีผี): ตกปลาแบบ AFK ได้ปลาและพระเครื่อง ทางเข้าอยู่ทางใต้ของหมู่บ้าน
	"lam_than": {"name": "ลำธารใสเย็น", "levels": "", "boss": "", "fee": 30, "safe": true},
}
const ORDER := ["khlong_village", "lam_than", "pa_cha", "krung_kao", "doi_phi", "nong_naga", "yom_lok"]

## ถ้ำ: สุ่มเลือกบางแผนที่ (ไม่รวมหมู่บ้าน) ตอนเริ่มโลกใหม่ เก็บไว้ใน state["caves"]
const CAVE_CANDIDATES := ["pa_cha", "krung_kao", "doi_phi", "nong_naga", "yom_lok"]
const CAVE_COUNT := 3
const CAVE_PREFIX := "cave:"
## ถ้ำลึกขึ้นตามแผนที่แม่: ผีพิเศษเก่งขึ้น และแร่หายากออกบ่อยขึ้น
const CAVE_TIER := {"pa_cha": 1, "krung_kao": 2, "doi_phi": 3, "nong_naga": 4, "yom_lok": 5}

## น้ำหนักสุ่มแร่จากการขุดหินหนึ่งครั้ง: สังกะสีออกง่ายสุด เพชรออกยากสุด
const ORE_ORDER := ["ore_zinc", "ore_iron", "ore_gold", "ore_diamond"]


static func pick_caves(rng: RandomNumberGenerator) -> Array:
	var pool: Array = CAVE_CANDIDATES.duplicate()
	var result := []
	for i in CAVE_COUNT:
		var idx := rng.randi() % pool.size()
		result.append(pool[idx])
		pool.remove_at(idx)
	return result


## เปอร์เซ็นต์โอกาสได้แร่แต่ละชนิดในถ้ำระดับ tier (รวม 100) เรียงตาม ORE_ORDER
static func ore_weights(tier: int) -> Array:
	return [60.0 - 4.0 * tier, 28.0 + tier, 10.0 + 2.0 * tier, 2.0 + tier]


static func roll_ore(tier: int, rng: RandomNumberGenerator) -> String:
	var w := ore_weights(tier)
	var roll := rng.randf() * 100.0
	for i in w.size():
		roll -= w[i]
		if roll < 0.0:
			return ORE_ORDER[i]
	return ORE_ORDER[0]


static func is_cave(map_id: String) -> bool:
	return map_id.begins_with(CAVE_PREFIX)


static func cave_parent(map_id: String) -> String:
	return map_id.substr(CAVE_PREFIX.length())


static func map_name(map_id: String) -> String:
	if is_cave(map_id):
		return "ถ้ำใต้" + MAPS[cave_parent(map_id)]["name"]
	return MAPS[map_id]["name"]
