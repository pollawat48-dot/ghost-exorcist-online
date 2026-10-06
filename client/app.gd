extends Node
## ตัวเปิดเกม: หน้าเมนู (เข้าสู่ระบบ/สมัคร/Guest/เลือก-สร้างตัวละคร) แล้วค่อยเข้าเกมหลัก (main.tscn)
## รันเป็นเซิร์ฟเวอร์: godot --headless --path . -- --server [--port 7777]
## Guest: ตัวละครเก็บในเครื่อง ถ้าต่อเซิร์ฟเวอร์ได้ก็เล่นออนไลน์ (แชท/ปาร์ตี้) ถ้าไม่ได้ก็เล่นออฟไลน์

const Server = preload("res://server/server.gd")
const NetClient = preload("res://client/net/net_client.gd")
const LocalStore = preload("res://client/net/local_store.gd")
const TitleScreen = preload("res://client/ui/title_screen.gd")
const Backdrop = preload("res://client/title_backdrop.gd")
const Protocol = preload("res://shared/net/protocol.gd")
const Sound = preload("res://client/audio/sound.gd")
const GAME_SCENE := "res://main.tscn"
const SETTINGS := "user://settings.cfg"

var net: Node
var store: RefCounted
var title: Control
var title_layer: CanvasLayer
var backdrop: Node3D
var game: Node3D
var guest := false
var pending := ""  ## สิ่งที่รอหลังต่อเซิร์ฟเวอร์สำเร็จ: login / register / guest
var _user := ""
var _pw := ""
var host := "127.0.0.1"
var port := Protocol.DEFAULT_PORT


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--server" in args:
		_run_server(args)
		return
	_load_settings()
	store = LocalStore.new()
	net = NetClient.new()
	net.name = "Net"
	add_child(net)
	net.connected.connect(_on_connected)
	net.connection_failed.connect(_on_connection_failed)
	net.auth_result.connect(_on_auth_result)
	net.logged_in.connect(_on_logged_in)
	net.chars_updated.connect(_on_chars_updated)
	net.entered.connect(_on_entered)
	net.notice.connect(func(text: String):
		if title != null:
			title.set_status(text))
	show_title()


func _run_server(args: PackedStringArray) -> void:
	var p := Protocol.DEFAULT_PORT
	var i := args.find("--port")
	if i >= 0 and i + 1 < args.size() and args[i + 1].is_valid_int():
		p = int(args[i + 1])
	var server := Server.new()
	add_child(server)
	if server.start(p) != OK:
		printerr("เปิดเซิร์ฟเวอร์ไม่สำเร็จ (พอร์ต %d ถูกใช้อยู่?)" % p)
		get_tree().quit(1)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		host = str(cfg.get_value("net", "host", host))
		port = int(cfg.get_value("net", "port", port))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("net", "host", host)
	cfg.set_value("net", "port", port)
	cfg.save(SETTINGS)


# ---------- หน้าเมนู ----------

func show_title() -> void:
	backdrop = Backdrop.new()
	add_child(backdrop)
	title_layer = CanvasLayer.new()
	title_layer.layer = 10
	add_child(title_layer)
	title = TitleScreen.new()
	title.host = host
	title.port = port
	title_layer.add_child(title)
	title.login_requested.connect(func(u: String, pw: String): _connect_then("login", u, pw))
	title.register_requested.connect(func(u: String, pw: String): _connect_then("register", u, pw))
	title.guest_requested.connect(func(): _connect_then("guest"))
	title.server_changed.connect(func(h: String, p: int):
		host = h
		port = p
		_save_settings())
	title.char_selected.connect(_on_char_selected)
	title.char_create_requested.connect(_on_char_create)
	title.char_delete_requested.connect(_on_char_delete)
	title.preview_changed.connect(func(look: Dictionary): backdrop.show_avatar("novice", look))
	title.back_requested.connect(_logout)
	Sound.music(self, "title")


func _hide_title() -> void:
	if title_layer != null:
		title_layer.queue_free()
		title_layer = null
		title = null
	if backdrop != null:
		backdrop.queue_free()
		backdrop = null


