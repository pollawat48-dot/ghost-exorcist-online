extends RefCounted
## ข้อมูลแผนที่ทั้งโลก: ชื่อ ช่วงเลเวล ค่าวาร์ป และแผนที่ที่สุ่มให้มีถ้ำ
## ใช้ร่วมกันทั้ง client และ zone server (ตัว scene ของแผนที่อยู่ใน maps/)

## เรียงตามลำดับการเดินทาง: แต่ละแผนที่มีประตูไปแผนที่ถัดไปทางตะวันออก
## country: th = ประเทศไทย (ผีไม่เกิน Lv50), cn = ประเทศจีน (Lv55–90 ข้ามมาได้ด้วยเรือสำเภาหลังทำเควสขึ้นเรือ)
## วาร์ปได้เฉพาะแผนที่ในประเทศเดียวกัน ข้ามประเทศต้องนั่งเรือ
const MAPS := {
	"khlong_village": {"name": "หมู่บ้านริมคลอง", "levels": "2–5", "boss": "krasue_queen", "fee": 50, "country": "th"},
	"pa_cha": {"name": "ป่าช้าวัดร้าง", "levels": "10–18", "boss": "pret_king", "fee": 150, "country": "th"},
	"krung_kao": {"name": "กรุงเก่าร้าง", "levels": "21–28", "boss": "khun_suek", "fee": 300, "country": "th"},
	"doi_phi": {"name": "ดอยผีปันน้ำ", "levels": "30–36", "boss": "phraya_phrai", "fee": 500, "country": "th"},
	"nong_naga": {"name": "บึงนาคาบาดาล", "levels": "37–43", "boss": "phaya_nak", "fee": 700, "country": "th"},
	"yom_lok": {"name": "ยมโลก", "levels": "45–50", "boss": "matchurat", "fee": 900, "country": "th"},
	## แผนที่ปลอดภัย (ไม่มีผี): ตกปลาแบบ AFK ได้ปลาและพระเครื่อง ทางเข้าอยู่ทางใต้ของหมู่บ้าน
	"lam_than": {"name": "ลำธารใสเย็น", "levels": "", "boss": "", "fee": 30, "safe": true, "country": "th"},
	# ---- ประเทศจีน ----
	"china_harbor": {"name": "ท่าเรือเมืองเฉวียนโจว", "levels": "55–58", "boss": "jiangshi_wang", "fee": 300, "country": "cn"},
	"china_bamboo": {"name": "ป่าไผ่หมอกมรกต", "levels": "61–67", "boss": "jiuwei_hu", "fee": 600, "country": "cn"},
	"china_tomb": {"name": "สุสานจักรพรรดิฉิน", "levels": "69–75", "boss": "qin_gui_di", "fee": 900, "country": "cn"},
	"china_wall": {"name": "ด่านกำแพงเมืองจีน", "levels": "77–83", "boss": "baigu_jing", "fee": 1200, "country": "cn"},
	"china_fengdu": {"name": "เมืองผีเฟิงตู", "levels": "85–89", "boss": "yan_wang", "fee": 1500, "country": "cn"},
}
const ORDER := ["khlong_village", "lam_than", "pa_cha", "krung_kao", "doi_phi", "nong_naga", "yom_lok",
	"china_harbor", "china_bamboo", "china_tomb", "china_wall", "china_fengdu"]
const COUNTRY_NAMES := {"th": "ประเทศไทย", "cn": "ประเทศจีน"}
## จุดลงเรือของแต่ละประเทศ (แผนที่ที่มีท่าเรือสำเภา)
const PORTS := {"th": "khlong_village", "cn": "china_harbor"}
## เลเวลต่ำสุดที่ขึ้นเรือข้ามประเทศได้ (ต้องทำเควสเตรียมเรือครบด้วย)
const BOAT_LEVEL := 50

## ถ้ำ (ดันเจี้ยน): สุ่มเลือกบางแผนที่ของแต่ละประเทศตอนเริ่มโลกใหม่ เก็บไว้ใน state["caves"]
const CAVE_CANDIDATES := ["pa_cha", "krung_kao", "doi_phi", "nong_naga", "yom_lok"]
const CHINA_CAVE_CANDIDATES := ["china_harbor", "china_bamboo", "china_tomb", "china_wall", "china_fengdu"]
const CAVE_COUNT := 3
const CAVE_PREFIX := "cave:"
## ถ้ำลึกขึ้นตามแผนที่แม่: ผีพิเศษเก่งขึ้น และแร่หายากออกบ่อยขึ้น (ถ้ำจีนดีกว่าถ้ำไทย)
const CAVE_TIER := {"pa_cha": 1, "krung_kao": 2, "doi_phi": 3, "nong_naga": 4, "yom_lok": 5,
	"china_harbor": 6, "china_bamboo": 7, "china_tomb": 8, "china_wall": 9, "china_fengdu": 10}
## หินพิเศษ (หินหยกวิญญาณ): เจอเฉพาะถ้ำจีน ขุดแล้วได้แร่ดีกว่าหินปกติ (คิดเหมือนถ้ำลึกขึ้นอีก SPECIAL_ROCK_BONUS ขั้น)
const SPECIAL_ROCK_CHANCE := 0.3
const SPECIAL_ROCK_BONUS := 4

## น้ำหนักสุ่มแร่จากการขุดหินหนึ่งครั้ง: สังกะสีออกง่ายสุด เพชรออกยากสุด
const ORE_ORDER := ["ore_zinc", "ore_iron", "ore_gold", "ore_diamond"]


static func pick_caves(rng: RandomNumberGenerator) -> Array:
	return _pick(CAVE_CANDIDATES, rng) + _pick(CHINA_CAVE_CANDIDATES, rng)


## ตัวละครเก่าที่สุ่มถ้ำไว้ก่อนมีประเทศจีน: สุ่มถ้ำจีนเพิ่มให้ (คืน true ถ้าเปลี่ยน)
static func ensure_china_caves(caves: Array, rng: RandomNumberGenerator) -> bool:
	for id in caves:
		if id in CHINA_CAVE_CANDIDATES:
			return false
	caves.append_array(_pick(CHINA_CAVE_CANDIDATES, rng))
	return true


static func _pick(candidates: Array, rng: RandomNumberGenerator) -> Array:
	var pool: Array = candidates.duplicate()
	var result := []
	for i in CAVE_COUNT:
		var idx := rng.randi() % pool.size()
		result.append(pool[idx])
		pool.remove_at(idx)
	return result


## ประเทศของแผนที่ (ถ้ำนับตามแผนที่แม่)
static func country_of(map_id: String) -> String:
	if is_cave(map_id):
		map_id = cave_parent(map_id)
	return MAPS[map_id].get("country", "th") if MAPS.has(map_id) else "th"


## เปอร์เซ็นต์โอกาสได้แร่แต่ละชนิดในถ้ำระดับ tier (รวม 100) เรียงตาม ORE_ORDER
## tier สูงสุดที่ใช้ได้ 14 (ถ้ำเฟิงตู + หินพิเศษ) สังกะสียังเหลือ 4%
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
