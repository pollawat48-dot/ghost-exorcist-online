extends "res://client/ui/game_window.gd"
## หน้าต่างตัวละคร: อัปสเตตัสเอง, ดูค่าพลัง, ของที่สวมอยู่, ปุ่มเลื่อนขั้นคลาส

const Progression = preload("res://shared/combat/progression.gd")
const Classes = preload("res://shared/data/classes.gd")
const ItemDB = preload("res://shared/data/items.gd")

signal open_class_change

const Quests = preload("res://shared/data/quests.gd")


## รายการเงื่อนไขเปลี่ยนอาชีพ พร้อมสถานะผ่าน/ยังไม่ผ่าน (ใช้ทั้งหน้าต่างตัวละครและหน้าต่าง NPC)
static func requirement_lines(req: Dictionary) -> Array[String]:
	var mark := func(ok: bool) -> String: return "[ผ่าน] " if ok else "[ยัง] "
	return [
		mark.call(req["level_ok"]) + "เลเวล %d ขึ้นไป" % req["level"],
		mark.call(req["quest_ok"]) + "ผ่านเควส \"%s\"" % Quests.QUESTS[req["quest"]]["name"],
		mark.call(req["fee_ok"]) + "ค่าครู %d เหรียญ" % req["fee"],
	]


func _ready() -> void:
	setup("ตัวละคร", 640)


func _build() -> void:
	var st: Dictionary = player.state
	var s: Dictionary = player.stats
	var cls: Dictionary = player.class_info()
	var head := row()
	head.add_child(P.label("%s  ·  Lv %d / %d" % [cls["name"], st["level"], Progression.MAX_LEVEL], 17))
	var pts := P.label("แต้มสเตตัส: %d" % st["stat_points"], 17, P.PINK_DEEP if st["stat_points"] > 0 else P.TEXT)
	pts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(pts)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	content.add_child(cols)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 4)
	cols.add_child(grid)
	var bonus: Dictionary = Progression.equipment_bonus(st)
	for key in Progression.STATS:
		var name_l := P.label(Progression.STAT_NAMES[key], 15)
		name_l.tooltip_text = Progression.STAT_DESC[key]
		name_l.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(name_l)
		var val := "%d" % st["base"][key]
		if bonus.get(key, 0) > 0:
			val += " (+%d)" % bonus[key]
		grid.add_child(P.label(val, 15))
		var plus := P.button("+", P.MINT, 16)
		plus.disabled = st["stat_points"] <= 0
		plus.custom_minimum_size = Vector2(40, 0)
		plus.pressed.connect(func(): player.add_stat(key))
		grid.add_child(plus)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 2)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	var derived := right
	var kind_names := {"melee": "ประชิด", "ranged": "ระยะไกล", "magic": "เวท"}
	for line in [
		"HP %d   SP %d" % [s["max_hp"], s["max_sp"]],
		"ATK %d   MATK %d" % [s["atk"], s["matk"]],
		"DEF %d" % s["def"],
		"ตีทุก %.2f วินาที" % s["attack_interval"],
		"คริติคอล %d%%" % int(s["crit"] * 100),
		"การโจมตี: %s" % kind_names[s["attack"]],
	]:
		derived.add_child(P.label(line, 14))

	right.add_child(P.label("ของที่สวมอยู่", 16, P.PINK_DEEP))
	for slot in ItemDB.SLOTS:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		right.add_child(r)
		r.add_child(P.label("%s:" % ItemDB.SLOT_NAMES[slot], 14))
		if st["equipment"].has(slot):
			var id: String = st["equipment"][slot]
			var l := P.label(ItemDB.ITEMS[id]["name"], 14, ItemDB.color_of(id).darkened(0.25))
			l.tooltip_text = ItemDB.bonus_text(id)
			l.mouse_filter = Control.MOUSE_FILTER_PASS
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r.add_child(l)
			var off := P.button("ถอด", P.LEMON, 13)
			off.pressed.connect(func(): player.unequip(slot))
			r.add_child(off)
		else:
			r.add_child(P.label("-", 14, P.TEXT.lightened(0.4)))

	section("คลาส")
	var need := Classes.change_level(st["class"])
	if need < 0:
		content.add_child(P.label("ถึงขั้นสูงสุดแล้ว (เลื่อนขั้นครบ 3 ครั้ง)", 14))
	else:
		var req: Dictionary = player.class_change_status()
		content.add_child(P.label("เปลี่ยนอาชีพที่ ครูใหญ่สำนัก (หน้าโบสถ์ หมู่บ้านริมคลอง)", 14, P.PINK_DEEP if player.can_change_class() else P.TEXT))
		for line in requirement_lines(req):
			content.add_child(P.label(line, 13))
