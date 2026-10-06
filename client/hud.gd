extends CanvasLayer
## หน้าจอข้อมูลผู้เล่นแบบพาสเทลน่ารัก ใช้ได้ทั้ง PC และมือถือ
## ซ้ายบน: ชื่อ/เลเวล/HP/SP  กลางบน: ชื่อแผนที่+เวลา+ประกาศ+หลอดบอส  ขวาบน: แผนที่ย่อ+ปุ่มเมนู
## ล่างซ้าย: จอย  ล่างกลาง: แถบสกิล 1–8 + ยามานา (9) + ยาเลือด (0)  ล่างขวา: ปุ่มโจมตี+สกิล+ยา+ออโต้
## ซ้าย: ข้อความเกม + รายการเควสที่กำลังทำ
## หน้าต่าง: ตัวละคร (C), สกิล (K), กระเป๋า (I), เควส (J), ออโต้, เลื่อนขั้นคลาส, ร้านค้า, เควสจาก NPC

const ItemDB = preload("res://shared/data/items.gd")
const Progression = preload("res://shared/combat/progression.gd")
const P = preload("res://client/ui/palette.gd")
const TouchButton = preload("res://client/ui/touch_button.gd")
const VirtualStick = preload("res://client/ui/virtual_stick.gd")
const Minimap = preload("res://client/ui/minimap.gd")
const Skills = preload("res://shared/data/skills.gd")
const CharWindow = preload("res://client/ui/char_window.gd")
const SkillWindow = preload("res://client/ui/skill_window.gd")
const BagWindow = preload("res://client/ui/bag_window.gd")
const ClassWindow = preload("res://client/ui/class_window.gd")
const ShopWindow = preload("res://client/ui/shop_window.gd")
const QuestWindow = preload("res://client/ui/quest_window.gd")
const AutoWindow = preload("res://client/ui/auto_window.gd")
const WarpWindow = preload("res://client/ui/warp_window.gd")
const SmithWindow = preload("res://client/ui/smith_window.gd")
const RefineWindow = preload("res://client/ui/refine_window.gd")
const Quests = preload("res://shared/data/quests.gd")
const ChatBox = preload("res://client/ui/chat_box.gd")
const PartyWindow = preload("res://client/ui/party_window.gd")
const SettingsWindow = preload("res://client/ui/settings_window.gd")
const Sound = preload("res://client/audio/sound.gd")

signal action(name: String)  ## "attack", "potion_hp", "potion_sp", "auto", "fish", "logout", "skill:<id>", "warp:<map>"
signal chat_sent(ch: String, text: String, to: String)
signal party_request(what: String)  ## invite:<ชื่อ> / kick:<ชื่อ> / leave / accept:<ชื่อ> / decline:<ชื่อ>

const MAX_LOG_LINES := 5
const ANNOUNCE_TIME := 7.0
const SLOT_COLORS := [P.PINK, P.MINT, P.SKY, P.LEMON, P.MINT, P.SKY, P.PINK, P.PINK, P.LEMON, P.SKY]

