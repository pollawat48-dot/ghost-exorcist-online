extends Node3D
## เอฟเฟกต์ตีและสกิล: วงแหวน ลูกธนู/ลูกไฟมีหางแสง เสาแสง รอยฟัน ประกายไฟ แสงวาบ วงเวท คลื่นกระแทก
## ของตกจากฟ้า (อุกกาบาต ฟ้าผ่า ฝนธนู) และใบดาบหมุนรอบตัว
## แค่ภาพเท่านั้น ดาเมจคำนวณไปแล้วตอนตี/ใช้สกิล จำนวนประกายลดลงตามระดับกราฟิก
## วัสดุสร้างใหม่ทุกครั้ง (ไม่ใช้ K.mat ที่แชร์กัน) เพราะต้องค่อยๆ จางหาย

const K = preload("res://maps/props/mesh_kit.gd")
const Graphics = preload("res://client/graphics.gd")

const PARTICLE_SCALE := {"lowest": 0.3, "low": 0.45, "medium": 0.75, "high": 1.0, "ultra": 1.3}

var kind := "ring"
var life := 0.4
var max_life := 0.4
var radius := 1.0
var from := Vector3.ZERO
var to := Vector3.ZERO
var color := Color.WHITE
var opts := {}
var mesh: MeshInstance3D
var pivot: Node3D
var mats: Array[StandardMaterial3D] = []  ## วัสดุที่ค่อยๆ จาง
var alphas: Array[float] = []
var light: OmniLight3D
var light_energy := 0.0
var _landed := false


# ================= เอฟเฟกต์พื้นฐาน =================

static func ring(parent: Node, at: Vector3, radius_m: float, c: Color, duration: float = 0.45) -> void:
	_spawn(parent, "ring", at, at, radius_m, c, duration)


## ลูกธนู/ลูกพลังพุ่งไปหาเป้า มีหางแสง และระเบิดประกายตอนโดน (big = สกิล)
static func shot(parent: Node, a: Vector3, b: Vector3, shot_kind: String, c: Color, big := false) -> void:
	_spawn(parent, shot_kind, a, b, 1.6 if big else 1.0, c, 0.22 if not big else 0.26, {"big": big})


static func pillar(parent: Node, at: Vector3, radius_m: float, c: Color) -> void:
	_spawn(parent, "pillar", at, at, radius_m, c, 0.7)


## รอยฟันโค้ง (yaw = ทิศที่ฟัน, roll = เอียงใบ)
static func slash(parent: Node, at: Vector3, yaw: float, c: Color, size := 1.0, roll := 0.0, duration := 0.36) -> void:
	_spawn(parent, "slash", at, at, size, c, duration, {"yaw": yaw, "roll": roll})


## ประกายกระจายออก (gravity < 0 = ตกลง เช่นหยดน้ำ)
static func burst(parent: Node, at: Vector3, c: Color, amount := 16, speed := 3.5, size := 0.07, duration := 0.55, gravity := -4.0, up := false) -> void:
	_spawn(parent, "burst", at, at, size, c, duration, {"amount": amount, "speed": speed, "gravity": gravity, "up": up})


## แสงวาบทรงกลมขยายแล้วจาง + ไฟส่องรอบๆ
static func flash(parent: Node, at: Vector3, c: Color, radius_m := 0.8, duration := 0.25) -> void:
	_spawn(parent, "flash", at, at, radius_m, c, duration)


## วงเวทบนพื้น (วงซ้อน + ดาวแฉก + อักขระ) หมุนแล้วจาง
static func rune(parent: Node, at: Vector3, radius_m: float, c: Color, duration := 0.8) -> void:
	_spawn(parent, "rune", at, at, radius_m, c, duration)


## คลื่นกระแทกแผ่นแบนขยายออกตามพื้น
static func shockwave(parent: Node, at: Vector3, radius_m: float, c: Color, duration := 0.45) -> void:
	_spawn(parent, "shockwave", at, at, radius_m, c, duration)


## ของตกจากฟ้าลงที่ at แล้วระเบิด: what = meteor / bolt (ฟ้าผ่า) / arrow / drop (หยดน้ำมนต์)
static func fall(parent: Node, at: Vector3, what: String, c: Color, size := 1.0, delay := 0.0, duration := 0.3) -> void:
	_spawn(parent, "fall", at + Vector3(0, 9.0, 0), at, size, c, duration + delay, {"what": what, "delay": delay, "fall_time": duration})


