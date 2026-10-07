extends Node3D
## ออร่ารอบตัวตอนติดบัฟ (ลูกของ player): วงเวทหมุนใต้เท้า ลูกแก้วลอยวนรอบตัว ประกายลอยขึ้น
## แต่ละบัฟมีสีของตัวเอง ติดหลายบัฟวงจะซ้อนกันหลายชั้น อาคมคงกระพันมีโล่ใสครอบตัว
## player เรียก show_buffs() ทุกเฟรมด้วยรายชื่อบัฟที่ติดอยู่ สร้างใหม่เฉพาะตอนรายชื่อเปลี่ยน

const Effect = preload("res://client/effect.gd")
const Graphics = preload("res://client/graphics.gd")

const COLORS := {
	"guard": Color(1.0, 0.82, 0.35),
	"atk": Color(1.0, 0.4, 0.35),
	"def": Color(1.0, 0.85, 0.45),
	"aspd": Color(1.0, 0.95, 0.4),
	"speed": Color(0.45, 1.0, 0.75),
	"sp_regen": Color(0.45, 0.7, 1.0),
}

var active: Array = []
var rings: Array[Node3D] = []
var orbs: Array[Node3D] = []
var shield: MeshInstance3D
var sparks: CPUParticles3D
var mats: Array[StandardMaterial3D] = []
var _t := 0.0


func _ready() -> void:
	add_to_group("no_fade")


static func color_of(effect: String) -> Color:
	return Effect.vivid(COLORS.get(effect, Color(1.0, 0.9, 0.6)))


## effects = ["guard", "atk", ...] ลำดับคงที่
func show_buffs(effects: Array) -> void:
	if effects == active:
		return
	active = effects.duplicate()
	_rebuild()


func _glow(c: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(c, alpha)
	mats.append(m)
	return m


func _mi(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	rings.clear()
	orbs.clear()
	mats.clear()
	shield = null
	sparks = null
	if active.is_empty():
		return
	for i in active.size():
		var c := color_of(active[i])
		var holder := Node3D.new()
		holder.position.y = 0.05 + i * 0.03
		add_child(holder)
		rings.append(holder)
		var r := 0.75 + i * 0.16
		var ring := TorusMesh.new()
		ring.inner_radius = r - 0.05
		ring.outer_radius = r
		ring.rings = 32
		ring.ring_segments = 4
		_mi(holder, ring, Vector3.ZERO, _glow(c, 0.75))
		# ขีดอักขระรอบวง
		for k in 8:
			var a := k * TAU / 8.0
			var tick := BoxMesh.new()
			tick.size = Vector3(0.04, 0.01, 0.16)
			var t := _mi(holder, tick, Vector3(cos(a), 0, sin(a)) * (r - 0.14), _glow(c.lerp(Color.WHITE, 0.4), 0.8))
			t.rotation.y = -a
		# ลูกแก้วลอยวน 2 ลูกต่อบัฟ
		for k in 2:
			var orb := Node3D.new()
			add_child(orb)
			orb.set_meta("phase", k * PI + i * 1.1)
			orb.set_meta("radius", 0.6 + i * 0.1)
			orb.set_meta("height", 0.7 + i * 0.35)
			var ball := SphereMesh.new()
			ball.radius = 0.07
			ball.height = 0.14
			ball.radial_segments = 8
			ball.rings = 4
			_mi(orb, ball, Vector3.ZERO, _glow(Color.WHITE, 0.95))
			var halo := SphereMesh.new()
			halo.radius = 0.15
			halo.height = 0.3
			halo.radial_segments = 8
			halo.rings = 4
			_mi(orb, halo, Vector3.ZERO, _glow(c, 0.45))
			orbs.append(orb)
	if "guard" in active:
		var bubble := SphereMesh.new()
		bubble.radius = 1.0
		bubble.height = 2.2
		bubble.radial_segments = 24
		bubble.rings = 12
		shield = _mi(self, bubble, Vector3(0, 1.0, 0), _glow(color_of("guard"), 0.14))
	# ประกายลอยขึ้นจากพื้นตลอดเวลา
	sparks = CPUParticles3D.new()
	sparks.amount = maxi(4, int(10 * active.size() * Effect.PARTICLE_SCALE.get(Graphics.level(), 1.0)))
	sparks.lifetime = 1.2
	sparks.local_coords = false
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	sparks.emission_ring_axis = Vector3.UP
	sparks.emission_ring_radius = 0.7
	sparks.emission_ring_inner_radius = 0.4
	sparks.emission_ring_height = 0.05
	sparks.direction = Vector3.UP
	sparks.spread = 10.0
	sparks.gravity = Vector3(0, 1.0, 0)
	sparks.initial_velocity_min = 0.6
	sparks.initial_velocity_max = 1.3
	var pm := SphereMesh.new()
	pm.radius = 0.045
	pm.height = 0.09
	pm.radial_segments = 6
	pm.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	pm.material = mat
	sparks.mesh = pm
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for i in active.size():
		offsets.append(float(i) / maxf(1.0, active.size() - 1.0) * 0.6)
		colors.append(Color(color_of(active[i]).lerp(Color.WHITE, 0.3), 0.95))
	offsets.append(1.0)
	colors.append(Color(color_of(active[-1]), 0.0))
	var g := Gradient.new()
	g.offsets = offsets
	g.colors = colors
	sparks.color_ramp = g
	sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sparks)
	sparks.emitting = true


func _process(delta: float) -> void:
	if active.is_empty():
		return
	_t += delta
	for i in rings.size():
		rings[i].rotation.y += delta * (1.4 if i % 2 == 0 else -1.0)
		var s := 1.0 + sin(_t * 3.0 + i) * 0.04
		rings[i].scale = Vector3(s, 1, s)
	for orb in orbs:
		var a: float = _t * 2.4 + orb.get_meta("phase")
		var r: float = orb.get_meta("radius")
		orb.position = Vector3(cos(a) * r, orb.get_meta("height") + sin(_t * 3.0 + a) * 0.12, sin(a) * r)
	if shield != null:
		var p := 1.0 + sin(_t * 4.0) * 0.03
		shield.scale = Vector3(p, p, p)
		(shield.material_override as StandardMaterial3D).albedo_color.a = 0.11 + 0.05 * sin(_t * 4.0)
