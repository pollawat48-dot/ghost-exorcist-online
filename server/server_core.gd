extends RefCounted
## ตรรกะของเซิร์ฟเวอร์ออนไลน์ แยกจากการรับส่งจริง เพื่อให้ทดสอบได้ง่าย
## ตัวส่งข้อมูล (server.gd) เรียก handle() เมื่อได้ข้อความ และดึง take_outbox() ไปส่งต่อ
## ข้อมูลจาก client ถือว่าเชื่อไม่ได้ทั้งหมด: ตรวจชนิดและความยาวทุกช่อง ข้อความผิดรูปแบบให้ข้ามไป
## ผู้เล่นทุกคนถือตัวละครของตัวเอง (คำนวณต่อสู้ฝั่ง client) เซิร์ฟเวอร์ทำหน้าที่ ไอดี/เซฟ แชต ปาร์ตี้ แบ่ง EXP และส่งต่อบัฟ

const Protocol = preload("res://shared/net/protocol.gd")
const GhostDB = preload("res://shared/data/ghosts.gd")
const AccountStore = preload("res://server/account_store.gd")

const INVITE_TIMEOUT := 30.0
const PARTY_PUSH_INTERVAL := 1.0
## แชตได้ไม่เกิน CHAT_BURST ข้อความใน CHAT_WINDOW วินาที
const CHAT_BURST := 5
const CHAT_WINDOW := 5.0
## รายงานปราบผีได้ไม่เกินวินาทีละ KILLS_PER_SEC ครั้ง
const KILLS_PER_SEC := 10
## สมัคร/ล็อกอินได้ไม่เกิน AUTH_BURST ครั้งใน AUTH_WINDOW วินาที (กันเดารหัส)
const AUTH_BURST := 6
const AUTH_WINDOW := 10.0
const POS_LIMIT := 1000000.0
const MAX_STAT := 100000000

var store
## [[peer_id, msg, reliable]] ที่รอส่ง
var outbox: Array = []
## peer_id -> Dictionary ข้อมูลผู้เล่นที่ต่ออยู่
var sessions: Dictionary = {}
## party_id -> {"leader": peer, "members": [peer, ...]}
var parties: Dictionary = {}
## peer ผู้ถูกชวน -> {peer ผู้ชวน: เวลาหมดอายุ}
var invites: Dictionary = {}
## เวลาของเซิร์ฟเวอร์ (วินาที) เดินด้วย tick()
var now := 0.0

var _next_party := 1
var _snapshot_timer := 0.0
var _party_timer := 0.0
var _rng := RandomNumberGenerator.new()


func _init(account_store) -> void:
	store = account_store
	_rng.randomize()


func take_outbox() -> Array:
	var out := outbox
	outbox = []
	return out


func peer_joined(peer: int) -> void:
	sessions[peer] = {
		"hello": false, "account": "", "guest": false, "logged_in": false, "in_world": false,
		"name": "", "map": "", "pos": Vector2.ZERO, "cls": "novice", "lv": 1, "hp": 1, "mhp": 1,
		"look": {}, "equip": {}, "party": 0,
		"chat_times": [], "auth_times": [], "kill_sec": -1, "kill_count": 0,
	}


func peer_left(peer: int) -> void:
	if not sessions.has(peer):
		return
	_leave_world(peer)
	sessions.erase(peer)


func tick(delta: float) -> void:
	if typeof(delta) != TYPE_FLOAT or not is_finite(delta) or delta < 0.0:
		return
	now += delta
	_snapshot_timer += delta
	if _snapshot_timer >= Protocol.SNAPSHOT_INTERVAL:
		_snapshot_timer = 0.0
		_send_snapshots()
	_party_timer += delta
	if _party_timer >= PARTY_PUSH_INTERVAL:
		_party_timer = 0.0
		_expire_invites()
		for pid in parties:
			_push_party(pid)