## ใบดาบ/แสงหมุนรอบตัวผู้ใช้ (ดาบหมุนวน)
static func whirl(parent: Node, at: Vector3, radius_m: float, c: Color, duration := 0.55) -> void:
	_spawn(parent, "whirl", at, at, radius_m, c, duration)


# ================= ชุดเอฟเฟกต์สำเร็จรูป =================

## ตีโดน: แสงวาบ + ประกาย (คริติคอลใหญ่และมีดาวสีทอง)
static func impact(parent: Node, at: Vector3, c: Color, size := 1.0, crit := false) -> void:
	flash(parent, at, c, 0.55 * size * (1.5 if crit else 1.0), 0.22)
	burst(parent, at, c, int(14 * size), 3.2 * size, 0.06 * maxf(1.0, size * 0.8), 0.5)
	if crit:
		burst(parent, at, Color(1.0, 0.92, 0.45), 14, 5.0, 0.09, 0.6, -2.0)
		ring(parent, Vector3(at.x, 0.05, at.z), 1.0, Color(1.0, 0.9, 0.45), 0.3)


## ระเบิดใหญ่ (สกิลวงกว้าง): แสงวาบ คลื่นกระแทก วงแหวน ประกายพุ่งขึ้น
static func explosion(parent: Node, at: Vector3, radius_m: float, c: Color) -> void:
	var ground := Vector3(at.x, 0.05, at.z)
	flash(parent, ground + Vector3(0, 0.8, 0), c, clampf(radius_m * 0.45, 0.8, 2.6), 0.35)
	shockwave(parent, ground, radius_m, c, 0.5)
	ring(parent, ground, radius_m, c, 0.5)
	burst(parent, ground + Vector3(0, 0.4, 0), c, 30, 5.5, 0.09, 0.8, -6.0, true)
	burst(parent, ground + Vector3(0, 0.3, 0), c.lerp(Color.WHITE, 0.6), 16, 3.0, 0.06, 0.7, 1.5, true)


## ร่ายสกิล: วงเวทใต้เท้า + ประกายลอยขึ้น
static func cast(parent: Node, at: Vector3, c: Color, radius_m := 1.2) -> void:
	rune(parent, Vector3(at.x, 0.06, at.z), radius_m, c, 0.7)
	burst(parent, Vector3(at.x, 0.3, at.z), c, 14, 1.6, 0.06, 0.8, 2.5, true)


static func _spawn(parent: Node, k: String, a: Vector3, b: Vector3, r: float, c: Color, duration: float, extra := {}) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var e: Node3D = load("res://client/effect.gd").new()
	e.kind = k
	e.from = a
	e.to = b
	e.radius = r
	e.color = vivid(c)
	e.life = duration
	e.max_life = duration
	e.opts = extra
	parent.add_child(e)


## สีพาสเทลจางเกินไปบนพื้นสว่าง: ดันความสดขึ้นให้เอฟเฟกต์เด่น
static func vivid(c: Color) -> Color:
	return Color.from_hsv(c.h, maxf(c.s, 0.7), maxf(c.v, 0.95), c.a)


static func particle_scale() -> float:
	return PARTICLE_SCALE.get(Graphics.level(), 1.0)


# ================= สร้างภาพ =================

## วัสดุเรืองแสง: สีหลักแบบทึบแสงบางส่วน (เห็นชัดบนพื้นสว่าง) ส่วนสีขาวเป็นแสงบวก (สว่างจ้าตอนกลางคืน)
func _glow(c: Color, alpha := 0.9, additive := false) -> StandardMaterial3D:
	if c.is_equal_approx(Color.WHITE):
		additive = true
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(c, alpha)
	mats.append(m)
	alphas.append(alpha)
	return m


