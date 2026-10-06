extends RefCounted
## คลังไอดีและตัวละครของเซิร์ฟเวอร์ เก็บลงไฟล์ในโฟลเดอร์ data_dir
## accounts.dat = รายชื่อไอดี (รหัสผ่านเก็บเป็น salt + SHA-256 วนซ้ำ ไม่เก็บตัวจริง) และสรุปตัวละคร
## chars/<hash ของชื่อ>.dat = ข้อมูลเซฟของตัวละครแต่ละตัว
## ไอดีและชื่อตัวละครไม่สนตัวพิมพ์เล็กใหญ่ ชื่อตัวละครห้ามซ้ำกันทั้งเซิร์ฟเวอร์

const Protocol = preload("res://shared/net/protocol.gd")
const Classes = preload("res://shared/data/classes.gd")

const HASH_ROUNDS := 2000
const LOOK_DEFAULT := {"gender": "m", "hair": 0, "skin": 0}

var data_dir: String
## user (ตัวเล็ก) -> {"user", "salt", "hash", "chars": [สรุปตัวละคร]}
var accounts: Dictionary = {}
## ชื่อตัวละคร (ตัวเล็ก) -> user (ตัวเล็ก)
var name_index: Dictionary = {}


func _init(dir: String = "user://server_data") -> void:
	data_dir = dir
	DirAccess.make_dir_recursive_absolute(data_dir + "/chars")
	_load()


## สมัครไอดี: คืน "" ถ้าสำเร็จ ไม่งั้นคืนข้อความผิดพลาด
func register(user, pw) -> String:
	if not Protocol.valid_username(user):
		return "ไอดีต้องยาว 4–16 ตัว ใช้ได้แค่ A–Z 0–9 และ _"
	if not Protocol.valid_password(pw):
		return "รหัสผ่านต้องยาว 6–32 ตัว"
	var key: String = String(user).to_lower()
	if accounts.has(key):
		return "ไอดีนี้มีคนใช้แล้ว"
	var salt := _random_salt()
	accounts[key] = {"user": String(user), "salt": salt, "hash": _hash(salt, pw), "chars": []}
	_save_accounts()
	return ""


func check_login(user, pw) -> bool:
	if typeof(user) != TYPE_STRING or typeof(pw) != TYPE_STRING:
		return false
	var acc = accounts.get(String(user).to_lower())
	if typeof(acc) != TYPE_DICTIONARY:
		return false
	return _hash(acc["salt"], pw) == acc["hash"]


func has_account(user) -> bool:
	return typeof(user) == TYPE_STRING and accounts.has(String(user).to_lower())


## ชื่อนี้มีตัวละครที่ลงทะเบียนไว้แล้วหรือยัง
func name_taken(name) -> bool:
	return typeof(name) == TYPE_STRING and name_index.has(String(name).to_lower())


## สรุปตัวละครของไอดี: [{"name","level","class","look"}]
func chars_of(user) -> Array:
	var acc = accounts.get(String(user).to_lower()) if typeof(user) == TYPE_STRING else null
	if typeof(acc) != TYPE_DICTIONARY:
		return []
	return acc["chars"].duplicate(true)


## สร้างตัวละคร: คืน "" ถ้าสำเร็จ ไม่งั้นคืนข้อความผิดพลาด
func create_char(user, name, look) -> String:
	var acc = accounts.get(String(user).to_lower()) if typeof(user) == TYPE_STRING else null
	if typeof(acc) != TYPE_DICTIONARY:
		return "ไม่พบไอดีนี้"
	if not Protocol.valid_char_name(name):
		return "ชื่อตัวละครต้องยาว 2–12 ตัว ใช้อักษรไทย อังกฤษ หรือตัวเลข ไม่มีเว้นวรรค"
	if acc["chars"].size() >= Protocol.MAX_CHARS:
		return "สร้างตัวละครได้สูงสุด %d ตัวต่อไอดี" % Protocol.MAX_CHARS
	var lname: String = String(name).to_lower()
	if name_index.has(lname):
		return "ชื่อตัวละครนี้มีคนใช้แล้ว"
	acc["chars"].append({"name": String(name), "level": 1, "class": "novice", "look": sanitize_look(look)})
	name_index[lname] = String(user).to_lower()
	_save_accounts()
	return ""


