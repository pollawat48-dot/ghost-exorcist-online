extends "res://client/ui/game_window.gd"
## หน้าต่างเลื่อนขั้นคลาส: ศิษย์วัดเลือกได้ 3 สาย ขั้นต่อไปเลื่อนตามสายเดิม

const Classes = preload("res://shared/data/classes.gd")
const Skills = preload("res://shared/data/skills.gd")

const KIND_NAMES := {"melee": "ประชิด", "ranged": "ระยะไกล", "magic": "เวท"}
const KIND_ICONS := {"melee": "sword", "ranged": "arrow", "magic": "fire"}


func _ready() -> void:
	setup("เลื่อนขั้นคลาส", 640)


func _build() -> void:
	var options: Array[String] = Classes.next_classes(player.state["class"])
	content.add_child(P.label("เลือกเส้นทางของคุณ (เปลี่ยนแล้วกลับไม่ได้)" if options.size() > 1 else "พร้อมเลื่อนขั้นแล้ว!", 15))
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
		var pick := P.button("เลือก", P.LEMON, 15)
		pick.pressed.connect(_pick.bind(id))
		v.add_child(pick)


func _pick(id: String) -> void:
	if player.change_class(id):
		hide_window()
