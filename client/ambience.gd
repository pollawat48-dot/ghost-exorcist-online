extends Node3D
## บรรยากาศ 3D: ดวงอาทิตย์เคลื่อน, ท้องฟ้า, เงา, หมอก, กลางวัน–กลางคืน
## ตอนกลางคืนเปิดไฟในกลุ่ม "night_light" (ตะเกียง บ้าน ผี) และมีหิ่งห้อย

signal phase_changed(text: String)

const K = preload("res://maps/props/mesh_kit.gd")
const DAY_LENGTH := 240.0

## 0..1 ของหนึ่งวัน: 0–0.42 กลางวัน, 0.42–0.55 พลบค่ำ, 0.55–0.88 กลางคืน, 0.88–1 รุ่งสาง
var time_of_day := 0.08
var night := 0.0
var phase := ""
var map: Node3D
var sun: DirectionalLight3D
var moon: DirectionalLight3D
var env: Environment
var sky_mat: ProceduralSkyMaterial
var fireflies: CPUParticles3D


func setup(map_ref: Node3D) -> void:
	map = map_ref


func _ready() -> void:
	sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env.ambient_light_color = Color(1.0, 0.9, 0.85)
	env.ambient_light_sky_contribution = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.2
	env.ssao_enabled = true
	env.ssao_radius = 0.8
	env.ssao_intensity = 0.8
	env.fog_enabled = true
	env.fog_density = 0.006
	env.fog_sky_affect = 0.3
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.2
	env.adjustment_brightness = 1.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	sun.shadow_blur = 2.0
	sun.shadow_opacity = 0.55
	add_child(sun)
	moon = DirectionalLight3D.new()
	moon.light_color = Color(0.55, 0.65, 1.0)
	moon.rotation = Vector3(deg_to_rad(-55), deg_to_rad(-30), 0)
	moon.shadow_enabled = true
	add_child(moon)

	fireflies = CPUParticles3D.new()
	var dot := SphereMesh.new()
	dot.radius = 0.04
	dot.height = 0.08
	dot.radial_segments = 4
	dot.rings = 2
	fireflies.mesh = dot
	fireflies.material_override = K.mat(Color(0.75, 1.0, 0.35), 6.0)
	fireflies.amount = 260
	fireflies.lifetime = 6.0
	fireflies.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	var field: Rect2 = map.field_rect
	fireflies.emission_box_extents = Vector3(field.size.x * K.S / 2.0, 1.0, field.size.y * K.S / 2.0)
	fireflies.position = K.to3d(field.get_center(), 1.4)
	fireflies.gravity = Vector3.ZERO
	fireflies.direction = Vector3(1, 0.2, 0)
	fireflies.spread = 180.0
	fireflies.initial_velocity_min = 0.1
	fireflies.initial_velocity_max = 0.5
	fireflies.emitting = false
	add_child(fireflies)
	tick(0.0)


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	time_of_day = fposmod(time_of_day + delta / DAY_LENGTH, 1.0)
	night = _night_factor(time_of_day)
	var dusk := clampf(1.0 - absf(night - 0.5) * 2.0, 0.0, 1.0)

	# ดวงอาทิตย์เคลื่อนจากตะวันออกไปตะวันตกในช่วงกลางวัน
	var sun_t := clampf(time_of_day / 0.55, 0.0, 1.0)
	sun.rotation = Vector3(-0.37 - sin(sun_t * PI) * 0.95, lerpf(-1.4, 1.4, sun_t), 0)
	sun.light_energy = 0.85 * (1.0 - night)
	sun.light_color = Color(1.0, 0.97, 0.9).lerp(Color(1.0, 0.65, 0.5), dusk)
	moon.light_energy = 0.45 * night

	sky_mat.sky_top_color = Color(0.55, 0.76, 0.98).lerp(Color(0.7, 0.55, 0.85), dusk).lerp(Color(0.16, 0.16, 0.36), clampf(night * 1.5 - 0.5, 0.0, 1.0))
	sky_mat.sky_horizon_color = Color(1.0, 0.95, 0.88).lerp(Color(1.0, 0.72, 0.62), dusk).lerp(Color(0.32, 0.3, 0.52), clampf(night * 1.5 - 0.5, 0.0, 1.0))
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color
	sky_mat.ground_bottom_color = Color(0.1, 0.12, 0.1).lerp(Color(0.02, 0.02, 0.04), night)
	env.ambient_light_energy = lerpf(0.5, 0.45, night)
	env.fog_light_color = sky_mat.sky_horizon_color
	env.fog_density = lerpf(0.0015, 0.012, night)

	var lights := get_tree().get_nodes_in_group("night_light") if is_inside_tree() else []
	for l in lights:
		l.light_energy = float(l.get_meta("base_energy", 1.0)) * night
		l.visible = night > 0.02
	fireflies.emitting = night > 0.3

	var p := _phase_name(time_of_day)
	if p != phase:
		phase = p
		phase_changed.emit(phase)


func _night_factor(t: float) -> float:
	if t < 0.42:
		return 0.0
	if t < 0.55:
		return smoothstep(0.42, 0.55, t)
	if t < 0.88:
		return 1.0
	return 1.0 - smoothstep(0.88, 1.0, t)


func _phase_name(t: float) -> String:
	if t < 0.42:
		return "กลางวัน"
	if t < 0.55:
		return "พลบค่ำ"
	if t < 0.88:
		return "กลางคืน"
	return "รุ่งสาง"
