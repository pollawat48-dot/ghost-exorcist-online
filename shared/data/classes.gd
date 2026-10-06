extends RefCounted
## คลาส (สำนัก) ทั้งหมด: เริ่มเป็นศิษย์วัด แล้วเปลี่ยนคลาสได้ 3 ครั้ง ที่เลเวล 10, 50 และ 100
## แต่ละสายโจมตีต่างกัน: melee = ประชิด (STR), ranged = ระยะไกล (DEX), magic = เวท (INT)
## look = หน้าตาตัวละคร (สีจีวร อาวุธ หมวก ผ้าคลุม ออร่า)

const CLASS_CHANGE_LEVELS := [10, 50, 100]
## เงื่อนไขเปลี่ยนอาชีพที่ NPC ครูใหญ่สำนัก (ต่อขั้น): ผ่านเควสบททดสอบ + จ่ายค่าครู
## ขั้น 1 ปราบผีตะเกียง (เลเวล 10 ยังสู้บอสไม่ไหว), ขั้น 2 ปราบนางพญากระสือ, ขั้น 3 ปราบพญาเปรต
const CLASS_TRIALS := [
	{"quest": "q_trial_1", "fee": 300},
	{"quest": "q_trial_2", "fee": 5000},
	{"quest": "q_trial_3", "fee": 30000},
]
const MASTER_NPC := "khru_yai"

const CLASSES := {
	"novice": {
		"name": "ศิษย์วัด", "tier": 0, "line": "novice", "parent": "",
		"attack": "melee", "range": 42.0, "hp_mult": 1.0, "sp_mult": 1.0, "aspd": 1.0,
		"desc": "ผู้เริ่มต้นฝึกวิชาปราบผีที่วัด",
		"look": {"robe": Color(1.0, 0.72, 0.4), "sash": Color(0.96, 0.52, 0.42), "weapon": "staff", "hat": "", "cape": false, "aura": false},
	},
	# ---- สายประชิด ----
	"nak_rob": {
		"name": "นักรบเวทย์", "tier": 1, "line": "melee", "parent": "novice",
		"attack": "melee", "range": 44.0, "hp_mult": 1.3, "sp_mult": 0.9, "aspd": 1.0,
		"desc": "ถือดาบลงอาคม ตีประชิดแรง ทนทาน",
		"look": {"robe": Color(0.6, 0.7, 0.95), "sash": Color(0.95, 0.45, 0.45), "weapon": "sword", "hat": "headband", "cape": false, "aura": false},
	},
	"nak_dab": {
		"name": "นักดาบคาถา", "tier": 2, "line": "melee", "parent": "nak_rob",
		"attack": "melee", "range": 46.0, "hp_mult": 1.5, "sp_mult": 0.95, "aspd": 0.95,
		"desc": "ดาบคาถาฟันหมู่ผีได้ทีละหลายตัว",
		"look": {"robe": Color(0.45, 0.55, 0.9), "sash": Color(1.0, 0.8, 0.4), "weapon": "sword", "hat": "headband", "cape": true, "aura": false},
	},
	"khun_phaen": {
		"name": "ขุนแผนดาบฟ้าฟื้น", "tier": 3, "line": "melee", "parent": "nak_dab",
		"attack": "melee", "range": 48.0, "hp_mult": 1.75, "sp_mult": 1.0, "aspd": 0.9,
		"desc": "ยอดนักรบในตำนาน ถือดาบฟ้าฟื้น",
		"look": {"robe": Color(0.38, 0.42, 0.78), "sash": Color(1.0, 0.82, 0.38), "weapon": "great_sword", "hat": "crown", "cape": true, "aura": true},
	},
	# ---- สายระยะไกล ----
	"phran": {
		"name": "นักล่าพเนจร", "tier": 1, "line": "ranged", "parent": "novice",
		"attack": "ranged", "range": 230.0, "hp_mult": 1.0, "sp_mult": 1.0, "aspd": 0.9,
		"desc": "ยิงธนูจากระยะไกล คล่องแคล่ว",
		"look": {"robe": Color(0.6, 0.85, 0.6), "sash": Color(0.85, 0.6, 0.4), "weapon": "bow", "hat": "hat_wide", "cape": false, "aura": false},
	},
	"phran_ratri": {
		"name": "พรานราตรี", "tier": 2, "line": "ranged", "parent": "phran",
		"attack": "ranged", "range": 250.0, "hp_mult": 1.1, "sp_mult": 1.05, "aspd": 0.85,
		"desc": "ล่าผียามค่ำคืน ยิงธนูเป็นห่าฝน",
		"look": {"robe": Color(0.45, 0.68, 0.55), "sash": Color(0.6, 0.45, 0.75), "weapon": "bow", "hat": "hat_wide", "cape": true, "aura": false},
	},
	"mue_prab": {
		"name": "มือปราบเงา", "tier": 3, "line": "ranged", "parent": "phran_ratri",
		"attack": "ranged", "range": 270.0, "hp_mult": 1.25, "sp_mult": 1.1, "aspd": 0.8,
		"desc": "นักล่าในเงามืด ลูกธนูเดียวปลิดวิญญาณ",
		"look": {"robe": Color(0.42, 0.4, 0.6), "sash": Color(0.75, 0.95, 0.75), "weapon": "great_bow", "hat": "hood", "cape": true, "aura": true},
	},
	# ---- สายเวท ----
	"mo_phi": {
		"name": "หมอผีไสยเวท", "tier": 1, "line": "magic", "parent": "novice",
		"attack": "magic", "range": 190.0, "hp_mult": 0.85, "sp_mult": 1.5, "aspd": 1.15,
		"desc": "ใช้ยันต์และคาถาโจมตีจากระยะไกล",
		"look": {"robe": Color(0.82, 0.62, 0.95), "sash": Color(0.98, 0.85, 0.45), "weapon": "book", "hat": "topknot", "cape": false, "aura": false},
	},
	"ajarn_yant": {
		"name": "อาจารย์สักยันต์", "tier": 2, "line": "magic", "parent": "mo_phi",
		"attack": "magic", "range": 210.0, "hp_mult": 0.9, "sp_mult": 1.7, "aspd": 1.1,
		"desc": "ปรมาจารย์ยันต์ ทั้งโจมตีและรักษา",
		"look": {"robe": Color(0.7, 0.48, 0.88), "sash": Color(1.0, 0.7, 0.75), "weapon": "book", "hat": "topknot", "cape": true, "aura": false},
	},
	"jom_khamang": {
		"name": "จอมขมังเวทย์", "tier": 3, "line": "magic", "parent": "ajarn_yant",
		"attack": "magic", "range": 230.0, "hp_mult": 1.0, "sp_mult": 2.0, "aspd": 1.05,
		"desc": "ผู้ปลุกเพลิงเวทย์ เผาผีทั้งป่าช้าในพริบตา",
		"look": {"robe": Color(0.58, 0.36, 0.78), "sash": Color(1.0, 0.82, 0.38), "weapon": "orb_staff", "hat": "crown", "cape": true, "aura": true},
	},
}