func _mi(parent: Node3D, m: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.position = pos
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _torus(inner: float, outer: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 32
	t.ring_segments = 6
	return t


func _ball(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 10
	s.rings = 5
	return s


func _add_light(c: Color, energy: float, rng: float) -> void:
	if Graphics.level() in ["lowest", "low"]:
		return
	light = OmniLight3D.new()
	light.light_color = c
	light.omni_range = rng
	light.light_energy = energy
	light.position = Vector3(0, 0.6, 0)
	light_energy = energy
	add_child(light)


## ประกายแบบ CPUParticles (หมุนตามโลก ไม่ติดตามตัวเอฟเฟกต์)
func _particles(c: Color, amount: int, speed: float, size: float, lifetime: float, gravity: float, up: bool, one_shot := true) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = maxi(2, int(amount * particle_scale()))
	p.lifetime = lifetime
	p.one_shot = one_shot
	p.explosiveness = 1.0 if one_shot else 0.0
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 70.0 if up else 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, gravity, 0)
	p.damping_min = 1.0
	p.damping_max = 3.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var m := _ball(size)
	m.radial_segments = 6
	m.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	m.material = mat
	p.mesh = m
	var g := Gradient.new()
	g.set_color(0, Color(c.lerp(Color.WHITE, 0.25), 1.0))
	g.set_color(1, Color(c, 0.0))
	g.add_point(0.4, Color(c, 0.9))
	p.color_ramp = g
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0.2))
	p.scale_amount_curve = curve
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)
	p.emitting = true
	return p


func _ready() -> void:
	position = from
	match kind:
		"ring":
			mesh = _mi(self, _torus(0.86, 1.0), Vector3(0, 0.25, 0), _glow(color, 0.85))
			_mi(self, _torus(0.6, 0.66), Vector3(0, 0.2, 0), _glow(color.lerp(Color.WHITE, 0.5), 0.6))
		"arrow", "orb":
			_build_shot()
		"pillar":
			var cyl := CylinderMesh.new()
			cyl.top_radius = radius * 0.35
			cyl.bottom_radius = radius
			cyl.height = 8.0
			cyl.cap_top = false
			cyl.cap_bottom = false
			mesh = _mi(self, cyl, Vector3(0, 4.0, 0), _glow(color, 0.45))
			var core := CylinderMesh.new()
			core.top_radius = radius * 0.12
			core.bottom_radius = radius * 0.35
			core.height = 9.0
			_mi(self, core, Vector3(0, 4.5, 0), _glow(Color.WHITE, 0.5))
			_mi(self, _torus(radius * 0.9, radius * 1.15), Vector3(0, 0.08, 0), _glow(color, 0.8))
			var p := _particles(color, 24, 5.0, 0.07, 0.8, 3.0, true)
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			p.emission_sphere_radius = radius * 0.8
			_add_light(color, 3.0, 6.0)
		"slash":
			_build_slash()
		"burst":
			var p := _particles(color, opts.get("amount", 16), opts.get("speed", 3.5), radius, max_life, opts.get("gravity", -4.0), opts.get("up", false))
			p.lifetime = max_life
		"flash":
			mesh = _mi(self, _ball(1.0), Vector3.ZERO, _glow(color.lerp(Color.WHITE, 0.35), 0.5))
			_mi(mesh, _ball(0.45), Vector3.ZERO, _glow(Color.WHITE, 0.9))
			mesh.scale = Vector3.ONE * radius * 0.3
			_add_light(color, 4.0, radius * 4.0 + 2.0)
		"rune":
			_build_rune()
		"shockwave":
			var disc := CylinderMesh.new()
			disc.top_radius = 1.0
			disc.bottom_radius = 1.0
			disc.height = 0.02
			disc.radial_segments = 32
			mesh = _mi(self, disc, Vector3(0, 0.06, 0), _glow(color, 0.45))
			_mi(mesh, _torus(0.9, 1.0), Vector3(0, 0.02, 0), _glow(color.lerp(Color.WHITE, 0.4), 0.9)).scale = Vector3(1, 6, 1)
		"fall":
			_build_fall()
		"whirl":
			_build_whirl()


