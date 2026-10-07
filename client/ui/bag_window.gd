extends "res://client/ui/game_window.gd"
## หน้าต่างกระเป๋า: ดูไอเทม สวมของ ใช้ยา

const ItemDB = preload("res://shared/data/items.gd")
const ItemIcons = preload("res://client/ui/item_icons.gd")


## ค่าที่โชว์ตอนเทียบของ: [คีย์, ชื่อ, แสดงเสมอ]
const COMPARE_STATS := [["atk", "พลังโจมตี (ATK)", true], ["matk", "พลังเวท (MATK)", true], ["def", "ป้องกัน (DEF)", true],
	["max_hp", "HP สูงสุด", true], ["max_sp", "SP สูงสุด", true], ["str", "STR", false], ["agi", "AGI", false],
	["vit", "VIT", false], ["int", "INT", false], ["dex", "DEX", false], ["luk", "LUK", false]]

var _compare := ""  ## ของที่กำลังเทียบก่อนสวม ("" = แสดงรายการกระเป๋า)


func _ready() -> void:
	setup("กระเป๋า", 520)


func show_window() -> void:
	_compare = ""
	super.show_window()


func _build() -> void:
	if _compare != "" and player.inventory.get(_compare, 0) > 0:
		_build_compare(_compare)
		return
	_compare = ""
	if player.inventory.is_empty():
		content.add_child(P.label("กระเป๋าว่างเปล่า", 15))
		return
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, mini(400, 46 * player.inventory.size()))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	var ids: Array = player.inventory.keys()
	ids.sort_custom(func(a, b): return _order(a) < _order(b))
	for id in ids:
		var item: Dictionary = ItemDB.info(id)
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 8)
		list.add_child(r)
		r.add_child(ItemIcons.make(id, 40))
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", -2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(info)
		info.add_child(P.label("%s  x%d" % [ItemDB.display_name(id), player.inventory[id]], 15))
		if item["type"] == "equip":
			var line_names := {"any": "ทุกสาย", "melee": "สายประชิด", "ranged": "สายระยะไกล", "magic": "สายเวท"}
			info.add_child(P.label("[%s] %s · %s · %s" % [ItemDB.RARITY[item["rarity"]]["name"], ItemDB.SLOT_NAMES[item["slot"]], ItemDB.bonus_text(id), line_names[item["line"]]], 12, ItemDB.color_of(id).darkened(0.3)))
			var b := P.button("สวม", P.MINT, 14)
			b.disabled = not player.can_equip(id)
			b.pressed.connect(func():
				_compare = id
				refresh())
			r.add_child(b)
		elif item["type"] == "consumable":
			info.add_child(P.label(ItemDB.use_text(id), 12, P.TEXT.lightened(0.2)))
			var b := P.button("ใช้", P.SKY, 14)
			b.pressed.connect(func(): player.use_item(id))
			r.add_child(b)
		elif item["type"] == "refine":
			info.add_child(P.label("ใช้ตีบวกของสวมใส่ได้ถึง +%d" % item["refine_max"], 12, P.TEXT.lightened(0.2)))
			var b := P.button("ใช้", P.PINK, 14)
			b.pressed.connect(func(): player.use_item(id))
			r.add_child(b)
		elif item["type"] == "fashion":
			var Fashion = load("res://shared/data/fashion.gd")
			var what: String = Fashion.SLOT_NAMES[item["slot"]]
			info.add_child(P.label("[%s] แฟชั่น%s · %s" % [ItemDB.RARITY[item["rarity"]]["name"], what, ItemDB.bonus_text(id) if item.has("bonus") else "ช่วยสู้ ใช้สกิลเอง"], 12, ItemDB.color_of(id).darkened(0.3)))
			var b := P.button("ใส่", P.MINT, 14)
			b.pressed.connect(func(): player.wear_fashion(id))
			r.add_child(b)
		elif item["type"] == "gacha":
			info.add_child(P.label("เปิดสุ่ม: เกลือเสก ยา หินตี+ แฟชั่น หรือแฟชั่น (ออกยาก)", 12, P.TEXT.lightened(0.2)))
			var b := P.button("เปิด", P.PINK, 14)
			b.pressed.connect(func(): player.use_item(id))
			r.add_child(b)
		elif item["type"] == "fashion_refine":
			info.add_child(P.label("ใช้ตีบวกแฟชั่น (ชุด หมวก ปีก) ได้ถึง +10", 12, P.TEXT.lightened(0.2)))
			var b := P.button("ใช้", P.PINK, 14)
			b.pressed.connect(func(): player.use_item(id))
			r.add_child(b)
		elif item["type"] == "ore":
			info.add_child(P.label("แร่ ใช้หลอมหินตี+ ที่ร้านหลอมแร่ (ขายได้ %d)" % ItemDB.sell_price(id), 12, P.TEXT.lightened(0.2)))
		elif item["type"] == "tool":
			info.add_child(P.label("ใช้ตกปลาที่ลำธาร", 12, P.TEXT.lightened(0.2)))
		elif item["type"] == "fish":
			info.add_child(P.label("ขายได้ %d เหรียญ" % ItemDB.sell_price(id), 12, P.TEXT.lightened(0.2)))
		elif item["type"] == "amulet":
			info.add_child(P.label("ใช้ตอนตีบวก เพิ่มโอกาสสำเร็จ +%d%%" % int(round(float(item.get("refine_bonus", 0.0)) * 100.0)), 12, P.TEXT.lightened(0.2)))


