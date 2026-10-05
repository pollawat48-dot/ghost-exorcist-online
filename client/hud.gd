extends CanvasLayer
## หน้าจอข้อมูลผู้เล่นแบบพาสเทลน่ารัก ใช้ได้ทั้ง PC และมือถือ
## ซ้ายบน: ชื่อ/เลเวล/HP/SP  กลางบน: ชื่อแผนที่+เวลา  ขวาบน: แผนที่ย่อ+กระเป๋า
## ล่างซ้าย: จอย  ล่างกลาง: แถบสกิล 1–0  ล่างขวา: ปุ่มโจมตี+สกิล

const ItemDB = preload("res://shared/data/items.gd")
const Progression = preload("res://shared/combat/progression.gd")
const P = preload("res://client/ui/palette.gd")
const TouchButton = preload("res://client/ui/touch_button.gd")
const VirtualStick = preload("res://client/ui/virtual_stick.gd")
const Minimap = preload("res://client/ui/minimap.gd")

signal action(name: String)  ## "attack", "holy_water", "herb"

const MAX_LOG_LINES := 5
const SLOT_ACTIONS := ["holy_water", "herb", "", "", "", "", "", "", "", ""]
const SLOT_KINDS := ["water", "herb", "", "", "", "", "", "", "", ""]
const SLOT_COLORS := [P.PINK, P.MINT, P.SKY, P.LEMON, P.MINT, P.SKY, P.PINK, P.PINK, P.LEMON, P.SKY]

var player: Node3D
var camera: Camera3D
var ghosts: Node
var overlay: Control
var title_label: Label
var info_label: Label
var bars: Control
var inv_label: Label
var log_label: Label
var location_label: Label
var phase_label: Label
var stick: Control
var minimap: Control
var slots: Array[Control] = []
var skill_water: Control
var skill_herb: Control
var attack_button: Control
var lines: Array[String] = []


func _ready() -> void:
	layer = 5
	overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.draw.connect(_draw_overhead)
	add_child(overlay)

	# จุดยึดตามขอบจอ เพื่อให้จอมือถือที่กว้างกว่า 16:9 วาง UI ชิดขอบได้ถูก
	var top_right := _anchor(1, 0)
	var top_center := _anchor(0.5, 0)
	var bottom_left := _anchor(0, 1)
	var bottom_center := _anchor(0.5, 1)
	var bottom_right := _anchor(1, 1)

	# ---- สถานะผู้เล่น ----
	var status := _panel(Vector2(14, 14), Vector2(300, 0))
	var head := HBoxContainer.new()
	status.add_child(head)
	var star := Label.new()
	star.text = "✦"
	star.add_theme_color_override("font_color", P.PINK_DEEP)
	head.add_child(star)
	title_label = _label(head, "", 20, P.TEXT)
	info_label = _label(status, "", 14, P.TEXT.lightened(0.2))
	bars = Control.new()
	bars.custom_minimum_size = Vector2(300, 66)
	bars.draw.connect(_draw_status_bars)
	status.add_child(bars)

	# ---- ชื่อแผนที่ + ช่วงเวลา ----
	var pill := PanelContainer.new()
	var pill_style := P.panel_style(22)
	pill_style.content_margin_left = 22
	pill_style.content_margin_right = 22
	pill_style.content_margin_top = 4
	pill_style.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", pill_style)
	var pill_box := VBoxContainer.new()
	pill_box.add_theme_constant_override("separation", -4)
	pill.add_child(pill_box)
	location_label = _label(pill_box, "", 17, P.TEXT)
	location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label = _label(pill_box, "", 13, P.TEXT.lightened(0.25))
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_center.add_child(pill)
	pill.resized.connect(func(): pill.position = Vector2(-pill.size.x / 2.0, 12))

	# ---- แผนที่ย่อ + กระเป๋า ----
	minimap = Minimap.new()
	minimap.position = Vector2(-234, 14)
	minimap.size = Vector2(220, 142)
	top_right.add_child(minimap)
	var inv := _panel(Vector2(-234, 166), Vector2(220, 0), 14, top_right)
	inv_label = _label(inv, "", 13, P.TEXT)

	# ---- ข้อความเกม ----
	var log_panel := PanelContainer.new()
	log_panel.add_theme_stylebox_override("panel", P.panel_style(14, Color(1, 0.97, 0.94, 0.7), Color(P.LAVENDER, 0.6)))
	log_panel.position = Vector2(14, 214)
	add_child(log_panel)
	log_label = _label(log_panel, "", 13, P.TEXT)
	log_label.custom_minimum_size = Vector2(330, 104)
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# ---- จอย ----
	stick = VirtualStick.new()
	stick.position = Vector2(42, -214)
	stick.size = Vector2(172, 172)
	bottom_left.add_child(stick)

	# ---- แถบสกิล 1–0 ----
	var slot_size := 54.0
	var gap := 6.0
	var bar_w := slot_size * 10 + gap * 9
	var bar_bg := Panel.new()
	var bar_style := P.panel_style(18)
	bar_bg.add_theme_stylebox_override("panel", bar_style)
	bar_bg.position = Vector2(-bar_w / 2.0 - 10, -slot_size - 26)
	bar_bg.size = Vector2(bar_w + 20, slot_size + 18)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_center.add_child(bar_bg)
	for i in 10:
		var b := TouchButton.new()
		b.round = false
		b.kind = SLOT_KINDS[i]
		b.fill = SLOT_COLORS[i]
		b.hotkey = str((i + 1) % 10)
		b.position = Vector2(-bar_w / 2.0 + i * (slot_size + gap), -slot_size - 17)
		b.size = Vector2(slot_size, slot_size)
		var act: String = SLOT_ACTIONS[i]
		if act != "":
			b.pressed.connect(func(): action.emit(act))
		bottom_center.add_child(b)
		slots.append(b)
	var help := _label(bottom_center, "คลิก/แตะ: เดิน · คลิกผี: ตี · ลากเมาส์ขวา: หมุนกล้อง · WASD/จอย: เดิน · 1–2/Q: สกิล", 12, P.TEXT)
	help.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	help.add_theme_constant_override("outline_size", 5)
	help.position = Vector2(-bar_w / 2.0, -slot_size - 50)

	# ---- ปุ่มโจมตี + สกิล (มุมขวาล่าง) ----
	attack_button = _round_button(bottom_right, "sword", P.PINK, Vector2(-156, -168), 132, "attack")
	skill_water = _round_button(bottom_right, "water", P.SKY, Vector2(-262, -104), 80, "holy_water")
	skill_herb = _round_button(bottom_right, "herb", P.MINT, Vector2(-222, -250), 80, "herb")