func delete_char(user, name) -> bool:
	var idx := _char_index(user, name)
	if idx < 0:
		return false
	var acc: Dictionary = accounts[String(user).to_lower()]
	acc["chars"].remove_at(idx)
	var lname: String = String(name).to_lower()
	name_index.erase(lname)
	var path := _char_path(lname)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	_save_accounts()
	return true


## โหลดตัวละคร: {"name","look","data"} (data = {} ถ้ายังไม่เคยเซฟ) หรือ {} ถ้าไม่ใช่ตัวของไอดีนี้
func load_char(user, name) -> Dictionary:
	var idx := _char_index(user, name)
	if idx < 0:
		return {}
	var summary: Dictionary = accounts[String(user).to_lower()]["chars"][idx]
	var data := {}
	var path := _char_path(String(name).to_lower())
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f != null:
			var v = f.get_var(false)
			if typeof(v) == TYPE_DICTIONARY:
				data = v
	return {"name": summary["name"], "look": summary["look"].duplicate(), "data": data}


## เซฟตัวละคร: data ต้องมี "state" เป็น Dictionary และขนาดไม่เกิน SAVE_MAX_BYTES
func save_char(user, name, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY or typeof(data.get("state")) != TYPE_DICTIONARY:
		return false
	if var_to_bytes(data).size() > Protocol.SAVE_MAX_BYTES:
		return false
	var idx := _char_index(user, name)
	if idx < 0:
		return false
	var f := FileAccess.open(_char_path(String(name).to_lower()), FileAccess.WRITE)
	if f == null:
		return false
	f.store_var(data, false)
	f.close()
	var summary: Dictionary = accounts[String(user).to_lower()]["chars"][idx]
	var state: Dictionary = data["state"]
	var lv = state.get("level")
	if typeof(lv) == TYPE_INT and lv >= 1 and lv <= 999:
		summary["level"] = lv
	var cls = state.get("class")
	if typeof(cls) == TYPE_STRING and Classes.CLASSES.has(cls):
		summary["class"] = cls
	_save_accounts()
	return true


## รับเฉพาะ gender ("m"/"f"), hair (0–4), skin (0–2) ค่าอื่นใช้ค่าเริ่มต้น
static func sanitize_look(look) -> Dictionary:
	var out: Dictionary = LOOK_DEFAULT.duplicate()
	if typeof(look) != TYPE_DICTIONARY:
		return out
	var g = look.get("gender")
	if typeof(g) == TYPE_STRING and (g == "m" or g == "f"):
		out["gender"] = g
	var h = look.get("hair")
	if typeof(h) == TYPE_INT or typeof(h) == TYPE_FLOAT:
		out["hair"] = clampi(int(h), 0, 4)
	var s = look.get("skin")
	if typeof(s) == TYPE_INT or typeof(s) == TYPE_FLOAT:
		out["skin"] = clampi(int(s), 0, 2)
	return out


func _char_index(user, name) -> int:
	if typeof(user) != TYPE_STRING or typeof(name) != TYPE_STRING:
		return -1
	var acc = accounts.get(String(user).to_lower())
	if typeof(acc) != TYPE_DICTIONARY:
		return -1
	var lname: String = String(name).to_lower()
	for i in acc["chars"].size():
		if String(acc["chars"][i]["name"]).to_lower() == lname:
			return i
	return -1


func _char_path(lname: String) -> String:
	return data_dir + "/chars/" + lname.sha256_text().substr(0, 32) + ".dat"


func _hash(salt: String, pw) -> String:
	var h: String = salt + String(pw)
	for i in HASH_ROUNDS:
		h = (salt + h).sha256_text()
	return h


func _random_salt() -> String:
	var crypto := Crypto.new()
	return crypto.generate_random_bytes(16).hex_encode()


func _load() -> void:
	accounts = {}
	name_index = {}
	var path := data_dir + "/accounts.dat"
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var v = f.get_var(false)
	if typeof(v) != TYPE_DICTIONARY:
		return
	accounts = v
	for key in accounts:
		for c in accounts[key]["chars"]:
			name_index[String(c["name"]).to_lower()] = key


func _save_accounts() -> void:
	var path := data_dir + "/accounts.dat"
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("บันทึกไอดีไม่ได้: " + path)
		return
	f.store_var(accounts, false)
	f.close()
	DirAccess.rename_absolute(tmp, path)
