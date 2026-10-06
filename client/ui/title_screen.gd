extends Control
## หน้าเมนูเข้าเกม: เข้าสู่ระบบ / สมัครไอดี / เล่นแบบ Guest → เลือกตัวละคร / สร้างตัวละคร
## เป็นแค่หน้าตา: ส่งคำขอออกทาง signal ให้ App จัดการกับเซิร์ฟเวอร์หรือที่เก็บในเครื่อง

const P = preload("res://client/ui/palette.gd")
const Classes = preload("res://shared/data/classes.gd")
const Protocol = preload("res://shared/net/protocol.gd")
const Sound = preload("res://client/audio/sound.gd")

signal login_requested(user: String, pw: String)
signal register_requested(user: String, pw: String)
signal guest_requested
signal server_changed(host: String, port: int)
signal char_selected(name: String)
signal char_create_requested(name: String, look: Dictionary)
signal char_delete_requested(name: String)
signal preview_changed(look: Dictionary)  ## หน้าสร้างตัวละคร: เปลี่ยนหน้าตาตัวอย่าง
signal back_requested  ## ออกจากหน้าเลือกตัวละครกลับหน้าเข้าสู่ระบบ

const HAIR_COLORS := [Color(0.36, 0.25, 0.24), Color(0.16, 0.14, 0.18), Color(0.62, 0.36, 0.22), Color(1.0, 0.68, 0.78), Color(0.8, 0.76, 0.95)]
const SKIN_COLORS := [Color(1.0, 0.86, 0.74), Color(0.9, 0.72, 0.56), Color(0.98, 0.78, 0.66)]

var page := ""
var panel: PanelContainer
var body: VBoxContainer
var status_label: Label
var logo: Control
var host := "127.0.0.1"
var port := Protocol.DEFAULT_PORT
var chars: Array = []
var mode_text := ""  ## "ออนไลน์: ไอดี xxx" / "Guest ออฟไลน์" ฯลฯ
var look := {"gender": "m", "hair": 0, "skin": 0}
var delete_armed := ""
var _user: LineEdit
var _pw: LineEdit
var _pw2: LineEdit
var _name: LineEdit


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo = Control.new()
	logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.draw.connect(_draw_logo)
	add_child(logo)
	var anchor := Control.new()
	anchor.anchor_left = 1.0
	anchor.anchor_right = 1.0
	anchor.anchor_top = 0.5
	anchor.anchor_bottom = 0.5
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)
	panel = PanelContainer.new()
	var st := P.panel_style(26, Color(1.0, 0.97, 0.94, 0.94), P.LAVENDER)
	st.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", st)
	anchor.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.custom_minimum_size.x = 400
	panel.add_child(root)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 9)
	root.add_child(body)
	status_label = P.label("", 14, P.PINK_DEEP)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.x = 400
	root.add_child(status_label)
	panel.resized.connect(_place_panel)
	show_login()


func _place_panel() -> void:
	var view := get_viewport_rect().size
	var x := -panel.size.x - maxf(40.0, view.x * 0.06)
	if view.x < 900.0:
		x = -panel.size.x / 2.0 - view.x / 2.0  # จอแคบ: วางกลาง
	panel.position = Vector2(x, -panel.size.y / 2.0 + 30.0)


func _draw_logo() -> void:
	if page in ["create"]:
		return
	var font: Font = load("res://assets/fonts/Mali-Bold.ttf")
	var view := get_viewport_rect().size
	var left := 60.0 if view.x >= 900.0 else 20.0
	var top := 120.0
	var title := "Ghost Exorcist"
	logo.draw_string_outline(font, Vector2(left, top), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, 14, Color(1, 1, 1, 0.95))
	logo.draw_string(font, Vector2(left, top), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 64, P.PINK_DEEP)
	logo.draw_string_outline(font, Vector2(left + 6, top + 56), "ONLINE", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, 12, Color(1, 1, 1, 0.95))
	logo.draw_string(font, Vector2(left + 6, top + 56), "ONLINE", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(0.55, 0.45, 0.85))
	logo.draw_string_outline(font, Vector2(left + 8, top + 100), "ตำนานหมอผีสยาม", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, 10, Color(1, 1, 1, 0.95))
	logo.draw_string(font, Vector2(left + 8, top + 100), "ตำนานหมอผีสยาม", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, P.TEXT)
	# ผีน้อยลอยข้างโลโก้
	var t := Time.get_ticks_msec() / 1000.0
	var title_w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 64).x
	for i in 3:
		var c := Vector2(left + title_w + 40 + i * 62, top - 34 + sin(t * 1.6 + i * 1.7) * 10.0 + i * 30)
		var r := 20.0 - i * 3.0
		logo.draw_circle(c, r, Color(1, 1, 1, 0.92))
		logo.draw_colored_polygon(PackedVector2Array([c + Vector2(-r, 0), c + Vector2(r, 0), c + Vector2(r * 0.6, r * 1.3), c + Vector2(0, r * 0.9), c + Vector2(-r * 0.6, r * 1.3)]), Color(1, 1, 1, 0.92))
		logo.draw_circle(c + Vector2(-r * 0.35, -r * 0.1), r * 0.14, P.TEXT)
		logo.draw_circle(c + Vector2(r * 0.35, -r * 0.1), r * 0.14, P.TEXT)
		logo.draw_circle(c + Vector2(-r * 0.55, r * 0.22), r * 0.14, Color(P.PINK, 0.8))
		logo.draw_circle(c + Vector2(r * 0.55, r * 0.22), r * 0.14, Color(P.PINK, 0.8))
	var foot := "v%d · เล่นได้ทั้ง PC และมือถือ" % Protocol.VERSION
	logo.draw_string(font, Vector2(left, view.y - 24), foot, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.9))


