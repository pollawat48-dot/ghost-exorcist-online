extends Node
## ตัวต่อเซิร์ฟเวอร์ฝั่ง client: ส่ง/รับข้อความ Dictionary ผ่าน ENet แบบ packet ดิบ
## ข้อความที่ได้รับส่งออกทาง signal message() และ signal เฉพาะเรื่อง (ล็อกอิน แชต ปาร์ตี้ EXP บัฟ ฯลฯ)

const Protocol = preload("res://shared/net/protocol.gd")

signal connected
signal connection_failed
signal disconnected
signal message(msg: Dictionary)
signal auth_result(ok: bool, text: String)
signal logged_in(user: String, guest: bool, chars: Array)
signal chars_updated(chars: Array, error: String)
signal entered(name: String, look: Dictionary, data: Dictionary)
signal chat_received(ch: String, from: String, to: String, text: String)
signal players_updated(list: Array)
signal party_updated(leader: String, members: Array)
signal party_invited(from: String)
signal exp_shared(amount: int, ghost_id: String, from: String, members: int)
signal buff_received(msg: Dictionary)
signal heal_received(amount: int, from: String)
signal notice(text: String)

const CONNECT_TIMEOUT := 5.0
const SERVER_PEER := 1

var peer: ENetMultiplayerPeer
## ต่อติดและเซิร์ฟเวอร์ตอบ hello แล้ว
var ready_ok := false
var my_name := ""
var user := ""
var guest_mode := false
var chars: Array = []
var party_leader := ""
var party_members: Array = []
## ถ้า false ต้องเรียก poll() เอง (ใช้ในเทสต์)
var auto_poll := true

var _connecting := false
var _link_up := false
var _wait := 0.0
var _last_ms := 0


## เริ่มต่อเซิร์ฟเวอร์ ต่อติดแล้วจะส่ง hello ให้เอง (connected เมื่อเซิร์ฟเวอร์ตอบรับ)
func connect_to(host: String, port: int) -> Error:
	close()
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(host, port)
	if err != OK:
		peer = null
		connection_failed.emit()
		return err
	_connecting = true
	_link_up = false
	_wait = 0.0
	_last_ms = Time.get_ticks_msec()
	return OK


func close() -> void:
	var was_online := _link_up
	if peer != null:
		peer.close()
		peer = null
	_connecting = false
	_link_up = false
	ready_ok = false
	my_name = ""
	party_leader = ""
	party_members = []
	if was_online:
		disconnected.emit()


func is_online() -> bool:
	return peer != null and ready_ok


func in_party() -> bool:
	return party_members.size() >= 2


func party_names() -> Array:
	var out := []
	for m in party_members:
		out.append(m.get("name", ""))
	return out


# ---------- คำสั่งส่งไปเซิร์ฟเวอร์ ----------

func register(user_id: String, pw: String) -> void:
	send({"t": "register", "user": user_id, "pass": pw})


func login(user_id: String, pw: String) -> void:
	send({"t": "login", "user": user_id, "pass": pw})


func guest() -> void:
	send({"t": "guest"})


func create_char(name: String, look: Dictionary) -> void:
	send({"t": "create_char", "name": name, "look": look})


func delete_char(name: String) -> void:
	send({"t": "delete_char", "name": name})


func enter(name: String) -> void:
	send({"t": "enter", "name": name})


func enter_guest(name: String, look: Dictionary, data: Dictionary) -> void:
	send({"t": "enter_guest", "name": name, "look": look, "data": data})


func save(data: Dictionary) -> void:
	send({"t": "save", "data": data})


## info: {"cls","lv","hp","mhp","equip"}
func send_pos(map_id: String, pos: Vector2, info: Dictionary) -> void:
	send({
		"t": "pos", "map": map_id, "x": pos.x, "y": pos.y,
		"cls": info.get("cls", "novice"), "lv": int(info.get("lv", 1)),
		"hp": int(info.get("hp", 1)), "mhp": int(info.get("mhp", 1)),
		"equip": info.get("equip", {}),
	}, false)


func send_chat(ch: String, text: String, to := "") -> void:
	send({"t": "chat", "ch": ch, "text": text, "to": to})


func party_invite(name: String) -> void:
	send({"t": "party_invite", "name": name})


func party_reply(from: String, accept: bool) -> void:
	send({"t": "party_reply", "from": from, "accept": accept})


