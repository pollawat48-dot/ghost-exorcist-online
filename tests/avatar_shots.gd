extends SceneTree
## ถ่ายภาพตรวจหน้าตาตัวละครตามของสวมใส่ และไอคอนไอเทมทั้งหมด (ต้องมีหน้าจอ เช่น xvfb-run):
## godot --rendering-driver vulkan --path . --script res://tests/avatar_shots.gd -- <โฟลเดอร์ปลายทาง> [avatars|icons|ui|all] [ขนาดไอคอน]
## ได้ไฟล์ avatars_1.png, avatars_2.png (+ _back), avatars_close.png, icons_1.png, ... และ ui_*.png (หน้าต่างที่ใช้ไอคอน)

const ItemIcons = preload("res://client/ui/item_icons.gd")
const ItemDB = preload("res://shared/data/items.gd")
const P = preload("res://client/ui/palette.gd")
const K = preload("res://maps/props/mesh_kit.gd")

## ตัวละครที่จะเรียงถ่าย: [ชื่อ, คลาส, look, equipment, ท่าตกปลา]
const LINEUP := [
	["ศิษย์วัด ช", "novice", {"gender": "m", "hair": 0, "skin": 0}, {}, false],
	["ศิษย์วัด ญ", "novice", {"gender": "f", "hair": 3, "skin": 1}, {}, false],
	["ญ ผมเงิน", "novice", {"gender": "f", "hair": 4, "skin": 2}, {}, false],
	["ของต้นเกม", "nak_rob", {"gender": "m", "hair": 2, "skin": 0}, {"weapon": "mitmo+3", "armor": "suea_yant", "head": "pha_khat_hua", "accessory": "saisin"}, false],
	["หมอผี ต้นเกม", "mo_phi", {"gender": "f", "hair": 1, "skin": 0}, {"weapon": "khamphi_yant", "armor": "suea_kraphan", "head": "mongkhon", "accessory": "takrut"}, false],
	["กรุงเก่า", "nak_dab", {"gender": "m", "hair": 1, "skin": 1}, {"weapon": "dab_krung+5", "armor": "kraphan_krung", "head": "muak_boran", "accessory": "waen_pirot"}, false],
	["พราน กรุงเก่า", "phran_ratri", {"gender": "f", "hair": 2, "skin": 0}, {"weapon": "thanu_krung", "armor": "jiwon_saksit", "head": "chada_khun", "accessory": "prajiat_khun"}, false],
	["นาค", "nak_dab", {"gender": "f", "hair": 0, "skin": 0}, {"weapon": "dab_naga+7", "armor": "kraphan_naga", "head": "mongkut_naki", "accessory": "kaeo_naga"}, false],
	["ยมทูต +10", "khun_phaen", {"gender": "m", "hair": 4, "skin": 2}, {"weapon": "dab_matchu+10", "armor": "chut_yom", "head": "mongkut_matchu", "accessory": "prakham_pret"}, false],
	["จอมขมัง", "jom_khamang", {"gender": "f", "hair": 3, "skin": 0}, {"weapon": "khamphi_matchu+7", "armor": "pha_yant_pret", "head": "mongkut_queen", "accessory": "khiao_queen"}, false],
	["มือปราบ", "mue_prab", {"gender": "m", "hair": 0, "skin": 1}, {"weapon": "thanu_matchu", "armor": "kraphan_thamin", "head": "muak_ngoen", "accessory": "khiao_saming"}, false],
	["ตกปลา", "novice", {"gender": "f", "hair": 2, "skin": 1}, {"armor": "chut_phran", "accessory": "phra_khrueang"}, true],
]

var out_dir := "/tmp/claude-0/shots"


func _initialize() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	var mode := args[1] if args.size() > 1 else "all"
	var icon_size := float(args[2]) if args.size() > 2 else 52.0
	root.size = Vector2i(1280, 720)
	if mode in ["icons", "all"]:
		await _icon_pages(icon_size)
	if mode in ["avatars", "all"]:
		await _avatars()
	if mode in ["ui", "all"]:
		await _ui_windows()
	quit()


func _save(name: String) -> void:
	for i in 6:
		await process_frame
	var path := out_dir.path_join(name)
	root.get_texture().get_image().save_png(path)
	print("saved ", path)


