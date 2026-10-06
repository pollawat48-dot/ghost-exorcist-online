extends "res://client/ui/game_window.gd"
## หน้าต่างปาร์ตี้ (P): สมาชิก (สูงสุด 5 คน) ชวนเพื่อนด้วยชื่อหรือจากผู้เล่นใกล้ๆ ออก/เตะออก
## อยู่ปาร์ตี้แล้วฆ่าผีจะแชร์ EXP ให้เพื่อนในแผนที่เดียวกัน โบนัส +5% ต่อคน แล้วหารเท่ากัน

const Protocol = preload("res://shared/net/protocol.gd")
const Classes = preload("res://shared/data/classes.gd")
const World = preload("res://shared/data/world.gd")

signal request(what: String)  ## invite:<ชื่อ> / kick:<ชื่อ> / leave

var net: Node = null
var remotes: Node = null
var map_id := ""  ## แผนที่ที่เราอยู่ (นับคนแชร์ EXP)
var name_input: LineEdit


func _ready() -> void:
	setup("ปาร์ตี้", 520)


func current_map() -> String:
	return map_id


func _build() -> void:
	if net == null or not net.is_online():
		content.add_child(P.label("ต้องเชื่อมต่อเซิร์ฟเวอร์ก่อนถึงจะตั้งปาร์ตี้ได้", 15))
		content.add_child(P.label("(เข้าเกมด้วยไอดีหรือ Guest ตอนเซิร์ฟเวอร์เปิดอยู่)", 12, P.TEXT.lightened(0.25)))
		return
	var members: Array = net.party_members
	var same_map := 0
	for m in members:
		if m.get("map", "") == map_id:
			same_map += 1
	if members.size() >= 2:
		section("สมาชิก %d/%d · หัวหน้า: %s" % [members.size(), Protocol.MAX_PARTY, net.party_leader])
		content.add_child(P.label("ฆ่าผีแล้ว EXP +%d%% แบ่งเท่ากันให้ %d คนในแผนที่เดียวกัน" % [same_map * 5, same_map], 13, Color(0.35, 0.6, 0.4)))
		for m in members:
			var r := row()
			var info := VBoxContainer.new()
			info.add_theme_constant_override("separation", -2)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r.add_child(info)
			var crown := "♛ " if m.get("name", "") == net.party_leader else ""
			var cls: String = m.get("cls", "novice")
			info.add_child(P.label("%s%s  Lv %d" % [crown, m.get("name", ""), int(m.get("lv", 1))], 15))
			var where: String = str(m.get("map", ""))
			var map_label: String = World.map_name(where) if World.MAPS.has(where) or World.is_cave(where) else where
			info.add_child(P.label("%s · %s · HP %d/%d" % [Classes.CLASSES.get(cls, Classes.CLASSES["novice"])["name"], map_label, int(m.get("hp", 0)), int(m.get("mhp", 1))], 12, P.TEXT.lightened(0.2)))
			var them: String = m.get("name", "")
			if net.party_leader == net.my_name and them != net.my_name:
				var kick := P.button("เตะออก", Color(1.0, 0.82, 0.8), 12)
				kick.pressed.connect(func(): request.emit("kick:" + them))
				r.add_child(kick)
		var leave := P.button("ออกจากปาร์ตี้", P.PINK, 14)
		leave.pressed.connect(func(): request.emit("leave"))
		content.add_child(leave)
	else:
		content.add_child(P.label("ยังไม่มีปาร์ตี้ ชวนเพื่อนเพื่อตั้งปาร์ตี้ (คนชวนเป็นหัวหน้า)", 14))
		content.add_child(P.label("อยู่ปาร์ตี้: EXP +5% ต่อคน แล้วแบ่งเท่ากัน · ใช้สกิลบัฟ/ฮีลให้เพื่อนได้", 12, P.TEXT.lightened(0.2)))
	if members.size() < Protocol.MAX_PARTY and (members.size() < 2 or net.party_leader == net.my_name):
		section("ชวนเข้าปาร์ตี้")
		var r := row()
		name_input = P.line_edit("ชื่อผู้เล่น")
		name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(name_input)
		var b := P.button("ชวน", P.MINT, 14)
		b.pressed.connect(func():
			if name_input.text.strip_edges() != "":
				request.emit("invite:" + name_input.text.strip_edges()))
		r.add_child(b)
		if remotes != null and remotes.get_child_count() > 0:
			content.add_child(P.label("ผู้เล่นในแผนที่นี้", 13, P.PINK_DEEP))
			for rp in remotes.get_children().slice(0, 6):
				if rp.in_party:
					continue
				var rr := row()
				var l := P.label("%s  Lv %d" % [rp.player_name, rp.level], 14)
				l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				rr.add_child(l)
				var who: String = rp.player_name
				var ib := P.button("ชวน", P.MINT, 12)
				ib.pressed.connect(func(): request.emit("invite:" + who))
				rr.add_child(ib)
