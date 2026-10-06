extends "res://client/ui/game_window.gd"
## หน้าต่างเลื่อนขั้นคลาส: ศิษย์วัดเลือกได้ 3 สาย ขั้นต่อไปเลื่อนตามสายเดิม

const Classes = preload("res://shared/data/classes.gd")
const Skills = preload("res://shared/data/skills.gd")
const Quests = preload("res://shared/data/quests.gd")
const CharWindow = preload("res://client/ui/char_window.gd")

const KIND_NAMES := {"melee": "ประชิด", "ranged": "ระยะไกล", "magic": "เวท"}
const KIND_ICONS := {"melee": "sword", "ranged": "arrow", "magic": "fire"}


func _ready() -> void:
	setup("ครูใหญ่สำนัก · เปลี่ยนอาชีพ", 640)


## เปิดจาก NPC ครูใหญ่สำนัก
func open_for(_npc: Dictionary) -> void:
	show_window()


func _build() -> void:
	var req: Dictionary = player.class_change_status()
	if req.is_empty():
		content.add_child(P.label("\"เจ้าเป็น%sขั้นสูงสุดแล้ว ไม่มีอะไรจะสอนอีก\"" % player.class_info()["name"], 15))
		return
	content.add_child(P.label("\"อยากเลื่อนขั้นต้องพิสูจน์ฝีมือ และจ่ายค่าครูก่อน\"", 14, P.TEXT.lightened(0.15)))
	section("เงื่อนไข")
	for line in CharWindow.requirement_lines(req):
		content.add_child(P.label(line, 14, P.TEXT if line.begins_with("[ผ่าน]") else P.PINK_DEEP))
	_trial_row(req["quest"])
	var ready: bool = player.can_change_class()
	var options: Array[String] = Classes.next_classes(player.state["class"])
	section("เลือกเส้นทางของคุณ (เปลี่ยนแล้วกลับไม่ได้)" if options.size() > 1 else "อาชีพขั้นถัดไป")
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 10)
	content.add_child(cards)
	for id in options:
		var cls: Dictionary = Classes.CLASSES[id]
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", P.panel_style(16, Color(1, 1, 1, 0.7), cls["look"]["robe"]))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cards.add_child(card)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 4)
		card.add_child(v)
		var h := HBoxContainer.new()
		v.add_child(h)
		h.add_child(icon(KIND_ICONS[cls["attack"]], 34))
		h.add_child(P.label(cls["name"], 18))
		v.add_child(P.label("สาย%s" % KIND_NAMES[cls["attack"]], 13, P.PINK_DEEP))
		var d := P.label(cls["desc"], 13)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size.x = 170
		v.add_child(d)
		var names: Array[String] = []
		for sid in Skills.SKILLS:
			if Skills.SKILLS[sid]["class"] == id:
				names.append(Skills.SKILLS[sid]["name"])
		var sl := P.label("สกิล: " + ", ".join(names), 12)
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sl.custom_minimum_size.x = 170
		v.add_child(sl)
		var pick := P.button("เปลี่ยนอาชีพ (%d เหรียญ)" % req["fee"], P.LEMON, 14)
		pick.disabled = not ready
		pick.pressed.connect(_pick.bind(id))
		v.add_child(pick)


## เควสบททดสอบ: รับ / ดูความคืบหน้า / ส่ง ได้ที่นี่เลย
func _trial_row(id: String) -> void:
	var st: String = player.quest_status(id)
	var r := row()
	var text := "บททดสอบ: %s" % Quests.QUESTS[id]["name"]
	match st:
		"active", "ready":
			text += "  (%s)" % Quests.goal_text(player.state, player.inventory, id)
		"done":
			text += "  (ผ่านแล้ว)"
	var l := P.label(text, 14)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(l)
	match st:
		"available":
			var b := P.button("รับบททดสอบ", P.MINT, 14)
			b.pressed.connect(func(): player.accept_quest(id))
			r.add_child(b)
		"ready":
			var b := P.button("ส่งบททดสอบ", P.LEMON, 14)
			b.pressed.connect(func(): player.complete_quest(id))
			r.add_child(b)
		"locked":
			r.add_child(P.label("ต้องเลเวล %d" % Quests.QUESTS[id]["min_level"], 13, P.TEXT.lightened(0.3)))
	var desc := P.label(Quests.QUESTS[id]["desc"], 12, P.TEXT.lightened(0.2))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 600
	content.add_child(desc)


func _pick(id: String) -> void:
	if player.change_class(id):
		hide_window()
