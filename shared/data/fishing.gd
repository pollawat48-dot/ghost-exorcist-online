extends RefCounted
## ตกปลาที่ลำธาร (AFK): ยืนริมน้ำ ถือคันเบ็ด ทุกๆ fish_time วินาทีสุ่มได้ปลา หรือพระเครื่อง
## พระเครื่องเอาไปใช้ตอนตีบวก เพิ่มโอกาสสำเร็จ ยิ่งหายากยิ่งเพิ่มมาก
## luck ของคันเบ็ด คูณน้ำหนักของที่หายาก (ปลาบึกและพระเครื่อง)

const RODS := ["bet_thong", "bet_mai"]  ## เรียงจากดีไปธรรมดา (ใช้คันที่ดีที่สุดในกระเป๋า)
const REACH := 70.0  ## ต้องยืนห่างน้ำไม่เกินนี้ถึงจะตกปลาได้
## [ไอเทม, น้ำหนัก, หายาก (คูณ luck)] น้ำหนักรวมของคันธรรมดา = 100
const CATCH := [
	["pla_siew", 44.0, false],
	["pla_nil", 30.0, false],
	["pla_chon", 16.0, false],
	["pla_buek", 3.0, true],
	["phra_din", 5.0, true],
	["phra_phong", 1.6, true],
	["phra_thong", 0.4, true],
]


static func weights(luck: float) -> Array:
	var out := []
	for c in CATCH:
		out.append(c[1] * (luck if c[2] else 1.0))
	return out


## เปอร์เซ็นต์โอกาสของแต่ละอย่าง (ไว้แสดงในหน้าต่าง/ทดสอบ)
static func chances(luck: float) -> Dictionary:
	var w := weights(luck)
	var total := 0.0
	for x in w:
		total += x
	var out := {}
	for i in CATCH.size():
		out[CATCH[i][0]] = w[i] / total
	return out


static func roll(rng: RandomNumberGenerator, luck: float) -> String:
	var w := weights(luck)
	var total := 0.0
	for x in w:
		total += x
	var r := rng.randf() * total
	for i in w.size():
		r -= w[i]
		if r < 0.0:
			return CATCH[i][0]
	return CATCH[0][0]
