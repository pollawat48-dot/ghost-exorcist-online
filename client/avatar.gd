extends Node3D
## โมเดลตัวละครจิบิ (ใช้ทั้งผู้เล่นเองและผู้เล่นออนไลน์คนอื่น)
## หน้าตามาจาก: คลาส (สีจีวร ผ้าคาด อาวุธ หมวก ผ้าคลุม ออร่า) + look (เพศ สีผม สีผิว) + ของที่สวมอยู่
## ของสวมใส่เปลี่ยนหน้าตาจริง: อาวุธที่ถือ, ชุด (สี/ลาย/เกราะ), หมวก (แทนหมวกของคลาส), เครื่องราง (ชิ้นเล็กที่มองเห็น)
## ของระดับตำนานเรืองแสงอ่อนๆ อาวุธตีบวก +7 ขึ้นไปมีประกายวิ้งๆ +10 แรงขึ้น
## ตาราง WEAPON_LOOK / ARMOR_LOOK / HEAD_LOOK / ACC_LOOK แมปตาม id ไอเทม ถ้าไม่มีจะเดาจาก line / ความหายาก / ชื่อ

const K = preload("res://maps/props/mesh_kit.gd")
const Classes = preload("res://shared/data/classes.gd")
const ItemDB = preload("res://shared/data/items.gd")
const ItemIcons = preload("res://client/ui/item_icons.gd")

## สีผม: น้ำตาลเข้ม ดำ น้ำตาลแดง ชมพูพาสเทล เงินอมม่วง
const HAIR_COLORS := [Color(0.36, 0.25, 0.24), Color(0.2, 0.17, 0.22), Color(0.6, 0.36, 0.24), Color(1.0, 0.68, 0.78), Color(0.82, 0.8, 0.94)]
## สีผิว: ขาว แทน อมส้ม
const SKIN_COLORS := [Color(1.0, 0.86, 0.74), Color(0.88, 0.68, 0.52), Color(0.97, 0.77, 0.62)]

## อาวุธ -> รูปทรงโมเดลที่ถือ
const WEAPON_LOOK := {
	"maipai_staff": "bamboo_staff",
	"mitmo": "knife",
	"dab_lek": "sword", "dab_ngoen": "sword", "dab_pa_cha": "sword",
	"dab_krung": "curved", "dab_chao_pa": "curved",
	"dab_naga": "wavy",
	"dab_yom": "great_sword", "dab_fafuen": "great_sword", "dab_phrai": "great_sword", "dab_matchu": "great_sword",
	"khan_thanu": "bow", "thanu_ngoen": "bow", "thanu_krung": "bow", "thanu_doi": "bow",
	"thanu_khao": "horn_bow",
	"na_mai_khamot": "crossbow",
	"thanu_naga": "great_bow", "thanu_awe": "great_bow", "thanu_ratri": "great_bow", "thanu_phrai": "great_bow", "thanu_matchu": "great_bow",
	"khamphi_yant": "palm_book",
	"khoi_boran": "khoi",
}
## ชุด -> สไตล์ (robe = เปลี่ยนสีจีวรเป็นสีของชุด)
const ARMOR_LOOK := {
	"suea_yant": "yant_shirt",
	"suea_kraphan": "vest",
	"suea_so": "chain",
	"jiwon_saksit": "jiwon",
	"pha_yant_pret": "yant_robe",
	"chut_phran": "hunter",
	"chut_yom": "reaper",
	"kraphan_ngoen": "plate",
	"kraphan_krung": "plate",
	"kraphan_naga": "naga_plate",
	"kraphan_thamin": "naga_plate",
}
const HEAD_LOOK := {
	"pha_khat_hua": "headband",
	"mongkhon": "mongkol",
	"muak_ngoen": "helmet",
	"muak_boran": "plume_helmet",
	"mongkut_queen": "tiara",
	"mongkut_naki": "naga_crown",
	"mongkut_matchu": "dark_crown",
	"chada_khun": "chada",
}
const ACC_LOOK := {
	"saisin": "wrist_string",
	"takrut": "takrut",
	"phra_khrueang": "pendant",
	"khiao_queen": "fang",
	"khiao_saming": "fang",
	"prakham_pret": "beads",
	"waen_pirot": "ring",
	"prajiat_khun": "armband",
	"kaeo_naga": "orb",
}

var model: Node3D
var body: Node3D
var head: Node3D
var weapon: Node3D
var aura: Node3D
var name_label: Label3D
var rod: Node3D  ## คันเบ็ด (ซ่อนไว้จนกว่าจะตกปลา)
var bobber: Node3D  ## ทุ่นลอย (เกมขยับขึ้นลงได้เอง)
var levelup_beam: MeshInstance3D
var fishing := false

var class_id := "novice"
var look_data := {}
var equipment := {}
var display_name := ""
var walk_t := 0.0
var anim_t := 0.0
var _sparkles: Node3D  ## ประกายรอบอาวุธที่ตีบวกสูง
var _orb: Node3D  ## แก้วลอยข้างตัว (เครื่องรางบางชิ้น)
var _rod_tip: Node3D
var _line: MeshInstance3D
var _label_y := 2.15


func _ready() -> void:
	if model == null:
		build(class_id, look_data, equipment, display_name)


# ---------- API ----------

## สร้างโมเดลใหม่ทั้งตัว (เรียกเมื่อเปลี่ยนคลาส เปลี่ยนของสวมใส่ หรือเปลี่ยนหน้าตา)
func build(p_class_id: String, look: Dictionary, p_equipment: Dictionary, p_display_name: String) -> void:
	class_id = p_class_id if Classes.CLASSES.has(p_class_id) else "novice"
	look_data = look.duplicate()
	equipment = p_equipment.duplicate()
	display_name = p_display_name
	var keep_rot := model.rotation.y if model != null else 0.0
	if model != null:
		remove_child(model)
		model.queue_free()
	if name_label != null:
		remove_child(name_label)
		name_label.queue_free()
	_sparkles = null
	_orb = null
	_build_model()
	model.rotation.y = keep_rot
	if levelup_beam == null:
		_build_fx()
	set_fishing(fishing)


func set_display_name(text: String, color: Color = Color(1, 0.97, 0.88)) -> void:
	display_name = text
	if name_label != null:
		name_label.text = text
		name_label.modulate = color


## ท่าทางรายเฟรม: หันหน้า เดินเด้งๆ เหวี่ยงอาวุธ ออร่าหมุน แสงเลเวลอัป
## facing = ทิศบนพื้นราบ (หน่วยเดียวกับ player.gd), swing = เวลาที่เหลือของท่าตี (0.2 → 0)
func animate(delta: float, moving: bool, facing: Vector2, swing: float, flash: bool, levelup_fx: float) -> void:
	if model == null:
		return
	anim_t += delta
	if facing.length() > 0.001:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(facing.x, facing.y), 0.3)
	if moving:
		walk_t += delta * 10.0
		body.position.y = absf(sin(walk_t)) * 0.06
		body.rotation.z = sin(walk_t) * 0.04
	else:
		body.position.y = lerpf(body.position.y, 0.0, 0.3)
		body.rotation.z = 0.0
	weapon.rotation.x = -sin((0.2 - swing) / 0.2 * PI) * 1.3 if swing > 0.0 else 0.0
	if aura != null:
		aura.rotation.y += delta * 1.5
	if _sparkles != null:
		_sparkles.rotation.y += delta * 2.2
		for i in _sparkles.get_child_count():
			var sp := _sparkles.get_child(i) as Node3D
			sp.scale = Vector3.ONE * (0.7 + 0.5 * absf(sin(anim_t * 3.0 + i * 1.7)))
	if _orb != null:
		_orb.position.y = 1.05 + sin(anim_t * 2.0) * 0.06
		_orb.rotation.y += delta * 1.2
	if fishing:
		_update_line()
	levelup_beam.visible = levelup_fx > 0.0
	if levelup_fx > 0.0:
		levelup_beam.scale = Vector3(1, levelup_fx / 1.2, 1)
	model.scale = Vector3.ONE * (1.08 if flash else 1.0)