func _anchor(ax: float, ay: float) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.anchor_left = ax
	c.anchor_right = ax
	c.anchor_top = ay
	c.anchor_bottom = ay
	add_child(c)
	return c


func _round_button(parent: Control, kind: String, fill: Color, pos: Vector2, d: float, act: String) -> Control:
	var b := TouchButton.new()
	b.kind = kind
	b.fill = fill
	b.position = pos
	b.size = Vector2(d, d)
	b.pressed.connect(func(): action.emit(act))
	parent.add_child(b)
	return b


func track(cam: Camera3D, ghost_root: Node) -> void:
	camera = cam
	ghosts = ghost_root


func setup_minimap(map: Node3D) -> void:
	minimap.setup(map, player, ghosts)


func _process(_delta: float) -> void:
	overlay.queue_redraw()
	if player == null:
		return
	var cd: float = player.skill_cooldown / player.SKILL_COOLDOWN
	for b in [slots[0], skill_water]:
		if not is_equal_approx(b.cooldown, cd):
			b.cooldown = cd
			b.queue_redraw()


## หลอด HP ใต้เท้าผู้เล่น (สีเขียวแบบ RO) และใต้ผีที่โดนตี
func _draw_overhead() -> void:
	if camera == null or player == null:
		return
	_foot_bar(player.global_position, float(player.hp) / player.stats["max_hp"], 60.0, P.HP if player.hp * 3 > player.stats["max_hp"] else P.HP_LOW)
	for g in ghosts.get_children():
		if not g.has_method("take_damage") or not g.alive or g.hp >= g.data["hp"]:
			continue
		_foot_bar(g.global_position + Vector3(0, 0.45, 0), float(g.hp) / g.data["hp"], 50.0, P.HP_LOW)


func _foot_bar(p3: Vector3, ratio: float, w: float, color: Color) -> void:
	if camera.is_position_behind(p3):
		return
	var p := camera.unproject_position(p3)
	P.draw_round_bar(overlay, Rect2(p.x - w / 2.0, p.y + 10, w, 11), ratio, color)


func _draw_status_bars() -> void:
	if player == null:
		return
	var s: Dictionary = player.stats
	var font := bars.get_theme_default_font()
	var rows := [["HP", player.hp, s["max_hp"], P.HP if player.hp * 3 > s["max_hp"] else P.HP_LOW], ["SP", player.sp, s["max_sp"], P.SP]]
	for i in rows.size():
		var y := 4.0 + i * 24.0
		var row: Array = rows[i]
		bars.draw_string(font, Vector2(0, y + 15), row[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, P.TEXT)
		P.draw_round_bar(bars, Rect2(32, y, 268, 18), float(row[1]) / float(row[2]), row[3])
		var t := "%d / %d" % [row[1], row[2]]
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		var tp := Vector2(32 + (268 - tw) / 2.0, y + 14)
		bars.draw_string_outline(font, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(1, 1, 1, 0.9))
		bars.draw_string(font, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, P.TEXT)
	var need := Progression.exp_to_next(player.state["level"])
	P.draw_round_bar(bars, Rect2(32, 54, 268, 10), float(player.state["exp"]) / need, P.EXP)
	bars.draw_string(font, Vector2(0, 64), "EXP", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, P.TEXT)


func bind(p: Node3D) -> void:
	player = p
	player.changed.connect(refresh)
	player.message.connect(add_log)
	refresh()


func refresh() -> void:
	var level: int = player.state["level"]
	var need := Progression.exp_to_next(level)
	title_label.text = player.player_name
	info_label.text = "Lv %d  ·  สำนัก: ศิษย์วัด  ·  Exp %.1f%%" % [level, 100.0 * player.state["exp"] / need]
	bars.queue_redraw()
	var herbs: int = player.inventory.get(player.HERB_ITEM, 0)
	for b in [slots[1], skill_herb]:
		b.count = herbs
		b.queue_redraw()
	var text := "กระเป๋า"
	for item_id in player.inventory:
		text += "\n· %s x%d" % [ItemDB.ITEMS[item_id]["name"], player.inventory[item_id]]
	inv_label.text = text


func set_location(country: String, map_name: String) -> void:
	location_label.text = "%s · %s" % [country, map_name]


func set_phase(text: String) -> void:
	phase_label.text = text


func add_log(text: String) -> void:
	lines.append(text)
	if lines.size() > MAX_LOG_LINES:
		lines.pop_front()
	log_label.text = "\n".join(lines)


func _panel(pos: Vector2, min_size: Vector2, radius: int = 18, parent: Node = self) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.add_theme_stylebox_override("panel", P.panel_style(radius))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.custom_minimum_size = min_size
	panel.add_child(box)
	return box


func _label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l
