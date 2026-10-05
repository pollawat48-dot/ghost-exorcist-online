extends RefCounted
## ข้อมูลไอเทม ใช้ร่วมกันทั้ง client และ zone server
## type: etc = วัตถุดิบ, consumable = ใช้ได้, soul = ดวงวิญญาณสำหรับผนึก (ระบบผนึกมาใน M5)

const ITEMS := {
	"herb_potion": {"name": "ยาหอมสมุนไพร", "type": "consumable", "heal": 45, "color": Color(0.4, 0.85, 0.4)},
	"spirit_shard": {"name": "เศษวิญญาณ", "type": "etc", "color": Color(0.7, 0.85, 1.0)},
	"red_thread": {"name": "ด้ายแดง", "type": "etc", "color": Color(0.9, 0.15, 0.2)},
	"lantern_oil": {"name": "น้ำมันตะเกียง", "type": "etc", "color": Color(0.95, 0.75, 0.3)},
	"soul_krasue": {"name": "ดวงวิญญาณผีกระสือ", "type": "soul", "color": Color(1.0, 0.4, 1.0)},
	"soul_takiang": {"name": "ดวงวิญญาณผีตะเกียง", "type": "soul", "color": Color(1.0, 0.4, 1.0)},
}