func handle(peer: int, msg) -> void:
	if typeof(msg) != TYPE_DICTIONARY or not sessions.has(peer):
		return
	var t = msg.get("t")
	if typeof(t) != TYPE_STRING:
		return
	var s: Dictionary = sessions[peer]
	if t == "hello":
		_on_hello(peer, s, msg)
		return
	if not s["hello"]:
		return
	match t:
		"register": _on_register(peer, s, msg)
		"login": _on_login(peer, s, msg)
		"guest": _on_guest(peer, s)
		"create_char": _on_create_char(peer, s, msg)
		"delete_char": _on_delete_char(peer, s, msg)
		"enter": _on_enter(peer, s, msg)
		"enter_guest": _on_enter_guest(peer, s, msg)
		"save": _on_save(peer, s, msg)
		"pos": _on_pos(s, msg)
		"chat": _on_chat(peer, s, msg)
		"party_invite": _on_party_invite(peer, s, msg)
		"party_reply": _on_party_reply(peer, s, msg)
		"party_leave":
			if s["in_world"]:
				_party_remove(peer, "")
		"party_kick": _on_party_kick(peer, s, msg)
		"kill": _on_kill(peer, s, msg)
		"buff": _on_buff(peer, s, msg)
		"heal": _on_heal(peer, s, msg)


# ---------- ไอดีและตัวละคร ----------

func _on_hello(peer: int, s: Dictionary, msg: Dictionary) -> void:
	var v = msg.get("v")
	if typeof(v) != TYPE_INT or v != Protocol.VERSION:
		_send(peer, {"t": "error", "text": "เวอร์ชันเกมไม่ตรงกับเซิร์ฟเวอร์ กรุณาอัปเดตเกม"})
		return
	s["hello"] = true
	_send(peer, {"t": "hello_ok"})


func _auth_allowed(peer: int, s: Dictionary) -> bool:
	var times: Array = s["auth_times"]
	while not times.is_empty() and now - float(times[0]) >= AUTH_WINDOW:
		times.pop_front()
	if times.size() >= AUTH_BURST:
		_send(peer, {"t": "auth_err", "text": "ลองบ่อยเกินไป รอสักครู่แล้วลองใหม่"})
		return false
	times.append(now)
	return true


func _on_register(peer: int, s: Dictionary, msg: Dictionary) -> void:
	if s["in_world"] or not _auth_allowed(peer, s):
		return
	var err: String = store.register(msg.get("user"), msg.get("pass"))
	if err == "":
		_send(peer, {"t": "register_ok"})
	else:
		_send(peer, {"t": "auth_err", "text": err})


func _on_login(peer: int, s: Dictionary, msg: Dictionary) -> void:
	if s["in_world"] or not _auth_allowed(peer, s):
		return
	var user = msg.get("user")
	if not store.check_login(user, msg.get("pass")):
		_send(peer, {"t": "auth_err", "text": "ไอดีหรือรหัสผ่านไม่ถูกต้อง"})
		return
	var key: String = String(user).to_lower()
	for other in sessions:
		if other != peer and sessions[other]["account"] == key:
			_send(peer, {"t": "auth_err", "text": "ไอดีนี้กำลังออนไลน์อยู่ที่เครื่องอื่น"})
			return
	s["account"] = key
	s["guest"] = false
	s["logged_in"] = true
	_send(peer, {"t": "login_ok", "user": key, "chars": store.chars_of(key)})


func _on_guest(peer: int, s: Dictionary) -> void:
	if s["in_world"]:
		return
	s["account"] = ""
	s["guest"] = true
	s["logged_in"] = true
	_send(peer, {"t": "login_ok", "user": "", "guest": true, "chars": []})


func _is_member(s: Dictionary) -> bool:
	return s["logged_in"] and not s["guest"] and s["account"] != ""


func _on_create_char(peer: int, s: Dictionary, msg: Dictionary) -> void:
	if not _is_member(s) or s["in_world"]:
		return
	var err: String = store.create_char(s["account"], msg.get("name"), msg.get("look"))
	if err == "":
		_send(peer, {"t": "chars", "chars": store.chars_of(s["account"])})
	else:
		_send(peer, {"t": "char_err", "text": err})


func _on_delete_char(peer: int, s: Dictionary, msg: Dictionary) -> void:
	if not _is_member(s) or s["in_world"]:
		return
	store.delete_char(s["account"], msg.get("name"))
	_send(peer, {"t": "chars", "chars": store.chars_of(s["account"])})