var player: Node3D
var camera: Camera3D
var ghosts: Node
var overlay: Control
var title_label: Label
var info_label: Label
var bars: Control
var menu_buttons := {}
var windows := {}
var announce_panel: PanelContainer
var announce_label: Label
var announce_timer := 0.0
var slot_actions: Array[String] = []
var log_label: Label
var location_label: Label
var phase_label: Label
var stick: Control
var minimap: Control
var slots: Array[Control] = []
var bubble_a: Control
var bubble_b: Control
var skill_herb: Control
var skill_sp: Control
var auto_button: Control
var auto_play: RefCounted
var coin_label: Label
var quest_panel: PanelContainer
var quest_label: Label
var attack_button: Control
var lines: Array[String] = []
var chat: PanelContainer
var buff_label: Label
var fish_button: Control
var party_frame: Control
var invite_panel: PanelContainer
var invite_label: Label
var invite_from := ""
var invite_timer := 0.0
var player_menu: PanelContainer
var player_menu_name := ""
var dialog: PanelContainer
var dialog_label: Label
var net: Node = null
var remotes: Node = null


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
	coin_label = _label(status, "", 14, Color(0.78, 0.55, 0.15))
	buff_label = _label(status, "", 12, Color(0.85, 0.45, 0.25))
	buff_label.visible = false
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
	var menus := [["char", "user", "ตัวละคร", P.PINK], ["skills", "book", "สกิล", P.SKY], ["bag", "bag", "กระเป๋า", P.LEMON], ["questlog", "scroll", "เควส", P.MINT],
		["party", "party", "ปาร์ตี้", P.PINK.lightened(0.2)], ["auto", "auto", "ออโต้", P.LAVENDER.lightened(0.3)], ["settings", "gear", "ตั้งค่า", Color(0.9, 0.88, 0.95)]]
	for i in menus.size():
		var m: Array = menus[i]
		var b := TouchButton.new()
		b.kind = m[1]
		b.fill = m[3]
		b.caption = m[2]
		b.position = Vector2(-402 + i * 56, 166)
		b.size = Vector2(50, 50)
		var key: String = m[0]
		b.pressed.connect(func(): toggle_window(key))
		top_right.add_child(b)
		menu_buttons[key] = b

	# ---- ประกาศ (บอสเกิด ฯลฯ) ----
	announce_panel = PanelContainer.new()
	var ann_style := P.panel_style(20, Color(1.0, 0.93, 0.95, 0.96), P.PINK_DEEP)
	ann_style.content_margin_left = 18
	ann_style.content_margin_right = 18
	announce_panel.add_theme_stylebox_override("panel", ann_style)
	announce_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ann_row := HBoxContainer.new()
	announce_panel.add_child(ann_row)
	var crown := Control.new()
	crown.custom_minimum_size = Vector2(30, 30)
	crown.draw.connect(func(): P.draw_icon(crown, "crown", crown.size / 2.0, 30))
	ann_row.add_child(crown)
	announce_label = _label(ann_row, "", 17, P.TEXT)
	announce_panel.visible = false
	top_center.add_child(announce_panel)
	announce_panel.resized.connect(func(): announce_panel.position = Vector2(-announce_panel.size.x / 2.0, 72))

	# ---- แชท + ข้อความเกม ----
	chat = ChatBox.new()
	chat.position = Vector2(14, 214)
	add_child(chat)
	chat.sent.connect(func(ch: String, text: String, to: String): chat_sent.emit(ch, text, to))
	log_label = Label.new()  # ข้อความเกมล่าสุด (ไว้ทดสอบ/โค้ดเก่า) ไม่ได้แสดง

	# ---- เควสที่กำลังทำ ----
	quest_panel = PanelContainer.new()
	quest_panel.add_theme_stylebox_override("panel", P.panel_style(14, Color(0.94, 1.0, 0.96, 0.78), Color(P.MINT.darkened(0.2), 0.8)))
	quest_panel.position = Vector2(14, 418)
	quest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(quest_panel)
	quest_label = _label(quest_panel, "", 13, P.TEXT)
	quest_label.custom_minimum_size = Vector2(250, 0)
	quest_panel.visible = false

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
		b.fill = SLOT_COLORS[i]
		b.hotkey = str((i + 1) % 10)
		b.position = Vector2(-bar_w / 2.0 + i * (slot_size + gap), -slot_size - 17)
		b.size = Vector2(slot_size, slot_size)
		b.pressed.connect(press_slot.bind(i))
		bottom_center.add_child(b)
		slots.append(b)
		slot_actions.append("")
	var help := _label(bottom_center, "คลิก: เดิน/ตี/คุย NPC · WASD: เดิน · 1–8 สกิล · 0/Q ยาเลือด · 9/E ยามานา · V ออโต้ · F คุย · C K I J หน้าต่าง", 12, P.TEXT)
	help.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.9))
	help.add_theme_constant_override("outline_size", 5)
	help.position = Vector2(-bar_w / 2.0, -slot_size - 50)

	# ---- ปุ่มโจมตี + สกิล (มุมขวาล่าง) ----
	attack_button = _round_button(bottom_right, "sword", P.PINK, Vector2(-156, -168), 132, "attack")
	bubble_a = _round_button(bottom_right, "", P.SKY, Vector2(-262, -104), 80, "")
	bubble_a.pressed.connect(press_slot.bind(0))
	bubble_b = _round_button(bottom_right, "", P.LEMON, Vector2(-232, -238), 80, "")
	bubble_b.pressed.connect(press_slot.bind(1))
	skill_herb = _round_button(bottom_right, "herb", P.MINT, Vector2(-120, -262), 70, "potion_hp")
	skill_sp = _round_button(bottom_right, "water", P.SKY, Vector2(-104, -338), 62, "potion_sp")
	auto_button = _round_button(bottom_right, "auto", P.LAVENDER.lightened(0.35), Vector2(-216, -336), 74, "auto")
	auto_button.caption = "ออโต้"
	fish_button = _round_button(bottom_right, "fish", P.SKY.lightened(0.2), Vector2(-330, -200), 70, "fish")
	fish_button.caption = "ตกปลา"
	fish_button.visible = false

	# ---- ปาร์ตี้ (ใต้ปุ่มเมนูขวาบน) ----
	party_frame = Control.new()
	party_frame.position = Vector2(-234, 238)
	party_frame.size = Vector2(220, 0)
	party_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	party_frame.draw.connect(_draw_party_frame)
	top_right.add_child(party_frame)

	# ---- คำชวนเข้าปาร์ตี้ / เมนูผู้เล่น / กล่องแจ้งเตือน ----
	invite_panel = _popup(top_center, Color(0.95, 1.0, 0.96, 0.97), P.MINT.darkened(0.25))
	var inv_box: VBoxContainer = invite_panel.get_child(0)
	invite_label = _label(inv_box, "", 16, P.TEXT)
	var inv_row := HBoxContainer.new()
	inv_row.alignment = BoxContainer.ALIGNMENT_CENTER
	inv_row.add_theme_constant_override("separation", 12)
	inv_box.add_child(inv_row)
	var yes := P.button("เข้าร่วม", P.MINT, 15)
	yes.pressed.connect(func(): _answer_invite(true))
	inv_row.add_child(yes)
	var no := P.button("ปฏิเสธ", P.PINK, 15)
	no.pressed.connect(func(): _answer_invite(false))
	inv_row.add_child(no)
	invite_panel.resized.connect(func(): invite_panel.position = Vector2(-invite_panel.size.x / 2.0, 130))

	player_menu = _popup(self, P.CREAM, P.LAVENDER)
	var pm_box: VBoxContainer = player_menu.get_child(0)
	var pm_title := _label(pm_box, "", 15, P.PINK_DEEP)
	pm_title.name = "Title"
	for entry in [["กระซิบ", P.SKY, "whisper"], ["ชวนเข้าปาร์ตี้", P.MINT, "invite"], ["ปิด", Color(1, 1, 1, 0.9), "close"]]:
		var b := P.button(entry[0], entry[1], 14)
		var what: String = entry[2]
		b.pressed.connect(func(): _player_menu_pick(what))
		pm_box.add_child(b)

	dialog = _popup(self, Color(1.0, 0.95, 0.96, 0.98), P.PINK_DEEP)
	dialog.set_anchors_preset(Control.PRESET_CENTER)
	var dlg_box: VBoxContainer = dialog.get_child(0)
	dialog_label = _label(dlg_box, "", 17, P.TEXT)
	dialog_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var dlg_row := HBoxContainer.new()
	dlg_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dlg_row.add_theme_constant_override("separation", 12)
	dlg_box.add_child(dlg_row)
	var back := P.button("กลับหน้าเมนู", P.PINK, 15)
	back.pressed.connect(func(): action.emit("logout"))
	dlg_row.add_child(back)
	var stay := P.button("เล่นต่อแบบออฟไลน์", P.SKY, 15)
	stay.pressed.connect(func(): dialog.visible = false)
	dlg_row.add_child(stay)

	# ---- หน้าต่างเมนู ----
	var kinds := {"char": CharWindow, "skills": SkillWindow, "bag": BagWindow, "class": ClassWindow,
		"shop": ShopWindow, "quest": QuestWindow, "questlog": QuestWindow, "auto": AutoWindow,
		"warp": WarpWindow, "smith": SmithWindow, "refine": RefineWindow, "party": PartyWindow, "settings": SettingsWindow}
	for key in kinds:
		var w: Control = kinds[key].new()
		add_child(w)
		windows[key] = w
	windows["char"].open_class_change.connect(func(): toggle_window("class"))
	windows["auto"].toggle_requested.connect(func(): action.emit("auto"))
	windows["warp"].warp_requested.connect(func(id: String): action.emit("warp:" + id))
	windows["smith"].open_refine_requested.connect(func(): open_refine(""))
	windows["party"].request.connect(func(what: String): party_request.emit(what))
	windows["settings"].logout_requested.connect(func(): action.emit("logout"))


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
	if act != "":
		b.pressed.connect(func(): action.emit(act))
	parent.add_child(b)
	return b


