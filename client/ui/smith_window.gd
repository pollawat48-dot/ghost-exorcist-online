extends "res://client/ui/game_window.gd"
## หน้าต่างร้านหลอมแร่: ใช้เหรียญ + แร่หลายชนิดหลอมเป็นหินตี+ (ขั้นสูงใช้แร่หายากกว่า)

const ItemDB = preload("res://shared/data/items.gd")
const Crafting = preload("res://shared/data/crafting.gd")
const World = preload("res://shared/data/world.gd")
const ItemIcons = preload("res://client/ui/item_icons.gd")

signal open_refine_requested


func _ready() -> void:
	setup("ร้านหลอมแร่", 600)


func open_for(npc_data: Dictionary) -> void:
	title_label.text = npc_data["name"]
	show_window()


func _build() -> void:
	content.add_child(P.label("\"เอาแร่จากถ้ำมาให้ข้า แล้วข้าจะหลอมเป็นหินตี+ ให้\"", 14, P.TEXT.lightened(0.15)))
	var top := row()
	top.add_child(icon("coin", 24))
	top.add_child(P.label("เหรียญ %d" % player.coins(), 15, Color(0.72, 0.5, 0.12)))
	top.add_child(P.label("· แร่ที่มี:", 13))
	for ore in World.ORE_ORDER:
		var ic := ItemIcons.make(ore, 26)
		ic.tooltip_text = ItemDB.ITEMS[ore]["name"]
		ic.mouse_filter = Control.MOUSE_FILTER_PASS
		top.add_child(ic)
		top.add_child(P.label("%d" % player.inventory.get(ore, 0), 13))
	section("สูตรหลอม")
	for id in Crafting.ORDER:
		var r: Dictionary = Crafting.RECIPES[id]
		var item: Dictionary = ItemDB.ITEMS[id]
		var h := row()
		h.add_child(ItemIcons.make(id, 42))
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", -2)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(text)
		text.add_child(P.label("%s  (มี %d) · ตีได้ถึง +%d" % [item["name"], player.inventory.get(id, 0), item["refine_max"]], 15))
		# วัตถุดิบ: ไอคอนแร่ + จำนวนที่มี/ที่ต้องใช้ (ไม่พอเป็นสีแดง)
		var need := HBoxContainer.new()
		need.add_theme_constant_override("separation", 3)
		text.add_child(need)
		var bad := Color(0.85, 0.4, 0.45)
		need.add_child(icon("coin", 18))
		need.add_child(P.label("%d" % r["coins"], 12, P.TEXT.lightened(0.15) if player.coins() >= r["coins"] else bad))
		for ore in r["ores"]:
			var have: int = player.inventory.get(ore, 0)
			need.add_child(P.label(" +", 12, P.TEXT.lightened(0.3)))
			var ic := ItemIcons.make(ore, 22)
			ic.tooltip_text = ItemDB.ITEMS[ore]["name"]
			ic.mouse_filter = Control.MOUSE_FILTER_PASS
			need.add_child(ic)
			need.add_child(P.label("%s %d/%d" % [ItemDB.ITEMS[ore]["name"], have, r["ores"][ore]], 12, P.TEXT.lightened(0.15) if have >= r["ores"][ore] else bad))
		var can := Crafting.max_craft(id, player.inventory, player.coins())
		var one := P.button("หลอม x1", P.LEMON, 13)
		one.disabled = can < 1
		one.pressed.connect(func(): player.craft(id, 1))
		h.add_child(one)
		var five := P.button("x5", P.LEMON, 13)
		five.disabled = can < 5
		five.pressed.connect(func(): player.craft(id, 5))
		h.add_child(five)
	var w := World.ore_weights(1)
	content.add_child(P.label("ขุดแร่ในถ้ำ: สังกะสีออกง่ายสุด (~%d%%) เหล็ก (~%d%%) ทอง (~%d%%) เพชรยากสุด (~%d%%) ถ้ำลึกยิ่งได้แร่หายากบ่อยขึ้น" % [w[0], w[1], w[2], w[3]], 12, P.TEXT.lightened(0.2)))
	var go := P.button("ตีบวกของสวมใส่", P.PINK, 14)
	go.pressed.connect(func(): open_refine_requested.emit())
	content.add_child(go)
