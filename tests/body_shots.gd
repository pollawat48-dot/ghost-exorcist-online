extends SceneTree
## ถ่ายภาพตรวจร่างตัวละครแบบใหม่ (client/chibi_body.gd) ต้องมีหน้าจอ เช่น xvfb-run:
## godot --path . --rendering-driver opengl3 --rendering-method gl_compatibility --script res://tests/body_shots.gd -- <โฟลเดอร์>
## ได้ไฟล์ body_turn.png (หน้า/เฉียง/ข้าง/หลัง), body_variants.png (ชาย/หญิง สีผิว สีผม), body_walk.png (ท่าเดิน), body_face.png (หน้าใกล้ๆ)

const K = preload("res://maps/props/mesh_kit.gd")
const Body = preload("res://client/chibi_body.gd")
const Avatar = preload("res://client/avatar.gd")

const HAIR := [Color(0.36, 0.25, 0.24), Color(0.2, 0.17, 0.22), Color(0.6, 0.36, 0.24), Color(1.0, 0.68, 0.78), Color(0.82, 0.8, 0.94)]
const SKIN := [Color(1.0, 0.86, 0.74), Color(0.88, 0.68, 0.52), Color(0.97, 0.77, 0.62)]
const NOVICE := {"shirt": Color(0.98, 0.78, 0.5), "sash": Color(0.95, 0.55, 0.25), "pants": Color(0.55, 0.42, 0.4), "shoe": Color(0.62, 0.42, 0.36)}

var out_dir := "/tmp/claude-0/bodyshots"
var world: Node3D
var cam: Camera3D


func _initialize() -> void:
	_run()