## กดช่องแถบสกิล (คีย์ 1–9/0, แตะช่อง หรือแตะปุ่มกลมสกิล)
func press_slot(i: int) -> void:
	if i < slot_actions.size() and slot_actions[i] != "":
		action.emit(slot_actions[i])


## เปิดหน้าต่างของ NPC ที่คุยด้วย (ร้านค้า หรือรายการเควส)
func open_npc(npc: Dictionary) -> void:
	close_windows()
	var w: Control = windows[{"shop": "shop", "class": "class", "warp": "warp", "smith": "smith"}.get(npc["role"], "quest")]
	w.open_for(npc)


## กดใช้หินตี+ (หรือปุ่มที่ร้านหลอม): เปิดหน้าต่างตีบวก
func open_refine(stone_id: String) -> void:
	close_windows()
	windows["refine"].open_with(stone_id)


func set_map_id(map_id: String) -> void:
	windows["warp"].current_map = map_id


func bind_auto(a: RefCounted) -> void:
	auto_play = a
	windows["auto"].auto_play = a
	refresh_auto()


func refresh_auto() -> void:
	if auto_play == null:
		return
	auto_button.lit = auto_play.enabled
	auto_button.caption = "ออโต้: เปิด" if auto_play.enabled else "ออโต้"
	auto_button.queue_redraw()
	if windows["auto"].visible:
		windows["auto"].refresh()


