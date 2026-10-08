extends SceneTree
## สร้างไอคอนเกม (assets/icon.png) จากหัวตัวละครจิบิ: ต้องมีหน้าจอ เช่น xvfb-run
## godot --path . --rendering-driver opengl3 --rendering-method gl_compatibility --resolution 512x512 --script res://tests/icon_shot.gd

const K = preload("res://maps/props/mesh_kit.gd")
const Body = preload("res://client/chibi_body.gd")


func _initialize() -> void:
	_run()


func _run() -> void:
	root.size = Vector2i(512, 512)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(1.0, 0.8, 0.86)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1.0, 0.95, 0.95)
	env.environment.ambient_light_energy = 0.25
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment.tonemap_exposure = 0.55
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-40), deg_to_rad(20), 0)
	sun.light_energy = 0.45
	world.add_child(sun)
	var b: Node3D = Body.new()
	world.add_child(b)
	b.build({"gender": "m", "hair": 0, "skin": 0}, {"shirt": Color(1.0, 0.72, 0.4), "sash": Color(0.96, 0.52, 0.42), "hair": Color(0.36, 0.25, 0.24), "skin": Color(1.0, 0.86, 0.74)})
	b.rotation.y = 0.25
	# ผีน้อยลอยข้างหัว
	var ghost := K.mat(Color(1, 1, 1), 0.2, 0.6)
	K.sphere(world, 0.17, Vector3(0.62, 1.42, 0.1), ghost, 16, Vector3(1.0, 1.15, 1.0))
	K.cyl(world, 0.17, 0.1, 0.16, Vector3(0.62, 1.26, 0.1), ghost, 16)
	for x in [-0.06, 0.06]:
		K.sphere(world, 0.025, Vector3(0.62 + x, 1.45, 0.26), K.mat(Color(0.25, 0.15, 0.2), 0.0, 0.5, 0.0, false), 8)
	var cam := Camera3D.new()
	cam.fov = 24
	world.add_child(cam)
	cam.look_at_from_position(Vector3(0.15, 1.35, 3.2), Vector3(0.12, 1.1, 0))
	for i in 8:
		await process_frame
	root.get_texture().get_image().save_png("res://assets/icon.png")
	quit()
