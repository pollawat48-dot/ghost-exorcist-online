extends "res://client/ui/game_window.gd"
## หน้าต่างเควส: คุยกับ NPC เพื่อรับ/ส่งเควส หรือเปิดจากเมนูเพื่อดูเควสที่กำลังทำ

const Quests = preload("res://shared/data/quests.gd")
const ItemIcons = preload("res://client/ui/item_icons.gd")
const ItemDB = preload("res://shared/data/items.gd")

signal guide_requested(id: String)  ## กดนำทาง: เดินไปล่าผี/กลับไปส่งเควสให้อัตโนมัติ

var npc := {}  ## ว่าง = สมุดเควส (ดูเควสที่รับไว้ทั้งหมด)


func _ready() -> void:
	setup("สมุดเควส", 580)


func open_for(npc_data: Dictionary) -> void:
	npc = npc_data
	title_label.text = npc["name"]
	show_window()


func _build() -> void:
	var ids: Array[String] = []
	if npc.is_empty():
		for id in player.active_quests():
			ids.append(id)
		if ids.is_empty():
			content.add_child(P.label("ยังไม่ได้รับเควส คุยกับ NPC ที่มีเครื่องหมาย ! บนหัวเพื่อรับเควส", 14))
			return
	else:
		content.add_child(P.label(_greeting(), 14, P.TEXT.lightened(0.15)))
		var locked_shown := 0
		for id in Quests.for_giver(npc["id"]):
			var st: String = player.quest_status(id)
			if st == "locked":
				locked_shown += 1
				if locked_shown > 2:
					continue
			ids.append(id)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(580, mini(440, 116 * ids.size()))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	for id in ids:
		_quest_card(list, id)


func _greeting() -> String:
	match npc["id"]:
		"luang_ta":
			return "\"โยมศิษย์วัด ช่วยหลวงตาปราบผีที่มากวนชาวบ้านหน่อยนะ\""
		"ta_sappare":
			return "\"ป่าช้านี้ไม่สงบมานานแล้ว เจ้ากล้าพอจะช่วยตาไหม\""
	return ""


func _quest_card(list: VBoxContainer, id: String) -> void:
	var q: Dictionary = Quests.QUESTS[id]
	var st: String = player.quest_status(id)
	var card := PanelContainer.new()
	var bg: Color = {"ready": Color(0.9, 1.0, 0.9), "active": Color(1.0, 0.98, 0.9), "available": Color(1.0, 0.95, 0.97), "done": Color(0.94, 0.94, 0.94), "locked": Color(0.95, 0.94, 0.96)}[st]
	var style := P.panel_style(12, bg, P.LAVENDER.lightened(0.2))
	style.shadow_size = 0
	card.add_theme_stylebox_override("panel", style)
	list.add_child(card)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	card.add_child(h)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	var tag: String = {"ready": "ส่งได้", "active": "กำลังทำ", "available": "ใหม่", "done": "สำเร็จแล้ว", "locked": "ยังรับไม่ได้"}[st]
	var title := "%s  [%s]%s" % [q["name"], tag, "  (ทำซ้ำได้)" if q["repeatable"] else ""]
	info.add_child(P.label(title, 15, P.TEXT if st != "locked" else P.TEXT.lightened(0.4)))
	var desc := P.label(q["desc"], 12, P.TEXT.lightened(0.2))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 420
	info.add_child(desc)
	var goal := Quests.goal_text(player.state, player.inventory, id)
	if st == "locked":
		var need := "ต้องเลเวล %d" % q["min_level"]
		if q["requires"] != "" and not player.state["quests_done"].has(q["requires"]):
			need += " และทำเควส \"%s\" ก่อน" % Quests.QUESTS[q["requires"]]["name"]
		goal = need
	info.add_child(P.label("เป้าหมาย: " + goal, 13, P.PINK_DEEP if st == "ready" else P.TEXT))
	info.add_child(P.label("รางวัล: " + Quests.reward_text(id, player.class_info()["line"]), 12, Color(0.7, 0.5, 0.15)))
	var reward_items: Dictionary = Quests.reward(id, player.class_info()["line"]).get("items", {})
	if not reward_items.is_empty():
		var icons := HBoxContainer.new()
		icons.add_theme_constant_override("separation", 4)
		info.add_child(icons)
		for item_id in reward_items:
			var ic := ItemIcons.make(item_id, 28)
			ic.tooltip_text = ItemDB.display_name(item_id)
			ic.mouse_filter = Control.MOUSE_FILTER_PASS
			icons.add_child(ic)
			icons.add_child(P.label("x%d" % reward_items[item_id], 12, Color(0.7, 0.5, 0.15)))
	match st:
		"available":
			var b := P.button("รับเควส", P.MINT, 15)
			b.pressed.connect(func(): player.accept_quest(id))
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(b)
		"ready":
			var b := P.button("ส่งเควส", P.LEMON, 15)
			if npc.is_empty():
				# เปิดจากสมุดเควส: ส่งตรงนี้ไม่ได้ ให้เดินกลับไปหาผู้ให้เควสแทน
				b.text = "เดินกลับไปส่ง"
				b.pressed.connect(func(): guide_requested.emit(id))
			else:
				b.disabled = npc["id"] != q["giver"]
				b.pressed.connect(func(): player.complete_quest(id))
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(b)
		"active":
			var col := VBoxContainer.new()
			col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(col)
			var go := P.button("ไปล่าผี", P.MINT, 14)
			go.pressed.connect(func(): guide_requested.emit(id))
			col.add_child(go)
			var b := P.button("ยกเลิก", P.PINK, 13)
			b.pressed.connect(func(): player.abandon_quest(id))
			col.add_child(b)
