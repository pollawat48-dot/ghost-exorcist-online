extends Node3D
## ไอเทมที่ตกอยู่บนพื้น (อัญมณีหมุนเรืองแสง) เดินทับเพื่อเก็บ

const K = preload("res://maps/props/mesh_kit.gd")
const ItemDB = preload("res://shared/data/items.gd")

var item_id := ""
var pos := Vector2.ZERO
var t := 0.0
var gem: MeshInstance3D


func _ready() -> void:
	position = K.to3d(pos)
	var item: Dictionary = ItemDB.ITEMS[item_id]
	var glow := 2.5 if item["type"] == "soul" else 0.8
	gem = K.sphere(self, 0.16, Vector3(0, 0.35, 0), K.mat(item["color"], glow, 0.3), 4, Vector3(1, 1.5, 1))


func _process(delta: float) -> void:
	t += delta
	gem.rotation.y = t * 2.0
	gem.position.y = 0.35 + sin(t * 3.0) * 0.06
