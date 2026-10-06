extends SceneTree
## ทดสอบระบบออนไลน์แบบ headless: godot --headless --path . --script res://tests/test_net.gd
## (ก) protocol (ข) server_core เรียก handle() ตรง ๆ (ค) ต่อ ENet จริงที่ 127.0.0.1

const Protocol = preload("res://shared/net/protocol.gd")
const AccountStore = preload("res://server/account_store.gd")
const ServerCore = preload("res://server/server_core.gd")
const Server = preload("res://server/server.gd")
const NetClient = preload("res://client/net/net_client.gd")
const GhostDB = preload("res://shared/data/ghosts.gd")

var failures := 0
var core
var out: Array = []
## เหตุการณ์จาก signal ในเทสต์ ENet (Dictionary จึงแก้จาก lambda ได้)
var ev: Dictionary = {}


func _initialize() -> void:
	_run_all()


func _run_all() -> void:
	print("== protocol ==")
	_test_protocol()
	print("== server core ==")
	_test_core()
	print("== ENet จริง ==")
	await _test_enet()
	if failures == 0:
		print("ผ่านทั้งหมด")
	else:
		printerr("ล้มเหลว %d รายการ" % failures)
	quit(1 if failures > 0 else 0)


func check(cond: bool, name: String) -> void:
	if cond:
		print("  ok   ", name)
	else:
		failures += 1
		printerr("  FAIL ", name)


func _test_protocol() -> void:
	check(Protocol.party_share(100, 5) == 25, "party_share(100,5) = 25")
	check(Protocol.party_share(100, 1) == 105, "party_share(100,1) = 105")
	check(Protocol.party_share(100, 2) == 55, "party_share(100,2) = 55")
	check(Protocol.party_share(100, 0) == 105, "party_share กันหารศูนย์")
	check(Protocol.valid_username("ab_C9") and not Protocol.valid_username("abc")
		and not Protocol.valid_username("a".repeat(17)) and not Protocol.valid_username("ab cd")
		and not Protocol.valid_username("ผีผีผีผี") and not Protocol.valid_username(1234), "valid_username")
	check(Protocol.valid_password("123456") and not Protocol.valid_password("12345")
		and not Protocol.valid_password("x".repeat(33)) and not Protocol.valid_password(null), "valid_password")
	check(Protocol.valid_char_name("สมชาย") and Protocol.valid_char_name("บ๊อบ99") and Protocol.valid_char_name("Al")
		and not Protocol.valid_char_name("A") and not Protocol.valid_char_name("ab cd")
		and not Protocol.valid_char_name("ab#1") and not Protocol.valid_char_name("x".repeat(13))
		and not Protocol.valid_char_name({}), "valid_char_name")
	check(Protocol.clean_chat("  hi\nthere\r\n ") == "hi there", "clean_chat ขึ้นบรรทัดใหม่เป็นเว้นวรรค")
	check(Protocol.clean_chat("ก".repeat(300)).length() == Protocol.CHAT_MAX, "clean_chat ตัดความยาว")
	check(Protocol.clean_chat(42) == "", "clean_chat ไม่ใช่ข้อความ")


# ---------- server core ----------

func _drain() -> void:
	out = core.take_outbox()


func _of(peer: int, t: String) -> Array:
	var r := []
	for item in out:
		if item[0] == peer and item[1].get("t") == t:
			r.append(item[1])
	return r


func _one(peer: int, t: String) -> Dictionary:
	var r := _of(peer, t)
	return r[r.size() - 1] if not r.is_empty() else {}


func _h(peer: int, msg) -> void:
	core.handle(peer, msg)
	_drain()


func _join(peer: int) -> void:
	core.peer_joined(peer)
	_h(peer, {"t": "hello", "v": Protocol.VERSION})


func _guest(peer: int, name: String, map := "pa_cha", pos := Vector2.ZERO) -> String:
	_join(peer)
	_h(peer, {"t": "guest"})
	_h(peer, {"t": "enter_guest", "name": name, "look": {}, "data": {}})
	var final_name: String = _one(peer, "entered").get("name", "")
	_pos(peer, map, pos)
	return final_name