func _build_shot() -> void:
	var big: bool = opts.get("big", false)
	pivot = Node3D.new()
	add_child(pivot)
	if kind == "arrow":
		var s := 1.4 if big else 1.0
		var shaft := BoxMesh.new()
		shaft.size = Vector3(0.05, 0.05, 0.9) * s
		_mi(pivot, shaft, Vector3.ZERO, _glow(color.lerp(Color.WHITE, 0.5), 1.0))
		var glow := BoxMesh.new()
		glow.size = Vector3(0.16, 0.16, 1.3) * s
		_mi(pivot, glow, Vector3(0, 0, 0.15), _glow(color, 0.4))
		var tip := PrismMesh.new()
		tip.size = Vector3(0.18, 0.28, 0.06) * s
		var t := _mi(pivot, tip, Vector3(0, 0, -0.5 * s), _glow(Color.WHITE, 1.0))
		t.rotation.x = -PI / 2
	else:
		var r := 0.28 if big else 0.2
		_mi(pivot, _ball(r), Vector3.ZERO, _glow(Color.WHITE, 0.95))
		_mi(pivot, _ball(r * 1.8), Vector3.ZERO, _glow(color, 0.5))
		_mi(pivot, _torus(r * 1.9, r * 2.2), Vector3.ZERO, _glow(color, 0.7))
	var trail := _particles(color, 40 if big else 24, 0.3, 0.07 if big else 0.05, 0.35, 0.0, false, false)
	trail.explosiveness = 0.0
	if from.distance_to(to) > 0.01:
		pivot.basis = Basis.looking_at(to - from + Vector3(0, 0.001, 0), Vector3.UP)
	_add_light(color, 1.5 if big else 0.8, 3.0)


func _build_slash() -> void:
	pivot = Node3D.new()
	add_child(pivot)
	pivot.rotation = Vector3(0, opts.get("yaw", 0.0), opts.get("roll", 0.0))
	var arc := Node3D.new()
	pivot.add_child(arc)
	# พระจันทร์เสี้ยว: ชิ้นเล็กเรียงเป็นโค้ง กลางหนา ปลายบาง
	var n := 11
	var r := 1.1 * radius
	var white := _glow(color.lerp(Color.WHITE, 0.65), 0.95)
	var tint := _glow(color, 0.6)
	for i in n:
		var t := float(i) / (n - 1)
		var a := lerpf(-1.15, 1.15, t)
		var thick := sin(t * PI) * 0.26 * radius + 0.03
		var seg := BoxMesh.new()
		seg.size = Vector3(0.45 * radius, 0.05, thick)
		var p := Vector3(sin(a) * r, 0, -cos(a) * r)
		var core := _mi(arc, seg, p, white)
		core.rotation.y = -a + PI / 2
		var halo := BoxMesh.new()
		halo.size = Vector3(0.5 * radius, 0.07, thick * 2.4)
		var h := _mi(arc, halo, p + Vector3(sin(a), 0, -cos(a)) * -0.05, tint)
		h.rotation.y = -a + PI / 2
	mesh = null


func _build_rune() -> void:
	pivot = Node3D.new()
	add_child(pivot)
	var r := radius
	_mi(pivot, _torus(r * 0.95, r), Vector3(0, 0.02, 0), _glow(color, 0.9))
	_mi(pivot, _torus(r * 0.78, r * 0.81), Vector3(0, 0.02, 0), _glow(color, 0.75))
	_mi(pivot, _torus(r * 0.3, r * 0.33), Vector3(0, 0.02, 0), _glow(color.lerp(Color.WHITE, 0.5), 0.7))
	# ดาวหกแฉก: สามเหลี่ยมสองอันซ้อนกัน
	var pts: Array[Vector3] = []
	for i in 6:
		var a := i * TAU / 6.0
		pts.append(Vector3(cos(a), 0, sin(a)) * r * 0.78)
	var line := _glow(color.lerp(Color.WHITE, 0.3), 0.8)
	for tri in [[0, 2, 4], [1, 3, 5]]:
		for j in 3:
			var a: Vector3 = pts[tri[j]]
			var b: Vector3 = pts[tri[(j + 1) % 3]]
			var seg := BoxMesh.new()
			seg.size = Vector3(0.04 * maxf(1.0, r * 0.5), 0.01, a.distance_to(b))
			var mi := _mi(pivot, seg, (a + b) / 2.0 + Vector3(0, 0.03, 0), line)
			mi.basis = Basis.looking_at(b - a, Vector3.UP)
	# อักขระ: จุดแสงเล็กๆ รอบวง
	for i in 12:
		var a := i * TAU / 12.0 + 0.13
		_mi(pivot, _ball(0.05 * maxf(1.0, r * 0.4)), Vector3(cos(a), 0.05, sin(a)) * Vector3(r * 0.88, 1, r * 0.88), _glow(color.lerp(Color.WHITE, 0.6), 0.9))
	_add_light(color, 1.2, r * 2.0 + 1.5)


