extends PanelContainer
## กล่องแชท + ข้อความเกม (มุมซ้าย): แท็บ ทั้งหมด / โลก / ปาร์ตี้ / กระซิบ / ระบบ
## พิมพ์แล้วกด Enter ส่ง เลือกช่องด้วยปุ่มช่อง หรือพิมพ์คำสั่ง /w ชื่อ ข้อความ (กระซิบ) /p (ปาร์ตี้) /g (โลก)

const P = preload("res://client/ui/palette.gd")

signal sent(ch: String, text: String, to: String)

const MAX_LINES := 80
const TABS := [["all", "ทั้งหมด"], ["world", "โลก"], ["party", "ปาร์ตี้"], ["whisper", "กระซิบ"], ["system", "ระบบ"]]
const SEND_CHANNELS := ["world", "party", "whisper"]
const CH_NAMES := {"world": "โลก", "party": "ปาร์ตี้", "whisper": "กระซิบ", "system": "ระบบ"}
const CH_COLORS := {
	"world": Color(0.36, 0.3, 0.42), "party": Color(0.86, 0.36, 0.52),
	"whisper": Color(0.5, 0.36, 0.8), "system": Color(0.55, 0.47, 0.42),
}

var entries: Array[Dictionary] = []  ## {"ch", "text"(bbcode)}
var tab := "all"
var channel := "world"
var log_view: RichTextLabel
var input: LineEdit
var target_input: LineEdit
var channel_button: Button
var tab_buttons := {}
var me := ""  ## ชื่อตัวเอง (ไว้แสดง "ถึง ..." ตอนกระซิบ)
var unread := {}


func _ready() -> void:
	add_to_group(P.UI_BLOCK)
	add_theme_stylebox_override("panel", P.panel_style(14, Color(1, 0.97, 0.94, 0.78), Color(P.LAVENDER, 0.7)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	var tabs_row := HBoxContainer.new()
	tabs_row.add_theme_constant_override("separation", 3)
	box.add_child(tabs_row)
	for t in TABS:
		var b := P.button(t[1], P.PINK if t[0] == tab else Color(1, 1, 1, 0.85), 11)
		var id: String = t[0]
		b.pressed.connect(func(): set_tab(id))
		tabs_row.add_child(b)
		tab_buttons[id] = b
	log_view = RichTextLabel.new()
	log_view.bbcode_enabled = true
	log_view.scroll_following = true
	log_view.custom_minimum_size = Vector2(360, 118)
	log_view.add_theme_font_size_override("normal_font_size", 13)
	log_view.add_theme_font_size_override("bold_font_size", 13)
	log_view.add_theme_color_override("default_color", P.TEXT)
	log_view.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(log_view)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	box.add_child(row)
	channel_button = P.button("", P.MINT, 12)
	channel_button.custom_minimum_size.x = 62
	channel_button.pressed.connect(_next_channel)
	row.add_child(channel_button)
	target_input = P.line_edit("ถึงใคร", 12)
	target_input.custom_minimum_size.x = 80
	target_input.visible = false
	row.add_child(target_input)
	input = P.line_edit("พิมพ์ข้อความ... (Enter ส่ง)", 12)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.max_length = 120
	input.text_submitted.connect(_submit)
	row.add_child(input)
	var send := P.button("ส่ง", P.PINK, 12)
	send.pressed.connect(func(): _submit(input.text))
	row.add_child(send)
	_refresh_channel()


func is_typing() -> bool:
	return input.has_focus() or target_input.has_focus()


func focus_input() -> void:
	input.grab_focus()


## เลือกกระซิบหาคนนี้ (จากการคลิกตัวละครผู้เล่นอื่น)
func whisper_to(name_: String) -> void:
	channel = "whisper"
	target_input.text = name_
	_refresh_channel()
	input.grab_focus()


func set_tab(id: String) -> void:
	tab = id
	unread.erase(id)
	for key in tab_buttons:
		var b: Button = tab_buttons[key]
		var st: StyleBoxFlat = b.get_theme_stylebox("normal").duplicate()
		st.bg_color = P.PINK if key == tab else Color(1, 1, 1, 0.85)
		b.add_theme_stylebox_override("normal", st)
		b.text = _tab_title(key)
	_render()


func _tab_title(key: String) -> String:
	for t in TABS:
		if t[0] == key:
			return t[1] + (" •" if unread.has(key) else "")
	return key


## เพิ่มข้อความ ch = world/party/whisper/system
func add(ch: String, from: String, to: String, text: String) -> void:
	var safe := text.replace("[", "[lb]")
	var color: Color = CH_COLORS.get(ch, P.TEXT)
	var line := ""
	match ch:
		"system":
			line = "[color=#%s]%s[/color]" % [color.to_html(false), safe]
		"whisper":
			var who := ("ถึง %s" % to) if from == me and me != "" else ("จาก %s" % from)
			line = "[color=#%s][b][กระซิบ %s][/b] %s[/color]" % [color.to_html(false), who.replace("[", "[lb]"), safe]
		_:
			line = "[color=#%s][b][%s] %s:[/b] %s[/color]" % [color.to_html(false), CH_NAMES.get(ch, ch), from.replace("[", "[lb]"), safe]
	entries.append({"ch": ch, "text": line})
	if entries.size() > MAX_LINES:
		entries.pop_front()
	if ch != "system" and tab != "all" and tab != ch:
		unread[ch] = true
		if tab_buttons.has(ch):
			tab_buttons[ch].text = _tab_title(ch)
	if tab == "all" or tab == ch:
		log_view.append_text(("\n" if log_view.get_parsed_text() != "" else "") + line)


## ข้อความล่าสุด (ไว้ทดสอบ)
func last_text() -> String:
	return "" if entries.is_empty() else entries[-1]["text"]


func _render() -> void:
	log_view.clear()
	var first := true
	for e in entries:
		if tab == "all" or e["ch"] == tab:
			log_view.append_text(("" if first else "\n") + e["text"])
			first = false


func _next_channel() -> void:
	channel = SEND_CHANNELS[(SEND_CHANNELS.find(channel) + 1) % SEND_CHANNELS.size()]
	_refresh_channel()


func _refresh_channel() -> void:
	channel_button.text = CH_NAMES[channel]
	target_input.visible = channel == "whisper"


func _submit(text: String) -> void:
	text = text.strip_edges()
	if text == "":
		input.release_focus()
		return
	var ch := channel
	var to := target_input.text.strip_edges()
	if text.begins_with("/w ") or text.begins_with("/กระซิบ "):
		var parts := text.split(" ", false, 2)
		if parts.size() >= 3:
			ch = "whisper"
			to = parts[1]
			text = parts[2]
			target_input.text = to
	elif text.begins_with("/p "):
		ch = "party"
		text = text.substr(3)
	elif text.begins_with("/g "):
		ch = "world"
		text = text.substr(3)
	if ch == "whisper" and to == "":
		add("system", "", "", "ใส่ชื่อผู้เล่นที่จะกระซิบหา หรือพิมพ์ /w ชื่อ ข้อความ")
		return
	input.text = ""
	sent.emit(ch, text, to)