func _process(_delta: float) -> void:
	logo.queue_redraw()


func set_status(text: String, ok: bool = false) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", Color(0.3, 0.6, 0.4) if ok else P.PINK_DEEP)


func set_busy(on: bool) -> void:
	for b in _all_buttons(body):
		b.disabled = on


func _all_buttons(n: Node) -> Array:
	var out := []
	for c in n.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_all_buttons(c))
	return out


func _clear(new_page: String) -> void:
	page = new_page
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	set_status("")
	panel.reset_size()
	_place_panel.call_deferred()


func _title(text: String) -> void:
	var l := P.label(text, 24, P.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(l)


func _row() -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 8)
	body.add_child(r)
	return r


func _wide(text: String, fill: Color, size: int = 17) -> Button:
	var b := P.button(text, fill, size)
	b.custom_minimum_size.y = 44
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(func(): Sound.play(self, "click"))
	return b


# ---------- หน้าเข้าสู่ระบบ ----------

func show_login() -> void:
	_clear("login")
	_title("เข้าสู่ระบบ")
	_user = P.line_edit("ไอดี (ภาษาอังกฤษ/ตัวเลข)", 17)
	body.add_child(_user)
	_pw = P.line_edit("รหัสผ่าน", 17)
	_pw.secret = true
	_pw.text_submitted.connect(func(_t: String): _do_login())
	body.add_child(_pw)
	var login := _wide("เข้าสู่ระบบ", P.PINK)
	login.pressed.connect(_do_login)
	body.add_child(login)
	var r := _row()
	var reg := _wide("สมัครไอดีใหม่", P.MINT, 15)
	reg.pressed.connect(show_register)
	r.add_child(reg)
	var guest := _wide("เล่นแบบ Guest", P.SKY, 15)
	guest.pressed.connect(func(): guest_requested.emit())
	r.add_child(guest)
	body.add_child(P.label("ยังไม่มีไอดี? เล่นแบบ Guest ได้เลย (ตัวละครเก็บในเครื่องนี้)", 12, P.TEXT.lightened(0.25)))
	_server_row()


func _server_row() -> void:
	var r := _row()
	r.add_child(P.label("เซิร์ฟเวอร์", 13, P.TEXT.lightened(0.2)))
	var h := P.line_edit("ที่อยู่เซิร์ฟเวอร์", 13)
	h.text = host
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(h)
	var pt := P.line_edit("พอร์ต", 13)
	pt.text = str(port)
	pt.custom_minimum_size.x = 70
	r.add_child(pt)
	var apply := func(_t = ""):
		host = h.text.strip_edges() if h.text.strip_edges() != "" else "127.0.0.1"
		port = int(pt.text) if pt.text.is_valid_int() else Protocol.DEFAULT_PORT
		server_changed.emit(host, port)
	h.text_changed.connect(apply)
	pt.text_changed.connect(apply)


func _do_login() -> void:
	var u := _user.text.strip_edges()
	if not Protocol.valid_username(u) or not Protocol.valid_password(_pw.text):
		set_status("ใส่ไอดี (4–16 ตัว a-z 0-9 _) และรหัสผ่าน (6 ตัวขึ้นไป)")
		return
	login_requested.emit(u, _pw.text)


# ---------- หน้าสมัครไอดี ----------

func show_register() -> void:
	_clear("register")
	_title("สมัครไอดีใหม่")
	body.add_child(P.label("ง่ายๆ แค่ตั้งไอดีกับรหัสผ่าน", 13, P.TEXT.lightened(0.2)))
	_user = P.line_edit("ไอดี 4–16 ตัว (a-z 0-9 _)", 17)
	body.add_child(_user)
	_pw = P.line_edit("รหัสผ่าน 6 ตัวขึ้นไป", 17)
	_pw.secret = true
	body.add_child(_pw)
	_pw2 = P.line_edit("ยืนยันรหัสผ่านอีกครั้ง", 17)
	_pw2.secret = true
	_pw2.text_submitted.connect(func(_t: String): _do_register())
	body.add_child(_pw2)
	var ok := _wide("สมัครไอดี", P.MINT)
	ok.pressed.connect(_do_register)
	body.add_child(ok)
	var back := _wide("กลับ", Color(1, 1, 1, 0.9), 15)
	back.pressed.connect(show_login)
	body.add_child(back)