func toggle_window(key: String) -> void:
	var w: Control = windows[key]
	if w.visible:
		w.hide_window()
	else:
		close_windows()
		w.show_window()
		Sound.play(self, "open")


func close_windows() -> void:
	for w in windows.values():
		if w.visible:
			w.hide_window()


func any_window_open() -> bool:
	for w in windows.values():
		if w.visible:
			return true
	return false


## ประกาศตัวใหญ่กลางจอด้านบน (บอสเกิด/ถูกปราบ) และลงบันทึกด้วย
func announce(text: String) -> void:
	announce_label.text = text
	announce_panel.visible = true
	announce_panel.reset_size()
	announce_timer = ANNOUNCE_TIME
	add_log("[ประกาศ] " + text)


## จัดสกิลที่เรียนแล้วลงแถบ 1–8 ช่อง 9 เป็นยามานา ช่อง 0 เป็นยาเลือดเสมอ
func _refresh_hotbar() -> void:
	var learned: Array[String] = player.learned_skills()
	for i in 10:
		var b: Control = slots[i]
		if i == 9:
			slot_actions[i] = "potion_hp"
			b.kind = "herb"
			b.count = player.potion_count("hp")
		elif i == 8:
			slot_actions[i] = "potion_sp"
			b.kind = "water"
			b.count = player.potion_count("sp")
		elif i < learned.size():
			slot_actions[i] = "skill:" + learned[i]
			b.kind = Skills.SKILLS[learned[i]]["icon"]
			b.count = -1
		else:
			slot_actions[i] = ""
			b.kind = ""
			b.count = -1
		b.queue_redraw()
	for pair in [[bubble_a, 0], [bubble_b, 1]]:
		var bubble: Control = pair[0]
		var idx: int = pair[1]
		bubble.visible = idx < learned.size()
		if bubble.visible:
			bubble.kind = Skills.SKILLS[learned[idx]]["icon"]
			bubble.queue_redraw()
	skill_herb.count = player.potion_count("hp")
	skill_herb.queue_redraw()
	skill_sp.count = player.potion_count("sp")
	skill_sp.queue_redraw()
	var st: Dictionary = player.state
	_set_badge("char", st["stat_points"] > 0 or player.can_change_class())
	_set_badge("skills", st["skill_points"] > 0)


