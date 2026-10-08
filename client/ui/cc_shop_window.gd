extends "res://client/ui/game_window.gd"
## ร้าน CC: ซื้อกาชาปอง (ลูกละ 10 CC) แล้วเปิดสุ่มได้ เกลือเสก ยา หินตี+ แฟชั่น หรือแฟชั่น/สัตว์เลี้ยง (ออกยาก)
## แสดงอัตราออกของทุกอย่างให้ผู้เล่นเห็น

const ItemDB = preload("res://shared/data/items.gd")
const ItemIcons = preload("res://client/ui/item_icons.gd")
const Fashion = preload("res://shared/data/fashion.gd")

var last_results: Array = []


func _ready() -> void:
	setup("ร้าน CC · กาชาปองนำโชค", 720)


func _build() -> void:
	var top := row()
	top.add_child(icon("gacha", 28))
	top.add_child(P.label("CC ของคุณ: %d" % player.cc(), 18, P.PINK_DEEP))
	var hint := P.label("ได้ CC จาก: ตัวละครใหม่ %d · เลเวลอัป +%d · ปราบบอส +%d" % [Fashion.CC_START, Fashion.CC_PER_LEVEL, Fashion.CC_PER_BOSS], 12, P.TEXT.lightened(0.25))
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(hint)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	content.add_child(cols)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 380
	left.add_theme_constant_override("separation", 6)
	cols.add_child(left)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 320
	right.add_theme_constant_override("separation", 2)
	cols.add_child(right)

	# ---- สินค้า ----
	left.add_child(P.label("สินค้า", 16, P.PINK_DEEP))
	var item_row := HBoxContainer.new()
	item_row.add_theme_constant_override("separation", 8)
	left.add_child(item_row)
	item_row.add_child(ItemIcons.make(Fashion.GACHA_ID, 52))
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", -2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_row.add_child(info)
	info.add_child(P.label("กาชาปองนำโชค", 16))
	info.add_child(P.label("ลูกละ %d CC · ในกระเป๋า %d ลูก" % [Fashion.GACHA_PRICE, player.inventory.get(Fashion.GACHA_ID, 0)], 12, P.TEXT.lightened(0.2)))
	var buy_row := HBoxContainer.new()
	buy_row.add_theme_constant_override("separation", 8)
	left.add_child(buy_row)
	for n in [1, 10]:
		var b := P.button("ซื้อ %d ลูก (%d CC)" % [n, n * Fashion.GACHA_PRICE], P.MINT, 14)
		b.disabled = player.cc() < n * Fashion.GACHA_PRICE
		b.pressed.connect(func(): player.buy_gacha(n))
		buy_row.add_child(b)
	var open_row := HBoxContainer.new()
	open_row.add_theme_constant_override("separation", 8)
	left.add_child(open_row)
	var have: int = player.inventory.get(Fashion.GACHA_ID, 0)
	for n in [1, 10]:
		var b := P.button("เปิด %d ลูก" % n, P.PINK, 15)
		b.disabled = have <= 0
		b.pressed.connect(func(): open(n))
		open_row.add_child(b)

	# ---- ผลที่เปิดล่าสุด ----
	if not last_results.is_empty():
		left.add_child(P.label("ได้รับ", 16, P.PINK_DEEP))
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 4)
		left.add_child(grid)
		for r in last_results:
			var cell := VBoxContainer.new()
			cell.custom_minimum_size.x = 70
			cell.add_theme_constant_override("separation", 0)
			grid.add_child(cell)
			var ic := ItemIcons.make(r["item"], 46)
			ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			cell.add_child(ic)
			var rare: bool = ItemDB.info(r["item"])["type"] == "fashion"
			var l := P.label(("★ " if rare else "") + "%s x%d" % [ItemDB.info(r["item"])["name"], r["count"]], 10, ItemDB.color_of(r["item"]).darkened(0.35) if rare else P.TEXT)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.custom_minimum_size.x = 70
			cell.add_child(l)

	# ---- อัตราออก ----
	right.add_child(P.label("อัตราออกต่อหนึ่งลูก", 16, P.PINK_DEEP))
	var groups := {}
	var order: Array[String] = []
	for e in Fashion.GACHA_TABLE:
		var name: String = "แฟชั่น / สัตว์เลี้ยง" if e["item"] == "@fashion" else ItemDB.ITEMS[e["item"]]["name"]
		if e["item"] != "@fashion":
			name += " x%d" % e["count"][0] if e["count"][0] == e["count"][1] else " x%d–%d" % [e["count"][0], e["count"][1]]
		if not groups.has(name):
			order.append(name)
		groups[name] = groups.get(name, 0.0) + e["weight"]
	for name in order:
		right.add_child(P.label("%s  %.0f%%" % [name, groups[name]], 13, P.PINK_DEEP if name.begins_with("แฟชั่น") else P.TEXT))
	right.add_child(P.label("ในกลุ่มแฟชั่น (ต่อหนึ่งลูก)", 14, P.PINK_DEEP))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(320, 210)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	scroll.add_child(list)
	for id in Fashion.fashion_pool():
		var r := HBoxContainer.new()
		list.add_child(r)
		r.add_child(ItemIcons.make(id, 24))
		var it: Dictionary = ItemDB.ITEMS[id]
		r.add_child(P.label("%s [%s] %.2f%%" % [it["name"], ItemDB.RARITY[it["rarity"]]["name"], Fashion.fashion_chance(id) * 100.0], 12, ItemDB.color_of(id).darkened(0.35)))


func open(n: int) -> void:
	last_results = player.open_gacha(n)
	refresh()