func _on_enter(peer: int, s: Dictionary, msg: Dictionary) -> void:
	if not _is_member(s):
		return
	var loaded: Dictionary = store.load_char(s["account"], msg.get("name"))
	if loaded.is_empty():
		_send(peer, {"t": "char_err", "text": "ไม่พบตัวละครนี้"})
		return
	_leave_world(peer)
	var summary := {}
	for c in store.chars_of(s["account"]):
		if c["name"] == loaded["name"]:
			summary = c
	s["lv"] = int(summary.get("level", 1))
	s["cls"] = String(summary.get("class", "novice"))
	_enter_world(peer, s, loaded["name"], loaded["look"])
	_send(peer, {"t": "entered", "name": loaded["name"], "look": loaded["look"], "data": loaded["data"]})


func _on_enter_guest(peer: int, s: Dictionary, msg: Dictionary) -> void:
	if not s["logged_in"] or not s["guest"]:
		return
	var name = msg.get("name")
	if not Protocol.valid_char_name(name):
		_send(peer, {"t": "char_err", "text": "ชื่อตัวละครต้องยาว 2–12 ตัว ใช้อักษรไทย อังกฤษ หรือตัวเลข ไม่มีเว้นวรรค"})
		return
	_leave_world(peer)
	var final_name: String = name
	while store.name_taken(final_name) or _find_online(final_name) != 0:
		final_name = String(name) + "#%03d" % _rng.randi_range(0, 999)
	var look: Dictionary = AccountStore.sanitize_look(msg.get("look"))
	_enter_world(peer, s, final_name, look)
	_send(peer, {"t": "entered", "name": final_name, "look": look, "data": {}})


func _enter_world(peer: int, s: Dictionary, name: String, look: Dictionary) -> void:
	s["in_world"] = true
	s["name"] = name
	s["look"] = look
	s["map"] = ""
	s["pos"] = Vector2.ZERO
	s["equip"] = {}
	s["party"] = 0
	invites.erase(peer)


## ออกจากโลก: ออกจากปาร์ตี้ ล้างคำชวน ผู้เล่นอื่นจะไม่เห็นอีก
func _leave_world(peer: int) -> void:
	var s: Dictionary = sessions[peer]
	if not s["in_world"]:
		return
	_party_remove(peer, "")
	invites.erase(peer)
	for target in invites:
		invites[target].erase(peer)
	s["in_world"] = false
	s["name"] = ""
	s["map"] = ""


func _on_save(peer: int, s: Dictionary, msg: Dictionary) -> void:
	if not s["in_world"] or not _is_member(s):
		return
	var ok: bool = store.save_char(s["account"], s["name"], msg.get("data"))
	if ok:
		var state: Dictionary = msg["data"]["state"]
		if typeof(state.get("level")) == TYPE_INT:
			s["lv"] = clampi(state["level"], 1, 999)
	_send(peer, {"t": "saved", "ok": ok})


func _on_pos(s: Dictionary, msg: Dictionary) -> void:
	if not s["in_world"]:
		return
	var map = msg.get("map")
	if typeof(map) == TYPE_STRING and map.length() <= 64:
		s["map"] = map
	if _is_num(msg.get("x")) and _is_num(msg.get("y")):
		s["pos"] = Vector2(
			clampf(float(msg["x"]), -POS_LIMIT, POS_LIMIT),
			clampf(float(msg["y"]), -POS_LIMIT, POS_LIMIT))
	var cls = msg.get("cls")
	if typeof(cls) == TYPE_STRING and cls.length() <= 32:
		s["cls"] = cls
	if typeof(msg.get("lv")) == TYPE_INT:
		s["lv"] = clampi(msg["lv"], 1, 999)
	if typeof(msg.get("mhp")) == TYPE_INT:
		s["mhp"] = clampi(msg["mhp"], 1, MAX_STAT)
	if typeof(msg.get("hp")) == TYPE_INT:
		s["hp"] = clampi(msg["hp"], 0, s["mhp"])
	var equip = msg.get("equip")
	if typeof(equip) == TYPE_DICTIONARY and equip.size() <= 16:
		var clean := {}
		for slot in equip:
			var item = equip[slot]
			if typeof(slot) == TYPE_STRING and slot.length() <= 24 \
					and typeof(item) == TYPE_STRING and item.length() <= 48:
				clean[slot] = item
		s["equip"] = clean


# ---------- แชต ----------