# ---------- ไอคอน ----------

func _icon_pages(icon_size: float) -> void:
	var ids: Array = ItemDB.ITEMS.keys()
	# ตัวอย่างของตีบวก
	ids.append("mitmo+3")
	ids.append("dab_naga+7")
	ids.append("dab_matchu+10")
	var cell := Vector2(icon_size + 44.0, icon_size + 36.0)
	var cols := int(1260.0 / cell.x)
	var rows := int(700.0 / cell.y)
	var per_page := cols * rows
	var page := 0
	var i := 0
	while i < ids.size():
		page += 1
		var bg := ColorRect.new()
		bg.color = Color(0.99, 0.95, 0.96)
		bg.size = Vector2(1280, 720)
		root.add_child(bg)
		var grid := GridContainer.new()
		grid.columns = cols
		grid.position = Vector2(10, 8)
		grid.add_theme_constant_override("h_separation", 0)
		grid.add_theme_constant_override("v_separation", 0)
		bg.add_child(grid)
		for k in per_page:
			if i >= ids.size():
				break
			var id: String = ids[i]
			i += 1
			var box := VBoxContainer.new()
			box.custom_minimum_size = cell
			box.add_theme_constant_override("separation", 1)
			var ic := ItemIcons.make(id, icon_size)
			ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			box.add_child(ic)
			var l := P.label(ItemDB.display_name(id), 10)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.custom_minimum_size.x = cell.x - 4
			l.clip_text = true
			box.add_child(l)
			grid.add_child(box)
		await _save("icons_%d.png" % page)
		bg.queue_free()
		await process_frame


# ---------- ตัวละคร ----------

func _avatars() -> void:
	var Avatar: GDScript = load("res://client/avatar.gd")
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.86, 0.9, 1.0)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1.0, 0.95, 0.95)
	env.environment.ambient_light_energy = 0.5
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment.tonemap_exposure = 0.95
	env.environment.tonemap_white = 6.0
	env.environment.glow_enabled = true
	env.environment.glow_intensity = 0.4
	env.environment.glow_bloom = 0.0
	env.environment.glow_hdr_threshold = 1.2
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-55), deg_to_rad(30), 0)
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	world.add_child(sun)
	var ground := K.box(world, Vector3(40, 0.2, 12), Vector3(0, -0.1, 0), K.mat(Color(0.82, 0.93, 0.78), 0.0, 0.9, 0.0, false))
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cam := Camera3D.new()
	cam.fov = 30
	world.add_child(cam)
	var n := LINEUP.size()
	var per_row := 6
	var avatars: Array = []
	for i in n:
		var e: Array = LINEUP[i]
		var a: Node3D = Avatar.new()
		world.add_child(a)
		a.build(e[1], e[2], e[3], e[0])
		if e[4]:
			a.set_fishing(true)
		avatars.append(a)
	# ถ่ายทีละแถว 6 ตัว หันหน้าเข้ากล้อง แล้วถ่ายมุมหลังเฉียง
	for page in (n + per_row - 1) / per_row:
		for i in n:
			var a: Node3D = avatars[i]
			a.visible = i / per_row == page
			a.position = Vector3((i % per_row - (per_row - 1) / 2.0) * 1.75, 0, 0)
			a.model.rotation.y = 0.0
			a.animate(0.3, false, Vector2(0, 1), 0.0, false, 0.0)
		cam.look_at_from_position(Vector3(0, 4.6, 11.0), Vector3(0, 0.75, 0))
		await _save("avatars_%d.png" % (page + 1))
		for a in avatars:
			a.model.rotation.y = atan2(0.8, -0.7)
		await _save("avatars_%d_back.png" % (page + 1))
	# ภาพใกล้ทีละ 4 ตัว
	cam.fov = 24
	var groups := [[3, 7, 8, 9], [5, 6, 10, 11], [0, 1, 2, 4]]
	for g in groups.size():
		var close: Array = groups[g]
		for i in n:
			var a: Node3D = avatars[i]
			a.visible = i in close
			a.model.rotation.y = 0.3
			a.position = Vector3((close.find(i) - 1.5) * 1.5, 0, 0)
		cam.look_at_from_position(Vector3(0, 3.6, 8.5), Vector3(0, 0.95, 0))
		await _save("avatars_close_%d.png" % (g + 1))