func party_leave() -> void:
	send({"t": "party_leave"})


func party_kick(name: String) -> void:
	send({"t": "party_kick", "name": name})


func report_kill(ghost_id: String, map_id: String) -> void:
	send({"t": "kill", "ghost_id": ghost_id, "map": map_id})


## fields: {"skill","lv","power","duration","effect","x","y"}
func send_buff(fields: Dictionary) -> void:
	var msg := fields.duplicate()
	msg["t"] = "buff"
	send(msg)


func send_heal(amount: int, pos: Vector2) -> void:
	send({"t": "heal", "amount": amount, "x": pos.x, "y": pos.y})


func send(msg: Dictionary, reliable: bool = true) -> void:
	if peer == null or not _link_up:
		return
	peer.set_transfer_mode(
		MultiplayerPeer.TRANSFER_MODE_RELIABLE if reliable
		else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED)
	peer.set_target_peer(SERVER_PEER)
	peer.put_packet(var_to_bytes(msg))


# ---------- รับข้อความ ----------

func _process(_delta: float) -> void:
	if auto_poll:
		poll()


func poll() -> void:
	if peer == null:
		return
	var ms := Time.get_ticks_msec()
	var dt := (ms - _last_ms) / 1000.0
	_last_ms = ms
	peer.poll()
	if peer == null:
		return
	var status := peer.get_connection_status()
	if _connecting:
		if status == MultiplayerPeer.CONNECTION_CONNECTED:
			_connecting = false
			_link_up = true
			_wait = 0.0
			send({"t": "hello", "v": Protocol.VERSION})
		else:
			_wait += dt
			if status == MultiplayerPeer.CONNECTION_DISCONNECTED or _wait >= CONNECT_TIMEOUT:
				peer.close()
				peer = null
				_connecting = false
				connection_failed.emit()
				return
	elif _link_up and status == MultiplayerPeer.CONNECTION_DISCONNECTED:
		close()
		return
	while peer != null and peer.get_available_packet_count() > 0:
		var bytes := peer.get_packet()
		var msg = bytes_to_var(bytes)
		if typeof(msg) == TYPE_DICTIONARY and typeof(msg.get("t")) == TYPE_STRING:
			_dispatch(msg)


func _dispatch(msg: Dictionary) -> void:
	message.emit(msg)
	match msg["t"]:
		"hello_ok":
			ready_ok = true
			connected.emit()
		"error":
			notice.emit(str(msg.get("text", "")))
			if not ready_ok:
				_link_up = false
				close()
				connection_failed.emit()
		"register_ok":
			auth_result.emit(true, "สมัครไอดีสำเร็จ")
		"auth_err":
			auth_result.emit(false, str(msg.get("text", "")))
		"login_ok":
			user = str(msg.get("user", ""))
			guest_mode = msg.get("guest") == true
			chars = _arr(msg.get("chars"))
			logged_in.emit(user, guest_mode, chars)
		"chars":
			chars = _arr(msg.get("chars"))
			chars_updated.emit(chars, "")
		"char_err":
			chars_updated.emit(chars, str(msg.get("text", "")))
		"entered":
			my_name = str(msg.get("name", ""))
			entered.emit(my_name, _dict(msg.get("look")), _dict(msg.get("data")))
		"chat":
			chat_received.emit(str(msg.get("ch", "")), str(msg.get("from", "")),
				str(msg.get("to", "")), str(msg.get("text", "")))
		"players":
			players_updated.emit(_arr(msg.get("list")))
		"party":
			party_leader = str(msg.get("leader", ""))
			party_members = _arr(msg.get("members"))
			if party_members.is_empty():
				party_leader = ""
			party_updated.emit(party_leader, party_members)
		"party_invite":
			party_invited.emit(str(msg.get("from", "")))
		"exp":
			exp_shared.emit(_int(msg.get("amount")), str(msg.get("ghost_id", "")),
				str(msg.get("from", "")), _int(msg.get("members")))
		"buff":
			buff_received.emit(msg)
		"heal":
			heal_received.emit(_int(msg.get("amount")), str(msg.get("from", "")))
		"notice":
			notice.emit(str(msg.get("text", "")))


func _int(v) -> int:
	return int(v) if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT else 0


func _arr(v) -> Array:
	return v if typeof(v) == TYPE_ARRAY else []


func _dict(v) -> Dictionary:
	return v if typeof(v) == TYPE_DICTIONARY else {}