## คลาสถัดไปที่เลือกได้ (ศิษย์วัดเลือกได้ 3 สาย ขั้นต่อไปมีทางเดียว)
static func next_classes(class_id: String) -> Array[String]:
	var result: Array[String] = []
	for id in CLASSES:
		if CLASSES[id]["parent"] == class_id:
			result.append(id)
	return result


## เลเวลที่ต้องถึงก่อนเปลี่ยนจากคลาสนี้ไปขั้นถัดไป (-1 = ขั้นสุดท้ายแล้ว)
static func change_level(class_id: String) -> int:
	var tier: int = CLASSES[class_id]["tier"]
	return CLASS_CHANGE_LEVELS[tier] if tier < CLASS_CHANGE_LEVELS.size() else -1


## เงื่อนไขเลื่อนขั้นถัดไปของคลาสนี้ ({} = ขั้นสุดท้ายแล้ว)
static func trial_for(class_id: String) -> Dictionary:
	var tier: int = CLASSES[class_id]["tier"]
	return CLASS_TRIALS[tier] if tier < CLASS_TRIALS.size() else {}


## สายคลาสตั้งแต่ศิษย์วัดจนถึงคลาสนี้ (ใช้ดูว่าเรียนสกิลอะไรได้บ้าง)
static func lineage(class_id: String) -> Array[String]:
	var chain: Array[String] = []
	var id := class_id
	while id != "":
		chain.push_front(id)
		id = CLASSES[id]["parent"]
	return chain
