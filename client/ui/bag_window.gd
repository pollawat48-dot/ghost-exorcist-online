extends "res://client/ui/game_window.gd"
## หน้าต่างกระเป๋า: ดูไอเทม สวมของ ใช้ยา

const ItemDB = preload("res://shared/data/items.gd")


func _ready() -> void:
	setup("กระเป๋า", 520)


func _build() -> void:
	if player.inventory.is_empty():
		content.add_child(P.label("กระเป๋าว่างเปล่า", 15))
		return
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520, mini(380, 44 * player.inventory.size()))
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
		var dot := ColorRect.new()
		dot.color = ItemDB.color_of(id)
		dot.custom_minimum_size = Vector2(14, 14)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r.add_child(dot)
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
		elif item["type"] == "ore":
			info.add_child(P.label("แร่ ใช้หลอมหินตี+ ที่ร้านหลอมแร่ (ขายได้ %d)" % ItemDB.sell_price(id), 12, P.TEXT.lightened(0.2)))


func _order(id: String) -> int:
	var order := {"equip": 0, "consumable": 1, "refine": 2, "ore": 3, "soul": 4, "etc": 5}
	return order.get(ItemDB.info(id)["type"], 9)
