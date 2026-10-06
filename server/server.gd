extends Node
## เซิร์ฟเวอร์ออนไลน์: เปิดพอร์ต ENet รับส่ง packet ดิบ แล้วส่งต่อให้ server_core.gd จัดการ
## ใช้ ENetMultiplayerPeer แบบ PacketPeer ตรง ๆ (ไม่ใช้ RPC) ข้อความทุกอันเป็น Dictionary

const Protocol = preload("res://shared/net/protocol.gd")
const AccountStore = preload("res://server/account_store.gd")
const ServerCore = preload("res://server/server_core.gd")

## packet ที่ใหญ่กว่านี้ทิ้งเลย (เซฟตัวละคร 64 KB + ส่วนหัว)
const MAX_PACKET := Protocol.SAVE_MAX_BYTES + 4096
const MAX_CLIENTS := 256

var peer: ENetMultiplayerPeer
var core
var store
## peer ที่ต่ออยู่ตอนนี้ (กันส่งหา peer ที่หลุดไปแล้ว)
var connected: Dictionary = {}
## ถ้า false ต้องเรียก poll() เอง (ใช้ในเทสต์)
var auto_poll := true


func start(port: int = Protocol.DEFAULT_PORT, data_dir := "user://server_data") -> Error:
	stop()
	store = AccountStore.new(data_dir)
	core = ServerCore.new(store)
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_error("เปิดเซิร์ฟเวอร์ที่พอร์ต %d ไม่สำเร็จ (%s)" % [port, error_string(err)])
		peer = null
		return err
	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)
	print("เซิร์ฟเวอร์เปิดที่พอร์ต %d" % port)
	return OK


func stop() -> void:
	if peer != null:
		peer.close()
		peer = null
	connected.clear()
	core = null


func is_running() -> bool:
	return peer != null


func _process(delta: float) -> void:
	if auto_poll:
		poll(delta)


## รับ packet ทั้งหมดที่มา ส่งให้ core แล้วส่งข้อความที่ค้างอยู่ออกไป
func poll(delta: float) -> void:
	if peer == null:
		return
	peer.poll()
	while peer != null and peer.get_available_packet_count() > 0:
		var from := peer.get_packet_peer()
		var bytes := peer.get_packet()
		if not connected.has(from) or bytes.size() == 0 or bytes.size() > MAX_PACKET:
			continue
		var msg = bytes_to_var(bytes)
		if typeof(msg) == TYPE_DICTIONARY:
			core.handle(from, msg)
	if core == null:
		return
	core.tick(delta)
	_flush()


const UNRELIABLE_MAX := 1200


func _flush() -> void:
	for item in core.take_outbox():
		var to: int = item[0]
		if not connected.has(to):
			continue
		var bytes := var_to_bytes(item[1])
		# snapshot ที่ใหญ่เกิน MTU ส่งแบบ reliable แทน (ส่งแบบ unreliable จะถูกตัดเป็นชิ้นแล้วหายง่าย)
		var reliable: bool = item[2] or bytes.size() > UNRELIABLE_MAX
		peer.set_transfer_mode(
			MultiplayerPeer.TRANSFER_MODE_RELIABLE if reliable
			else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED)
		peer.set_target_peer(to)
		peer.put_packet(bytes)


func _on_peer_connected(id: int) -> void:
	connected[id] = true
	if core != null:
		core.peer_joined(id)


func _on_peer_disconnected(id: int) -> void:
	connected.erase(id)
	if core != null:
		core.peer_left(id)
		_flush()
