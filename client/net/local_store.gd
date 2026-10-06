extends RefCounted
## ตัวละครของผู้เล่นแบบ Guest เก็บไว้ในเครื่องตัวเอง (ยังไม่ได้สมัครไอดี)
## เล่นได้ทั้งออฟไลน์ และออนไลน์แบบ guest (เซิร์ฟเวอร์ไม่เก็บข้อมูล guest)

const Protocol = preload("res://shared/net/protocol.gd")

var path := "user://guest_chars.dat"
var chars := {}  ## ชื่อ -> {"look", "data"}


func _init(file_path: String = "") -> void:
	if file_path != "":
		path = file_path
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		if f != null:
			var v: Variant = f.get_var(false)
			if v is Dictionary:
				chars = v


func _write() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_var(chars, false)


## สรุปตัวละครทั้งหมด (รูปแบบเดียวกับที่เซิร์ฟเวอร์ส่งมา)
func list() -> Array:
	var out := []
	for n in chars:
		var st: Dictionary = chars[n]["data"].get("state", {})
		out.append({"name": n, "level": st.get("level", 1), "class": st.get("class", "novice"), "look": chars[n]["look"]})
	return out


## สร้างตัวละครใหม่ คืนข้อความผิดพลาด ("" = สำเร็จ)
func create(char_name: String, look: Dictionary) -> String:
	if not Protocol.valid_char_name(char_name):
		return "ชื่อตัวละครต้องยาว 2–12 ตัวอักษร ใช้ภาษาไทย อังกฤษ หรือตัวเลข"
	if chars.size() >= Protocol.MAX_CHARS:
		return "สร้างตัวละครได้สูงสุด %d ตัว" % Protocol.MAX_CHARS
	for n in chars:
		if n.to_lower() == char_name.to_lower():
			return "มีตัวละครชื่อนี้แล้ว"
	chars[char_name] = {"look": look.duplicate(), "data": {}}
	_write()
	return ""


func delete(char_name: String) -> void:
	chars.erase(char_name)
	_write()


func load_char(char_name: String) -> Dictionary:
	return chars.get(char_name, {})


func save(char_name: String, data: Dictionary) -> void:
	if chars.has(char_name):
		chars[char_name]["data"] = data
		_write()