func _pos(peer: int, map: String, pos: Vector2) -> void:
	_h(peer, {"t": "pos", "map": map, "x": pos.x, "y": pos.y, "cls": "novice", "lv": 10, "hp": 50, "mhp": 80, "equip": {"weapon": "wood_sword"}})


## ส่งคำชวนแล้วตอบรับ
func _invite_accept(leader: int, leader_name: String, target: int, target_name: String) -> void:
	_h(leader, {"t": "party_invite", "name": target_name})
	_h(target, {"t": "party_reply", "from": leader_name, "accept": true})


func _test_core() -> void:
	var dir := "user://test_server_%d" % (randi() % 1000000)
	var store = AccountStore.new(dir)
	core = ServerCore.new(store)

	# เวอร์ชันไม่ตรง
	core.peer_joined(99)
	_h(99, {"t": "hello", "v": 999})
	check(_one(99, "error").has("text") and _of(99, "hello_ok").is_empty(), "hello เวอร์ชันไม่ตรงได้ error")
	_h(99, {"t": "register", "user": "nohello", "pass": "123456"})
	check(out.is_empty(), "ยังไม่ hello สั่งอะไรไม่ได้")
	_join(10)
	check(not _of(10, "hello_ok").is_empty(), "hello ได้ hello_ok")

	# สมัคร ล็อกอิน
	_h(10, {"t": "register", "user": "alice", "pass": "secret1"})
	check(not _of(10, "register_ok").is_empty(), "สมัครไอดี")
	_h(10, {"t": "register", "user": "ALICE", "pass": "secret1"})
	check(_one(10, "auth_err").get("text", "") == "ไอดีนี้มีคนใช้แล้ว", "สมัครซ้ำไม่ได้ (ไม่สนตัวพิมพ์)")
	_h(10, {"t": "register", "user": "a!", "pass": "secret1"})
	check(not _of(10, "auth_err").is_empty(), "ไอดีผิดรูปแบบสมัครไม่ได้")
	var raw := FileAccess.get_file_as_bytes(dir + "/accounts.dat").get_string_from_ascii()
	check(not raw.contains("secret1"), "ไม่เก็บรหัสผ่านตัวจริง")
	_h(10, {"t": "login", "user": "alice", "pass": "wrongpw"})
	check(not _of(10, "auth_err").is_empty() and not core.sessions[10]["logged_in"], "รหัสผิดเข้าไม่ได้")
	core.tick(11.0)
	_h(10, {"t": "login", "user": "alice", "pass": "secret1"})
	var lo := _one(10, "login_ok")
	check(lo.get("user") == "alice" and lo.get("chars") == [], "ล็อกอินสำเร็จ")
	core.peer_joined(12)
	_h(12, {"t": "hello", "v": Protocol.VERSION})
	_h(12, {"t": "login", "user": "alice", "pass": "secret1"})
	check(not _of(12, "auth_err").is_empty() and not core.sessions[12]["logged_in"], "ไอดีออนไลน์อยู่แล้วล็อกอินซ้ำไม่ได้")

	# ตัวละคร
	_h(10, {"t": "create_char", "name": "Alice", "look": {"gender": "f", "hair": 9, "skin": "x", "evil": 1}})
	var cs: Array = _one(10, "chars").get("chars", [])
	check(cs.size() == 1 and cs[0]["name"] == "Alice" and cs[0]["look"] == {"gender": "f", "hair": 4, "skin": 0}, "สร้างตัวละคร + กรองหน้าตา")
	_join(11)
	_h(11, {"t": "register", "user": "bob_1", "pass": "hunter22"})
	_h(11, {"t": "login", "user": "bob_1", "pass": "hunter22"})
	_h(11, {"t": "create_char", "name": "alice", "look": {}})
	check(not _of(11, "char_err").is_empty(), "ชื่อตัวละครซ้ำข้ามไอดีไม่ได้")
	_h(11, {"t": "create_char", "name": "บ๊อบ", "look": {}})
	check(_one(11, "chars").get("chars", []).size() == 1, "สร้างตัวละครชื่อไทย")
	_h(11, {"t": "create_char", "name": "Bob2", "look": {}})
	_h(11, {"t": "create_char", "name": "Bob3", "look": {}})
	_h(11, {"t": "create_char", "name": "Bob4", "look": {}})
	check(not _of(11, "char_err").is_empty() and store.chars_of("bob_1").size() == 3, "ตัวละครสูงสุด 3 ตัว")
	_h(11, {"t": "delete_char", "name": "Bob3"})
	check(_one(11, "chars").get("chars", []).size() == 2, "ลบตัวละคร")
	_h(11, {"t": "enter", "name": "Alice"})
	check(_of(11, "entered").is_empty(), "เข้าตัวละครของคนอื่นไม่ได้")

	# เข้าเกม เซฟ
	_h(10, {"t": "enter", "name": "alice"})
	var en := _one(10, "entered")
	check(en.get("name") == "Alice" and en.get("data") == {} and core.sessions[10]["in_world"], "เข้าเกม")
	var data := {"state": {"level": 7, "class": "novice", "coins": 250}, "inv": {"potion": 3}}
	_h(10, {"t": "save", "data": data})
	check(_one(10, "saved").get("ok") == true, "เซฟ")
	_h(10, {"t": "save", "data": {"nostate": 1}})
	check(_one(10, "saved").get("ok") == false, "เซฟที่ไม่มี state ไม่ผ่าน")
	_h(10, {"t": "save", "data": {"state": {}, "junk": "x".repeat(70000)}})
	check(_one(10, "saved").get("ok") == false, "เซฟใหญ่เกิน 64KB ไม่ผ่าน")
	var store2 = AccountStore.new(dir)
	var loaded: Dictionary = store2.load_char("alice", "Alice")
	var inv = loaded.get("data", {}).get("inv", {})
	check(typeof(inv.get("potion")) == TYPE_INT and inv["potion"] == 3
		and typeof(loaded["data"]["state"]["level"]) == TYPE_INT, "โหลดใหม่ค่า int ยังเป็น int")
	check(store2.chars_of("alice")[0]["level"] == 7 and store2.check_login("alice", "secret1"), "สรุปเลเวลอัปเดต + ไอดีอยู่ครบหลังโหลดใหม่")

	# แขก
	_join(13)
	_h(13, {"t": "guest"})
	check(_one(13, "login_ok").get("guest") == true, "เข้าแบบแขก")
	_h(13, {"t": "enter_guest", "name": "alice", "look": {"gender": "f"}, "data": {"state": {}}})
	var gname: String = _one(13, "entered").get("name", "")
	check(gname.begins_with("alice#") and gname.length() == 9, "แขกชื่อชนตัวละครที่ลงทะเบียน ได้ต่อท้าย #xxx (%s)" % gname)
	_h(13, {"t": "save", "data": data})
	check(_of(13, "saved").is_empty(), "แขกเซฟบนเซิร์ฟเวอร์ไม่ได้")
	_h(13, {"t": "enter_guest", "name": "a b", "look": {}, "data": {}})
	check(not _of(13, "char_err").is_empty(), "ชื่อแขกผิดรูปแบบไม่ได้")
	core.peer_left(13)
	core.peer_left(11)
	core.peer_left(12)
	core.peer_left(99)

	# ผู้เล่นในโลก 6 คน (Alice อยู่แล้ว peer 10)
	_pos(10, "khlong_village", Vector2.ZERO)
	var n1 := _guest(21, "Pa", "pa_cha", Vector2(0, 0))
	var n2 := _guest(22, "Pb", "pa_cha", Vector2(100, 0))
	var n3 := _guest(23, "Pc", "pa_cha", Vector2(1000, 0))
	var n4 := _guest(24, "Pd", "pa_cha", Vector2(50, 50))
	var n5 := _guest(25, "Pe", "pa_cha", Vector2(0, 0))
	var n6 := _guest(26, "Pf", "pa_cha", Vector2(10, 10))
	var dup := _guest(27, "pa", "pa_cha", Vector2.ZERO)
	check(n1 == "Pa" and dup.begins_with("pa#"), "แขกชื่อชนผู้เล่นออนไลน์ได้ต่อท้าย #")
	core.peer_left(27)

	# แชต
	_h(21, {"t": "chat", "ch": "world", "text": " สวัสดี\nทุกคน ", "to": ""})
	var all_got := true
	for p in [10, 21, 22, 23, 24, 25, 26]:
		var c := _one(p, "chat")
		all_got = all_got and c.get("text") == "สวัสดี ทุกคน" and c.get("from") == "Pa" and c.get("ch") == "world"
	check(all_got, "แชตโลกถึงทุกคน")
	_h(21, {"t": "chat", "ch": "whisper", "text": "ลับ", "to": "pb"})
	check(_one(22, "chat").get("to") == "Pb" and _one(21, "chat").get("text") == "ลับ"
		and _of(23, "chat").is_empty(), "กระซิบถึงคนเดียว + ส่งกลับผู้ส่ง")
	_h(21, {"t": "chat", "ch": "whisper", "text": "hi", "to": "Nobody"})
	check(_one(21, "notice").get("text", "").begins_with("ไม่พบผู้เล่นชื่อ"), "กระซิบหาคนที่ไม่อยู่ได้ notice")
	_h(21, {"t": "chat", "ch": "world", "text": "3"})
	_h(21, {"t": "chat", "ch": "world", "text": "4"})
	_h(21, {"t": "chat", "ch": "world", "text": "5"})
	check(_of(22, "chat").is_empty() and not _of(21, "notice").is_empty(), "กันแชตรัว")
	_h(21, {"t": "chat", "ch": "party", "text": "x"})
	core.tick(6.0)
	_drain()
	_h(21, {"t": "chat", "ch": "party", "text": "x"})
	check(not _of(21, "notice").is_empty() and _of(22, "chat").is_empty(), "แชตปาร์ตี้ตอนไม่มีปาร์ตี้ได้ notice")

	# ปาร์ตี้
	_h(21, {"t": "party_invite", "name": "Pb"})
	check(_one(22, "party_invite").get("from") == "Pa", "ส่งคำชวนปาร์ตี้")
	_h(22, {"t": "party_reply", "from": "Pa", "accept": true})
	var pm := _one(21, "party")
	check(pm.get("leader") == "Pa" and pm.get("members", []).size() == 2
		and _one(22, "party").get("members", []).size() == 2, "ตอบรับ → ปาร์ตี้ 2 คน")
	_h(22, {"t": "party_invite", "name": "Pc"})
	check(not _of(22, "notice").is_empty() and _of(23, "party_invite").is_empty(), "ลูกทีมชวนไม่ได้")
	_h(26, {"t": "party_invite", "name": "Pb"})
	check(_one(26, "notice").get("text", "").contains("ปาร์ตี้อื่น"), "ชวนคนที่มีปาร์ตี้แล้วไม่ได้")
	_invite_accept(21, "Pa", 23, n3)
	_invite_accept(21, "Pa", 24, n4)
	_h(21, {"t": "party_invite", "name": "Pe"})
	_h(25, {"t": "party_reply", "from": "Pa", "accept": false})
	check(_one(21, "notice").get("text", "").contains("ปฏิเสธ") and core.sessions[25]["party"] == 0, "ปฏิเสธคำชวน")
	_invite_accept(21, "Pa", 25, n5)
	check(_one(25, "party").get("members", []).size() == 5, "ปาร์ตี้ 5 คน")
	_h(21, {"t": "party_invite", "name": "Pf"})
	_h(26, {"t": "party_reply", "from": "Pa", "accept": true})
	check(_of(26, "party").is_empty() and core.sessions[26]["party"] == 0
		and core.parties[core.sessions[21]["party"]]["members"].size() == 5, "คนที่ 6 เข้าไม่ได้ (สูงสุด 5)")

	# แบ่ง EXP
	var gid := "krasue_noi"
	var gexp: int = GhostDB.GHOSTS[gid]["exp"]
	_h(21, {"t": "kill", "ghost_id": gid, "map": "pa_cha"})
	var share_ok := true
	for p in [21, 22, 23, 24, 25]:
		var e := _one(p, "exp")
		share_ok = share_ok and e.get("amount") == Protocol.party_share(gexp, 5) and e.get("members") == 5 and e.get("from") == "Pa"
	check(share_ok and _of(26, "exp").is_empty(), "ปาร์ตี้ 5 คนแผนที่เดียวกันได้ EXP คนละ party_share(exp,5)")
	_pos(25, "khlong_village", Vector2.ZERO)
	_h(22, {"t": "kill", "ghost_id": gid, "map": "pa_cha"})
	check(_one(21, "exp").get("amount") == Protocol.party_share(gexp, 4) and _one(21, "exp").get("members") == 4
		and _of(25, "exp").is_empty(), "สมาชิกต่างแผนที่ไม่ได้ EXP และไม่นับ")
	_h(26, {"t": "kill", "ghost_id": gid, "map": "pa_cha"})
	check(_one(26, "exp").get("amount") == gexp and _one(26, "exp").get("members") == 1, "ไม่มีปาร์ตี้ได้ EXP เต็ม")
	_h(26, {"t": "kill", "ghost_id": "not_a_ghost", "map": "pa_cha"})
	check(_of(26, "exp").is_empty(), "ผีไม่รู้จักไม่ได้ EXP")
	var spam := 0
	for i in 20:
		_h(26, {"t": "kill", "ghost_id": gid, "map": "pa_cha"})
		spam += _of(26, "exp").size()
	check(spam <= ServerCore.KILLS_PER_SEC, "จำกัดรายงานปราบผีต่อวินาที (%d)" % spam)

	# บัฟ / ฮีล
	_h(21, {"t": "buff", "skill": "blessing", "lv": 9, "power": 5.0, "duration": 999.0, "effect": "atk", "x": 0.0, "y": 0.0})
	var b := _one(22, "buff")
	check(b.get("from") == "Pa" and b.get("lv") == 5 and b.get("power") == 1.0 and b.get("duration") == 120.0, "บัฟถึงเพื่อนในระยะ + จำกัดค่า")
	check(not _of(24, "buff").is_empty() and _of(23, "buff").is_empty() and _of(25, "buff").is_empty()
		and _of(21, "buff").is_empty() and _of(26, "buff").is_empty(), "บัฟไม่ถึงคนไกล/ต่างแผนที่/ตัวเอง/นอกปาร์ตี้")
	_h(21, {"t": "heal", "amount": 999999, "x": 0, "y": 0})
	check(_one(22, "heal").get("amount") == 100000 and _of(23, "heal").is_empty() and _of(26, "heal").is_empty(), "ฮีลถึงเพื่อนในระยะ")

	# ตำแหน่งผู้เล่นอื่น (และสถานะปาร์ตี้ที่ส่งทุก 1 วินาที)
	core.tick(1.0)
	_drain()
	var snap_item = null
	for item in out:
		if item[0] == 21 and item[1]["t"] == "players":
			snap_item = item
	var names := {}
	var flags := {}
	if snap_item != null:
		for e in snap_item[1]["list"]:
			names[e["name"]] = true
			flags[e["name"]] = e["party"]
	check(snap_item != null and snap_item[2] == false, "snapshot ส่งแบบ unreliable")
	check(names.has("Pb") and names.has("Pf") and not names.has("Pa") and not names.has("Pe") and not names.has("Alice"), "snapshot มีแค่คนอื่นในแผนที่เดียวกัน")
	check(flags.get("Pb") == true and flags.get("Pf") == false, "snapshot บอกว่าอยู่ปาร์ตี้เดียวกันไหม")
	check(_one(21, "party").get("members", []).size() == 5, "ส่งสถานะปาร์ตี้ทุก 1 วินาที")

	# เตะ / ออก / เปลี่ยนหัวหน้า
	_h(22, {"t": "party_kick", "name": "Pc"})
	check(core.sessions[23]["party"] != 0, "ลูกทีมเตะไม่ได้")
	_h(21, {"t": "party_kick", "name": "Pc"})
	check(_one(23, "party").get("members") == [] and _one(21, "party").get("members", []).size() == 4, "หัวหน้าเตะได้")
	_h(21, {"t": "party_leave"})
	check(_one(21, "party").get("members") == [] and _one(22, "party").get("leader") == "Pb", "หัวหน้าออก → คนถัดไปเป็นหัวหน้า")
	_h(24, {"t": "party_leave"})
	core.peer_left(25)
	_drain()
	check(_one(22, "party").get("members") == [] and core.parties.is_empty() and core.sessions[22]["party"] == 0, "เหลือคนเดียวยุบปาร์ตี้")
	check(not core.sessions.has(25), "ออกจากเกมแล้วลบ session")

	# คำชวนหมดอายุ
	_h(21, {"t": "party_invite", "name": "Pf"})
	core.tick(31.0)
	_drain()
	_h(26, {"t": "party_reply", "from": "Pa", "accept": true})
	check(core.sessions[26]["party"] == 0 and not _of(26, "notice").is_empty(), "คำชวนหมดอายุหลัง 30 วินาที")

	# ข้อความมั่ว ห้ามพัง
	var junk: Array = [null, 5, "x", [], {}, {"t": 5}, {"t": "nope"}, {"t": "chat", "ch": "world", "text": 123},
		{"t": "chat", "ch": 1, "text": "a"}, {"t": "pos", "x": "a", "y": null, "map": 3, "equip": [1], "lv": "9"},
		{"t": "pos", "x": NAN, "y": INF, "hp": -5, "equip": {1: 2, "a": "b".repeat(500)}},
		{"t": "kill", "ghost_id": []}, {"t": "buff", "skill": 1}, {"t": "buff", "skill": "a", "effect": "b", "lv": NAN, "power": 1, "duration": 1, "x": 0, "y": 0},
		{"t": "heal", "amount": "9"}, {"t": "party_reply", "from": 3, "accept": "yes"}, {"t": "party_invite", "name": null},
		{"t": "party_kick"}, {"t": "save", "data": "x"}, {"t": "enter", "name": 1}, {"t": "create_char", "name": [], "look": 1},
		{"t": "login", "user": {}, "pass": []}, {"t": "register"}, {"t": "enter_guest"}, {"t": "hello", "v": "1"}]
	for m in junk:
		core.handle(21, m)
		core.handle(10, m)
		core.handle(12345, m)
	_drain()
	check(core.sessions[21]["pos"].is_finite(), "ข้อความมั่วไม่ทำให้พังและตำแหน่งไม่เสีย")

	_rm_rf(dir)
	check(not DirAccess.dir_exists_absolute(dir), "ลบโฟลเดอร์ทดสอบ")
	core = null