## ท่าตกปลา: ถือคันเบ็ดไม้ไผ่ยื่นไปข้างหน้า มีสายกับทุ่น (ซ่อนอาวุธระหว่างตกปลา)
func set_fishing(on: bool) -> void:
	fishing = on
	if rod == null:
		return
	rod.visible = on
	bobber.visible = on
	_line.visible = on
	weapon.visible = not on
	if on:
		_update_line()


# ---------- โมเดล ----------

func _look(key: String, default: Variant) -> Variant:
	return look_data.get(key, default)


func _item_for(slot: String) -> String:
	var key: String = equipment.get(slot, "")
	if key == "" or not ItemDB.has(key):
		return ""
	return key


func _rarity(key: String) -> String:
	return ItemDB.info(key).get("rarity", "common")


## วัสดุของของสวมใส่: ระดับตำนานเรืองแสงอ่อนๆ
func _gear_mat(key: String, color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
	var glow := 0.35 if _rarity(key) == "legendary" else 0.0
	return K.mat(color, glow, roughness, metallic)


func _metal(key: String, color: Color) -> StandardMaterial3D:
	return _gear_mat(key, color, 0.35, 0.75)


## รัศมีของจีวรทรงกรวยที่ความสูง y (ไว้วางลายบนหน้าอก)
static func _robe_r(y: float) -> float:
	return 0.3 - (y - 0.105) / 0.55 * 0.13


static func _chest(y: float, out: float = 0.012) -> Vector3:
	return Vector3(0, y, _robe_r(y) + out)


const CHEST_TILT := Vector3(-0.23, 0, 0)


func _build_model() -> void:
	var cls: Dictionary = Classes.CLASSES[class_id]
	var look: Dictionary = cls["look"]
	var tier: int = cls["tier"]
	var female: bool = str(_look("gender", "m")) == "f"
	var hair_c: Color = HAIR_COLORS[clampi(int(_look("hair", 0)), 0, HAIR_COLORS.size() - 1)]
	var skin_c: Color = SKIN_COLORS[clampi(int(_look("skin", 0)), 0, SKIN_COLORS.size() - 1)]
	var armor_key := _item_for("armor")
	var armor_style := _armor_style(armor_key)
	var head_key := _item_for("head")
	var head_style := _head_style(head_key)
	var robe_c: Color = look["robe"]
	if armor_style in ["yant_shirt", "jiwon", "yant_robe", "hunter", "reaper"]:
		robe_c = ItemIcons.tint_of(armor_key)
	model = Node3D.new()
	add_child(model)
	body = Node3D.new()
	model.add_child(body)
	# ตัวจิบิ: หัวโต ตัวเล็ก ตาโตมีประกาย แก้มแดง
	var robe := K.mat(robe_c, 0.0, 0.8) if armor_style != "yant_robe" else _gear_mat(armor_key, robe_c)
	var sash := K.mat(look["sash"])
	var skin := K.mat(skin_c, 0.0, 0.7)
	var hair := K.mat(hair_c, 0.0, 0.6)
	var eye := K.mat(Color(0.2, 0.13, 0.16), 0.0, 0.3, 0.0, false)
	var shine := K.mat(Color(1, 1, 1), 1.5, 0.3, 0.0, false)
	var blush := K.mat(Color(1.0, 0.6, 0.65), 0.3, 0.8, 0.0, false)
	var shoe := K.mat(Color(0.62, 0.42, 0.36))
	if armor_style in ["plate", "naga_plate", "hunter"]:
		shoe = K.mat(ItemIcons.tint_of(armor_key).darkened(0.35))
	for x in [-0.1, 0.1]:
		K.sphere(body, 0.09, Vector3(x, 0.07, 0.03), shoe, 8, Vector3(1, 0.7, 1.3))
	K.cyl(body, 0.17, 0.3, 0.55, Vector3(0, 0.38, 0), robe, 14)
	if armor_style == "reaper" or armor_style == "jiwon":
		# ชุดยาวกรอมเท้า
		K.cyl(body, 0.29, 0.33, 0.12, Vector3(0, 0.1, 0), robe, 14)
	if armor_style != "jiwon":
		K.beam(body, Vector3(-0.18, 0.62, 0.14), Vector3(0.2, 0.3, 0.17), 0.07, sash)
	if tier >= 1:
		# ขั้น 1 ขึ้นไป: เข็มขัดและปกเสื้อ
		K.cyl(body, 0.27, 0.27, 0.07, Vector3(0, 0.33, 0), sash, 14)
		K.cyl(body, 0.2, 0.2, 0.06, Vector3(0, 0.64, 0), K.mat(look["sash"].lightened(0.3)), 14)
	if look["cape"] and armor_style != "reaper":
		K.box(body, Vector3(0.5, 0.6, 0.05), Vector3(0, 0.36, -0.26), K.mat(look["sash"].darkened(0.15)), Vector3(0.18, 0, 0))
	for x in [-0.27, 0.27]:
		K.sphere(body, 0.08, Vector3(x, 0.42, 0.04), skin, 8)
	_build_armor(armor_key, armor_style, look)
	_build_accessory(_item_for("accessory"))
	head = Node3D.new()
	head.position = Vector3(0, 1.0, 0)
	head.rotation.x = -0.25  # เงยหน้าเล็กน้อยให้เห็นหน้าจากกล้องมุมสูง
	body.add_child(head)
	K.sphere(head, 0.4, Vector3.ZERO, skin, 18)
	var covered := head_style in ["helmet", "plume_helmet"] or (head_style == "" and armor_style == "reaper")
	if not covered:
		K.sphere(head, 0.41, Vector3(0, 0.15, -0.11), hair, 18, Vector3(1.0, 0.78, 1.0))
	if female:
		_build_female_hair(head, hair, look, covered)
	for x in [-0.15, 0.15]:
		K.sphere(head, 0.095, Vector3(x, 0.0, 0.34), eye, 10, Vector3(0.85, 1.25, 0.5))
		K.sphere(head, 0.035, Vector3(x + 0.03, 0.06, 0.39), shine, 6)
		K.sphere(head, 0.065, Vector3(x * 1.55, -0.11, 0.32), blush, 8, Vector3(1.2, 0.6, 0.4))
		if female:
			# ขนตางอนเล็กๆ ที่หางตา
			K.box(head, Vector3(0.06, 0.025, 0.02), Vector3(x * 1.55, 0.09, 0.33), eye, Vector3(0, -signf(x) * 0.5, signf(x) * 0.5))
	K.sphere(head, 0.03, Vector3(0, -0.15, 0.38), K.mat(Color(0.85, 0.4, 0.42), 0.0, 0.8, 0.0, false), 6, Vector3(1.4, 0.7, 0.6))
	_label_y = 2.15
	if head_style != "":
		_build_headgear(head, head_key, head_style, hair, female)
	elif armor_style == "reaper":
		_build_hat(head, {"hat": "hood", "robe": robe_c, "sash": look["sash"]}, hair, female)
	else:
		_build_hat(head, look, hair, female)
		if look["hat"] == "crown":
			_label_y += 0.2
	weapon = Node3D.new()
	body.add_child(weapon)
	var weapon_key := _item_for("weapon")
	if weapon_key != "":
		_build_gear_weapon(weapon_key, look)
	else:
		_build_weapon(look)
	_build_rod()
	aura = null
	if look["aura"]:
		aura = Node3D.new()
		model.add_child(aura)
		var torus := TorusMesh.new()
		torus.inner_radius = 0.6
		torus.outer_radius = 0.7
		var glow := K.mat(Color(look["sash"], 0.8), 2.5, 0.3, 0.0, false)
		K.add(aura, torus, Vector3(0, 0.05, 0), glow)
		for i in 3:
			var a := i * TAU / 3.0
			K.sphere(aura, 0.07, Vector3(cos(a) * 0.65, 0.6, sin(a) * 0.65), K.mat(look["sash"], 3.0, 0.3, 0.0, false), 6)
	name_label = K.label(self, display_name, Vector3(0, _label_y, 0), Color(1, 0.97, 0.88), 36)


## ผมผู้หญิง: มวยสองข้าง ผมยาวด้านหลัง ปอยผมข้างแก้ม และโบว์สีผ้าคาด
func _build_female_hair(h: Node3D, hair: Material, look: Dictionary, covered: bool) -> void:
	K.sphere(h, 0.3, Vector3(0, -0.12, -0.2), hair, 14, Vector3(1.25, 1.25, 0.8))
	for x in [-0.3, 0.3]:
		K.sphere(h, 0.11, Vector3(x * 1.05, -0.12, 0.12), hair, 10, Vector3(0.7, 1.4, 0.8))
	if covered:
		return
	var ribbon := K.mat(look["sash"])
	for x in [-0.3, 0.3]:
		K.sphere(h, 0.13, Vector3(x, 0.32, -0.12), hair, 12)
	# โบว์ผูกผมบนมวยซ้าย (สองห่วง + ปม) ฝั่งเดียวกับมือที่ว่าง ไม่ชนอาวุธ
	var bow := Node3D.new()
	bow.position = Vector3(-0.3, 0.38, 0.03)
	bow.rotation = Vector3(-0.3, -0.3, 0.35)
	h.add_child(bow)
	for sgn in [-1.0, 1.0]:
		K.sphere(bow, 0.065, Vector3(sgn * 0.075, 0.0, 0.0), ribbon, 8, Vector3(1.25, 0.8, 0.45))
		K.box(bow, Vector3(0.035, 0.09, 0.02), Vector3(sgn * 0.03, -0.07, 0.0), ribbon, Vector3(0, 0, sgn * 0.35))
	K.sphere(bow, 0.035, Vector3(0, 0, 0.015), K.mat(look["sash"].lightened(0.3)), 6)
	# หน้าม้าเฉียง
	K.sphere(h, 0.18, Vector3(-0.12, 0.26, 0.24), hair, 10, Vector3(1.3, 0.55, 0.6))


func _build_hat(h: Node3D, look: Dictionary, hair: Material, female: bool) -> void:
	match look["hat"]:
		"":
			if not female:
				K.sphere(h, 0.1, Vector3(0, 0.46, -0.12), hair, 10)
		"headband":
			var band := TorusMesh.new()
			band.inner_radius = 0.38
			band.outer_radius = 0.44
			K.add(h, band, Vector3(0, 0.14, -0.02), K.mat(look["sash"]), Vector3(-0.15, 0, 0))
			K.box(h, Vector3(0.06, 0.28, 0.04), Vector3(0.1, 0.0, -0.42), K.mat(look["sash"]), Vector3(0.3, 0, 0.3))
			K.box(h, Vector3(0.06, 0.24, 0.04), Vector3(-0.05, 0.0, -0.43), K.mat(look["sash"]), Vector3(0.3, 0, -0.2))
		"hat_wide":
			K.cyl(h, 0.05, 0.62, 0.26, Vector3(0, 0.42, -0.04), K.mat(Color(1.0, 0.86, 0.55)), 16)
			K.cyl(h, 0.32, 0.32, 0.05, Vector3(0, 0.33, -0.04), K.mat(look["sash"]), 16)
		"topknot":
			K.sphere(h, 0.14, Vector3(0, 0.5, -0.1), hair, 10)
			K.cyl(h, 0.015, 0.015, 0.4, Vector3(0, 0.55, -0.1), K.gold(), 4, Vector3(0, 0, PI / 2.0))
			K.sphere(h, 0.05, Vector3(0.2, 0.55, -0.1), K.mat(look["sash"]), 6)
		"hood":
			K.sphere(h, 0.46, Vector3(0, 0.08, -0.08), K.mat(look["robe"].darkened(0.15)), 18, Vector3(1.0, 1.0, 1.0))
			K.cyl(h, 0.01, 0.12, 0.25, Vector3(0, 0.55, -0.2), K.mat(look["robe"].darkened(0.15)), 8, Vector3(-0.6, 0, 0))
		"crown":
			# ชฎาทองแบบไทย ทรงสอบขึ้นเป็นยอดแหลม
			if not female:
				K.sphere(h, 0.1, Vector3(0, 0.46, -0.12), hair, 10)
			K.cyl(h, 0.3, 0.34, 0.12, Vector3(0, 0.36, -0.03), K.gold(), 16)
			K.cyl(h, 0.16, 0.26, 0.2, Vector3(0, 0.52, -0.03), K.gold(), 14)
			K.cyl(h, 0.02, 0.15, 0.36, Vector3(0, 0.79, -0.03), K.gold(), 12)
			K.sphere(h, 0.05, Vector3(0, 0.36, 0.31), K.mat(Color(1.0, 0.4, 0.5), 1.2), 6)


func _build_weapon(look: Dictionary) -> void:
	match look["weapon"]:
		"staff", "orb_staff":
			weapon.position = Vector3(0.3, 0.45, 0.06)
			K.cyl(weapon, 0.03, 0.03, 1.1, Vector3(0, 0.25, 0), K.mat(Color(0.78, 0.55, 0.38)), 6)
			if look["weapon"] == "orb_staff":
				K.sphere(weapon, 0.17, Vector3(0, 0.95, 0), K.mat(look["sash"], 2.5, 0.3, 0.0, false), 12)
				var ring := TorusMesh.new()
				ring.inner_radius = 0.2
				ring.outer_radius = 0.24
				K.add(weapon, ring, Vector3(0, 0.95, 0), K.gold(), Vector3(PI / 2.0, 0, 0))
			else:
				K.sphere(weapon, 0.09, Vector3(0, 0.85, 0), K.gold(), 10)
		"sword", "great_sword":
			var big: bool = look["weapon"] == "great_sword"
			var len := 1.0 if big else 0.75
			weapon.position = Vector3(0.3, 0.42, 0.1)
			K.cyl(weapon, 0.035, 0.035, 0.22, Vector3(0, -0.05, 0), K.mat(Color(0.6, 0.38, 0.32)), 6)
			K.box(weapon, Vector3(0.28, 0.06, 0.08), Vector3(0, 0.08, 0), K.gold())
			var blade := K.mat(Color(0.88, 0.92, 1.0), 1.0 if big else 0.0, 0.3)
			K.box(weapon, Vector3(0.09 if big else 0.07, len, 0.025), Vector3(0, 0.1 + len / 2.0, 0), blade)
			K.box(weapon, Vector3(0.05, 0.1, 0.025), Vector3(0, 0.14 + len, 0), blade, Vector3(0, 0, PI / 4.0))
		"bow", "great_bow":
			var big: bool = look["weapon"] == "great_bow"
			var wood := Color(0.5, 0.35, 0.55) if big else Color(0.75, 0.52, 0.36)
			_bow_model(wood, big, look["sash"], 0.0)
		"book":
			weapon.position = Vector3(0.38, 0.6, 0.12)
			K.box(weapon, Vector3(0.28, 0.06, 0.34), Vector3.ZERO, K.mat(Color(0.75, 0.3, 0.35)), Vector3(0.4, 0, 0))
			K.box(weapon, Vector3(0.24, 0.07, 0.3), Vector3(0, 0.01, 0), K.mat(Color(1.0, 0.96, 0.85)), Vector3(0.4, 0, 0))
			for i in 2:
				K.box(weapon, Vector3(0.1, 0.2, 0.01), Vector3(-0.1 + i * 0.2, 0.3, 0), K.mat(Color(1.0, 0.9, 0.5), 1.2, 0.5, 0.0, false), Vector3(0, 0, (i - 0.5) * 0.4))


func _bow_model(wood_c: Color, big: bool, tip_c: Color, glow: float) -> void:
	var h := 0.75 if big else 0.6
	weapon.position = Vector3(-0.32, 0.5, 0.08)
	var wood := K.mat(wood_c, glow)
	var pts := [Vector3(0, -h, -0.05), Vector3(0, -h * 0.5, 0.12), Vector3(0, 0, 0.17), Vector3(0, h * 0.5, 0.12), Vector3(0, h, -0.05)]
	for i in 4:
		K.beam(weapon, pts[i], pts[i + 1], 0.05, wood)
	K.beam(weapon, pts[0], pts[4], 0.012, K.mat(Color(1, 1, 1), 0.0, 0.8, 0.0, false))
	if big:
		for tip in [pts[0], pts[4]]:
			K.sphere(weapon, 0.06, tip, K.mat(tip_c, 3.0, 0.3, 0.0, false), 6)
	# กระบอกลูกธนูที่หลัง
	K.cyl(body, 0.08, 0.08, 0.45, Vector3(0.12, 0.6, -0.26), K.mat(Color(0.7, 0.5, 0.38)), 8, Vector3(0.3, 0, -0.3))


# ---------- อาวุธตามไอเทม ----------

func _weapon_style(key: String) -> String:
	var id := ItemDB.base_id(key)
	if WEAPON_LOOK.has(id):
		return WEAPON_LOOK[id]
	var item: Dictionary = ItemDB.ITEMS[id]
	var name: String = item["name"]
	var rarity: String = item.get("rarity", "common")
	if "มีด" in name:
		return "knife"
	if "หน้าไม้" in name:
		return "crossbow"
	if "ไม้เท้า" in name:
		return "bamboo_staff"
	match item.get("line", "any"):
		"melee":
			return "great_sword" if rarity == "legendary" else "sword"
		"ranged":
			return "great_bow" if rarity in ["epic", "legendary"] else "bow"
		"magic":
			return "orb_staff" if "ไม้เท้า" in name else "book"
	return "bamboo_staff"


func _build_gear_weapon(key: String, look: Dictionary) -> void:
	var style := _weapon_style(key)
	var tint := ItemIcons.tint_of(key)
	var rarity := _rarity(key)
	var rc: Color = ItemDB.RARITY[rarity]["color"]
	var fancy := rarity in ["epic", "legendary"]
	var legend := rarity == "legendary"
	var lv := ItemDB.refine_of(key)
	var glow := 0.0
	if legend:
		glow = 0.6
	if lv >= 7:
		glow = maxf(glow, 0.9 if lv < 10 else 1.6)
	var guard := K.gold() if fancy else K.mat(tint.darkened(0.3), 0.0, 0.4, 0.6)
	var gem := K.mat(rc.lightened(0.2), 1.2, 0.3, 0.0, false)
	var top := 1.0  # ความสูงปลายอาวุธ (ไว้วางประกาย)
	match style:
		"bamboo_staff", "orb_staff":
			weapon.position = Vector3(0.3, 0.45, 0.06)
			var wood := K.mat(tint, glow * 0.5)
			K.cyl(weapon, 0.032, 0.032, 1.1, Vector3(0, 0.25, 0), wood, 6)
			for y in [-0.1, 0.15, 0.4, 0.65]:
				K.cyl(weapon, 0.038, 0.038, 0.03, Vector3(0, y, 0), K.mat(tint.darkened(0.25)), 6)
			if style == "orb_staff":
				K.sphere(weapon, 0.15, Vector3(0, 0.95, 0), K.mat(rc, 2.5, 0.3, 0.0, false), 12)
			else:
				K.sphere(weapon, 0.09, Vector3(0, 0.85, 0), K.gold(), 10)
				K.box(weapon, Vector3(0.1, 0.05, 0.02), Vector3(0.05, 0.72, 0.03), K.mat(Color(0.96, 0.52, 0.62)), Vector3(0, 0, -0.4))
				K.box(weapon, Vector3(0.03, 0.18, 0.02), Vector3(0.08, 0.63, 0.03), K.mat(Color(0.96, 0.52, 0.62)), Vector3(0, 0, 0.2))
			top = 0.9
		"knife", "sword", "curved", "wavy", "great_sword":
			weapon.position = Vector3(0.3, 0.42, 0.1)
			var big := style == "great_sword"
			var length: float = {"knife": 0.48, "sword": 0.78, "curved": 0.82, "wavy": 0.82, "great_sword": 1.02}[style]
			var width := 0.1 if big else (0.08 if style != "knife" else 0.075)
			var grip_c := Color(0.6, 0.38, 0.32) if style != "knife" else Color(0.9, 0.36, 0.38)
			K.cyl(weapon, 0.035, 0.035, 0.24 if not big else 0.28, Vector3(0, -0.05, 0), K.mat(grip_c), 6)
			K.sphere(weapon, 0.05, Vector3(0, -0.19, 0), guard, 8)
			var gw := 0.24 if style == "knife" else (0.36 if big else 0.3)
			K.box(weapon, Vector3(gw, 0.06, 0.09), Vector3(0, 0.08, 0), guard if style != "knife" else K.mat(Color(0.95, 0.4, 0.42)))
			if fancy:
				K.sphere(weapon, 0.05, Vector3(0, 0.08, 0.05), gem, 8)
				for sgn in [-1.0, 1.0]:
					K.sphere(weapon, 0.04, Vector3(sgn * gw / 2.0, 0.1, 0), guard, 6)
			var blade_c := tint.lerp(Color(1, 1, 1), 0.35)
			var blade := K.mat(blade_c, glow, 0.3, 0.3)
			match style:
				"curved":
					# ดาบไทยปลายงอนเล็กน้อย
					var segs := 4
					var x := 0.0
					var y := 0.11
					for i in segs:
						var seg := length / segs
						var ang := -0.06 * i
						K.box(weapon, Vector3(width, seg + 0.01, 0.025), Vector3(x + sin(-ang) * seg / 2.0, y + seg / 2.0, 0), blade, Vector3(0, 0, ang))
						x += sin(-ang) * seg
						y += cos(ang) * seg
					K.box(weapon, Vector3(width * 0.7, 0.12, 0.025), Vector3(x + 0.03, y + 0.03, 0), blade, Vector3(0, 0, -0.6))
					top = y + 0.1
				"wavy":
					# ดาบเกล็ดนาค: ใบดาบคดเหมือนกริช ปลายเป็นหัวนาค
					var segs := 5
					var y := 0.11
					for i in segs:
						var seg := length / segs
						var ang := 0.22 if i % 2 == 0 else -0.22
						K.box(weapon, Vector3(width, seg + 0.03, 0.025), Vector3(0, y + seg / 2.0, 0), blade, Vector3(0, 0, ang))
						y += seg
					K.box(weapon, Vector3(0.05, 0.1, 0.025), Vector3(0, y + 0.02, 0), blade, Vector3(0, 0, PI / 4.0))
					K.sphere(weapon, 0.07, Vector3(0, 0.15, 0.03), K.mat(tint.darkened(0.1)), 8, Vector3(1, 1.3, 1))
					top = y
				_:
					K.box(weapon, Vector3(width, length, 0.025), Vector3(0, 0.1 + length / 2.0, 0), blade)
					K.box(weapon, Vector3(width * 0.7, width * 0.7, 0.025), Vector3(0, 0.1 + length, 0), blade, Vector3(0, 0, PI / 4.0))
					# ร่องกลางดาบสีเข้ม
					K.box(weapon, Vector3(0.015, length * 0.75, 0.03), Vector3(0, 0.12 + length * 0.4, 0), K.mat(tint.darkened(0.2), glow, 0.4, 0.0, false))
					top = 0.1 + length
		"bow", "horn_bow", "great_bow":
			var wood_c := tint if style != "horn_bow" else Color(0.42, 0.36, 0.36)
			_bow_model(wood_c, style == "great_bow", rc.lightened(0.2), glow * 0.5)
			K.sphere(weapon, 0.06, Vector3(0, 0, 0.17), gem if fancy else K.mat(Color(0.96, 0.52, 0.62)), 8)
			top = 0.7
		"crossbow":
			weapon.position = Vector3(0.3, 0.45, 0.12)
			K.box(weapon, Vector3(0.07, 0.07, 0.6), Vector3(0, 0.05, 0.12), K.mat(Color(0.7, 0.5, 0.38)))
			var arm := K.mat(tint, glow)
			K.beam(weapon, Vector3(-0.32, 0.05, 0.22), Vector3(0, 0.05, 0.36), 0.045, arm)
			K.beam(weapon, Vector3(0.32, 0.05, 0.22), Vector3(0, 0.05, 0.36), 0.045, arm)
			K.beam(weapon, Vector3(-0.32, 0.05, 0.22), Vector3(0.32, 0.05, 0.22), 0.01, K.mat(Color(1, 1, 1), 0.0, 0.8, 0.0, false))
			K.sphere(weapon, 0.05, Vector3(0, 0.1, 0.1), gem, 8)
			K.cyl(body, 0.08, 0.08, 0.45, Vector3(0.12, 0.6, -0.26), K.mat(Color(0.7, 0.5, 0.38)), 8, Vector3(0.3, 0, -0.3))
			top = 0.3
		"book", "palm_book", "khoi":
			weapon.position = Vector3(0.38, 0.6, 0.12)
			match style:
				"palm_book":
					for i in 3:
						K.box(weapon, Vector3(0.42, 0.025, 0.1), Vector3(0, i * 0.03, 0), K.mat(tint.lightened(0.06 * i)), Vector3(0.4, 0, 0))
					K.box(weapon, Vector3(0.44, 0.1, 0.012), Vector3(-0.12, 0.03, 0), K.mat(Color(0.9, 0.3, 0.32)), Vector3(0.4, 0, 0))
				"khoi":
					for i in 4:
						K.box(weapon, Vector3(0.1, 0.07, 0.3), Vector3(-0.15 + i * 0.1, (i % 2) * 0.03, 0), K.mat(tint.lightened(0.08 if i % 2 == 0 else -0.04)), Vector3(0.4, 0, (0.25 if i % 2 == 0 else -0.25)))
				_:
					K.box(weapon, Vector3(0.3, 0.06, 0.36), Vector3.ZERO, _gear_mat(key, tint), Vector3(0.4, 0, 0))
					K.box(weapon, Vector3(0.25, 0.07, 0.31), Vector3(0, 0.01, 0), K.mat(Color(1.0, 0.96, 0.85)), Vector3(0.4, 0, 0))
					K.cyl(weapon, 0.07, 0.07, 0.02, Vector3(0, -0.02, 0.0), K.gold() if rarity != "common" else K.mat(Color(1, 0.96, 0.85)), 12, Vector3(0.4, 0, 0))
			# ยันต์ลอยเหนือคัมภีร์ (สีตามคัมภีร์ ของตำนานมีสามแผ่น)
			var card_c := tint.lerp(Color(1.0, 0.92, 0.55), 0.5)
			var cards := 3 if legend else 2
			for i in cards:
				var off := float(i) - (cards - 1) / 2.0
				K.box(weapon, Vector3(0.1, 0.2, 0.01), Vector3(off * 0.2, 0.3 + (0.05 if cards == 3 and i == 1 else 0.0), 0), K.mat(card_c, 1.2 + glow, 0.5, 0.0, false), Vector3(0, 0, off * 0.4))
			top = 0.4
	if lv >= 7:
		_sparkles = Node3D.new()
		_sparkles.position = Vector3(0, top * 0.6, 0)
		weapon.add_child(_sparkles)
		var n := 3 if lv < 10 else 5
		var sc := Color(1.0, 0.95, 0.6) if lv < 10 else rc.lightened(0.35)
		for i in n:
			var a := i * TAU / n
			var r := 0.22 if lv < 10 else 0.28
			var sp := K.sphere(_sparkles, 0.035 if lv < 10 else 0.045, Vector3(cos(a) * r, (i % 2) * 0.25 - 0.1, sin(a) * r), K.mat(sc, 3.0, 0.3, 0.0, false), 4)
			sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if lv >= 10:
			var ring := TorusMesh.new()
			ring.inner_radius = 0.2
			ring.outer_radius = 0.23
			var mi := K.add(_sparkles, ring, Vector3.ZERO, K.mat(Color(sc, 0.6), 2.5, 0.3, 0.0, false), Vector3(0.4, 0, 0))
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ---------- ชุด ----------

func _armor_style(key: String) -> String:
	if key == "":
		return ""
	var id := ItemDB.base_id(key)
	if ARMOR_LOOK.has(id):
		return ARMOR_LOOK[id]
	var name: String = ItemDB.ITEMS[id]["name"]
	if "โซ่" in name:
		return "chain"
	if "นาค" in name and "เกราะ" in name:
		return "naga_plate"
	if "เกราะ" in name:
		return "plate"
	if "จีวร" in name:
		return "jiwon"
	if "ยมทูต" in name:
		return "reaper"
	if "ผ้า" in name:
		return "yant_robe"
	if "พราน" in name:
		return "hunter"
	return "yant_shirt" if _rarity(key) == "common" else "vest"


## เครื่องหมายยันต์วงกลมบนหน้าอก
func _yant_mark(y: float, col: Material, r: float = 0.07) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = r * 0.78
	ring.outer_radius = r
	K.add(body, ring, _chest(y, 0.008), col, Vector3(PI / 2.0 - 0.23, 0, 0))
	K.box(body, Vector3(r * 1.6, 0.012, 0.012), _chest(y, 0.012), col, CHEST_TILT)
	K.box(body, Vector3(0.012, r * 1.6, 0.012), _chest(y, 0.012), col, CHEST_TILT)
	K.box(body, Vector3(r * 1.1, 0.012, 0.012), _chest(y + r * 1.5, 0.008), col, CHEST_TILT)


func _shoulder_pads(key: String, mat: Material, trim: Material, spiky: bool) -> void:
	for x in [-0.21, 0.21]:
		K.sphere(body, 0.12, Vector3(x, 0.62, 0.0), mat, 12, Vector3(1.0, 0.62, 1.0))
		K.sphere(body, 0.03, Vector3(x * 1.2, 0.66, 0.06), trim, 6)
		if spiky:
			K.cyl(body, 0.0, 0.04, 0.12, Vector3(x * 1.25, 0.72, 0.0), trim, 6, Vector3(0, 0, -signf(x) * 0.6))


func _build_armor(key: String, style: String, look: Dictionary) -> void:
	if style == "":
		return
	var tint := ItemIcons.tint_of(key)
	var rarity := _rarity(key)
	var rc: Color = ItemDB.RARITY[rarity]["color"]
	match style:
		"yant_shirt":
			_yant_mark(0.5, K.mat(Color(0.86, 0.26, 0.3), 0.0, 0.8, 0.0, false))
			for y in [0.2, 0.25]:
				K.box(body, Vector3(0.14, 0.012, 0.012), _chest(y, 0.005) + Vector3(-0.09, 0, 0), K.mat(Color(0.86, 0.26, 0.3), 0.0, 0.8, 0.0, false), CHEST_TILT)
		"vest":
			# เสื้อกั๊กคงกระพันสีแดง ผ่าหน้า มีลายยันต์ทอง
			K.cyl(body, 0.19, 0.255, 0.3, Vector3(0, 0.5, 0), _gear_mat(key, tint), 14)
			K.box(body, Vector3(0.06, 0.3, 0.02), _chest(0.5, 0.03), K.mat(look["robe"]), CHEST_TILT)
			for y in [0.42, 0.52, 0.6]:
				K.sphere(body, 0.022, _chest(y, 0.05) + Vector3(0.05, 0, 0), K.gold(), 6)
			for x in [-0.14, 0.14]:
				var ring := TorusMesh.new()
				ring.inner_radius = 0.035
				ring.outer_radius = 0.048
				K.add(body, ring, Vector3(x, 0.47, _robe_r(0.47) * 0.85 + 0.03), K.gold(), Vector3(PI / 2.0 - 0.23, 0, -x))
		"chain":
			var mail := _metal(key, tint)
			K.cyl(body, 0.19, 0.27, 0.38, Vector3(0, 0.46, 0), mail, 14)
			var link := K.mat(tint.darkened(0.35), 0.0, 0.4, 0.5, false)
			for row in 4:
				var y := 0.34 + row * 0.08
				for col in 5:
					var a := (col - 2) * 0.32 + (0.16 if row % 2 == 1 else 0.0)
					var r := _robe_r(y) + 0.032
					K.sphere(body, 0.014, Vector3(sin(a) * r, y, cos(a) * r), link, 4)
			K.cyl(body, 0.28, 0.28, 0.06, Vector3(0, 0.3, 0), K.mat(Color(0.55, 0.36, 0.3)), 14)
			K.box(body, Vector3(0.08, 0.07, 0.03), _chest(0.3, 0.06), K.gold())
		"plate", "naga_plate":
			var naga := style == "naga_plate"
			var metal := _metal(key, tint)
			var trim: Material = K.gold() if not naga else K.mat(tint.lightened(0.35), 0.3 if rarity == "legendary" else 0.0, 0.4, 0.5)
			K.cyl(body, 0.2, 0.275, 0.36, Vector3(0, 0.47, 0), metal, 14)
			K.cyl(body, 0.285, 0.285, 0.07, Vector3(0, 0.3, 0), trim, 14)
			if naga:
				# เกล็ดนาคเรียงเป็นแถวบนอก
				var scale_m := K.mat(tint.lightened(0.25), 0.3 if rarity == "legendary" else 0.0, 0.4, 0.4, false)
				for row in 3:
					var y := 0.38 + row * 0.08
					for col in 4:
						var a := (col - 1.5) * 0.36 + (0.18 if row % 2 == 1 else 0.0)
						var r := _robe_r(y) + 0.04
						K.sphere(body, 0.045, Vector3(sin(a) * r, y, cos(a) * r), scale_m, 6, Vector3(1.0, 0.7, 0.45))
			else:
				# แผ่นอกนูนกลาง
				K.box(body, Vector3(0.03, 0.3, 0.03), _chest(0.48, 0.045), trim, CHEST_TILT)
			K.sphere(body, 0.045, _chest(0.52, 0.06), K.mat(rc.lightened(0.2), 1.0, 0.3, 0.0, false), 8)
			_shoulder_pads(key, metal, trim, naga)
			if rarity == "legendary" and not look["cape"]:
				K.box(body, Vector3(0.5, 0.55, 0.04), Vector3(0, 0.36, -0.27), _gear_mat(key, tint.darkened(0.2)), Vector3(0.18, 0, 0))
		"jiwon":
			# ห่มเฉียงไหล่ซ้าย (ผ้าสีเข้มขึ้นพาดจากไหล่ไปเอว)
			var drape := _gear_mat(key, tint.darkened(0.12))
			K.beam(body, Vector3(-0.2, 0.66, 0.08), Vector3(0.22, 0.26, 0.2), 0.12, drape)
			K.beam(body, Vector3(-0.2, 0.66, -0.06), Vector3(0.24, 0.24, -0.18), 0.12, drape)
			K.sphere(body, 0.12, Vector3(-0.2, 0.6, 0.0), drape, 10, Vector3(1.0, 0.7, 1.0))
		"yant_robe":
			var gold_m := K.mat(Color(1.0, 0.82, 0.38), 0.6, 0.4, 0.5)
			_yant_mark(0.48, gold_m, 0.085)
			K.cyl(body, 0.31, 0.31, 0.05, Vector3(0, 0.13, 0), gold_m, 14)
			K.cyl(body, 0.21, 0.21, 0.05, Vector3(0, 0.64, 0), gold_m, 14)
			K.box(body, Vector3(0.5, 0.58, 0.05), Vector3(0, 0.36, -0.26), _gear_mat(key, tint.darkened(0.25)), Vector3(0.18, 0, 0))
		"hunter":
			# ปกขนสัตว์ เข็มขัด กระเป๋าหนัง
			var fur := TorusMesh.new()
			fur.inner_radius = 0.12
			fur.outer_radius = 0.24
			K.add(body, fur, Vector3(0, 0.64, 0), K.mat(Color(0.84, 0.68, 0.5)), Vector3.ZERO, Vector3(1, 0.8, 1))
			K.cyl(body, 0.28, 0.28, 0.06, Vector3(0, 0.3, 0), K.mat(Color(0.55, 0.36, 0.3)), 14)
			K.box(body, Vector3(0.12, 0.12, 0.06), Vector3(0.16, 0.24, 0.22), K.mat(Color(0.7, 0.48, 0.34)), Vector3(0, -0.5, 0))
		"reaper":
			# ชุดยมทูต: ผ้าคลุมขาดรุ่ย เชือกบ่วงคาดเอว
			var cloak := _gear_mat(key, tint.darkened(0.25))
			K.box(body, Vector3(0.52, 0.62, 0.05), Vector3(0, 0.34, -0.27), cloak, Vector3(0.18, 0, 0))
			for x in [-0.18, 0.0, 0.18]:
				K.cyl(body, 0.06, 0.0, 0.12, Vector3(x, 0.02, -0.33), cloak, 4)
			K.cyl(body, 0.285, 0.285, 0.035, Vector3(0, 0.3, 0), K.mat(Color(0.74, 0.66, 0.88)), 14)
			K.beam(body, Vector3(0.12, 0.3, 0.24), Vector3(0.16, 0.14, 0.27), 0.03, K.mat(Color(0.74, 0.66, 0.88)))
			var ring := TorusMesh.new()
			ring.inner_radius = 0.03
			ring.outer_radius = 0.05
			K.add(body, ring, Vector3(0.17, 0.11, 0.27), K.mat(Color(0.74, 0.66, 0.88)), Vector3(PI / 2.0, 0, 0))


# ---------- หมวก ----------

func _head_style(key: String) -> String:
	if key == "":
		return ""
	var id := ItemDB.base_id(key)
	if HEAD_LOOK.has(id):
		return HEAD_LOOK[id]
	var name: String = ItemDB.ITEMS[id]["name"]
	if "ชฎา" in name:
		return "chada"
	if "มงกุฎ" in name:
		return "dark_crown" if _rarity(key) == "legendary" else "tiara"
	if "หมวก" in name:
		return "helmet"
	if "มงคล" in name:
		return "mongkol"
	return "headband"


func _build_headgear(h: Node3D, key: String, style: String, hair: Material, female: bool) -> void:
	var tint := ItemIcons.tint_of(key)
	var rarity := _rarity(key)
	var rc: Color = ItemDB.RARITY[rarity]["color"]
	var legend := rarity == "legendary"
	match style:
		"headband":
			if not female:
				K.sphere(h, 0.1, Vector3(0, 0.46, -0.12), hair, 10)
			var band := TorusMesh.new()
			band.inner_radius = 0.38
			band.outer_radius = 0.44
			var m := _gear_mat(key, tint)
			K.add(h, band, Vector3(0, 0.16, -0.02), m, Vector3(-0.15, 0, 0))
			K.box(h, Vector3(0.06, 0.28, 0.04), Vector3(0.1, 0.02, -0.42), m, Vector3(0.3, 0, 0.3))
			K.box(h, Vector3(0.06, 0.24, 0.04), Vector3(-0.05, 0.02, -0.43), m, Vector3(0.3, 0, -0.2))
			# ยันต์ทองหน้าผาก
			K.box(h, Vector3(0.1, 0.07, 0.02), Vector3(0, 0.22, 0.4), K.mat(Color(1.0, 0.86, 0.45), 0.3, 0.5, 0.0, false), Vector3(-0.3, 0, 0))
		"mongkol":
			if not female:
				K.sphere(h, 0.1, Vector3(0, 0.46, -0.12), hair, 10)
			var ring := TorusMesh.new()
			ring.inner_radius = 0.37
			ring.outer_radius = 0.43
			K.add(h, ring, Vector3(0, 0.2, -0.02), _gear_mat(key, tint), Vector3(-0.15, 0, 0))
			var red := K.mat(Color(0.94, 0.4, 0.42))
			for i in 10:
				var a := i * TAU / 10.0
				var p := Vector3(cos(a) * 0.4, 0.2 - sin(a) * 0.4 * 0.15, sin(a) * 0.4 - 0.02)
				K.sphere(h, 0.035, p, red, 6)
			# หางมงคลชี้เฉียงไปด้านหลัง
			K.beam(h, Vector3(0, 0.3, -0.38), Vector3(0, 0.46, -0.58), 0.045, _gear_mat(key, tint))
			K.sphere(h, 0.05, Vector3(0, 0.3, -0.38), red, 6)
		"helmet", "plume_helmet":
			var metal := _metal(key, tint)
			K.sphere(h, 0.45, Vector3(0, 0.1, -0.03), metal, 18, Vector3(1.0, 0.85, 1.0))
			var brim := TorusMesh.new()
			brim.inner_radius = 0.4
			brim.outer_radius = 0.49
			K.add(h, brim, Vector3(0, 0.12, -0.03), K.mat(tint.darkened(0.15), 0.0, 0.4, 0.6), Vector3(-0.15, 0, 0))
			K.sphere(h, 0.05, Vector3(0, 0.24, 0.4), K.mat(rc.lightened(0.2), 1.0, 0.3, 0.0, false), 8)
			if style == "plume_helmet":
				K.cyl(h, 0.04, 0.06, 0.12, Vector3(0, 0.52, -0.06), K.gold(), 8)
				K.sphere(h, 0.12, Vector3(0, 0.68, -0.14), K.mat(Color(0.94, 0.36, 0.38)), 10, Vector3(0.6, 1.4, 1.0))
			else:
				K.cyl(h, 0.0, 0.06, 0.2, Vector3(0, 0.56, -0.04), K.gold(), 8)
		"tiara", "naga_crown":
			var gold := K.gold()
			if not female:
				K.sphere(h, 0.1, Vector3(0, 0.46, -0.12), hair, 10)
			var band := TorusMesh.new()
			band.inner_radius = 0.3
			band.outer_radius = 0.35
			K.add(h, band, Vector3(0, 0.3, -0.04), gold, Vector3(-0.2, 0, 0))
			var gem := K.mat(tint, 1.0, 0.3, 0.0, false)
			if style == "tiara":
				K.cyl(h, 0.0, 0.07, 0.22, Vector3(0, 0.46, 0.27), gold, 6, Vector3(0.2, 0, 0))
				for sgn in [-1.0, 1.0]:
					K.cyl(h, 0.0, 0.05, 0.14, Vector3(sgn * 0.17, 0.42, 0.22), gold, 6, Vector3(0.2, 0, -sgn * 0.3))
				K.sphere(h, 0.055, Vector3(0, 0.38, 0.33), gem, 8)
			else:
				# มงกุฎนาคี: หัวนาคสามเศียรชูขึ้น
				var naga_m := _gear_mat(key, tint)
				for i in 3:
					var x := (i - 1) * 0.18
					var base := Vector3(x, 0.36, 0.24 - absf(x) * 0.4)
					var tip := base + Vector3(x * 0.4, 0.26 - absf(x) * 0.3, -0.04)
					K.beam(h, base, tip, 0.05, naga_m)
					K.sphere(h, 0.055, tip, naga_m, 8, Vector3(1.0, 0.8, 1.3))
					K.sphere(h, 0.025, tip + Vector3(0, 0.0, 0.05), K.mat(Color(1.0, 0.85, 0.4), 1.5, 0.3, 0.0, false), 4)
				K.sphere(h, 0.05, Vector3(0, 0.34, 0.33), gem, 8)
		"dark_crown":
			var dark := _metal(key, Color(0.36, 0.3, 0.42))
			var red := K.mat(tint.lightened(0.1), 2.0, 0.3, 0.0, false)
			K.cyl(h, 0.31, 0.34, 0.14, Vector3(0, 0.36, -0.03), dark, 16)
			for i in 7:
				var a := -PI / 2.0 + (i - 3) * 0.55
				var p := Vector3(cos(a) * 0.29, 0.52, -sin(a) * 0.29 - 0.03)
				var hgt := 0.3 if i == 3 else (0.22 if i % 2 == 1 else 0.16)
				K.cyl(h, 0.0, 0.05, hgt, p + Vector3(0, hgt / 2.0 - 0.07, 0), dark, 5, Vector3(-sin(a) * 0.25, 0, -cos(a) * 0.25))
			K.sphere(h, 0.06, Vector3(0, 0.38, 0.32), red, 8)
			for sgn in [-1.0, 1.0]:
				K.sphere(h, 0.035, Vector3(sgn * 0.2, 0.38, 0.25), red, 6)
			_label_y += 0.2
		"chada":
			var gold := _gear_mat(key, Color(1.0, 0.8, 0.38), 0.35, 0.75) if legend else K.gold()
			if not female:
				K.sphere(h, 0.1, Vector3(0, 0.46, -0.12), hair, 10)
			K.cyl(h, 0.3, 0.34, 0.12, Vector3(0, 0.36, -0.03), gold, 16)
			K.cyl(h, 0.16, 0.26, 0.2, Vector3(0, 0.52, -0.03), gold, 14)
			K.cyl(h, 0.12, 0.17, 0.08, Vector3(0, 0.66, -0.03), gold, 12)
			K.cyl(h, 0.02, 0.12, 0.4, Vector3(0, 0.89, -0.03), gold, 12)
			# กรรเจียกข้างหู
			for sgn in [-1.0, 1.0]:
				K.box(h, Vector3(0.04, 0.24, 0.16), Vector3(sgn * 0.4, 0.12, -0.1), gold, Vector3(0.3, 0, sgn * 0.2))
			var ruby := K.mat(Color(1.0, 0.4, 0.5), 1.2, 0.3, 0.0, false)
			K.sphere(h, 0.05, Vector3(0, 0.36, 0.31), ruby, 6)
			K.sphere(h, 0.04, Vector3(0, 0.55, 0.2), ruby, 6)
			_label_y += 0.3


# ---------- เครื่องราง ----------

func _acc_style(key: String) -> String:
	if key == "":
		return ""
	var id := ItemDB.base_id(key)
	if ACC_LOOK.has(id):
		return ACC_LOOK[id]
	var name: String = ItemDB.ITEMS[id]["name"]
	if "เขี้ยว" in name:
		return "fang"
	if "แหวน" in name:
		return "ring"
	if "ตะกรุด" in name:
		return "takrut"
	if "ประคำ" in name:
		return "beads"
	if "แก้ว" in name:
		return "orb"
	if "พระ" in name:
		return "pendant"
	return "wrist_string"


func _necklace(m: Material, r: float = 0.17) -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = r - 0.012
	ring.outer_radius = r + 0.012
	K.add(body, ring, Vector3(0, 0.62, 0.02), m, Vector3(0.45, 0, 0))


func _build_accessory(key: String) -> void:
	var style := _acc_style(key)
	if style == "":
		return
	var tint := ItemIcons.tint_of(key)
	var rarity := _rarity(key)
	var rc: Color = ItemDB.RARITY[rarity]["color"]
	match style:
		"wrist_string", "armband":
			for x in [-0.27, 0.27]:
				if style == "armband" and x > 0:
					continue
				var ring := TorusMesh.new()
				ring.inner_radius = 0.07
				ring.outer_radius = 0.095 if style == "armband" else 0.088
				K.add(body, ring, Vector3(x, 0.46, 0.04), _gear_mat(key, tint), Vector3(0, 0, signf(x) * 0.3))
			if style == "armband":
				# ประเจียด: ชายผ้าแดงปลิว + ยันต์ทอง
				for k in 2:
					K.box(body, Vector3(0.04, 0.16, 0.02), Vector3(-0.33 - k * 0.03, 0.4, -0.02), _gear_mat(key, tint), Vector3(0.2, 0, 0.5 + k * 0.3))
				K.sphere(body, 0.03, Vector3(-0.3, 0.5, 0.1), K.gold(), 6)
		"ring":
			var ring := TorusMesh.new()
			ring.inner_radius = 0.06
			ring.outer_radius = 0.075
			K.add(body, ring, Vector3(-0.27, 0.42, 0.06), K.gold(), Vector3(PI / 2.0, 0, 0))
			K.sphere(body, 0.035, Vector3(-0.27, 0.49, 0.1), K.mat(tint, 1.5, 0.3, 0.0, false), 6)
		"takrut":
			_necklace(K.mat(Color(0.92, 0.32, 0.34)))
			K.cyl(body, 0.03, 0.03, 0.18, _chest(0.52, 0.05), _metal(key, tint), 8, Vector3(0, 0, PI / 2.0))
			for sgn in [-1.0, 1.0]:
				K.cyl(body, 0.034, 0.034, 0.02, _chest(0.52, 0.05) + Vector3(sgn * 0.08, 0, 0), K.mat(tint.darkened(0.25)), 8, Vector3(0, 0, PI / 2.0))
		"pendant":
			_necklace(K.mat(Color(0.95, 0.85, 0.55), 0.0, 0.4, 0.5))
			K.box(body, Vector3(0.1, 0.13, 0.03), _chest(0.5, 0.045), _metal(key, tint), CHEST_TILT)
			K.box(body, Vector3(0.065, 0.09, 0.03), _chest(0.5, 0.055), K.mat(Color(0.9, 0.84, 0.72)), CHEST_TILT)
			K.sphere(body, 0.02, _chest(0.52, 0.075), K.mat(Color(0.62, 0.5, 0.4), 0.0, 0.8, 0.0, false), 4)
		"fang":
			_necklace(K.mat(Color(0.6, 0.4, 0.32)))
			var fang := K.mat(Color(1.0, 0.97, 0.9))
			for i in 3:
				var x := (i - 1) * 0.07
				var y := 0.53 - (0.02 if i == 1 else 0.0)
				var p := _chest(y, 0.045) + Vector3(x, 0, 0)
				K.cyl(body, 0.026, 0.0, 0.1 if i == 1 else 0.08, p, fang, 6, Vector3(-0.23, 0, 0))
			K.sphere(body, 0.03, _chest(0.58, 0.04), K.mat(tint, 0.8, 0.4, 0.0, false), 6)
		"beads":
			# ประคำเม็ดโตคล้องคอ เรืองแสงสีม่วง
			var bead := _gear_mat(key, tint)
			for i in 14:
				var a := i * TAU / 14.0
				var p := Vector3(sin(a) * 0.2, 0.6 - (cos(a) * 0.5 + 0.5) * 0.12 * (1.0 if cos(a) > 0 else 0.3), cos(a) * 0.2 + 0.02)
				K.sphere(body, 0.035, p, bead, 6)
			K.sphere(body, 0.05, _chest(0.47, 0.06), K.gold(), 8)
		"orb":
			# แก้วพญานาค: ลูกแก้วเรืองแสงลอยข้างไหล่
			_orb = Node3D.new()
			_orb.position = Vector3(-0.45, 1.05, -0.15)
			model.add_child(_orb)
			var orb := K.sphere(_orb, 0.1, Vector3.ZERO, K.mat(tint, 2.2, 0.2, 0.0, false), 12)
			orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var ring := TorusMesh.new()
			ring.inner_radius = 0.13
			ring.outer_radius = 0.15
			K.add(_orb, ring, Vector3.ZERO, K.gold(), Vector3(0.5, 0, 0.3))


# ---------- ตกปลา / เอฟเฟกต์ ----------

func _build_rod() -> void:
	rod = Node3D.new()
	rod.position = Vector3(0.27, 0.45, 0.06)
	body.add_child(rod)
	var bamboo := K.mat(Color(0.86, 0.72, 0.42))
	var a := Vector3(0, -0.12, -0.08)
	var b := Vector3(0, 0.95, 1.05)
	K.beam(rod, a, b, 0.045, bamboo)
	for t in [0.25, 0.5, 0.75]:
		var p: Vector3 = a.lerp(b, t)
		K.cyl(rod, 0.032, 0.032, 0.02, p, K.mat(Color(0.7, 0.55, 0.3)), 6, Vector3(0.83, 0, 0))
	K.cyl(rod, 0.05, 0.05, 0.05, a.lerp(b, 0.12) + Vector3(0.05, 0, 0), K.mat(Color(0.86, 0.86, 0.9)), 8, Vector3(0, 0, PI / 2.0))
	_rod_tip = Node3D.new()
	_rod_tip.position = b
	rod.add_child(_rod_tip)
	bobber = Node3D.new()
	bobber.position = Vector3(0.27, 0.06, 2.1)
	model.add_child(bobber)
	K.sphere(bobber, 0.07, Vector3(0, 0.0, 0), K.mat(Color(1, 1, 1)), 10)
	K.sphere(bobber, 0.072, Vector3(0, 0.03, 0), K.mat(Color(0.98, 0.4, 0.42)), 10, Vector3(1.0, 0.6, 1.0))
	K.cyl(bobber, 0.012, 0.012, 0.12, Vector3(0, 0.12, 0), K.mat(Color(0.98, 0.4, 0.42)), 4)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.12
	ring.outer_radius = 0.15
	var ripple := K.add(bobber, ring, Vector3(0, -0.04, 0), K.mat(Color(1, 1, 1, 0.5), 0.5, 0.3, 0.0, false), Vector3.ZERO, Vector3(1, 0.2, 1))
	ripple.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var line_mesh := BoxMesh.new()
	line_mesh.size = Vector3(0.012, 1.0, 0.012)
	_line = MeshInstance3D.new()
	_line.mesh = line_mesh
	_line.material_override = K.mat(Color(0.96, 0.96, 1.0), 0.3, 0.8, 0.0, false)
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	model.add_child(_line)
	rod.visible = false
	bobber.visible = false
	_line.visible = false


## สายเบ็ดจากปลายคันถึงทุ่น (ทุ่นขยับได้ สายจึงคำนวณใหม่ทุกเฟรม)
func _update_line() -> void:
	if _line == null:
		return
	var tip := body.transform * (rod.transform * _rod_tip.position)
	var end := bobber.position + Vector3(0, 0.18, 0)
	var dir := end - tip
	var length := dir.length()
	if length < 0.001:
		return
	var up := dir / length
	var basis := Basis(Quaternion(Vector3.UP, up)) if absf(up.dot(Vector3.UP)) < 0.999 else Basis()
	_line.transform = Transform3D(basis * Basis.from_scale(Vector3(1, length, 1)), (tip + end) / 2.0)


func _build_fx() -> void:
	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.6
	beam_mesh.bottom_radius = 0.9
	beam_mesh.height = 6.0
	levelup_beam = MeshInstance3D.new()
	levelup_beam.mesh = beam_mesh
	levelup_beam.position.y = 3.0
	levelup_beam.material_override = K.mat(Color(1, 0.9, 0.5, 0.35), 2.5, 0.5, 0.0, false)
	levelup_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	levelup_beam.visible = false
	add_child(levelup_beam)
