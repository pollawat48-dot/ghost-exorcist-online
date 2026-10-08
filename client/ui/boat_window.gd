extends "res://client/ui/quest_window.gd"
## นายท้ายเรือสำเภา: ให้เควสขึ้นเรือ และพาข้ามประเทศ (ไทย ↔ จีน)
## ขึ้นเรือได้ต้องทำเควสขึ้นเรือครบ (Quests.has_boat_pass) และเลเวลถึง World.BOAT_LEVEL

const World = preload("res://shared/data/world.gd")

signal sail_requested(map_id: String)

var from_country := "th"


func _ready() -> void:
	setup("นายท้ายเรือสำเภา", 600)


func _greeting() -> String:
	if from_country == "cn":
		return "\"กลับสยามหรือ? ลมว่าวกำลังดี ขึ้นเรือได้เลย\""
	return "\"ข้ามทะเลไปแผ่นดินจีนไม่ใช่เรื่องเล่น ช่วยข้าเตรียมเรือก่อนสิ\""


func _build() -> void:
	_build_sail()
	section("เควสเตรียมเรือ")
	super._build()


func _build_sail() -> void:
	var to := "cn" if from_country == "th" else "th"
	var dest: String = World.PORTS[to]
	section("เรือสำเภาข้ามทะเล")
	var pass_ok: bool = Quests.has_boat_pass(player.state)
	var lv_ok: bool = player.state["level"] >= World.BOAT_LEVEL
	for l in [[lv_ok, "เลเวล %d ขึ้นไป (ตอนนี้ Lv.%d)" % [World.BOAT_LEVEL, player.state["level"]]],
			[pass_ok, "ทำเควสเตรียมเรือครบทั้ง 3 ขั้น"]]:
		content.add_child(P.label(("[ผ่าน] " if l[0] else "[ยังไม่ผ่าน] ") + l[1], 13, Color(0.3, 0.55, 0.4) if l[0] else P.TEXT))
	var b := P.button("ขึ้นเรือไป%s · %s" % [World.COUNTRY_NAMES[to], World.MAPS[dest]["name"]], P.SKY, 16)
	b.disabled = not (pass_ok and lv_ok)
	b.pressed.connect(func(): sail_requested.emit(dest))
	content.add_child(b)
