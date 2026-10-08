extends SceneTree
## ถ่ายภาพตรวจหน้าตาแฟชั่น สัตว์เลี้ยงทุกร่าง และเอฟเฟกต์อาวุธตามขั้นตีบวก (ต้องมีหน้าจอ เช่น xvfb-run):
## godot --path . --script res://tests/fashion_shots.gd -- <โฟลเดอร์ปลายทาง>
## ได้ไฟล์ fashion_sets.png, pets.png, weapon_refine.png

const K = preload("res://maps/props/mesh_kit.gd")
const Fashion = preload("res://shared/data/fashion.gd")

## [ชื่อ, คลาส, look, ของที่มองเห็น (ของสวมใส่ + f_costume/f_hat/f_wings)]
const SETS := [
	["ชุดเด็กวัด + หูแมว", "novice", {"gender": "f", "hair": 3, "skin": 0}, {"f_costume": "f_chut_dek_wat", "f_hat": "f_hu_maeo", "f_wings": "f_pik_khangkhao"}],
	["ชุดไทย + งอบ", "nak_rob", {"gender": "m", "hair": 0, "skin": 1}, {"weapon": "mitmo+4", "f_costume": "f_chut_thai", "f_hat": "f_ngob", "f_wings": "f_pik_phisuea"}],
	["นางรำ + มะลิ", "mo_phi", {"gender": "f", "hair": 1, "skin": 0}, {"weapon": "khamphi_yant+7", "f_costume": "f_chut_nang_ram", "f_hat": "f_mongkut_mali", "f_wings": "f_pik_nangfa"}],
	["เทวดา + ชฎา", "nak_dab", {"gender": "m", "hair": 4, "skin": 2}, {"weapon": "dab_krung+10", "f_costume": "f_chut_thewada+7", "f_hat": "f_chada_thep", "f_wings": "f_pik_kinnari+7"}],
]
const WEAPONS := ["dab_krung", "dab_krung+4", "dab_krung+7", "dab_krung+9", "dab_krung+10"]


class FakeOwner extends Node3D:
	var state := {"pets": {}}
	var pos := Vector2.ZERO


var out_dir := "/tmp/claude-0/shots"
var world: Node3D
var cam: Camera3D


func _initialize() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	root.size = Vector2i(1280, 720)
	_stage()
	var Avatar: GDScript = load("res://client/avatar.gd")
	var Pet: GDScript = load("res://client/pet.gd")

	# ---- ชุดแฟชั่น 4 แบบ ----
	var shown: Array = []
	for i in SETS.size():
		var e: Array = SETS[i]
		var a: Node3D = Avatar.new()
		world.add_child(a)
		a.build(e[1], e[2], e[3], e[0])
		a.position = Vector3((i - 1.5) * 1.9, 0, 0)
		a.model.rotation.y = 0.35
		shown.append(a)
	await _animate(shown, 0.6)
	cam.look_at_from_position(Vector3(0, 3.4, 9.0), Vector3(0, 1.0, 0))
	await _save("fashion_sets.png")
	for a in shown:
		a.model.rotation.y = PI - 0.5
	await _animate(shown, 0.3)
	await _save("fashion_sets_back.png")
	for a in shown:
		a.queue_free()

	# ---- สัตว์เลี้ยง: ทุกชนิด 3 ร่าง ----
	var owner := FakeOwner.new()
	world.add_child(owner)
	var pets: Array = []
	var species: Array = Fashion.PETS.keys()
	for si in species.size():
		for stage in 3:
			var sp: String = species[si]
			owner.state["pets"][sp] = {"lv": [10, 35, 70][stage], "exp": 0, "stage": stage}
			var p: Node3D = Pet.new()
			p.setup(owner, sp)
			world.add_child(p)
			p.rebuild()
			p.position = Vector3((si - 2.0) * 2.0, 0, (stage - 1.0) * 2.0)
			p.visual.rotation.y = 0.4
			# rebuild อ่านร่างจาก state ตอนนี้ ให้แต่ละตัวคงร่างของตัวเอง
			p.set_process(false)
			pets.append(p)
	cam.fov = 34
	cam.look_at_from_position(Vector3(0, 8.0, 11.0), Vector3(0, 0.4, 0))
	await _save("pets.png")
	for p in pets:
		p.queue_free()

	# ---- อาวุธ +0 / +4 / +7 / +9 / +10 ----
	var lineup: Array = []
	for i in WEAPONS.size():
		var a: Node3D = Avatar.new()
		world.add_child(a)
		a.build("nak_dab", {"gender": "m", "hair": 0, "skin": 0}, {"weapon": WEAPONS[i], "armor": "kraphan_krung"}, WEAPONS[i].replace("dab_krung", "ดาบกรุเก่า "))
		a.position = Vector3((i - 2.0) * 1.7, 0, 0)
		a.model.rotation.y = -0.5
		lineup.append(a)
	await _animate(lineup, 1.2)
	cam.fov = 30
	cam.look_at_from_position(Vector3(0, 3.2, 9.0), Vector3(0, 1.0, 0))
	await _save("weapon_refine.png")
	quit()


func _animate(list: Array, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		for a in list:
			a.animate(0.05, false, Vector2.ZERO, 0.0, false, 0.0)
		t += 0.05
		await process_frame


func _stage() -> void:
	world = Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.86, 0.9, 1.0)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1.0, 0.95, 0.95)
	env.environment.ambient_light_energy = 0.3
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment.tonemap_exposure = 0.8
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(30), 0)
	sun.light_energy = 0.6
	sun.shadow_enabled = true
	world.add_child(sun)
	var ground := K.box(world, Vector3(40, 0.2, 20), Vector3(0, -0.1, 0), K.mat(Color(0.55, 0.78, 0.5), 0.0, 0.9, 0.0, false))
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cam = Camera3D.new()
	cam.fov = 30
	world.add_child(cam)


func _save(name: String) -> void:
	for i in 8:
		await process_frame
	var path := out_dir.path_join(name)
	root.get_texture().get_image().save_png(path)
	print("saved ", path)