# ---------- ENet จริง ----------

func _wait_until(cond: Callable, timeout := 5.0) -> bool:
	var start := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - start > timeout * 1000.0:
			return false
		await process_frame
	return true


func _test_enet() -> void:
	var port := 20000 + randi() % 40000
	var dir := "user://test_server_int_%d" % (randi() % 1000000)
	var server = Server.new()
	root.add_child(server)
	check(server.start(port, dir) == OK, "เปิดเซิร์ฟเวอร์ ENet")
	var c1 = NetClient.new()
	var c2 = NetClient.new()
	root.add_child(c1)
	root.add_child(c2)
	ev = {"c1": {}, "c2": {}}
	for pair in [["c1", c1], ["c2", c2]]:
		var e: Dictionary = ev[pair[0]]
		var c = pair[1]
		c.connected.connect(func(): e["connected"] = true)
		c.auth_result.connect(func(ok: bool, _t: String): e["auth"] = ok)
		c.logged_in.connect(func(_u: String, _g: bool, _c: Array): e["logged_in"] = true)
		c.chars_updated.connect(func(chars: Array, _e: String): e["chars"] = chars.size())
		c.entered.connect(func(n: String, _l: Dictionary, _d: Dictionary): e["entered"] = n)
		c.chat_received.connect(func(_ch: String, from: String, _to: String, text: String): e["chat"] = from + ":" + text)
		c.party_invited.connect(func(from: String): e["invite"] = from)
		c.party_updated.connect(func(_l: String, m: Array): e["party"] = m.size())
		c.players_updated.connect(func(list: Array): e["players"] = list.size())
	c1.connect_to("127.0.0.1", port)
	c2.connect_to("127.0.0.1", port)
	var e1: Dictionary = ev["c1"]
	var e2: Dictionary = ev["c2"]
	check(await _wait_until(func(): return e1.has("connected") and e2.has("connected")), "client ทั้งสองต่อติด")
	check(c1.is_online() and c2.is_online(), "is_online")

	c1.register("user_one", "pass123")
	c2.register("user_two", "pass456")
	check(await _wait_until(func(): return e1.get("auth") == true and e2.get("auth") == true), "สมัครผ่าน ENet")
	c1.login("user_one", "pass123")
	c2.login("user_two", "pass456")
	check(await _wait_until(func(): return e1.has("logged_in") and e2.has("logged_in")), "ล็อกอินผ่าน ENet")
	c1.create_char("Hana", {"gender": "f", "hair": 1, "skin": 1})
	c2.create_char("มะลิ", {"gender": "f"})
	check(await _wait_until(func(): return e1.get("chars") == 1 and e2.get("chars") == 1), "สร้างตัวละครผ่าน ENet")
	c1.enter("Hana")
	c2.enter("มะลิ")
	check(await _wait_until(func(): return e1.get("entered") == "Hana" and e2.get("entered") == "มะลิ"), "เข้าเกมผ่าน ENet")
	var info := {"cls": "novice", "lv": 1, "hp": 30, "mhp": 30, "equip": {}}
	c1.send_pos("khlong_village", Vector2(10, 10), info)
	c2.send_pos("khlong_village", Vector2(20, 20), info)
	check(await _wait_until(func(): return e1.get("players") == 1 and e2.get("players") == 1), "เห็นผู้เล่นอีกคนในแผนที่")
	c1.send_chat("world", "สวัสดีจ้า")
	check(await _wait_until(func(): return e2.get("chat") == "Hana:สวัสดีจ้า"), "แชตโลกถึงอีกคน")
	c1.party_invite("มะลิ")
	check(await _wait_until(func(): return e2.get("invite") == "Hana"), "ได้รับคำชวนปาร์ตี้")
	c2.party_reply("Hana", true)
	check(await _wait_until(func(): return e1.get("party") == 2 and e2.get("party") == 2), "ทั้งสองได้ party_updated 2 คน")
	check(c1.in_party() and c2.party_names().has("Hana") and c2.party_leader == "Hana", "สถานะปาร์ตี้ฝั่ง client")

	c2.close()
	check(await _wait_until(func(): return e1.get("party") == 0), "อีกคนหลุด → ปาร์ตี้ยุบ")
	c1.close()
	server.stop()
	server.queue_free()
	c1.queue_free()
	c2.queue_free()
	await process_frame
	_rm_rf(dir)


func _rm_rf(path: String) -> void:
	var d := DirAccess.open(path)
	if d == null:
		return
	for f in d.get_files():
		d.remove(f)
	for sub in d.get_directories():
		_rm_rf(path + "/" + sub)
	DirAccess.remove_absolute(path)