func _make(gender: String, hair: int, skin: int, colors: Dictionary = NOVICE) -> Node3D:
	var b: Node3D = Body.new()
	world.add_child(b)
	var c := colors.duplicate()
	c["hair"] = HAIR[hair]
	c["skin"] = SKIN[skin]
	b.build({"gender": gender, "hair": hair, "skin": skin}, c)
	return b


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	root.size = Vector2i(1280, 720)
	_stage()

	# ---- รอบตัว: ตัวเก่า (ซ้ายสุด) เทียบกับร่างใหม่ หน้า / เฉียง / ข้าง / หลัง ----
	var list: Array = []
	var old: Node3D = Avatar.new()
	world.add_child(old)
	old.build("novice", {"gender": "m", "hair": 0, "skin": 0}, {}, "ตัวเดิม")
	old.position = Vector3(-4.0, 0, 0)
	list.append(old)
	var angles := [0.0, 0.7, PI / 2.0, PI]
	for i in angles.size():
		var b := _make("m", 0, 0)
		b.position = Vector3(-2.0 + i * 1.55, 0, 0)
		b.rotation.y = angles[i]
		list.append(b)
	cam.fov = 30
	cam.look_at_from_position(Vector3(0.3, 2.6, 8.5), Vector3(0.3, 0.75, 0))
	await _save("body_turn.png")
	for n in list:
		n.queue_free()

	# ---- แบบต่างๆ: ชาย/หญิง สีผิว 3 แบบ สีผม 5 แบบ ----
	list.clear()
	var combos := [["m", 0, 0], ["f", 3, 1], ["m", 2, 1], ["f", 4, 2], ["m", 1, 2], ["f", 0, 0]]
	for i in combos.size():
		var b := _make(combos[i][0], combos[i][1], combos[i][2])
		b.position = Vector3(-3.75 + i * 1.5, 0, 0)
		b.rotation.y = 0.35
		list.append(b)
	cam.look_at_from_position(Vector3(0, 2.8, 9.0), Vector3(0, 0.75, 0))
	await _save("body_variants.png")
	for n in list:
		n.queue_free()

	# ---- ท่าเดิน 5 จังหวะ (มองจากด้านข้างเฉียง) ----
	list.clear()
	for i in 5:
		var b := _make("f" if i % 2 == 1 else "m", i % 5, i % 3)
		b.position = Vector3(-3.0 + i * 1.5, 0, 0)
		b.rotation.y = 1.1
		b.animate_pose(i * PI / 4.0 + 0.3, true, 0.0)
		list.append(b)
	cam.look_at_from_position(Vector3(0, 2.4, 8.5), Vector3(0, 0.7, 0))
	await _save("body_walk.png")
	for n in list:
		n.queue_free()

	# ---- หน้าใกล้ๆ ชาย / หญิง ----
	list.clear()
	for i in 2:
		var b := _make("m" if i == 0 else "f", 0 if i == 0 else 3, 0)
		b.position = Vector3(-0.55 + i * 1.1, 0, 0)
		b.rotation.y = 0.15 - i * 0.3
		list.append(b)
	cam.fov = 22
	cam.look_at_from_position(Vector3(0, 1.75, 3.6), Vector3(0, 1.0, 0))
	await _save("body_face.png")
	for n in list:
		n.queue_free()

	# ---- ตัวละครในเกมจริง (avatar.gd ใช้ร่างใหม่) ใส่ชุด/อาวุธ/หมวกตามรายการใน avatar_shots ----
	var lineup: Array = load("res://tests/avatar_shots.gd").LINEUP
	cam.fov = 30
	for page in 2:
		for back in [false, true]:
			list.clear()
			for i in 6:
				var e: Array = lineup[page * 6 + i]
				var a: Node3D = Avatar.new()
				world.add_child(a)
				a.build(e[1], e[2], e[3], e[0])
				if e[4]:
					a.set_fishing(true)
				a.position = Vector3(-4.0 + i * 1.6, 0, 0)
				a.animate(0.3, false, Vector2(0, 1) if not back else Vector2(0.8, -0.7), 0.0, false, 0.0)
				a.model.rotation.y = 0.0 if not back else atan2(0.8, -0.7)
				list.append(a)
			cam.look_at_from_position(Vector3(0, 3.6, 10.5), Vector3(0, 0.9, 0))
			await _save("game_%d%s.png" % [page + 1, "_back" if back else ""])
			for n in list:
				n.queue_free()

	# ---- ท่าในเกม: เดิน 2 จังหวะ + ท่าฟัน 4 จังหวะ (swing 0.2 -> 0) ----
	list.clear()
	var poses := [[true, 0.0, 0.4], [true, 0.0, 2.0], [false, 0.17, 0.0], [false, 0.13, 0.0], [false, 0.08, 0.0], [false, 0.03, 0.0]]
	for i in poses.size():
		var a: Node3D = Avatar.new()
		world.add_child(a)
		a.build("nak_dab", {"gender": "m" if i % 2 == 0 else "f", "hair": i % 5, "skin": 0}, {"weapon": "dab_krung+5", "armor": "suea_yant"}, "")
		a.position = Vector3(-4.0 + i * 1.6, 0, 0)
		a.walk_t = poses[i][2] / 0.8
		a.animate(0.0, poses[i][0], Vector2(1, 0.4), poses[i][1], false, 0.0)
		a.model.rotation.y = 1.0
		list.append(a)
	cam.look_at_from_position(Vector3(0, 3.0, 10.0), Vector3(0, 0.9, 0))
	await _save("game_pose.png")
	quit()


func _stage() -> void:
	world = Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.86, 0.9, 1.0)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1.0, 0.95, 0.95)
	env.environment.ambient_light_energy = 0.2
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment.tonemap_exposure = 0.5
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(25), 0)
	sun.light_energy = 0.42
	sun.shadow_enabled = true
	world.add_child(sun)
	var ground := K.box(world, Vector3(40, 0.2, 20), Vector3(0, -0.1, 0), K.mat(Color(0.62, 0.8, 0.56), 0.0, 0.9, 0.0, false))
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cam = Camera3D.new()
	cam.fov = 30
	world.add_child(cam)


func _save(name: String) -> void:
	for i in 8:
		await process_frame
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(name))
