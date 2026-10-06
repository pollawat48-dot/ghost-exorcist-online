extends "res://client/ui/game_window.gd"
## หน้าต่างกระเป๋า: ดูไอเทม สวมของ ใช้ยา

const ItemDB = preload("res://shared/data/items.gd")
const ItemIcons = preload("res://client/ui/item_icons.gd")


func _ready() -> void:
	setup("กระเป๋า", 520)


func _build() -> void:
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
			b.pressed.connect(func(): player.equip(id))
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


func _order(id: String) -> int:
	var order := {"equip": 0, "fashion": 0, "gacha": 1, "consumable": 1, "tool": 2, "refine": 3, "fashion_refine": 3, "amulet": 4, "ore": 5, "fish": 6, "soul": 7, "etc": 8}
	return order.get(ItemDB.info(id)["type"], 9)