## หน้าเทียบของ: ชิ้นที่ใส่อยู่ (ซ้าย) กับชิ้นใหม่ (ขวา) + ค่าสถานะที่จะเปลี่ยน แล้วค่อยกดติดตั้งหรือยกเลิก
func _build_compare(id: String) -> void:
	var pv: Dictionary = player.preview_equip(id)
	var slot_name: String = ItemDB.SLOT_NAMES[pv["slot"]]
	content.add_child(P.label("เทียบ%sก่อนสวม" % slot_name, 17, P.P_TEXT_DARK))
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 8)
	content.add_child(cards)
	cards.add_child(_item_card("ใส่อยู่ตอนนี้", pv["current"], P.SKY))
	var arrow := P.label("➜", 26, P.P_TEXT_DARK)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cards.add_child(arrow)
	cards.add_child(_item_card("ของใหม่", id, P.MINT))
	# ค่าที่เปลี่ยน: เขียว = เพิ่ม แดง = ลด
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", P.panel_style(12, Color(1, 1, 1, 0.6), P.LAVENDER.lightened(0.3)))
	content.add_child(box)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	box.add_child(grid)
	var any := false
	for st in COMPARE_STATS:
		var before: int = int(pv["before"][st[0]])
		var after: int = int(pv["after"][st[0]])
		if before == after and not st[2]:
			continue
		any = any or before != after
		var diff := after - before
		var col := P.TEXT.lightened(0.25)
		var mark := "="
		if diff > 0:
			col = Color(0.2, 0.62, 0.32)
			mark = "▲ +%d" % diff
		elif diff < 0:
			col = Color(0.85, 0.3, 0.35)
			mark = "▼ %d" % diff
		var name_l := P.label(st[1], 14)
		name_l.custom_minimum_size.x = 150
		grid.add_child(name_l)
		grid.add_child(P.label(str(before), 14, P.TEXT.lightened(0.2)))
		grid.add_child(P.label("➜ %d" % after, 14, col))
		grid.add_child(P.label(mark, 14, col))
	if not any:
		content.add_child(P.label("ค่าสถานะเท่าเดิม", 13, P.TEXT.lightened(0.25)))
	if not player.can_equip(id):
		content.add_child(P.label("อาชีพนี้ใช้ของชิ้นนี้ไม่ได้", 14, Color(0.85, 0.3, 0.35)))
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 16)
	content.add_child(bar)
	var ok := P.button("ติดตั้ง", P.MINT, 17)
	ok.custom_minimum_size = Vector2(150, 44)
	ok.disabled = not player.can_equip(id)
	ok.pressed.connect(func():
		_compare = ""
		if not player.equip(id):
			refresh())
	bar.add_child(ok)
	var cancel := P.button("ยกเลิก", P.PINK, 17)
	cancel.custom_minimum_size = Vector2(150, 44)
	cancel.pressed.connect(func():
		_compare = ""
		refresh())
	bar.add_child(cancel)


## การ์ดของหนึ่งชิ้น: หัวการ์ด ไอคอน ชื่อ ระดับ และโบนัส (id ว่าง = ยังไม่ได้ใส่)
func _item_card(title: String, id: String, tint: Color) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", P.panel_style(14, tint.lightened(0.55), tint.darkened(0.1)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(v)
	var head := P.label(title, 13, P.P_TEXT_DARK)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	if id == "":
		var empty := P.label("(ยังไม่ได้ใส่)", 15, P.TEXT.lightened(0.3))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.custom_minimum_size.y = 90
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		v.add_child(empty)
		return card
	var ic := ItemIcons.make(id, 52)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var item: Dictionary = ItemDB.info(id)
	var nm := P.label(ItemDB.display_name(id), 15, ItemDB.color_of(id).darkened(0.35))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size.x = 200
	v.add_child(nm)
	var rr := P.label("[%s]" % ItemDB.RARITY[item["rarity"]]["name"], 12, ItemDB.color_of(id).darkened(0.3))
	rr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(rr)
	var bt := P.label(ItemDB.bonus_text(id), 12, P.TEXT.lightened(0.15))
	bt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bt.custom_minimum_size.x = 200
	v.add_child(bt)
	return card


func _order(id: String) -> int:
	var order := {"equip": 0, "fashion": 0, "gacha": 1, "consumable": 1, "tool": 2, "refine": 3, "fashion_refine": 3, "amulet": 4, "ore": 5, "fish": 6, "soul": 7, "etc": 8}
	return order.get(ItemDB.info(id)["type"], 9)