func _on_chat(peer: int, s: Dictionary, msg: Dictionary) -> void:
	if not s["in_world"]:
		return
	var ch = msg.get("ch")
	if typeof(ch) != TYPE_STRING or not (ch in ["world", "party", "whisper"]):
		return
	var text := Protocol.clean_chat(msg.get("text"))
	if text == "":
		return
	var times: Array = s["chat_times"]
	while not times.is_empty() and now - float(times[0]) >= CHAT_WINDOW:
		times.pop_front()
	if times.size() >= CHAT_BURST:
		_notice(peer, "พิมพ์เร็วเกินไป รอสักครู่แล้วค่อยพิมพ์ใหม่")
		return
	times.append(now)
	var out := {"t": "chat", "ch": ch, "from": s["name"], "to": "", "text": text}
	match ch:
		"world":
			for other in sessions:
				if sessions[other]["in_world"]:
					_send(other, out)
		"party":
			if s["party"] == 0:
				_notice(peer, "ยังไม่ได้อยู่ในปาร์ตี้")
				return
			for m in parties[s["party"]]["members"]:
				_send(m, out)
		"whisper":
			var to = msg.get("to")
			if typeof(to) != TYPE_STRING or to.length() > 20:
				return
			var target := _find_online(to)
			if target == 0:
				_notice(peer, "ไม่พบผู้เล่นชื่อ %s" % to)
				return
			out["to"] = sessions[target]["name"]
			_send(target, out)
			if target != peer:
				_send(peer, out)


# ---------- ปาร์ตี้ ----------

func _on_party_invite(peer: int, s: Dictionary, msg: Dictionary) -> void:
	if not s["in_world"]:
		return
	var name = msg.get("name")
	if typeof(name) != TYPE_STRING or name.length() > 20:
		return
	var target := _find_online(name)
	if target == 0:
		_notice(peer, "ไม่พบผู้เล่นชื่อ %s" % name)
		return
	if target == peer:
		_notice(peer, "ชวนตัวเองเข้าปาร์ตี้ไม่ได้")
		return
	var pid: int = s["party"]
	if pid != 0:
		if parties[pid]["leader"] != peer:
			_notice(peer, "เฉพาะหัวหน้าปาร์ตี้เท่านั้นที่ชวนคนเข้าได้")
			return
		if parties[pid]["members"].size() >= Protocol.MAX_PARTY:
			_notice(peer, "ปาร์ตี้เต็มแล้ว (สูงสุด %d คน)" % Protocol.MAX_PARTY)
			return
	var ts: Dictionary = sessions[target]
	if ts["party"] != 0:
		_notice(peer, "%s อยู่ในปาร์ตี้อื่นแล้ว" % ts["name"])
		return
	if not invites.has(target):
		invites[target] = {}
	invites[target][peer] = now + INVITE_TIMEOUT
	_send(target, {"t": "party_invite", "from": s["name"]})
	_notice(peer, "ส่งคำชวนเข้าปาร์ตี้ไปหา %s แล้ว" % ts["name"])


func _on_party_reply(peer: int, s: Dictionary, msg: Dictionary) -> void:
	if not s["in_world"]:
		return
	var from = msg.get("from")
	var accept = msg.get("accept")
	if typeof(from) != TYPE_STRING or from.length() > 20 or typeof(accept) != TYPE_BOOL:
		return
	var inviter := _find_online(from)
	var mine: Dictionary = invites.get(peer, {})
	if inviter == 0 or not mine.has(inviter) or float(mine[inviter]) < now:
		if inviter != 0:
			mine.erase(inviter)
		_notice(peer, "คำชวนนี้หมดอายุแล้ว")
		return
	mine.erase(inviter)
	if not accept:
		_notice(inviter, "%s ปฏิเสธคำชวนเข้าปาร์ตี้" % s["name"])
		return
	if s["party"] != 0:
		_notice(peer, "คุณอยู่ในปาร์ตี้อยู่แล้ว")
		return
	var inv_s: Dictionary = sessions[inviter]
	var pid: int = inv_s["party"]
	if pid == 0:
		pid = _next_party
		_next_party += 1
		parties[pid] = {"leader": inviter, "members": [inviter]}
		inv_s["party"] = pid
	elif parties[pid]["leader"] != inviter:
		_notice(peer, "คำชวนนี้หมดอายุแล้ว")
		return
	elif parties[pid]["members"].size() >= Protocol.MAX_PARTY:
		_notice(peer, "ปาร์ตี้เต็มแล้ว (สูงสุด %d คน)" % Protocol.MAX_PARTY)
		return
	parties[pid]["members"].append(peer)
	s["party"] = pid
	invites.erase(peer)
	for m in parties[pid]["members"]:
		if m != peer:
			_notice(m, "%s เข้าร่วมปาร์ตี้" % s["name"])
	_push_party(pid)


