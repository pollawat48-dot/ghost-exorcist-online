extends Node3D
## ประตูวาร์ปแบบ RO: วงแหวนเรืองแสงหมุนบนพื้น มีดวงไฟลอยวน เดินเข้าไปเพื่อย้ายแผนที่

const K = preload("res://maps/props/mesh_kit.gd")

const RADIUS := 34.0  ## ระยะที่ถือว่าเหยียบประตู (หน่วยเกม)

var data := {}
var pos := Vector2.ZERO
var t := 0.0
var spin: Node3D
var motes: Array[Node3D] = []


func setup(entry: Dictionary) -> void:
	data = entry
	pos = entry["pos"]


func _ready() -> void:
	position = K.to3d(pos)
	var glow := Color(0.62, 0.85, 1.0)
	spin = Node3D.new()
	add_child(spin)
	for i in 3:
		var ring := TorusMesh.new()
		ring.inner_radius = 0.95 - i * 0.28
		ring.outer_radius = 1.05 - i * 0.28
		ring.rings = 32
		K.add(spin, ring, Vector3(0, 0.06 + i * 0.02, 0), K.mat([glow, Color(0.85, 0.7, 1.0), Color(1, 1, 1)][i], 3.0, 0.3, 0.0, false))
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.02
	K.add(self, disc, Vector3(0, 0.03, 0), K.mat(Color(glow, 0.35), 2.0, 0.3, 0.0, false))
	var column := CylinderMesh.new()
	column.top_radius = 0.7
	column.bottom_radius = 1.0
	column.height = 3.0
	var col := K.add(self, column, Vector3(0, 1.5, 0), K.mat(Color(glow, 0.18), 1.5, 0.3, 0.0, false))
	col.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 6:
		var m := Node3D.new()
		add_child(m)
		K.sphere(m, 0.08, Vector3.ZERO, K.mat(Color(1, 1, 1), 4.0, 0.3, 0.0, false), 6)
		motes.append(m)
	var light := OmniLight3D.new()
	light.light_color = glow
	light.omni_range = 5.0
	light.light_energy = 1.4
	light.position.y = 1.0
	add_child(light)
	K.label(self, "วาร์ปไป " + data["name"], Vector3(0, 3.4, 0), Color(0.8, 0.93, 1.0), 38)


func _process(delta: float) -> void:
	t += delta
	spin.rotation.y = t * 1.2
	for i in motes.size():
		var a := t * 1.5 + i * TAU / motes.size()
		motes[i].position = Vector3(cos(a) * 0.9, fposmod(t * 0.6 + i * 0.4, 2.6), sin(a) * 0.9)