func _connect_then(what: String, u: String = "", pw: String = "") -> void:
	pending = what
	_user = u
	_pw = pw
	title.set_status("กำลังเชื่อมต่อเซิร์ฟเวอร์ %s:%d ..." % [host, port], true)
	title.set_busy(true)
	if net.is_online():
		_on_connected()
		return
	if net.connect_to(host, port) != OK:
		_on_connection_failed()


func _on_connected() -> void:
	match pending:
		"login":
			net.login(_user, _pw)
		"register":
			net.register(_user, _pw)
		"guest":
			net.guest()


func _on_connection_failed() -> void:
	if title == null:
		return
	title.set_busy(false)
	if pending == "guest":
		# ต่อไม่ได้: เล่น Guest แบบออฟไลน์
		guest = true
		title.show_chars(store.list(), "Guest · ออฟไลน์ (ต่อเซิร์ฟเวอร์ไม่ได้ แชท/ปาร์ตี้ใช้ไม่ได้)")
		return
	title.set_status("ต่อเซิร์ฟเวอร์ %s:%d ไม่ได้ ลองใหม่ หรือเล่นแบบ Guest" % [host, port])


func _on_auth_result(ok: bool, text: String) -> void:
	if title == null:
		return
	title.set_busy(false)
	if ok and pending == "register":
		title.set_status(text + " กำลังเข้าสู่ระบบ...", true)
		pending = "login"
		net.login(_user, _pw)
		return
	title.set_status(text, ok)


func _on_logged_in(user: String, is_guest: bool, list: Array) -> void:
	guest = is_guest
	if title == null:
		return
	title.set_busy(false)
	if guest:
		title.show_chars(store.list(), "Guest · ออนไลน์ (ตัวละครเก็บในเครื่องนี้)")
	else:
		title.show_chars(list, "ออนไลน์ · ไอดี %s" % user)


func _on_chars_updated(list: Array, error: String) -> void:
	if title == null or guest:
		return
	title.show_chars(list, title.mode_text)
	backdrop.show_avatar("", {})
	if error != "":
		title.set_status(error)


func _on_char_create(char_name: String, look: Dictionary) -> void:
	if guest:
		var err: String = store.create(char_name, look)
		if err != "":
			title.set_status(err)
			return
		title.show_chars(store.list(), title.mode_text)
		backdrop.show_avatar("", {})
		title.set_status("สร้าง %s แล้ว!" % char_name, true)
	else:
		net.create_char(char_name, look)


func _on_char_delete(char_name: String) -> void:
	if guest:
		store.delete(char_name)
		title.show_chars(store.list(), title.mode_text)
	else:
		net.delete_char(char_name)


func _on_char_selected(char_name: String) -> void:
	if guest:
		var c: Dictionary = store.load_char(char_name)
		if net.is_online():
			pending = "enter:" + char_name
			net.enter_guest(char_name, c.get("look", {}), c.get("data", {}))
		else:
			start_game({"name": char_name, "store_name": char_name, "look": c.get("look", {}), "data": c.get("data", {}), "guest": true})
	else:
		net.enter(char_name)


func _on_entered(char_name: String, look: Dictionary, data: Dictionary) -> void:
	if guest:
		var local_name := pending.substr(6) if pending.begins_with("enter:") else char_name
		var c: Dictionary = store.load_char(local_name)
		start_game({"name": char_name, "store_name": local_name, "look": c.get("look", look), "data": c.get("data", {}), "guest": true})
	else:
		start_game({"name": char_name, "look": look, "data": data, "guest": false})


# ---------- เข้าเกม / ออกเกม ----------

func start_game(session: Dictionary) -> void:
	_hide_title()
	game = load(GAME_SCENE).instantiate()
	game.session = session
	game.net = net if net.is_online() else null
	game.store = store
	game.logout_requested.connect(_logout)
	add_child(game)


func _logout() -> void:
	if game != null:
		game.queue_free()
		game = null
		if net.is_online():
			# ให้เซฟชุดสุดท้ายส่งถึงเซิร์ฟเวอร์ก่อนตัดการเชื่อมต่อ
			for i in 10:
				net.poll()
				await get_tree().create_timer(0.03).timeout
	net.close()
	guest = false
	pending = ""
	if title == null:
		show_title()
	else:
		title.show_login()
		backdrop.show_avatar("", {})
