extends Node3D
## เอฟเฟกต์สกิลแบบง่าย: วงแหวนขยาย, ลูกธนู/ลูกไฟพุ่งไปหาเป้า, เสาแสง
## แค่ภาพเท่านั้น ดาเมจคำนวณไปแล้วตอนใช้สกิล

const K = preload("res://maps/props/mesh_kit.gd")

var kind := "ring"
var life := 0.4
var max_life := 0.4
var radius := 1.0
var from := Vector3.ZERO
var to := Vector3.ZERO
var color := Color.WHITE
var mesh: MeshInstance3D


static func ring(parent: Node, at: Vector3, radius_m: float, c: Color, duration: float = 0.45) -> void:
	_spawn(parent, "ring", at, at, radius_m, c, duration)


static func shot(parent: Node, a: Vector3, b: Vector3, shot_kind: String, c: Color) -> void:
	_spawn(parent, shot_kind, a, b, 1.0, c, 0.22)


static func pillar(parent: Node, at: Vector3, radius_m: float, c: Color) -> void:
	_spawn(parent, "pillar", at, at, radius_m, c, 0.6)


static func _spawn(parent: Node, k: String, a: Vector3, b: Vector3, r: float, c: Color, duration: float) -> void:
	if parent == null:
		return
	var e: Node3D = load("res://client/effect.gd").new()
	e.kind = k
	e.from = a
	e.to = b
	e.radius = r
	e.color = c
	e.life = duration
	e.max_life = duration
	parent.add_child(e)


func _ready() -> void:
	position = from
	match kind:
		"ring":
			var torus := TorusMesh.new()
			torus.inner_radius = 0.88
			torus.outer_radius = 1.0
			mesh = K.add(self, torus, Vector3(0, 0.3, 0), K.mat(Color(color, 0.85), 3.0, 0.3, 0.0, false))
		"arrow":
			mesh = K.box(self, Vector3(0.05, 0.05, 0.9), Vector3.ZERO, K.mat(color, 1.5, 0.3, 0.0, false))
			look_at_from_position(from, to + Vector3(0, 0.001, 0), Vector3.UP)
		"orb":
			mesh = K.sphere(self, 0.2, Vector3.ZERO, K.mat(color, 4.0, 0.3, 0.0, false), 10)
		"pillar":
			var cyl := CylinderMesh.new()
			cyl.top_radius = radius * 0.4
			cyl.bottom_radius = radius
			cyl.height = 8.0
			mesh = K.add(self, cyl, Vector3(0, 4.0, 0), K.mat(Color(color, 0.45), 3.0, 0.3, 0.0, false))
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(delta: float) -> void:
	life -= delta
	var f := 1.0 - clampf(life / max_life, 0.0, 1.0)
	match kind:
		"ring":
			var r := radius * (0.3 + 0.7 * f)
			mesh.scale = Vector3(r, 1, r)
		"arrow", "orb":
			position = from.lerp(to, f)
		"pillar":
			mesh.scale = Vector3(1.0 - f * 0.6, 1.0, 1.0 - f * 0.6)
	if life <= 0.0:
		queue_free()