func _on_party_kick(peer: int, s: Dictionary, msg: Dictionary) -> void:
	var pid: int = s["party"]
	if not s["in_world"] or pid == 0:
		return
	if parties[pid]["leader"] != peer:
		_notice(peer, "เฉพาะหัวหน้าปาร์ตี้เท่านั้นที่เตะสมาชิกได้")
		return
	var name = msg.get("name")
	if typeof(name) != TYPE_STRING:
		return
	var target := _find_online(name)
	if target == 0 or target == peer or sessions[target]["party"] != pid:
		_notice(peer, "ไม่พบ %s ในปาร์ตี้" % name)
		return
	_party_remove(target, "คุณถูกเชิญออกจากปาร์ตี้")


## เอาผู้เล่นออกจากปาร์ตี้ ถ้าเป็นหัวหน้าให้คนถัดไปเป็นแทน เหลือคนเดียวก็ยุบปาร์ตี้
func _party_remove(peer: int, reason: String) -> void:
	var s: Dictionary = sessions[peer]
	var pid: int = s["party"]
	if pid == 0 or not parties.has(pid):
		s["party"] = 0
		return
	var party: Dictionary = parties[pid]
	party["members"].erase(peer)
	s["party"] = 0
	_send(peer, {"t": "party", "leader": "", "members": []})
	if reason != "":
		_notice(peer, reason)
	if party["members"].size() <= 1:
		for m in party["members"]:
			sessions[m]["party"] = 0
			_send(m, {"t": "party", "leader": "", "members": []})
			_notice(m, "ปาร์ตี้ถูกยุบแล้ว")
		parties.erase(pid)
		return
	if party["leader"] == peer:
		party["leader"] = party["members"][0]
	for m in party["members"]:
		_notice(m, "%s ออกจากปาร์ตี้" % s["name"])
	_push_party(pid)


func _push_party(pid: int) -> void:
	if not parties.has(pid):
		return
	var party: Dictionary = parties[pid]
	var list := []
	for m in party["members"]:
		var ms: Dictionary = sessions[m]
		list.append({"name": ms["name"], "lv": ms["lv"], "cls": ms["cls"], "map": ms["map"], "hp": ms["hp"], "mhp": ms["mhp"]})
	var out := {"t": "party", "leader": sessions[party["leader"]]["name"], "members": list}
	for m in party["members"]:
		_send(m, out)


func _expire_invites() -> void:
	for target in invites.keys():
		var mine: Dictionary = invites[target]
		for inviter in mine.keys():
			if float(mine[inviter]) < now:
				mine.erase(inviter)
		if mine.is_empty():
			invites.erase(target)


# ---------- ปราบผี แบ่ง EXP บัฟ ----------

func _on_kill(peer: int, s: Dictionary, msg: Dictionary) -> void:
	if not s["in_world"]:
		return
	var gid = msg.get("ghost_id")
	if typeof(gid) != TYPE_STRING or not GhostDB.GHOSTS.has(gid):
		return
	var sec := int(floor(now))
	if s["kill_sec"] != sec:
		s["kill_sec"] = sec
		s["kill_count"] = 0
	s["kill_count"] += 1
	if s["kill_count"] > KILLS_PER_SEC:
		return
	var map = msg.get("map")
	if typeof(map) == TYPE_STRING and map.length() <= 64:
		s["map"] = map
	var exp: int = int(GhostDB.GHOSTS[gid]["exp"])
	var receivers := [peer]
	if s["party"] != 0:
		receivers = []
		for m in parties[s["party"]]["members"]:
			if sessions[m]["map"] == s["map"]:
				receivers.append(m)
	var n := receivers.size()
	var amount: int = Protocol.party_share(exp, n) if s["party"] != 0 else exp
	for r in receivers:
		_send(r, {"t": "exp", "amount": amount, "ghost_id": gid, "from": s["name"], "members": n})