func _build_fall() -> void:
	pivot = Node3D.new()
	add_child(pivot)
	pivot.visible = opts.get("delay", 0.0) <= 0.0
	var s := radius
	match opts.get("what", "meteor"):
		"meteor":
			_mi(pivot, _ball(0.35 * s), Vector3.ZERO, _glow(Color(1.0, 0.95, 0.7), 1.0))
			_mi(pivot, _ball(0.65 * s), Vector3.ZERO, _glow(color, 0.55))
			var tail := CylinderMesh.new()
			tail.top_radius = 0.5 * s
			tail.bottom_radius = 0.05
			tail.height = 2.6 * s
			_mi(pivot, tail, Vector3(0, 1.4 * s, 0), _glow(color, 0.45))
			var fire := _particles(color, 30, 0.6, 0.12 * s, 0.4, 2.0, true, false)
			fire.explosiveness = 0.0
		"bolt":
			# ฟ้าผ่า: เส้นซิกแซกลงมาทั้งเส้น ค่อยๆ จาง
			var y := 9.0
			var x := 0.0
			var z := 0.0
			var core := _glow(Color.WHITE, 1.0)
			var halo := _glow(color, 0.55)
			for i in 7:
				var ny := y - 9.0 / 7.0
				var nx := randf_range(-0.6, 0.6) * s if i < 6 else 0.0
				var nz := randf_range(-0.6, 0.6) * s if i < 6 else 0.0
				var a := Vector3(x, y - 9.0, z)
				var b := Vector3(nx, ny - 9.0, nz)
				for e in [[0.08, core], [0.3, halo]]:
					var seg := BoxMesh.new()
					seg.size = Vector3(e[0] * s, e[0] * s, a.distance_to(b))
					var mi := _mi(pivot, seg, (a + b) / 2.0, e[1])
					mi.basis = Basis.looking_at(b - a, Vector3.RIGHT)
				x = nx
				y = ny
				z = nz
			pivot.position = Vector3(0, 9.0, 0)
			position = to
		"arrow":
			var shaft := BoxMesh.new()
			shaft.size = Vector3(0.06, 1.1, 0.06) * s
			_mi(pivot, shaft, Vector3.ZERO, _glow(color.lerp(Color.WHITE, 0.5), 1.0))
			var glow := BoxMesh.new()
			glow.size = Vector3(0.2, 1.6, 0.2) * s
			_mi(pivot, glow, Vector3(0, 0.3, 0), _glow(color, 0.4))
		"drop":
			_mi(pivot, _ball(0.16 * s), Vector3.ZERO, _glow(color.lerp(Color.WHITE, 0.4), 0.95))
			var tail := CylinderMesh.new()
			tail.top_radius = 0.0
			tail.bottom_radius = 0.16 * s
			tail.height = 0.5 * s
			_mi(pivot, tail, Vector3(0, 0.25 * s, 0), _glow(color, 0.6))


func _build_whirl() -> void:
	pivot = Node3D.new()
	add_child(pivot)
	var r := radius
	var blade := _glow(color.lerp(Color.WHITE, 0.65), 0.9)
	var tint := _glow(color, 0.55)
	for i in 4:
		var arm := Node3D.new()
		arm.rotation.y = i * TAU / 4.0
		pivot.add_child(arm)
		for j in 6:
			var a := -j * 0.16
			var seg := BoxMesh.new()
			var fade := 1.0 - j / 6.0
			seg.size = Vector3(0.12 + 0.12 * fade, 0.05, r * 0.32)
			var p := Vector3(sin(a), 0, cos(a)) * r * 0.75 + Vector3(0, 0.9, 0)
			var mi := _mi(arm, seg, p, blade if j == 0 else tint)
			mi.rotation.y = a
	_mi(pivot, _torus(r * 0.9, r), Vector3(0, 0.9, 0), _glow(color, 0.5))
	_add_light(color, 1.8, r * 2.5)


