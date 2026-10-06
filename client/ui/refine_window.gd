extends "res://client/ui/game_window.gd"
## หน้าต่างตีบวก (เปิดเมื่อกดใช้หินตี+ ในกระเป๋า): เลือกของสวมใส่ + หินตี+ แล้วจ่ายเหรียญ
## โอกาสสำเร็จลดลงตามขั้น ตั้งแต่ +7 ถ้าพลาดจะลดขั้น 1–2 ขั้น ตีได้สูงสุด +10
## ใส่พระเครื่อง (ได้จากตกปลา) เพิ่มโอกาสสำเร็จได้ (ใช้แล้วหมดไปทั้งสำเร็จและล้มเหลว)

const ItemDB = preload("res://shared/data/items.gd")
const ItemIcons = preload("res://client/ui/item_icons.gd")

var selected := {}  ## {"key", "slot"}
var stone := ""
var amulet := ""  ## พระเครื่องที่เลือก ("" = ไม่ใช้)
var last_result := ""


func _ready() -> void:
	setup("ตีบวกของสวมใส่", 680)


func open_with(stone_id: String) -> void:
	stone = stone_id
	last_result = ""
	if not selected.is_empty() and not _still_owned(selected):
		selected = {}
	show_window()


func _still_owned(entry: Dictionary) -> bool:
	for e in player.refinable_items():
		if e["key"] == entry["key"] and e["slot"] == entry["slot"]:
			return true
	return false


func _build() -> void:
	var items: Array = player.refinable_items()
	if items.is_empty():
		content.add_child(P.label("ไม่มีของสวมใส่ให้ตีบวก", 15))
		return
	if selected.is_empty() or not _still_owned(selected):
		selected = items[0]
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	content.add_child(cols)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 300
	cols.add_child(left)
	left.add_child(P.label("1. เลือกของ", 16, P.PINK_DEEP))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, mini(320, 42 * items.size()))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for e in items:
		var key: String = e["key"]
		var where := " (สวมอยู่)" if e["slot"] != "" else ""
		var b := P.button(ItemDB.display_name(key) + where, P.MINT if e == selected else Color(1, 1, 1, 0.9), 13)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_color_override("font_color", ItemDB.color_of(key).darkened(0.35))
		b.pressed.connect(func():
			selected = e
			refresh())
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var line := HBoxContainer.new()
		line.add_child(ItemIcons.make(key, 30))
		line.add_child(b)
		list.add_child(line)

	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 360
	right.add_theme_constant_override("separation", 5)
	cols.add_child(right)
	var key: String = selected["key"]
	var lv := ItemDB.refine_of(key)
	var head := HBoxContainer.new()
	head.add_child(ItemIcons.make(key, 44))
	var title := P.label(ItemDB.display_name(key), 18, ItemDB.color_of(key).darkened(0.3))
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(title)
	right.add_child(head)
	right.add_child(P.label("ตอนนี้: " + ItemDB.bonus_text(key), 13))
	if lv >= ItemDB.REFINE_MAX:
		right.add_child(P.label("ตีถึง +%d สูงสุดแล้ว" % ItemDB.REFINE_MAX, 15, P.PINK_DEEP))
		_result_line(right)
		return
	var next := ItemDB.refined_key(ItemDB.base_id(key), lv + 1)
	right.add_child(P.label("ถ้าสำเร็จ (+%d): %s" % [lv + 1, ItemDB.bonus_text(next)], 13, Color(0.3, 0.6, 0.35)))
	right.add_child(P.label("2. เลือกหินตี+", 16, P.PINK_DEEP))
	var stones: Array[String] = player.refine_stones_for(lv)
	if stones.is_empty():
		right.add_child(P.label("ไม่มีหินที่ใช้ตีขั้นนี้ได้ (ต้องตีได้ถึง +%d)\nหลอมหินได้ที่ร้านหลอมแร่" % (lv + 1), 13, Color(0.85, 0.4, 0.45)))
	else:
		if not stone in stones:
			stone = stones[0]
		var srow := HBoxContainer.new()
		right.add_child(srow)
		for id in stones:
			var b := P.button("%s x%d" % [ItemDB.ITEMS[id]["name"], player.inventory[id]], P.LEMON if id == stone else Color(1, 1, 1, 0.9), 12)
			b.pressed.connect(func():
				stone = id
				refresh())
			srow.add_child(b)
	var owned: Array[String] = player.amulets()
	if not amulet in owned:
		amulet = ""
	right.add_child(P.label("3. พระเครื่อง (ไม่บังคับ) เพิ่มโอกาสสำเร็จ", 16, P.PINK_DEEP))
	if owned.is_empty():
		right.add_child(P.label("ไม่มีพระเครื่อง (ตกปลาที่ลำธารใสเย็นมีโอกาสได้)", 12, P.TEXT.lightened(0.25)))
	else:
		var arow := HBoxContainer.new()
		right.add_child(arow)
		var none := P.button("ไม่ใช้", P.LEMON if amulet == "" else Color(1, 1, 1, 0.9), 12)
		none.pressed.connect(func():
			amulet = ""
			refresh())
		arow.add_child(none)
		for id in owned:
			var b := P.button("%s +%d%% x%d" % [ItemDB.ITEMS[id]["name"].replace("พระเครื่อง", "พระ"), int(round(ItemDB.ITEMS[id]["refine_bonus"] * 100)), player.inventory[id]], P.LEMON if id == amulet else Color(1, 1, 1, 0.9), 12)
			b.pressed.connect(func():
				amulet = id
				refresh())
			arow.add_child(b)
	var fee := ItemDB.refine_fee(lv)
	var chance: float = player.refine_chance(lv, amulet)
	var extra := "" if amulet == "" else " (รวมพระเครื่อง +%d%%)" % int(round(ItemDB.ITEMS[amulet]["refine_bonus"] * 100))
	right.add_child(P.label("โอกาสสำเร็จ %d%%%s · ค่าตี %d เหรียญ (มี %d)" % [int(round(chance * 100)), extra, fee, player.coins()], 14))
	if lv >= ItemDB.REFINE_RISKY_FROM:
		right.add_child(P.label("ระวัง! ตั้งแต่ +%d ถ้าล้มเหลวจะลดขั้น 1–2 ขั้น" % ItemDB.REFINE_RISKY_FROM, 13, Color(0.9, 0.35, 0.4)))
	else:
		right.add_child(P.label("ถ้าล้มเหลว ของยังอยู่ขั้นเดิม (เสียหินกับเหรียญ)", 12, P.TEXT.lightened(0.2)))
	var go := P.button("ตี +%d" % (lv + 1), P.PINK, 16)
	go.disabled = stones.is_empty() or player.coins() < fee
	go.pressed.connect(_do_refine)
	right.add_child(go)
	_result_line(right)


func _result_line(parent: Control) -> void:
	if last_result != "":
		parent.add_child(P.label(last_result, 15, P.PINK_DEEP))


func _do_refine() -> void:
	var res: Dictionary = player.refine(selected["key"], stone, selected["slot"], amulet)
	match res["result"]:
		"success":
			last_result = "สำเร็จ! ได้ %s" % ItemDB.display_name(res["key"])
		"down":
			last_result = "ล้มเหลว... ลดเหลือ +%d" % res["level"]
		"fail":
			last_result = "ล้มเหลว ของยังอยู่ +%d" % res["level"]
		_:
			last_result = ""
	if res["result"] != "error":
		selected = {"key": res["key"], "slot": selected["slot"]}
	refresh()
