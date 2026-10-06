extends RefCounted
## ข้อตกลงการสื่อสารระหว่าง client กับ server (ใช้ร่วมกันทั้งสองฝั่ง)
## ทุกข้อความเป็น Dictionary ที่มีคีย์ "t" บอกชนิดข้อความ ส่งผ่าน ENet แบบ packet ดิบ
## (var_to_bytes / bytes_to_var โดยห้ามมี object)

const DEFAULT_PORT := 7777
const VERSION := 1
## ปาร์ตี้ได้สูงสุด 5 คน ได้โบนัส EXP +5% ต่อสมาชิกหนึ่งคน
const MAX_PARTY := 5
const PARTY_EXP_BONUS := 0.05
## ตัวละครต่อหนึ่งไอดี
const MAX_CHARS := 3
## ความยาวข้อความแชตสูงสุด (ตัวอักษร)
const CHAT_MAX := 120
## ส่งตำแหน่งผู้เล่นคนอื่นทุกกี่วินาที
const SNAPSHOT_INTERVAL := 0.15
## ระยะที่บัฟ/ฮีลถึงเพื่อนในปาร์ตี้ (หน่วยเกม 32 = 1 เมตร)
const BUFF_RANGE := 600.0
## ขนาดข้อมูลเซฟตัวละครสูงสุด (ไบต์)
const SAVE_MAX_BYTES := 65536


## EXP ที่สมาชิกแต่ละคนได้ เมื่อแบ่งกันในปาร์ตี้ members คน (รวมโบนัสปาร์ตี้แล้ว)
static func party_share(exp: int, members: int) -> int:
	var n: int = maxi(members, 1)
	return int(round(exp * (1.0 + PARTY_EXP_BONUS * n) / n))


## ไอดี: 4–16 ตัว ใช้ได้เฉพาะ A–Z a–z 0–9 และ _
static func valid_username(s) -> bool:
	if typeof(s) != TYPE_STRING:
		return false
	var text: String = s
	if text.length() < 4 or text.length() > 16:
		return false
	for i in text.length():
		var c := text.unicode_at(i)
		if not (_is_ascii_alnum(c) or c == 95):
			return false
	return true


## รหัสผ่าน: 6–32 ตัว
static func valid_password(s) -> bool:
	if typeof(s) != TYPE_STRING:
		return false
	var text: String = s
	return text.length() >= 6 and text.length() <= 32


## ชื่อตัวละคร: 2–12 ตัว ใช้อักษรไทย (รวมสระ/วรรณยุกต์) หรือ A–Z a–z 0–9 ห้ามเว้นวรรคหรือสัญลักษณ์
static func valid_char_name(s) -> bool:
	if typeof(s) != TYPE_STRING:
		return false
	var text: String = s
	if text.length() < 2 or text.length() > 12:
		return false
	for i in text.length():
		var c := text.unicode_at(i)
		var thai := c >= 0x0E00 and c <= 0x0E7F
		if not (thai or _is_ascii_alnum(c)):
			return false
	return true


## ทำความสะอาดข้อความแชต: ตัดช่องว่างหัวท้าย เปลี่ยนขึ้นบรรทัดใหม่เป็นเว้นวรรค และตัดให้ไม่เกิน CHAT_MAX
static func clean_chat(text) -> String:
	if typeof(text) != TYPE_STRING:
		return ""
	var s: String = text
	s = s.replace("\r\n", " ").replace("\n", " ").replace("\r", " ").replace("\t", " ")
	s = s.strip_edges()
	if s.length() > CHAT_MAX:
		s = s.substr(0, CHAT_MAX).strip_edges()
	return s


static func _is_ascii_alnum(c: int) -> bool:
	return (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122)