func _set_badge(key: String, on: bool) -> void:
	var b: Control = menu_buttons[key]
	if b.badge != on:
		b.badge = on
		b.queue_redraw()


func track(cam: Camera3D, ghost_root: Node) -> void:
	camera = cam
	ghosts = ghost_root


func setup_minimap(map: Node3D, npc_root: Node = null, portal_root: Node = null, remote_root: Node = null) -> void:
	remotes = remote_root
	windows["party"].remotes = remote_root
	windows["party"].map_id = map.map_id
	minimap.setup(map, player, ghosts, npc_root, portal_root, remote_root)
	party_frame.queue_redraw()


func _process(delta: float) -> void:
	overlay.queue_redraw()
	if invite_timer > 0.0:
		invite_timer -= delta
		if invite_timer <= 0.0:
			_answer_invite(false)
	if player != null and not player.buffs.is_empty():
		_refresh_buffs()
	if player != null and fish_button.visible and fish_button.lit != player.fishing:
		refresh_fishing()
	if announce_timer > 0.0:
		announce_timer -= delta
		announce_panel.modulate.a = clampf(announce_timer, 0.0, 1.0)
		if announce_timer <= 0.0:
			announce_panel.visible = false
	if player == null:
		return
	for i in 9:
		if slot_actions[i].begins_with("skill:"):
			var cd: float = player.skill_cooldown_ratio(slot_actions[i].substr(6))
			for b in ([slots[i], bubble_a] if i == 0 else ([slots[i], bubble_b] if i == 1 else [slots[i]])):
				if not is_equal_approx(b.cooldown, cd):
					b.cooldown = cd
					b.queue_redraw()


## หลอด HP ใต้เท้าผู้เล่น (สีเขียวแบบ RO) และใต้ผีที่โดนตี
func _draw_overhead() -> void:
	if camera == null or player == null:
		return
	_foot_bar(player.global_position, float(player.hp) / player.stats["max_hp"], 60.0, P.HP if player.hp * 3 > player.stats["max_hp"] else P.HP_LOW)
	_draw_fishing()
	if remotes != null:
		for r in remotes.get_children():
			if r.in_party:
				_foot_bar(r.global_position, float(r.hp) / maxf(1.0, r.max_hp), 50.0, P.HP)
	for g in ghosts.get_children():
		if not g.has_method("take_damage") or not g.alive:
			continue
		if g.is_boss():
			_draw_boss_bar(g)
		if g.hp >= g.data["hp"]:
			continue
		_foot_bar(g.global_position + Vector3(0, 0.45, 0), float(g.hp) / g.data["hp"], 90.0 if g.is_boss() else 50.0, P.HP_LOW)