func _buff_targets(peer: int, s: Dictionary, x: float, y: float) -> Array:
	var out := []
	if s["party"] == 0:
		return out
	var center := Vector2(x, y)
	for m in parties[s["party"]]["members"]:
		if m == peer:
			continue
		var ms: Dictionary = sessions[m]
		if ms["map"] == s["map"] and ms["pos"].distance_to(center) <= Protocol.BUFF_RANGE:
			out.append(m)
	return out


func _on_buff(peer: int, s: Dictionary, msg: Dictionary) -> void:
	if not s["in_world"] or s["party"] == 0:
		return
	var skill = msg.get("skill")
	var effect = msg.get("effect")
	if typeof(skill) != TYPE_STRING or skill.length() > 32 or typeof(effect) != TYPE_STRING or effect.length() > 32:
		return
	if not (_is_num(msg.get("lv")) and _is_num(msg.get("power")) and _is_num(msg.get("duration"))):
		return
	if not (_is_num(msg.get("x")) and _is_num(msg.get("y"))):
		return
	var x := clampf(float(msg["x"]), -POS_LIMIT, POS_LIMIT)
	var y := clampf(float(msg["y"]), -POS_LIMIT, POS_LIMIT)
	var out := {
		"t": "buff", "skill": skill, "effect": effect,
		"lv": int(clampf(float(msg["lv"]), 1.0, 5.0)),
		"power": clampf(float(msg["power"]), 0.0, 1.0),
		"duration": clampf(float(msg["duration"]), 0.0, 120.0),
		"x": x, "y": y, "from": s["name"],
	}
	for m in _buff_targets(peer, s, x, y):
		_send(m, out)


func _on_heal(peer: int, s: Dictionary, msg: Dictionary) -> void:
	if not s["in_world"] or s["party"] == 0:
		return
	if not (_is_num(msg.get("amount")) and _is_num(msg.get("x")) and _is_num(msg.get("y"))):
		return
	var amount := int(clampf(float(msg["amount"]), 0.0, 100000.0))
	if amount <= 0:
		return
	var x := clampf(float(msg["x"]), -POS_LIMIT, POS_LIMIT)
	var y := clampf(float(msg["y"]), -POS_LIMIT, POS_LIMIT)
	for m in _buff_targets(peer, s, x, y):
		_send(m, {"t": "heal", "amount": amount, "from": s["name"]})


# ---------- ตำแหน่งผู้เล่นอื่น ----------

func _send_snapshots() -> void:
	var by_map := {}
	for p in sessions:
		var s: Dictionary = sessions[p]
		if s["in_world"] and s["map"] != "":
			if not by_map.has(s["map"]):
				by_map[s["map"]] = []
			by_map[s["map"]].append(p)
	for map in by_map:
		var peers: Array = by_map[map]
		for receiver in peers:
			var my_party: int = sessions[receiver]["party"]
			var list := []
			for p in peers:
				if p == receiver:
					continue
				var s: Dictionary = sessions[p]
				list.append({
					"id": p, "name": s["name"], "x": s["pos"].x, "y": s["pos"].y,
					"cls": s["cls"], "lv": s["lv"], "hp": s["hp"], "mhp": s["mhp"],
					"look": s["look"], "equip": s["equip"],
					"party": my_party != 0 and s["party"] == my_party,
				})
			_send(receiver, {"t": "players", "list": list}, false)


# ---------- ตัวช่วย ----------

## หา peer ของผู้เล่นที่อยู่ในโลกจากชื่อ (ไม่สนตัวพิมพ์) คืน 0 ถ้าไม่พบ
func _find_online(name) -> int:
	if typeof(name) != TYPE_STRING or name == "":
		return 0
	var lname: String = String(name).to_lower()
	for p in sessions:
		var s: Dictionary = sessions[p]
		if s["in_world"] and String(s["name"]).to_lower() == lname:
			return p
	return 0


func _is_num(v) -> bool:
	if typeof(v) == TYPE_INT:
		return true
	return typeof(v) == TYPE_FLOAT and is_finite(v)


func _notice(peer: int, text: String) -> void:
	_send(peer, {"t": "notice", "text": text})


func _send(peer: int, msg: Dictionary, reliable: bool = true) -> void:
	outbox.append([peer, msg, reliable])
