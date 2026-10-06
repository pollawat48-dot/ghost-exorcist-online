extends RefCounted
## โมเดล 3D สำเร็จรูป (.glb) จากชุดฟรี CC0 ของ Kenney (www.kenney.nl) ใน assets/models/kenney/<ชุด>/
## โหลดแต่ละไฟล์ครั้งเดียวแล้วใช้ร่วมกัน และแปลงวัสดุเป็นแบบการ์ตูน (toon + เส้นขอบ) ให้เข้ากับฉากเดิม

const K = preload("res://maps/props/mesh_kit.gd")
const ROOT := "res://assets/models/kenney/"

static var _scenes := {}
static var _materials := {}


## path เช่น "pirate/palm-bend" (ไม่ต้องใส่ .glb)
static func scene(path: String) -> PackedScene:
	if not _scenes.has(path):
		_scenes[path] = load(ROOT + path + ".glb")
	return _scenes[path]


static func exists(path: String) -> bool:
	return ResourceLoader.exists(ROOT + path + ".glb")


## วางโมเดลลงใน parent: pos เป็นเมตร, size คูณขนาดเดิมของไฟล์, tint คูณสีวัสดุ
static func spawn(parent: Node3D, path: String, pos := Vector3.ZERO, size := 1.0, rot_y := 0.0, tint := Color.WHITE, outlined := true) -> Node3D:
	var inst: Node3D = scene(path).instantiate()
	inst.position = pos
	inst.rotation.y = rot_y
	inst.scale = Vector3.ONE * size
	toonify(inst, tint, outlined)
	parent.add_child(inst)
	return inst


## เปลี่ยนวัสดุของทุก mesh ในโมเดลเป็นแบบการ์ตูน (แชร์วัสดุที่ซ้ำกัน)
static func toonify(node: Node, tint := Color.WHITE, outlined := true) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i)
			if src is BaseMaterial3D:
				mi.set_surface_override_material(i, _toon(src, tint, outlined))
	for c in node.get_children():
		toonify(c, tint, outlined)


static func _toon(src: BaseMaterial3D, tint: Color, outlined: bool) -> StandardMaterial3D:
	var key := "%d|%s|%s" % [src.get_instance_id(), tint.to_html(), outlined]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = src.albedo_color * tint
	m.albedo_texture = src.albedo_texture
	m.vertex_color_use_as_albedo = src.vertex_color_use_as_albedo
	# ภาพสีของ Kenney เป็นช่องสีเรียบ ใช้แบบไม่เบลอเพื่อไม่ให้สีข้างเคียงซึม
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	m.roughness = 0.85
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.rim_enabled = true
	m.rim = 0.2
	m.rim_tint = 0.6
	if src.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		m.transparency = src.transparency
	elif outlined:
		m.next_pass = K.outline()
	_materials[key] = m
	return m


## เล่นท่าทาง (idle / walk / run ...) ของโมเดลที่มีแอนิเมชัน คืนค่า AnimationPlayer (หรือ null)
static func play(model: Node, anim: String, speed := 1.0) -> AnimationPlayer:
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null or not ap.has_animation(anim):
		return ap
	var a := ap.get_animation(anim)
	a.loop_mode = Animation.LOOP_LINEAR
	if ap.current_animation != anim:
		ap.play(anim, 0.2, speed)
	else:
		ap.speed_scale = speed
	return ap