## หลอดเลือดบอสใหญ่ด้านบนจอ เมื่อผู้เล่นอยู่ใกล้บอส
func _draw_boss_bar(g: Node3D) -> void:
	if player.pos.distance_to(g.pos) > 700.0:
		return
	var w := 420.0
	var x := (overlay.size.x - w) / 2.0
	var y := 92.0 if not announce_panel.visible else 150.0
	var font := overlay.get_theme_default_font()
	var title := "%s  %d / %d" % [g.data["name"], maxi(0, g.hp), g.data["hp"]]
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	overlay.draw_string_outline(font, Vector2((overlay.size.x - tw) / 2.0, y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 5, Color.WHITE)
	overlay.draw_string(font, Vector2((overlay.size.x - tw) / 2.0, y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, P.PINK_DEEP)
	P.draw_round_bar(overlay, Rect2(x, y + 6, w, 16), float(g.hp) / g.data["hp"], P.HP_LOW)


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
	for w in windows.values():
		w.bind(p)
	refresh()


func refresh() -> void:
	var level: int = player.state["level"]
	var need := Progression.exp_to_next(level)
	title_label.text = player.player_name
	info_label.text = "Lv %d  ·  %s  ·  Exp %.1f%%" % [level, player.class_info()["name"], 100.0 * player.state["exp"] / need]
	coin_label.text = "เหรียญ %s" % _commas(player.coins())
	_refresh_buffs()
	bars.queue_redraw()
	_refresh_hotbar()
	_refresh_quests()


## บัฟที่ติดตัวอยู่ เช่น "ปลุกพลังกล้า ATK +30% 45 วิ"
func _refresh_buffs() -> void:
	var parts: Array[String] = []
	for effect in player.buffs:
		parts.append("✦ %s %s %d วิ" % [player.buffs[effect]["name"], player.buff_text(effect), ceili(player.buffs[effect]["time"])])
	var text := "  ".join(parts)
	buff_label.visible = text != ""
	if buff_label.text != text:
		buff_label.text = text


func _refresh_quests() -> void:
	var rows: Array[String] = []
	for id in player.active_quests():
		var mark := "★ " if player.quest_status(id) == "ready" else "- "
		rows.append(mark + Quests.goal_text(player.state, player.inventory, id))
	quest_panel.visible = not rows.is_empty()
	quest_label.text = "เควส\n" + "\n".join(rows.slice(0, 4))
	quest_panel.reset_size()


static func _commas(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out


func set_location(country: String, map_name: String) -> void:
	location_label.text = "%s · %s" % [country, map_name]


func set_phase(text: String) -> void:
	phase_label.text = text


func add_log(text: String) -> void:
	lines.append(text)
	if lines.size() > MAX_LOG_LINES:
		lines.pop_front()
	log_label.text = "\n".join(lines)
	chat.add("system", "", "", text)


## ข้อความแชทจากเซิร์ฟเวอร์ (หรือข้อความระบบ ch = "system")
func add_chat(ch: String, from: String, to: String, text: String) -> void:
	chat.add(ch, from, to, text)
	if ch == "whisper" and from != chat.me:
		Sound.play(self, "whisper")
	elif ch in ["world", "party"]:
		Sound.play(self, "chat")


func typing() -> bool:
	return chat.is_typing()


func focus_chat() -> void:
	chat.focus_input()


func bind_net(n: Node) -> void:
	net = n
	windows["party"].net = n
	if n != null:
		chat.me = n.my_name


# ---------- ปาร์ตี้ ----------

func refresh_party() -> void:
	var count: int = net.party_members.size() if net != null and net.in_party() else 0
	party_frame.size.y = 0 if count == 0 else 26 + count * 34
	party_frame.queue_redraw()
	if windows["party"].visible:
		windows["party"].refresh()


func _draw_party_frame() -> void:
	if net == null or not net.in_party():
		return
	var font := party_frame.get_theme_default_font()
	var rect := Rect2(Vector2.ZERO, party_frame.size)
	party_frame.draw_style_box(P.panel_style(14, Color(1, 0.97, 0.98, 0.85), Color(P.PINK, 0.9)), rect)
	party_frame.draw_string(font, Vector2(12, 19), "ปาร์ตี้ (%d/5)" % net.party_members.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, P.PINK_DEEP)
	var y := 26.0
	for m in net.party_members:
		var lead := "♛ " if m.get("name", "") == net.party_leader else ""
		var away := "" if m.get("map", "") == windows["party"].current_map() else " (ต่างแผนที่)"
		party_frame.draw_string(font, Vector2(12, y + 13), "%s%s Lv%d%s" % [lead, m.get("name", ""), int(m.get("lv", 1)), away], HORIZONTAL_ALIGNMENT_LEFT, 200, 12, P.TEXT)
		P.draw_round_bar(party_frame, Rect2(12, y + 17, 196, 9), float(m.get("hp", 0)) / maxf(1.0, float(m.get("mhp", 1))), P.HP)
		y += 34.0


func show_invite(from: String) -> void:
	invite_from = from
	invite_label.text = "%s ชวนคุณเข้าปาร์ตี้" % from
	invite_panel.visible = true
	invite_panel.reset_size()
	invite_timer = 30.0
	Sound.play(self, "party")


func _answer_invite(accept: bool) -> void:
	invite_panel.visible = false
	if invite_from != "":
		party_request.emit(("accept:" if accept else "decline:") + invite_from)
	invite_from = ""


## คลิกตัวละครผู้เล่นอื่น: เมนูกระซิบ/ชวนปาร์ตี้
func show_player_menu(name_: String, at: Vector2) -> void:
	player_menu_name = name_
	player_menu.get_child(0).get_node("Title").text = name_
	player_menu.visible = true
	player_menu.reset_size()
	var view := overlay.size
	player_menu.position = Vector2(clampf(at.x + 12, 0, view.x - player_menu.size.x), clampf(at.y - 20, 0, view.y - player_menu.size.y))


func _player_menu_pick(what: String) -> void:
	player_menu.visible = false
	match what:
		"whisper":
			chat.whisper_to(player_menu_name)
		"invite":
			party_request.emit("invite:" + player_menu_name)


func show_disconnected() -> void:
	dialog_label.text = "หลุดการเชื่อมต่อกับเซิร์ฟเวอร์\nความคืบหน้าบันทึกไว้ถึงครั้งล่าสุดแล้ว"
	dialog.visible = true
	dialog.reset_size()
	dialog.position = ((overlay.size - dialog.size) / 2.0).floor()


func _popup(parent: Node, bg: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var st := P.panel_style(18, bg, border)
	st.content_margin_left = 18
	st.content_margin_right = 18
	panel.add_theme_stylebox_override("panel", st)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	panel.visible = false
	parent.add_child(panel)
	return panel


# ---------- ตกปลา ----------

func set_fishing_map(on: bool) -> void:
	fish_button.visible = on


func refresh_fishing() -> void:
	fish_button.lit = player.fishing
	fish_button.queue_redraw()


## หลอดรอปลากินเบ็ดเหนือหัวผู้เล่น
func _draw_fishing() -> void:
	if not player.fishing or camera.is_position_behind(player.global_position + Vector3(0, 2.6, 0)):
		return
	var p := camera.unproject_position(player.global_position + Vector3(0, 2.6, 0))
	var font := overlay.get_theme_default_font()
	var text := "ตกปลา... (ได้แล้ว %d)" % player.fish_count
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	overlay.draw_string_outline(font, p + Vector2(-tw / 2.0, -14), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 5, Color.WHITE)
	overlay.draw_string(font, p + Vector2(-tw / 2.0, -14), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.3, 0.5, 0.75))
	P.draw_round_bar(overlay, Rect2(p.x - 45, p.y - 8, 90, 10), player.fish_timer / player.fish_time(), P.SKY)


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
