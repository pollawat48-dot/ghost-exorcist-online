extends "res://client/ui/game_window.gd"
## หน้าต่างร้านค้า: ซื้อของ (ยา หรือของสวมใส่ที่ร้านอาวุธ) ทางซ้าย และขายของทางขวา

const ItemDB = preload("res://shared/data/items.gd")
const ItemIcons = preload("res://client/ui/item_icons.gd")

var npc := {}


func _ready() -> void:
	setup("ร้านค้า", 760)


func open_for(npc_data: Dictionary) -> void:
	npc = npc_data
	title_label.text = npc["name"]
	show_window()


func _build() -> void:
	var top := row()
	top.add_child(icon("coin", 26))
	top.add_child(P.label("เหรียญของคุณ: %d" % player.coins(), 17, Color(0.72, 0.5, 0.12)))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	content.add_child(cols)
	var buy_col := _column(cols, 360)
	var sell_col := _column(cols, 380)

	var stock: Array = npc.get("stock", [])
	var gear_shop: bool = not stock.is_empty() and ItemDB.ITEMS[stock[0]]["type"] == "equip"
	var has_tool := false
	for id in stock:
		has_tool = has_tool or ItemDB.ITEMS[id]["type"] == "tool"
	buy_col.add_child(P.label("ซื้อของสวมใส่" if gear_shop else ("ซื้อของ" if has_tool else "ซื้อยา"), 16, P.PINK_DEEP))
	var buy_list: Control = buy_col
	if gear_shop:
		var bscroll := ScrollContainer.new()
		bscroll.custom_minimum_size = Vector2(360, mini(380, 48 * stock.size()))
		bscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		buy_col.add_child(bscroll)
		buy_list = VBoxContainer.new()
		buy_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bscroll.add_child(buy_list)
	for id in stock:
		var item: Dictionary = ItemDB.ITEMS[id]
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		buy_list.add_child(r)
		if item["type"] == "equip":
			_gear_row(r, id, item)
			continue
		r.add_child(ItemIcons.make(id, 38))
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", -2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(info)
		info.add_child(P.label("%s  (มี %d)" % [item["name"], player.inventory.get(id, 0)], 14))
		if item["type"] == "tool":
			info.add_child(P.label("ใช้ตกปลาที่ลำธาร · %d เหรียญ" % item["buy"], 11, P.TEXT.lightened(0.2)))
			var b := P.button("ซื้อ", P.MINT, 13)
			b.disabled = player.coins() < item["buy"]
			b.pressed.connect(func(): player.buy(id, 1))
			r.add_child(b)
			continue
		info.add_child(P.label("%s · %d เหรียญ" % [ItemDB.use_text(id), item["buy"]], 11, P.TEXT.lightened(0.2)))
		for n in [1, 10]:
			var b := P.button("x%d" % n, P.MINT, 13)
			b.disabled = player.coins() < item["buy"] * n
			b.pressed.connect(func(): player.buy(id, n))
			r.add_child(b)

	var head := HBoxContainer.new()
	sell_col.add_child(head)
	var title := P.label("ขายของ", 16, P.PINK_DEEP)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var loot_total := 0
	for id in player.inventory:
		if ItemDB.info(id)["type"] == "etc":
			loot_total += ItemDB.sell_price(id) * player.inventory[id]
	var all := P.button("ขายของจากผีทั้งหมด (+%d)" % loot_total, P.LEMON, 13)
	all.disabled = loot_total == 0
	all.pressed.connect(sell_all_loot)
	head.add_child(all)
	var ids: Array = []
	for id in player.inventory:
		if ItemDB.sell_price(id) > 0:
			ids.append(id)
	if ids.is_empty():
		sell_col.add_child(P.label("ไม่มีของที่ขายได้", 14, P.TEXT.lightened(0.3)))
		return
	ids.sort_custom(func(a, b): return _order(a) < _order(b))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, mini(340, 44 * ids.size()))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sell_col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	for id in ids:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		list.add_child(r)
		r.add_child(ItemIcons.make(id, 34))
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", -2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(info)
		info.add_child(P.label("%s x%d" % [ItemDB.display_name(id), player.inventory[id]], 14))
		info.add_child(P.label("ชิ้นละ %d เหรียญ" % ItemDB.sell_price(id), 11, P.TEXT.lightened(0.2)))
		var one := P.button("ขาย 1", P.PINK, 13)
		one.pressed.connect(func(): player.sell(id, 1))
		r.add_child(one)
		if player.inventory[id] > 1:
			var every := P.button("หมด", P.PINK, 13)
			every.pressed.connect(func(): player.sell(id, player.inventory.get(id, 0)))
			r.add_child(every)


## ขายวัตถุดิบจากผีทั้งหมดทีเดียว (ไม่รวมของสวมใส่ ดวงวิญญาณ และยา)
func sell_all_loot() -> void:
	for id in player.inventory.keys():
		if ItemDB.info(id)["type"] == "etc":
			player.sell(id, player.inventory[id])


func _column(parent: Control, width: float) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = width
	v.add_theme_constant_override("separation", 6)
	parent.add_child(v)
	return v


func _order(id: String) -> int:
	var order := {"etc": 0, "fish": 1, "ore": 2, "soul": 3, "equip": 4, "amulet": 5, "refine": 6, "tool": 7, "consumable": 8}
	return order.get(ItemDB.info(id)["type"], 9)


const LINE_NAMES := {"any": "ทุกสาย", "melee": "สายประชิด", "ranged": "สายระยะไกล", "magic": "สายเวท"}


func _gear_row(r: HBoxContainer, id: String, item: Dictionary) -> void:
	r.add_child(ItemIcons.make(id, 38))
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", -2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(info)
	info.add_child(P.label("%s · %s" % [item["name"], ItemDB.SLOT_NAMES[item["slot"]]], 14, ItemDB.color_of(id).darkened(0.35)))
	info.add_child(P.label("%s · %s · %d เหรียญ" % [ItemDB.bonus_text(id), LINE_NAMES[item["line"]], item["buy"]], 11, P.TEXT.lightened(0.2)))
	var b := P.button("ซื้อ", P.MINT, 13)
	b.disabled = player.coins() < item["buy"]
	b.pressed.connect(func(): player.buy(id, 1))
	r.add_child(b)
