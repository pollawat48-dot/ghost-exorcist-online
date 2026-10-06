extends Node3D
## ผู้เล่นคนอื่นในแผนที่เดียวกัน (ข้อมูลจากเซิร์ฟเวอร์ทุก ~0.15 วินาที) เดินตามตำแหน่งล่าสุดแบบนุ่มๆ
## ชื่อสีชมพู = เพื่อนในปาร์ตี้ คลิกที่ตัวเพื่อกระซิบหรือชวนเข้าปาร์ตี้

const K = preload("res://maps/props/mesh_kit.gd")
const Avatar = preload("res://client/avatar.gd")

const PARTY_COLOR := Color(1.0, 0.72, 0.85)
const OTHER_COLOR := Color(0.85, 0.95, 1.0)

var peer_id := 0
var player_name := ""
var pos := Vector2.ZERO
var target := Vector2.ZERO
var cls := "novice"
var look := {}
var equip := {}
var level := 1
var hp := 1
var max_hp := 1
var in_party := false
var avatar: Node3D
var _facing := Vector2(0, 1)


## d = ข้อมูลผู้เล่นจาก snapshot {"id","name","x","y","cls","lv","hp","mhp","look","equip","party"}
func setup(d: Dictionary) -> void:
	peer_id = int(d.get("id", 0))
	pos = Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0)))
	target = pos
	avatar = Avatar.new()
	add_child(avatar)
	apply(d, true)
	position = K.to3d(pos)


func apply(d: Dictionary, force: bool = false) -> void:
	target = Vector2(float(d.get("x", target.x)), float(d.get("y", target.y)))
	level = int(d.get("lv", level))
	hp = int(d.get("hp", hp))
	max_hp = maxi(1, int(d.get("mhp", max_hp)))
	var new_cls: String = str(d.get("cls", cls))
	var new_look: Dictionary = d.get("look", look) if d.get("look", look) is Dictionary else look
	var new_equip: Dictionary = d.get("equip", equip) if d.get("equip", equip) is Dictionary else equip
	var new_name: String = str(d.get("name", player_name))
	var new_party := bool(d.get("party", in_party))
	if force or new_cls != cls or new_look != look or new_equip != equip:
		cls = new_cls if preload("res://shared/data/classes.gd").CLASSES.has(new_cls) else "novice"
		look = new_look
		equip = new_equip
		player_name = new_name
		in_party = new_party
		avatar.build(cls, look, equip, _tag())
		avatar.set_display_name(_tag(), PARTY_COLOR if in_party else OTHER_COLOR)
	elif new_name != player_name or new_party != in_party:
		player_name = new_name
		in_party = new_party
		avatar.set_display_name(_tag(), PARTY_COLOR if in_party else OTHER_COLOR)


func _tag() -> String:
	return "%s Lv%d" % [player_name, level]


func _process(delta: float) -> void:
	var d := pos.distance_to(target)
	var moving := d > 1.0
	if d > 400.0:
		pos = target  # วาร์ปหรือหลุดไกล: กระโดดไปเลย
	elif moving:
		var step := maxf(160.0 * delta, d * minf(1.0, delta * 8.0))
		var dir := (target - pos).normalized()
		_facing = dir
		pos = pos.move_toward(target, step)
	position = K.to3d(pos)
	avatar.animate(delta, moving, _facing if moving else Vector2.ZERO, 0.0, false, 0.0)