func _do_register() -> void:
	var u := _user.text.strip_edges()
	if not Protocol.valid_username(u):
		set_status("ไอดีต้องยาว 4–16 ตัว ใช้ a-z 0-9 หรือ _")
		return
	if not Protocol.valid_password(_pw.text):
		set_status("รหัสผ่านต้องยาว 6–32 ตัว")
		return
	if _pw.text != _pw2.text:
		set_status("รหัสผ่านทั้งสองช่องไม่ตรงกัน")
		return
	register_requested.emit(u, _pw.text)


# ---------- หน้าเลือกตัวละคร ----------

func show_chars(list: Array, mode: String) -> void:
	chars = list
	mode_text = mode
	delete_armed = ""
	_clear("chars")
	_title("เลือกตัวละคร")
	body.add_child(P.label(mode_text, 13, Color(0.35, 0.6, 0.45)))
	if chars.is_empty():
		body.add_child(P.label("ยังไม่มีตัวละคร สร้างตัวแรกกันเลย!", 15))
	for c in chars:
		var r := _row()
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", -2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(info)
		var cls: String = str(c.get("class", "novice"))
		info.add_child(P.label(str(c.get("name", "")), 18))
		info.add_child(P.label("Lv %d · %s" % [int(c.get("level", 1)), Classes.CLASSES.get(cls, Classes.CLASSES["novice"])["name"]], 13, P.TEXT.lightened(0.2)))
		var n: String = str(c.get("name", ""))
		var play := P.button("เริ่มเกม", P.PINK, 15)
		play.custom_minimum_size.y = 40
		play.pressed.connect(func():
			Sound.play(self, "click")
			char_selected.emit(n))
		r.add_child(play)
		var del := P.button("ลบ?" if delete_armed != n else "ยืนยันลบ", Color(1, 1, 1, 0.9), 12)
		del.pressed.connect(func():
			if delete_armed == n:
				char_delete_requested.emit(n)
			else:
				delete_armed = n
				set_status("กด \"ยืนยันลบ\" อีกครั้งเพื่อลบ %s (ลบแล้วกู้คืนไม่ได้)" % n)
				del.text = "ยืนยันลบ")
		r.add_child(del)
	if chars.size() < Protocol.MAX_CHARS:
		var create := _wide("+ สร้างตัวละครใหม่", P.MINT)
		create.pressed.connect(show_create)
		body.add_child(create)
	var back := _wide("ออกจากระบบ", Color(1, 1, 1, 0.9), 14)
	back.pressed.connect(func(): back_requested.emit())
	body.add_child(back)


# ---------- หน้าสร้างตัวละคร ----------

func show_create() -> void:
	_clear("create")
	look = {"gender": "m", "hair": 0, "skin": 0}
	_title("สร้างตัวละคร")
	body.add_child(P.label("ทุกคนเริ่มเป็นศิษย์วัด แล้วเลือกสำนักได้ที่เลเวล 10", 13, P.TEXT.lightened(0.2)))
	_name = P.line_edit("ชื่อตัวละคร (2–12 ตัว ไทย/อังกฤษ)", 17)
	_name.max_length = 12
	body.add_child(_name)
	var g := _row()
	g.add_child(P.label("เพศ", 15))
	for entry in [["m", "ชาย"], ["f", "หญิง"]]:
		var id: String = entry[0]
		var b := P.button(entry[1], P.SKY if id == "m" else P.PINK, 15)
		b.toggle_mode = false
		b.pressed.connect(func():
			look["gender"] = id
			preview_changed.emit(look))
		g.add_child(b)
	_swatches("ผม", "hair", HAIR_COLORS)
	_swatches("ผิว", "skin", SKIN_COLORS)
	var ok := _wide("สร้างตัวละคร", P.MINT)
	ok.pressed.connect(func():
		var n := _name.text.strip_edges()
		if not Protocol.valid_char_name(n):
			set_status("ชื่อต้องยาว 2–12 ตัว ใช้ภาษาไทย อังกฤษ หรือตัวเลข (ไม่มีเว้นวรรค)")
			return
		char_create_requested.emit(n, look.duplicate()))
	body.add_child(ok)
	var back := _wide("กลับ", Color(1, 1, 1, 0.9), 15)
	back.pressed.connect(func(): show_chars(chars, mode_text))
	body.add_child(back)
	preview_changed.emit(look)


func _swatches(label_text: String, key: String, colors: Array) -> void:
	var r := _row()
	var l := P.label(label_text, 15)
	l.custom_minimum_size.x = 34
	r.add_child(l)
	for i in colors.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(40, 34)
		b.focus_mode = Control.FOCUS_NONE
		for state in ["normal", "hover", "pressed"]:
			var st := StyleBoxFlat.new()
			st.bg_color = colors[i] if state != "hover" else colors[i].lightened(0.15)
			st.border_color = P.OUTLINE
			st.set_border_width_all(2)
			st.set_corner_radius_all(17)
			b.add_theme_stylebox_override(state, st)
		var idx := i
		b.pressed.connect(func():
			look[key] = idx
			preview_changed.emit(look))
		r.add_child(b)