func _process(delta: float) -> void:
	life -= delta
	var f := 1.0 - clampf(life / max_life, 0.0, 1.0)
	var fade := 1.0
	match kind:
		"ring":
			var r := radius * (0.3 + 0.7 * f)
			scale = Vector3(r, 1, r)
			fade = 1.0 - f * f
		"arrow", "orb":
			position = from.lerp(to, minf(f * 1.05, 1.0))
			if pivot != null:
				pivot.rotate_object_local(Vector3.FORWARD, delta * 14.0)
			if f >= 0.95 and not _landed:
				_landed = true
				var big: bool = opts.get("big", false)
				impact(get_parent(), to, color, 1.6 if big else 1.0)
				if big:
					ring(get_parent(), Vector3(to.x, 0.05, to.z), 1.2, color, 0.4)
		"pillar":
			mesh.scale = Vector3(1.0 - f * 0.6, 1.0, 1.0 - f * 0.6)
			fade = 1.0 - f * f
		"slash":
			pivot.rotation.y = opts.get("yaw", 0.0) + lerpf(-0.5, 0.6, ease(f, 0.4))
			var s := 0.85 + f * 0.35
			pivot.scale = Vector3(s, 1, s)
			fade = 1.0 - ease(f, 3.0)
		"burst":
			fade = 1.0
		"flash":
			mesh.scale = Vector3.ONE * radius * (0.3 + 0.9 * ease(f, 0.5))
			fade = 1.0 - f
		"rune":
			pivot.rotation.y += delta * 2.2
			var s := 0.6 + 0.4 * ease(minf(f * 3.0, 1.0), 0.4)
			pivot.scale = Vector3(s, 1, s)
			fade = 1.0 if f < 0.6 else 1.0 - (f - 0.6) / 0.4
		"shockwave":
			var r := radius * (0.15 + 0.85 * ease(f, 0.45))
			mesh.scale = Vector3(r, 1, r)
			fade = 1.0 - f
		"fall":
			fade = _tick_fall()
		"whirl":
			pivot.rotation.y -= delta * 16.0
			fade = 1.0 - ease(f, 3.0)
	for i in mats.size():
		mats[i].albedo_color.a = alphas[i] * clampf(fade, 0.0, 1.0)
	if light != null:
		light.light_energy = light_energy * clampf(fade, 0.0, 1.0)
	if life <= 0.0:
		queue_free()


func _tick_fall() -> float:
	var delay: float = opts.get("delay", 0.0)
	var fall_time: float = opts.get("fall_time", 0.3)
	var t := (max_life - life) - delay
	if t < 0.0:
		return 1.0
	pivot.visible = true
	var f := clampf(t / fall_time, 0.0, 1.0)
	var what: String = opts.get("what", "meteor")
	if what == "bolt":
		# ฟ้าผ่าโผล่ทั้งเส้นทันที แล้วกะพริบ
		pivot.visible = int(t * 30.0) % 3 != 2
	else:
		position = from.lerp(to, f * f)
	if (f >= 1.0 or what == "bolt") and not _landed:
		_landed = true
		var size := radius
		match what:
			"meteor":
				explosion(get_parent(), to, 1.6 * size, color)
			"bolt":
				flash(get_parent(), to + Vector3(0, 0.5, 0), color, 1.4 * size, 0.3)
				shockwave(get_parent(), to, 1.8 * size, color, 0.4)
				burst(get_parent(), to + Vector3(0, 0.2, 0), color, 18, 4.5, 0.07, 0.6, -6.0, true)
			"arrow":
				burst(get_parent(), to + Vector3(0, 0.1, 0), color, 6, 2.0, 0.05, 0.4, -6.0, true)
				ring(get_parent(), to, 0.5 * size, color, 0.3)
			"drop":
				burst(get_parent(), to + Vector3(0, 0.1, 0), color, 8, 2.2, 0.05, 0.45, -8.0, true)
				ring(get_parent(), to, 0.45 * size, color, 0.35)
		if what != "bolt":
			pivot.visible = false
			life = minf(life, 0.05)
	return 1.0 - f if what == "bolt" else 1.0