# ---------- หน้าต่าง UI ที่ใช้ไอคอน (ใช้ผู้เล่นจำลอง ไม่ต้องโหลดฉากเกม) ----------

class FakePlayer extends Node3D:
	signal changed
	const Progression = preload("res://shared/combat/progression.gd")
	const Classes = preload("res://shared/data/classes.gd")
	const Quests = preload("res://shared/data/quests.gd")
	var state := Progression.new_state()
	var stats := {}
	var inventory := {}

	func _init() -> void:
		state["coins"] = 12345
		state["level"] = 42
		state["class"] = "nak_rob"
		state["equipment"] = {"weapon": "dab_naga+7", "armor": "kraphan_naga", "accessory": "kaeo_naga"}
		stats = Progression.derive(state)

	func coins() -> int: return state["coins"]
	func class_info() -> Dictionary: return Classes.CLASSES[state["class"]]
	func can_equip(_id: String) -> bool: return true
	func can_change_class() -> bool: return false
	func class_change_status() -> Dictionary:
		var trial := Classes.trial_for(state["class"])
		return {"level": 50, "level_ok": false, "quest": trial["quest"], "quest_ok": false, "fee": trial["fee"], "fee_ok": true}
	func active_quests() -> Array: return state["quests"].keys()
	func quest_status(id: String) -> String: return "active" if state["quests"].has(id) else "available"
	func equip(_id: String) -> bool: return true
	func unequip(_slot: String) -> bool: return true
	func use_item(_id: String) -> bool: return true
	func buy(_id: String, _n: int = 1) -> bool: return true
	func sell(_id: String, _n: int = 1) -> bool: return true
	func craft(_id: String, _n: int = 1) -> bool: return true
	func add_stat(_k: String) -> bool: return true
	func accept_quest(_id: String) -> bool: return true
	func abandon_quest(_id: String) -> void: pass
	func complete_quest(_id: String) -> bool: return true


func _ui_windows() -> void:
	for c in root.get_children():
		c.queue_free()
	await process_frame
	var Quests = load("res://shared/data/quests.gd")
	var fp := FakePlayer.new()
	root.add_child(fp)
	for id in ["dab_matchu+10", "mitmo+3", "suea_yant", "mongkhon", "ya_thip", "herb_potion", "nam_mon_yai", "bet_mai", "pla_nil", "pla_buek", "phra_phong", "phra_thong", "hin_ti_2", "ore_gold", "ore_diamond", "soul_krasue", "red_thread", "klet_nak"]:
		fp.inventory[id] = 3
	var n := 0
	for qid in Quests.QUESTS:
		var r: Dictionary = Quests.reward(qid, "melee")
		if not r["items"].is_empty() and n < 3:
			fp.state["quests"][qid] = 0
			n += 1
	var shots := [
		["bag", "res://client/ui/bag_window.gd", {}],
		["shop", "res://client/ui/shop_window.gd", {"name": "ร้านตาม่อง", "stock": ["bet_mai", "bet_thong", "herb_potion", "nam_mon"]}],
		["gearshop", "res://client/ui/shop_window.gd", {"name": "ร้านอาวุธ", "stock": ["dab_lek", "thanu_khao", "khamphi_thong", "suea_so", "suea_kraphan", "mongkhon", "takrut"]}],
		["char", "res://client/ui/char_window.gd", {}],
		["smith", "res://client/ui/smith_window.gd", {"name": "ช่างหลอมแร่"}],
		["quest", "res://client/ui/quest_window.gd", {}],
	]
	for e in shots:
		var bg := ColorRect.new()
		bg.color = Color(0.78, 0.86, 0.78)
		bg.size = Vector2(1280, 720)
		root.add_child(bg)
		var layer := Control.new()
		layer.size = Vector2(1280, 720)
		root.add_child(layer)
		var w: Control = (load(e[1]) as GDScript).new()
		layer.add_child(w)
		w.bind(fp)
		if e[2].is_empty():
			w.show_window()
		else:
			w.open_for(e[2])
		await _save("ui_%s.png" % e[0])
		bg.queue_free()
		layer.queue_free()
		await process_frame
