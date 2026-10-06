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
	var color := ItemDB.color_of(item_id)
	if item["type"] == "equip":
		# ของสวมใส่: กล่องของขวัญสีตามความหายาก มีลำแสงให้มองเห็นจากไกลๆ
		gem = K.box(self, Vector3(0.34, 0.34, 0.34), Vector3(0, 0.35, 0), K.mat(color, 1.2, 0.4))
		K.box(gem, Vector3(0.36, 0.08, 0.08), Vector3.ZERO, K.gold())
		K.box(gem, Vector3(0.08, 0.36, 0.08), Vector3.ZERO, K.gold())
		var beam := CylinderMesh.new()
		beam.top_radius = 0.05
		beam.bottom_radius = 0.25
		beam.height = 4.0
		var mi := K.add(self, beam, Vector3(0, 2.0, 0), K.mat(Color(color, 0.35), 2.5, 0.5, 0.0, false))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	else:
		var glow := 2.5 if item["type"] == "soul" else 0.8
		gem = K.sphere(self, 0.16, Vector3(0, 0.35, 0), K.mat(color, glow, 0.3), 4, Vector3(1, 1.5, 1))


func _process(delta: float) -> void:
	t += delta
	gem.rotation.y = t * 2.0
	gem.position.y = 0.35 + sin(t * 3.0) * 0.06
