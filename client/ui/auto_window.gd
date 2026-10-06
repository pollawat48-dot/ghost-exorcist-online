extends "res://client/ui/game_window.gd"
## ตั้งค่าออโต้: เปิด/ปิด, ใช้สกิล, เก็บของ, สู้บอส, เกณฑ์ใช้ยาเลือด/ยามานา

signal toggle_requested

var auto_play: RefCounted


func _ready() -> void:
	setup("ระบบช่วยเล่น (ออโต้)", 460)


func _build() -> void:
	if auto_play == null:
		return
	var s: Dictionary = auto_play.settings
	var r := row()
	var state := P.label("สถานะ: %s" % ("กำลังทำงาน" if auto_play.enabled else "ปิดอยู่"), 17, P.PINK_DEEP if auto_play.enabled else P.TEXT)
	state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(state)
	var toggle := P.button("ปิดออโต้" if auto_play.enabled else "เปิดออโต้", P.PINK if auto_play.enabled else P.MINT, 16)
	toggle.pressed.connect(func(): toggle_requested.emit())
	r.add_child(toggle)
	content.add_child(P.label("ออโต้จะหาผีใกล้ๆ ตี ใช้สกิล เก็บของ และกินยาให้เอง แตะจอหรือขยับจอยเพื่อบังคับเองชั่วคราว", 12, P.TEXT.lightened(0.2)))
	section("การต่อสู้")
	_switch("ใช้สกิลอัตโนมัติ", "use_skills")
	_switch("เดินเก็บของที่ตก", "loot")
	_switch("สู้กับบอสด้วย", "boss")
	section("ยา")
	_switch("ใช้ยาเพิ่มเลือดอัตโนมัติ", "use_hp")
	_threshold("กินยาเลือดเมื่อ HP ต่ำกว่า", "hp_pct")
	_switch("ใช้น้ำมนต์เพิ่ม SP อัตโนมัติ", "use_sp")
	_threshold("กินน้ำมนต์เมื่อ SP ต่ำกว่า", "sp_pct")
	content.add_child(P.label("ยาเลือดที่มี %d ขวด · น้ำมนต์ที่มี %d ขวด (ซื้อเพิ่มได้ที่ร้านยา)" % [player.potion_count("hp"), player.potion_count("sp")], 12, P.TEXT.lightened(0.2)))


func _switch(text: String, key: String) -> void:
	var r := row()
	var l := P.label(text, 15)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(l)
	var on: bool = auto_play.settings[key]
	var b := P.button("เปิด" if on else "ปิด", P.MINT if on else Color(0.9, 0.88, 0.9), 14)
	b.custom_minimum_size.x = 64
	b.pressed.connect(func():
		auto_play.settings[key] = not auto_play.settings[key]
		refresh())
	r.add_child(b)


func _threshold(text: String, key: String) -> void:
	var r := row()
	var l := P.label(text, 14, P.TEXT.lightened(0.1))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(l)
	for step in [-10, 10]:
		var b := P.button("-" if step < 0 else "+", P.SKY, 14)
		b.custom_minimum_size.x = 36
		b.pressed.connect(func():
			auto_play.settings[key] = clampi(auto_play.settings[key] + step, 10, 90)
			refresh())
		r.add_child(b)
		if step < 0:
			r.add_child(P.label("%d%%" % auto_play.settings[key], 16, P.PINK_DEEP))
