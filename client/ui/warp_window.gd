extends "res://client/ui/game_window.gd"
## หน้าต่างร่างทรงนำทาง: วาร์ปไปแผนที่ที่เคยไปแล้ว (จ่ายค่าวาร์ปตามความไกล/ความยากของแผนที่)

const World = preload("res://shared/data/world.gd")
const GhostDB = preload("res://shared/data/ghosts.gd")

signal warp_requested(map_id: String)

var current_map := ""


func _ready() -> void:
	setup("ร่างทรงนำทาง · วาร์ป", 560)


func open_for(npc_data: Dictionary) -> void:
	title_label.text = "%s · วาร์ป" % npc_data["name"].replace(" (วาร์ป)", "")
	show_window()


func _build() -> void:
	content.add_child(P.label("\"จะไปแผนที่ไหนจ๊ะ ต้องเคยเดินไปเองก่อนหนึ่งครั้งนะ\"", 14, P.TEXT.lightened(0.15)))
	var top := row()
	top.add_child(icon("coin", 24))
	top.add_child(P.label("เหรียญของคุณ: %d" % player.coins(), 15, Color(0.72, 0.5, 0.12)))
	for id in World.ORDER:
		var info: Dictionary = World.MAPS[id]
		var r := row()
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", -2)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(text)
		var visited: bool = player.state["visited"].has(id)
		var cave := "  · มีถ้ำ" if id in player.state["caves"] else ""
		text.add_child(P.label(info["name"] + cave, 15, P.TEXT if visited else P.TEXT.lightened(0.4)))
		if info.get("safe", false):
			text.add_child(P.label("ไม่มีผี · ตกปลาได้ปลาและพระเครื่อง", 12, P.TEXT.lightened(0.25)))
		else:
			var boss_name: String = GhostDB.GHOSTS[info["boss"]]["name"]
			text.add_child(P.label("ผีเลเวล %s · บอส %s" % [info["levels"], boss_name], 12, P.TEXT.lightened(0.25)))
		var b: Button
		if id == current_map:
			b = P.button("อยู่ที่นี่", P.LEMON, 13)
			b.disabled = true
		elif not visited:
			b = P.button("ยังไม่เคยไป", P.SKY, 13)
			b.disabled = true
		else:
			b = P.button("วาร์ป (%d)" % player.warp_fee(id), P.SKY, 13)
			b.disabled = not player.can_warp(id)
			b.pressed.connect(func(): warp_requested.emit(id))
		r.add_child(b)
