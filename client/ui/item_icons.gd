extends RefCounted
## ไอคอนไอเทมวาดด้วยโค้ด (เวกเตอร์พาสเทล ขอบหนาแบบการ์ตูน) ครบทุกไอเทมใน items.gd
## ใช้: ItemIcons.draw(ci, "mitmo+3", ศูนย์กลาง, ขนาด) หรือ ItemIcons.make("herb_potion", 36) ได้ Control พร้อมช่องพื้นหลัง
## รูปทรงเลือกจากตาราง SHAPES (ตาม id) ถ้าไม่มีจะเดาจาก type / slot / line / ชื่อ ไอเทมใหม่จึงมีไอคอนเสมอ
## สีหลักของของสวมใส่มาจาก TINTS (ตาม id) ซึ่ง avatar.gd ใช้ร่วมเพื่อให้โมเดลกับไอคอนสีตรงกัน

const ItemDB = preload("res://shared/data/items.gd")
const P = preload("res://client/ui/palette.gd")

const OL := Color(0.42, 0.29, 0.38)
const WHITE := Color(1, 1, 1)
const GOLD := Color(1.0, 0.82, 0.36)
const WOOD := Color(0.78, 0.55, 0.38)
const GLASS := Color(0.93, 0.97, 1.0)

## รูปทรงเฉพาะ: id -> [รูปทรง, ตัวแปร]
const SHAPES := {
	# ยา
	"herb_potion": ["potion", "heal"],
	"ya_hom_thong": ["potion", "heal_gold"],
	"ya_thip": ["potion", "heal_big"],
	"nam_mon": ["potion", "sp"],
	"nam_mon_yai": ["potion", "sp_big"],
	"nam_mon_thep": ["potion", "sp_big"],
	# ของจากผี
	"spirit_shard": ["crystal", ""],
	"red_thread": ["spool", ""],
	"lantern_oil": ["oil", ""],
	"khamot_ember": ["ember", ""],
	"pha_ho_sop": ["cloth", "shroud"],
	"luk_prakham": ["beads", "old"],
	"pha_prae": ["cloth", "silk"],
	"poi_phom": ["hair", ""],
	"lek_krung": ["armor_shard", ""],
	"mo_din": ["pot", ""],
	"fai_pong": ["ember", "orb"],
	"bai_takhian": ["leaf", ""],
	"sarai_phrai": ["seaweed", ""],
	"klet_nak": ["scale", ""],
	"khon_kong_koi": ["fur", ""],
	"khiao_asura": ["fang", ""],
	"buang_yom": ["rope", ""],
	"fai_awe": ["ember", "hell"],
	# แร่ หินตี+
	"ore_zinc": ["ore", ""],
	"ore_iron": ["ore", ""],
	"ore_gold": ["ore", "nugget"],
	"ore_diamond": ["gem", ""],
	"hin_ti_1": ["rune_stone", "1"],
	"hin_ti_2": ["rune_stone", "2"],
	"hin_ti_3": ["rune_stone", "3"],
	# ตกปลา
	"bet_mai": ["rod", ""],
	"bet_thong": ["rod", "gold"],
	"pla_siew": ["fish", "siew"],
	"pla_nil": ["fish", "nil"],
	"pla_chon": ["fish", "chon"],
	"pla_buek": ["fish", "buek"],
	"phra_din": ["amulet", "clay"],
	"phra_phong": ["amulet", "powder"],
	"phra_thong": ["amulet", "gold"],
	# อาวุธ
	"maipai_staff": ["staff", ""],
	"mitmo": ["sword", "knife"],
	"dab_lek": ["sword", "sword"],
	"dab_ngoen": ["sword", "sword"],
	"dab_pa_cha": ["sword", "sword"],
	"dab_krung": ["sword", "curved"],
	"dab_chao_pa": ["sword", "curved"],
	"dab_naga": ["sword", "wavy"],
	"dab_yom": ["sword", "great"],
	"dab_fafuen": ["sword", "great"],
	"dab_phrai": ["sword", "great"],
	"dab_matchu": ["sword", "great"],
	"khan_thanu": ["bow", ""],
	"thanu_khao": ["bow", "horn"],
	"thanu_ngoen": ["bow", ""],
	"na_mai_khamot": ["bow", "crossbow"],
	"thanu_krung": ["bow", ""],
	"thanu_doi": ["bow", ""],
	"thanu_naga": ["bow", "great"],
	"thanu_awe": ["bow", "great"],
	"thanu_ratri": ["bow", "great"],
	"thanu_phrai": ["bow", "great"],
	"thanu_matchu": ["bow", "great"],
	"khamphi_yant": ["book", "palm"],
	"khoi_boran": ["book", "khoi"],
	# ชุด
	"suea_yant": ["shirt", "yant"],
	"suea_kraphan": ["shirt", "vest"],
	"suea_so": ["shirt", "chain"],
	"jiwon_saksit": ["robe", "jiwon"],
	"pha_yant_pret": ["robe", "yant"],
	"chut_phran": ["shirt", "hunter"],
	"chut_yom": ["robe", "reaper"],
	"kraphan_ngoen": ["plate", ""],
	"kraphan_krung": ["plate", ""],
	"kraphan_naga": ["plate", "scale"],
	"kraphan_thamin": ["plate", "scale"],
	# หมวก
	"pha_khat_hua": ["headband", ""],
	"mongkhon": ["mongkol", ""],
	"muak_ngoen": ["helmet", ""],
	"muak_boran": ["helmet", "plume"],
	"mongkut_queen": ["crown", "tiara"],
	"mongkut_naki": ["crown", "naga"],
	"mongkut_matchu": ["crown", "spiky"],
	"chada_khun": ["chada", ""],
	# เครื่องราง
	"saisin": ["bracelet", ""],
	"takrut": ["takrut", ""],
	"phra_khrueang": ["pendant", ""],
	"khiao_queen": ["fang_necklace", ""],
	"khiao_saming": ["fang_necklace", "tiger"],
	"prakham_pret": ["beads", "big"],
	"waen_pirot": ["ring", ""],
	"prajiat_khun": ["armband", ""],
	"kaeo_naga": ["orb", ""],
}

## สีหลักของของสวมใส่ (โลหะ/ผ้า/ไม้) ใช้ทั้งไอคอนและโมเดลตัวละคร
const TINTS := {
	"maipai_staff": Color(0.95, 0.8, 0.42),
	"mitmo": Color(0.86, 0.9, 0.97),
	"khan_thanu": Color(0.74, 0.5, 0.34),
	"khamphi_yant": Color(0.93, 0.8, 0.52),
	"dab_fafuen": Color(0.55, 0.82, 1.0),
	"thanu_ratri": Color(0.42, 0.38, 0.72),
	"khamphi_queen": Color(1.0, 0.5, 0.75),
	"dab_pa_cha": Color(0.62, 0.78, 0.66),
	"na_mai_khamot": Color(0.4, 0.88, 0.82),
	"khamphi_khamot": Color(0.4, 0.85, 0.8),
	"suea_yant": Color(0.98, 0.95, 0.86),
	"suea_kraphan": Color(0.86, 0.38, 0.38),
	"jiwon_saksit": Color(1.0, 0.62, 0.24),
	"pha_yant_pret": Color(0.56, 0.42, 0.78),
	"pha_khat_hua": Color(0.94, 0.34, 0.36),
	"mongkhon": Color(0.98, 0.96, 0.9),
	"mongkut_queen": Color(1.0, 0.62, 0.8),
	"saisin": Color(0.98, 0.97, 0.93),
	"takrut": Color(0.88, 0.58, 0.38),
	"phra_khrueang": Color(1.0, 0.8, 0.38),
	"khiao_queen": Color(1.0, 0.6, 0.78),
	"prakham_pret": Color(0.62, 0.46, 0.88),
	"dab_lek": Color(0.76, 0.8, 0.9),
	"thanu_khao": Color(0.5, 0.42, 0.4),
	"khamphi_thong": Color(1.0, 0.8, 0.36),
	"suea_so": Color(0.74, 0.78, 0.86),
	"dab_ngoen": Color(0.88, 0.92, 1.0),
	"thanu_ngoen": Color(0.86, 0.9, 0.98),
	"khamphi_ngoen": Color(0.84, 0.88, 0.98),
	"kraphan_ngoen": Color(0.86, 0.9, 0.98),
	"muak_ngoen": Color(0.86, 0.9, 0.98),
	"dab_krung": Color(0.86, 0.68, 0.42),
	"thanu_krung": Color(0.8, 0.6, 0.38),
	"khoi_boran": Color(0.86, 0.7, 0.5),
	"kraphan_krung": Color(0.84, 0.64, 0.4),
	"muak_boran": Color(0.84, 0.64, 0.4),
	"waen_pirot": Color(1.0, 0.6, 0.4),
	"chada_khun": Color(1.0, 0.8, 0.32),
	"prajiat_khun": Color(0.92, 0.32, 0.34),
	"dab_chao_pa": Color(0.56, 0.8, 0.44),
	"thanu_doi": Color(0.56, 0.78, 0.42),
	"khamphi_nang_mai": Color(0.56, 0.84, 0.5),
	"chut_phran": Color(0.5, 0.72, 0.4),
	"khiao_saming": Color(1.0, 0.66, 0.3),
	"dab_phrai": Color(0.52, 1.0, 0.7),
	"thanu_phrai": Color(0.52, 0.98, 0.7),
	"khamphi_phrai": Color(0.52, 0.95, 0.72),
	"dab_naga": Color(0.36, 0.8, 0.74),
	"thanu_naga": Color(0.36, 0.78, 0.72),
	"khamphi_badan": Color(0.34, 0.66, 0.82),
	"kraphan_naga": Color(0.36, 0.78, 0.7),
	"mongkut_naki": Color(0.42, 0.86, 0.8),
	"kaeo_naga": Color(0.45, 0.9, 1.0),
	"kraphan_thamin": Color(0.26, 0.36, 0.52),
	"dab_yom": Color(0.5, 0.42, 0.66),
	"thanu_awe": Color(0.95, 0.42, 0.34),
	"khamphi_marana": Color(0.46, 0.38, 0.6),
	"chut_yom": Color(0.36, 0.3, 0.48),
	"dab_matchu": Color(0.92, 0.3, 0.36),
	"thanu_matchu": Color(0.86, 0.28, 0.36),
	"khamphi_matchu": Color(0.8, 0.26, 0.34),
	"mongkut_matchu": Color(0.86, 0.28, 0.34),
}

static var _ci: CanvasItem
static var _c := Vector2.ZERO
static var _s := 32.0
static var _font: Font


# ---------- API ----------

## วาดไอคอนของไอเทม (คีย์ตีบวกได้ เช่น "mitmo+3" จะมีป้าย +3 มุมขวาล่าง)
static func draw(ci: CanvasItem, item_key: String, center: Vector2, size: float) -> void:
	_ci = ci
	_c = center
	_s = size
	var id := ItemDB.base_id(item_key)
	if not ItemDB.ITEMS.has(id):
		_unknown()
		return
	var sp := spec(id)
	_draw_shape(sp["shape"], sp["variant"], sp["tint"], sp["rarity"], id)
	if sp["rarity"] == "legendary":
		_sparkle(Vector2(-0.38, -0.36), 0.1, Color(1.0, 0.9, 0.45))
		_sparkle(Vector2(0.4, 0.32), 0.07, Color(1.0, 0.9, 0.45))
	elif sp["rarity"] == "epic":
		_sparkle(Vector2(-0.38, -0.36), 0.08, Color(0.97, 0.88, 1.0))
	var lv := ItemDB.refine_of(item_key)
	if lv > 0:
		_badge("+%d" % lv, lv)
	_ci.draw_set_transform_matrix(Transform2D())


## Control ขนาด size x size ที่วาดช่องพื้นหลังพาสเทล + ไอคอน (ของสวมใส่มีขอบสีตามความหายาก)
static func make(item_key: String, size: float = 36.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(size, size)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func(): draw_slot(c, item_key, Rect2(Vector2.ZERO, c.size)))
	return c


## ช่องว่าง (ยังไม่ได้สวม) แสดงเงาจางๆ ของชนิดช่อง: weapon / armor / head / accessory
static func make_empty(slot: String, size: float = 36.0) -> Control:
	var sample: String = {"weapon": "dab_lek", "armor": "suea_yant", "head": "muak_ngoen", "accessory": "saisin"}.get(slot, "")
	var c := Control.new()
	c.custom_minimum_size = Vector2(size, size)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var st := StyleBoxFlat.new()
		st.bg_color = Color(1, 1, 1, 0.6)
		st.border_color = P.LAVENDER.lightened(0.35)
		st.set_border_width_all(2)
		st.set_corner_radius_all(int(c.size.x * 0.24))
		st.anti_aliasing = true
		c.draw_style_box(st, Rect2(Vector2.ZERO, c.size)))
	if sample != "":
		var ghost := Control.new()
		ghost.set_anchors_preset(Control.PRESET_FULL_RECT)
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost.modulate = Color(0.75, 0.7, 0.8, 0.28)
		ghost.draw.connect(func(): draw(ghost, sample, ghost.size / 2.0, ghost.size.x * 0.78))
		c.add_child(ghost)
	return c


## ช่องพื้นหลังโค้งมน + ไอคอน ในกรอบ rect
static func draw_slot(ci: CanvasItem, item_key: String, rect: Rect2) -> void:
	var id := ItemDB.base_id(item_key)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(1.0, 0.99, 0.97)
	st.border_color = P.LAVENDER.lightened(0.25)
	st.set_border_width_all(2)
	var rad := int(rect.size.x * 0.24)
	st.set_corner_radius_all(rad)
	st.anti_aliasing = true
	if ItemDB.ITEMS.has(id):
		var item: Dictionary = ItemDB.ITEMS[id]
		if item["type"] == "equip":
			var rc: Color = ItemDB.RARITY[item["rarity"]]["color"]
			st.bg_color = Color(1, 1, 1).lerp(rc, 0.13)
			st.border_color = rc
			st.set_border_width_all(maxi(2, int(rect.size.x / 16.0)))
		else:
			st.bg_color = Color(1, 1, 1).lerp(ItemDB.color_of(id), 0.1)
	ci.draw_style_box(st, rect)
	# เงาวาวด้านบนให้ดูเป็นปุ่มนุ่มๆ
	ci.draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.22, rect.size.y * 0.08), Vector2(rect.size.x * 0.56, rect.size.y * 0.07)), Color(1, 1, 1, 0.55))
	draw(ci, item_key, rect.get_center(), rect.size.x * 0.84)


## รูปทรง สี และความหายากที่ใช้วาด (ใช้ร่วมกับ avatar.gd ได้)
static func spec(item_key: String) -> Dictionary:
	var id := ItemDB.base_id(item_key)
	var item: Dictionary = ItemDB.ITEMS.get(id, {})
	var shape := ""
	var variant := ""
	if SHAPES.has(id):
		shape = SHAPES[id][0]
		variant = SHAPES[id][1]
	else:
		var fb := _fallback(item)
		shape = fb[0]
		variant = fb[1]
	return {"shape": shape, "variant": variant, "tint": tint_of(id), "rarity": item.get("rarity", "")}


## สีหลักของไอเทม (ของสวมใส่ใช้ TINTS ถ้าไม่มีใช้สีความหายากแบบอ่อนลง)
static func tint_of(item_key: String) -> Color:
	var id := ItemDB.base_id(item_key)
	if TINTS.has(id):
		return TINTS[id]
	if not ItemDB.ITEMS.has(id):
		return P.LAVENDER
	var item: Dictionary = ItemDB.ITEMS[id]
	if item.has("color"):
		return item["color"]
	return (ItemDB.RARITY[item.get("rarity", "common")]["color"] as Color).lightened(0.25)


## เดารูปทรงจากชนิดไอเทม (ไอเทมใหม่ที่ยังไม่ได้ใส่ใน SHAPES)
static func _fallback(item: Dictionary) -> Array:
	var name: String = item.get("name", "")
	match item.get("type", ""):
		"consumable":
			return ["potion", "sp" if item.has("sp") else "heal"]
		"soul":
			return ["soul", ""]
		"ore":
			return ["ore", ""]
		"refine":
			return ["rune_stone", "1"]
		"tool":
			return ["rod", ""]
		"fish":
			return ["fish", "nil"]
		"amulet":
			return ["amulet", "powder"]
		"equip":
			match item.get("slot", ""):
				"weapon":
					match item.get("line", "any"):
						"melee":
							return ["sword", "great" if item.get("rarity", "") == "legendary" else "sword"]
						"ranged":
							return ["bow", "great" if item.get("rarity", "") in ["epic", "legendary"] else ""]
						"magic":
							return ["book", ""]
					return ["staff", ""]
				"armor":
					if "โซ่" in name:
						return ["shirt", "chain"]
					if "เกราะ" in name:
						return ["plate", ""]
					if "จีวร" in name or "ผ้า" in name:
						return ["robe", "yant"]
					return ["shirt", "yant"]
				"head":
					if "ชฎา" in name:
						return ["chada", ""]
					if "มงกุฎ" in name:
						return ["crown", "tiara"]
					if "หมวก" in name:
						return ["helmet", ""]
					if "มงคล" in name:
						return ["mongkol", ""]
					return ["headband", ""]
				"accessory":
					if "เขี้ยว" in name:
						return ["fang_necklace", ""]
					if "แหวน" in name:
						return ["ring", ""]
					if "ตะกรุด" in name:
						return ["takrut", ""]
					if "ประคำ" in name:
						return ["beads", "big"]
					if "แก้ว" in name:
						return ["orb", ""]
					if "พระ" in name:
						return ["pendant", ""]
					return ["bracelet", ""]
	return ["crystal", ""]


static func _draw_shape(shape: String, v: String, tint: Color, rarity: String, id: String) -> void:
	var col := ItemDB.color_of(id)
	var rc: Color = ItemDB.RARITY[rarity]["color"] if rarity != "" else col
	match shape:
		"potion": _potion(col, v)
		"crystal": _crystal(col)
		"spool": _spool(col)
		"oil": _oil(col)
		"ember": _ember(col, v)
		"cloth": _cloth(col, v)
		"beads": _beads(tint if rarity != "" else col, v, rc)
		"hair": _hair(col)
		"armor_shard": _armor_shard(col)
		"pot": _pot(col)
		"leaf": _leaf(col)
		"seaweed": _seaweed(col)
		"scale": _scale_item(col)
		"fur": _fur(col)
		"fang": _fang(col)
		"rope": _rope(col)
		"soul": _soul(col, ItemDB.ITEMS[id].get("price", 0) >= 1500)
		"ore": _ore(col, v)
		"gem": _gem(col)
		"rune_stone": _rune_stone(col, int(v))
		"rod": _rod(col, v)
		"fish": _fish(col, v)
		"amulet": _amulet(col, v)
		"staff": _staff(tint, rarity)
		"sword": _sword(tint, rarity, v, rc)
		"bow": _bow(tint, rarity, v, rc)
		"book": _book(tint, rarity, v, rc)
		"shirt": _shirt(tint, v, rc)
		"robe": _robe(tint, v, rc)
		"plate": _plate(tint, v, rc)
		"headband": _headband(tint)
		"mongkol": _mongkol(tint)
		"helmet": _helmet(tint, v, rc)
		"crown": _crown(tint, v, rc)
		"chada": _chada(tint, rc)
		"bracelet": _bracelet(tint)
		"takrut": _takrut(tint)
		"pendant": _pendant(tint, rc)
		"fang_necklace": _fang_necklace(tint, v)
		"ring": _ring(tint, rc)
		"armband": _armband(tint)
		"orb": _orb(tint)
		_: _unknown()


# ---------- เครื่องมือวาด (พิกัดท้องถิ่น: 1 หน่วย = ขนาดไอคอน, ศูนย์กลาง 0,0) ----------

static func _v(p: Vector2) -> Vector2:
	return _c + p * _s


static func _w(k: float = 1.0) -> float:
	return maxf(1.3, _s * 0.045) * k


static func _pk(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(_v(p))
	return out


## รูปหลายเหลี่ยมเติมสี + เส้นขอบ (พิกัดท้องถิ่น)
static func _poly(pts: Array, fill: Color, outline: bool = true, k: float = 1.0) -> void:
	var pk := _pk(pts)
	_ci.draw_colored_polygon(pk, fill)
	if outline:
		pk.append(pk[0])
		_ci.draw_polyline(pk, OL, _w(k), true)


static func _ell(cx: float, cy: float, rx: float, ry: float, n: int = 24, a0: float = 0.0, a1: float = TAU) -> Array:
	var out: Array = []
	var full := absf(a1 - a0 - TAU) < 0.001
	var cnt := n if full else n + 1
	for i in cnt:
		var a := lerpf(a0, a1, float(i) / float(n))
		out.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	return out


static func _circle(p: Vector2, r: float, fill: Color, outline: bool = true, k: float = 1.0) -> void:
	_ci.draw_circle(_v(p), r * _s, fill)
	if outline:
		_ci.draw_arc(_v(p), r * _s, 0, TAU, 28, OL, _w(k), true)


static func _dot(p: Vector2, r: float, fill: Color) -> void:
	_ci.draw_circle(_v(p), r * _s, fill)


static func _line(a: Vector2, b: Vector2, col: Color, k: float = 1.0) -> void:
	_ci.draw_line(_v(a), _v(b), col, _w(k), true)


## เส้นหนามีขอบ (ด้าย ไม้ คันเบ็ด)
static func _stroke(pts: Array, col: Color, k: float = 2.0) -> void:
	var pk := _pk(pts)
	_ci.draw_polyline(pk, OL, _w(k + 2.0), true)
	_ci.draw_polyline(pk, col, _w(k), true)


static func _rot(pts: Array, ang: float, pivot: Vector2 = Vector2.ZERO) -> Array:
	var out: Array = []
	for p in pts:
		out.append(pivot + (p - pivot).rotated(ang))
	return out


static func _shift(pts: Array, d: Vector2) -> Array:
	var out: Array = []
	for p in pts:
		out.append(p + d)
	return out


static func _rrect(pos: Vector2, size: Vector2, r: float, fill: Color, outline: bool = true) -> void:
	var st := StyleBoxFlat.new()
	st.bg_color = fill
	st.set_corner_radius_all(int(r * _s))
	st.anti_aliasing = true
	if outline:
		st.border_color = OL
		st.set_border_width_all(int(maxf(1.0, round(_w()))))
	_ci.draw_style_box(st, Rect2(_v(pos), size * _s))


## เติมสีเฉพาะส่วนของ shape ที่อยู่ใต้ระดับ y (ของเหลวในขวด)
static func _fill_below(shape: Array, level: float, col: Color) -> void:
	var clip := PackedVector2Array([_v(Vector2(-1, level)), _v(Vector2(1, level)), _v(Vector2(1, 1)), _v(Vector2(-1, 1))])
	for part in Geometry2D.intersect_polygons(_pk(shape), clip):
		_ci.draw_colored_polygon(part, col)


static func _outline_only(pts: Array, k: float = 1.0) -> void:
	var pk := _pk(pts)
	pk.append(pk[0])
	_ci.draw_polyline(pk, OL, _w(k), true)


static func _star_pts(c: Vector2, r_out: float, r_in: float, n: int = 5, rot: float = -PI / 2.0) -> Array:
	var out: Array = []
	for i in n * 2:
		var r := r_out if i % 2 == 0 else r_in
		var a := rot + i * PI / n
		out.append(c + Vector2(cos(a), sin(a)) * r)
	return out


static func _sparkle(p: Vector2, r: float, col: Color) -> void:
	var pts := _star_pts(p, r, r * 0.32, 4)
	var pk := _pk(pts)
	_ci.draw_colored_polygon(pk, col)
	pk.append(pk[0])
	_ci.draw_polyline(pk, Color(0.96, 0.62, 0.3, 0.9) if col.b < 0.8 else Color(0.85, 0.6, 0.85, 0.9), maxf(1.0, _w(0.35)), true)


static func _shine(p: Vector2, rx: float, ry: float, alpha: float = 0.8) -> void:
	_ci.draw_colored_polygon(_pk(_ell(p.x, p.y, rx, ry, 12)), Color(1, 1, 1, alpha))


static func _face(p: Vector2, r: float, col: Color = OL) -> void:
	## หน้ายิ้มเล็กๆ ให้ไอเทมดูน่ารัก
	_dot(p + Vector2(-r, 0), r * 0.32, col)
	_dot(p + Vector2(r, 0), r * 0.32, col)
	_ci.draw_arc(_v(p + Vector2(0, r * 0.35)), r * 0.42 * _s, 0.3, PI - 0.3, 8, col, maxf(1.0, _w(0.5)), true)


static func _font_get() -> Font:
	if _font == null:
		_font = load("res://assets/fonts/Mali-Bold.ttf")
	return _font


static func _badge(text: String, lv: int) -> void:
	var fs := int(maxf(9.0, _s * 0.3))
	var f := _font_get()
	var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var h := fs * 1.05
	var br := _c + Vector2(_s * 0.56, _s * 0.56)
	var rect := Rect2(br - Vector2(tw + fs * 0.5, h), Vector2(tw + fs * 0.5, h))
	var st := StyleBoxFlat.new()
	st.bg_color = P.PINK_DEEP if lv >= 7 else (P.LAVENDER if lv >= 4 else P.MINT.darkened(0.15))
	if lv >= 10:
		st.bg_color = Color(1.0, 0.68, 0.2)
	st.border_color = Color(1, 1, 1)
	st.set_border_width_all(maxi(1, int(fs / 9.0)))
	st.set_corner_radius_all(int(h / 2.0))
	st.anti_aliasing = true
	_ci.draw_style_box(st, rect)
	var base := Vector2(rect.position.x + fs * 0.25, rect.position.y + h * 0.8)
	_ci.draw_string_outline(f, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(2, int(fs / 5.0)), OL)
	_ci.draw_string(f, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1))


static func _unknown() -> void:
	_circle(Vector2.ZERO, 0.32, P.LAVENDER.lightened(0.3))
	var f := _font_get()
	var fs := int(_s * 0.45)
	_ci.draw_string(f, _v(Vector2(-0.12, 0.16)), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, OL)


# ---------- ยา ----------

static func _potion(col: Color, v: String) -> void:
	var big := v.ends_with("big") or v == "heal_gold"
	if v.begins_with("sp"):
		# ขวดน้ำมนต์ทรงหยดน้ำ ปากแคบ
		var r := 0.27 if big else 0.23
		var body: Array = [Vector2(0.07, -0.18)]
		for p in _ell(0, 0.14, r, r, 20, -PI * 0.15, PI * 1.15):
			body.append(p)
		body.append(Vector2(-0.07, -0.18))
		_rrect(Vector2(-0.08, -0.32), Vector2(0.16, 0.16), 0.03, GLASS)
		_poly(body, GLASS)
		_fill_below(body, -0.02, col)
		_outline_only(body)
		_rrect(Vector2(-0.1, -0.42), Vector2(0.2, 0.12), 0.04, Color(0.65, 0.78, 1.0) if not big else GOLD)
		_shine(Vector2(-r * 0.5, 0.06), 0.04, 0.08)
		_sparkle(Vector2(0.05, 0.16), 0.09, Color(1, 1, 1, 0.95))
	else:
		var r := 0.3 if big else 0.26
		var body := _ell(0, 0.13, r, r * 0.95, 28)
		_rrect(Vector2(-0.09, -0.3), Vector2(0.18, 0.2), 0.03, GLASS)
		_poly(body, GLASS)
		_fill_below(body, 0.02, col)
		_outline_only(body)
		_rrect(Vector2(-0.11, -0.4), Vector2(0.22, 0.12), 0.04, WOOD)
		_shine(Vector2(-r * 0.5, 0.02), 0.045, 0.09)
		# ใบสมุนไพรบนฉลาก
		var leaf := [Vector2(-0.02, 0.24), Vector2(-0.12, 0.13), Vector2(-0.02, 0.04), Vector2(0.1, 0.1)]
		_poly(leaf, Color(0.55, 0.85, 0.45) if v != "heal_gold" else Color(1.0, 0.95, 0.7), true, 0.7)
	if big:
		# โบว์ผูกคอขวด
		var y := -0.17 if v.begins_with("sp") else -0.13
		_poly([Vector2(0, y), Vector2(-0.16, y - 0.08), Vector2(-0.15, y + 0.07)], P.PINK, true, 0.7)
		_poly([Vector2(0, y), Vector2(0.16, y - 0.08), Vector2(0.15, y + 0.07)], P.PINK, true, 0.7)
		_circle(Vector2(0, y), 0.035, P.PINK_DEEP, true, 0.6)


# ---------- ของจากผี ----------

static func _crystal(col: Color) -> void:
	var big := [Vector2(0, -0.42), Vector2(0.14, -0.2), Vector2(0.12, 0.3), Vector2(0, 0.4), Vector2(-0.12, 0.3), Vector2(-0.14, -0.2)]
	big = _rot(big, 0.25)
	var small := _shift(_rot([Vector2(0, -0.22), Vector2(0.08, -0.1), Vector2(0.07, 0.15), Vector2(0, 0.2), Vector2(-0.07, 0.15), Vector2(-0.08, -0.1)], -0.5), Vector2(-0.2, 0.12))
	_poly(small, col.darkened(0.08))
	_poly(big, col)
	_line(big[0], big[3], Color(1, 1, 1, 0.7), 0.8)
	_poly([big[0], big[1], (big[0] + big[3]) * 0.5], col.lightened(0.45), false)
	_sparkle(Vector2(0.24, -0.26), 0.08, WHITE)


static func _spool(col: Color) -> void:
	_rrect(Vector2(-0.16, -0.26), Vector2(0.32, 0.52), 0.04, col)
	for i in 5:
		var y := -0.2 + i * 0.1
		_line(Vector2(-0.14, y), Vector2(0.14, y + 0.04), col.darkened(0.25), 0.6)
	for y in [-0.33, 0.27]:
		_poly(_ell(0, y + 0.03, 0.26, 0.07, 18), WOOD)
	_stroke([Vector2(0.15, 0.1), Vector2(0.3, 0.18), Vector2(0.36, 0.34), Vector2(0.24, 0.42)], col, 1.2)
	_shine(Vector2(-0.08, -0.1), 0.03, 0.08, 0.6)


static func _oil(col: Color) -> void:
	# ขวดน้ำมันดินเผาทรงป้อม มีหูจับ และหยดน้ำมันสีทอง
	_ci.draw_arc(_v(Vector2(0.22, 0.02)), 0.12 * _s, -PI / 2.0, PI / 2.0, 12, OL, _w(3.0), true)
	_ci.draw_arc(_v(Vector2(0.22, 0.02)), 0.12 * _s, -PI / 2.0, PI / 2.0, 12, Color(0.85, 0.6, 0.45), _w(1.4), true)
	var body := _ell(0, 0.1, 0.26, 0.28, 24)
	_poly(body, Color(0.88, 0.62, 0.46))
	_rrect(Vector2(-0.08, -0.32), Vector2(0.16, 0.18), 0.03, Color(0.88, 0.62, 0.46))
	_poly([Vector2(-0.12, -0.36), Vector2(0.12, -0.36), Vector2(0.08, -0.28), Vector2(-0.08, -0.28)], Color(0.72, 0.45, 0.36))
	var drop: Array = [Vector2(0, -0.04)]
	for p in _ell(0, 0.14, 0.1, 0.1, 12, -PI * 0.2, PI * 1.2):
		drop.append(p)
	_poly(drop, col, true, 0.8)
	_shine(Vector2(-0.03, 0.12), 0.025, 0.04)


static func _flame_pts(c: Vector2, w: float, h: float) -> Array:
	var pts: Array = [c + Vector2(0, -h)]
	for p in _ell(c.x, c.y, w, w, 16, -PI * 0.15, PI * 1.15):
		pts.append(p)
	pts.reverse()
	return pts


static func _ember(col: Color, v: String) -> void:
	if v == "orb":
		# ไฟผีโป่ง: ลูกไฟกลมเรืองแสงมีหน้า
		for i in 3:
			_dot(Vector2(0, 0.04), 0.4 - i * 0.06, Color(col, 0.12 + i * 0.08))
		_circle(Vector2(0, 0.04), 0.24, col)
		_circle(Vector2(-0.06, -0.04), 0.1, col.lightened(0.5), false)
		_face(Vector2(0, 0.08), 0.07)
		return
	var outer := _flame_pts(Vector2(0, 0.14), 0.27, 0.46)
	_poly(outer, col)
	_poly(_flame_pts(Vector2(0, 0.2), 0.15, 0.24), col.lightened(0.45) if v != "hell" else Color(1.0, 0.85, 0.4), false)
	if v == "hell":
		_poly(_flame_pts(Vector2(-0.24, 0.26), 0.1, 0.2), col.darkened(0.1), true, 0.7)
		_poly(_flame_pts(Vector2(0.25, 0.28), 0.08, 0.16), col.darkened(0.1), true, 0.7)
	_face(Vector2(0, 0.2), 0.07)
	_sparkle(Vector2(0.28, -0.2), 0.06, WHITE)


static func _cloth(col: Color, v: String) -> void:
	var pts: Array = [Vector2(-0.36, -0.28), Vector2(0.0, -0.34), Vector2(0.36, -0.28), Vector2(0.32, 0.22)]
	# ชายผ้าขาดรุ่ย
	for i in 7:
		var x := 0.32 - i * 0.107
		pts.append(Vector2(x, 0.3 + (0.06 if i % 2 == 0 else -0.02)))
	pts.append(Vector2(-0.38, 0.22))
	_poly(pts, col)
	_poly([Vector2(-0.36, -0.28), Vector2(0.0, -0.34), Vector2(0.36, -0.28), Vector2(0.34, -0.12), Vector2(-0.36, -0.1)], col.lightened(0.3), true, 0.8)
	_line(Vector2(-0.1, -0.08), Vector2(-0.16, 0.26), col.darkened(0.2), 0.7)
	_line(Vector2(0.14, -0.1), Vector2(0.18, 0.24), col.darkened(0.2), 0.7)
	if v == "silk":
		for x in [-0.2, 0.02, 0.24]:
			_poly(_star_pts(Vector2(x, 0.08), 0.06, 0.025, 4), Color(1.0, 0.92, 0.6), false)
	else:
		_face(Vector2(0, 0.08), 0.06)


static func _beads(col: Color, v: String, rc: Color) -> void:
	var big := v == "big"
	var n := 14 if big else 11
	var r := 0.27 if big else 0.25
	var bead := 0.075 if big else 0.07
	var center := Vector2(0, -0.06)
	if big:
		for i in 3:
			_dot(center, 0.44 - i * 0.06, Color(col, 0.1 + i * 0.06))
	# พู่ห้อย
	_poly([Vector2(0, 0.2), Vector2(0.08, 0.42), Vector2(-0.08, 0.42)], rc if big else Color(0.95, 0.4, 0.4), true, 0.8)
	for i in n:
		var a := PI / 2.0 + i * TAU / n
		var p := center + Vector2(cos(a), sin(a)) * r
		_circle(p, bead, col if i != 0 else (GOLD if big else col.lightened(0.2)), true, 0.6)
		_dot(p + Vector2(-bead * 0.3, -bead * 0.3), bead * 0.3, Color(1, 1, 1, 0.6))
	_circle(center + Vector2(0, r + 0.02), bead * 1.25, GOLD if big else col.lightened(0.15), true, 0.7)


static func _hair(col: Color) -> void:
	for i in 4:
		var x := -0.18 + i * 0.12
		var pts: Array = []
		for k in 8:
			var t := k / 7.0
			pts.append(Vector2(x * (1.0 - t * 0.6) + sin(t * 6.0 + i) * 0.05, -0.36 + t * 0.78))
		_stroke(pts, col.lightened(0.15 * (i % 2)), 1.6)
	_rrect(Vector2(-0.16, -0.2), Vector2(0.32, 0.1), 0.03, Color(0.92, 0.25, 0.3))


static func _armor_shard(col: Color) -> void:
	var pts := [Vector2(-0.34, -0.26), Vector2(0.22, -0.34), Vector2(0.36, 0.0), Vector2(0.2, 0.06), Vector2(0.28, 0.3), Vector2(-0.3, 0.32)]
	_poly(pts, col)
	_poly([Vector2(-0.34, -0.26), Vector2(0.22, -0.34), Vector2(0.26, -0.22), Vector2(-0.3, -0.14)], col.lightened(0.3), false)
	for p in [Vector2(-0.22, -0.16), Vector2(0.12, -0.2), Vector2(-0.2, 0.2), Vector2(0.14, 0.2)]:
		_circle(p, 0.035, col.lightened(0.4), true, 0.6)
	_stroke([Vector2(0.2, 0.06), Vector2(0.0, 0.0), Vector2(-0.06, 0.12)], col.darkened(0.35), 0.5)


static func _pot(col: Color) -> void:
	var body := _ell(0, 0.1, 0.32, 0.27, 28)
	_poly(body, col)
	_rrect(Vector2(-0.16, -0.26), Vector2(0.32, 0.12), 0.04, col.lightened(0.15))
	_poly(_ell(0, -0.27, 0.19, 0.05, 16), col.darkened(0.35), true, 0.7)
	_line(Vector2(-0.3, 0.06), Vector2(0.3, 0.06), col.darkened(0.2), 0.8)
	# ผ้ายันต์แปะฝา
	_poly([Vector2(-0.05, -0.3), Vector2(0.06, -0.3), Vector2(0.08, -0.04), Vector2(-0.03, -0.04)], Color(1.0, 0.92, 0.55), true, 0.6)
	_line(Vector2(0.0, -0.24), Vector2(0.03, -0.1), Color(0.85, 0.2, 0.2), 0.6)
	_face(Vector2(0, 0.18), 0.07)
	_shine(Vector2(-0.18, 0.02), 0.04, 0.07, 0.5)


static func _leaf(col: Color) -> void:
	var pts: Array = []
	for i in 13:
		var t := i / 12.0
		pts.append(Vector2(sin(t * PI) * 0.24, -0.38 + t * 0.66))
	for i in range(11, 0, -1):
		var t := i / 12.0
		pts.append(Vector2(-sin(t * PI) * 0.24, -0.38 + t * 0.66))
	pts = _rot(pts, 0.5)
	_poly(pts, col)
	_poly(_rot([Vector2(0, -0.36), Vector2(0.18, -0.12), Vector2(0, 0.0)], 0.5), Color(1.0, 0.88, 0.45, 0.8), false)
	var stem := _rot([Vector2(0, -0.36), Vector2(0, 0.42)], 0.5)
	_line(stem[0], stem[1], col.darkened(0.35), 0.9)
	_sparkle(Vector2(0.26, -0.28), 0.07, Color(1.0, 0.95, 0.6))


static func _seaweed(col: Color) -> void:
	for i in 3:
		var x := -0.18 + i * 0.18
		var pts: Array = []
		for k in 9:
			var t := k / 8.0
			pts.append(Vector2(x + sin(t * 7.0 + i * 1.7) * 0.06, 0.38 - t * (0.66 + (0.1 if i == 1 else 0.0))))
		_stroke(pts, col.lightened(0.1 * i), 2.6)
	for p in [Vector2(-0.26, -0.2), Vector2(0.28, -0.1)]:
		_circle(p, 0.04, Color(0.85, 1.0, 1.0, 0.8), true, 0.5)


static func _scale_item(col: Color) -> void:
	for k in 2:
		var o := Vector2(-0.1 + k * 0.14, -0.08 + k * 0.12)
		var pts: Array = [o + Vector2(0, -0.26), o + Vector2(0.2, 0.0)] + _ell(o.x, o.y, 0.2, 0.2, 12, 0.0, PI).slice(1, 12) + [o + Vector2(-0.2, 0.0)]
		_poly(pts, col.lightened(0.12 * k))
		_ci.draw_arc(_v(o + Vector2(0, 0.0)), 0.12 * _s, 0.3, PI - 0.3, 10, col.lightened(0.45), _w(0.8), true)
	_sparkle(Vector2(0.24, -0.26), 0.07, WHITE)


static func _fur(col: Color) -> void:
	var pts: Array = []
	for i in 18:
		var a := -PI + i * PI / 17.0
		var r := 0.36 if i % 2 == 0 else 0.22
		pts.append(Vector2(cos(a) * r * 0.9, 0.14 + sin(a) * r))
	pts.append(Vector2(0.24, 0.28))
	pts.append(Vector2(-0.24, 0.28))
	_poly(pts, col)
	_poly([Vector2(-0.14, 0.04), Vector2(0, -0.16), Vector2(0.12, 0.06)], col.lightened(0.3), false)
	_rrect(Vector2(-0.2, 0.22), Vector2(0.4, 0.1), 0.04, Color(0.9, 0.3, 0.32))


static func _fang(col: Color) -> void:
	var pts: Array = [Vector2(-0.2, -0.3), Vector2(0.2, -0.3)]
	for i in 8:
		var t := (i + 1) / 9.0
		pts.append(Vector2(0.2 - t * 0.26 + t * t * 0.1, -0.3 + t * 0.7))
	pts.append(Vector2(-0.02, 0.42))
	for i in 8:
		var t := 1.0 - (i + 1) / 9.0
		pts.append(Vector2(-0.2 + t * 0.06, -0.3 + t * 0.62))
	_poly(pts, col)
	_rrect(Vector2(-0.22, -0.38), Vector2(0.44, 0.12), 0.04, Color(0.85, 0.42, 0.42))
	_shine(Vector2(-0.08, -0.08), 0.03, 0.1, 0.7)


static func _rope(col: Color) -> void:
	var loop := _ell(0, -0.08, 0.26, 0.24, 24, 0.0, TAU)
	loop.append(loop[0])
	_stroke(loop, col, 2.2)
	_stroke([Vector2(0.04, 0.14), Vector2(0.08, 0.26), Vector2(0.0, 0.42)], col, 2.2)
	_rrect(Vector2(-0.06, 0.1), Vector2(0.14, 0.14), 0.04, col.darkened(0.15))
	_poly(_ell(0, -0.08, 0.12, 0.12, 12), Color(0.75, 0.6, 1.0, 0.35), false)


# ---------- ดวงวิญญาณ ----------

static func _soul(col: Color, boss: bool) -> void:
	for i in 3:
		_dot(Vector2(0, 0.06), 0.44 - i * 0.07, Color(col, 0.1 + i * 0.07))
	# หางวิญญาณม้วนขึ้น
	var tail: Array = [Vector2(-0.2, 0.0), Vector2(-0.12, -0.24), Vector2(0.04, -0.4), Vector2(0.02, -0.2), Vector2(0.2, 0.0)]
	_poly(tail, col.lightened(0.25), true, 0.8)
	_circle(Vector2(0, 0.1), 0.24, col.lightened(0.15))
	_dot(Vector2(0, 0.12), 0.15, col.lightened(0.55))
	_face(Vector2(0, 0.12), 0.07)
	_shine(Vector2(-0.1, 0.0), 0.035, 0.05)
	if boss:
		var cr := [Vector2(-0.13, -0.14), Vector2(-0.13, -0.3), Vector2(-0.06, -0.21), Vector2(0, -0.34), Vector2(0.06, -0.21), Vector2(0.13, -0.3), Vector2(0.13, -0.14)]
		_poly(cr, GOLD, true, 0.7)
	_sparkle(Vector2(0.3, -0.18), 0.06, WHITE)


# ---------- แร่ หินตี+ ----------

static func _rock_pts() -> Array:
	return [Vector2(-0.36, 0.12), Vector2(-0.26, -0.18), Vector2(-0.04, -0.3), Vector2(0.22, -0.24), Vector2(0.38, 0.0), Vector2(0.3, 0.28), Vector2(-0.24, 0.3)]


static func _ore(col: Color, v: String) -> void:
	var rock := _rock_pts()
	_poly(rock, Color(0.66, 0.62, 0.66) if v != "nugget" else Color(0.7, 0.62, 0.56))
	_poly([Vector2(-0.26, -0.18), Vector2(-0.04, -0.3), Vector2(0.22, -0.24), Vector2(0.1, -0.12), Vector2(-0.16, -0.08)], Color(0.82, 0.78, 0.8), false)
	if v == "nugget":
		_poly([Vector2(-0.14, -0.04), Vector2(0.06, -0.1), Vector2(0.16, 0.04), Vector2(0.04, 0.16), Vector2(-0.16, 0.1)], col, true, 0.8)
		_poly([Vector2(0.18, 0.1), Vector2(0.28, 0.08), Vector2(0.26, 0.2), Vector2(0.16, 0.2)], col, true, 0.7)
		_sparkle(Vector2(0.0, 0.02), 0.07, WHITE)
	else:
		_stroke([Vector2(-0.3, 0.12), Vector2(-0.1, 0.04), Vector2(0.06, 0.12), Vector2(0.3, 0.02)], col, 1.6)
		_poly([Vector2(-0.06, 0.12), Vector2(0.04, 0.06), Vector2(0.12, 0.16), Vector2(0.0, 0.22)], col.lightened(0.15), true, 0.6)
	_line(Vector2(0.24, 0.18), Vector2(0.16, 0.26), Color(0.45, 0.4, 0.45), 0.6)


static func _gem_pts(c: Vector2, w: float, h: float) -> Array:
	return [c + Vector2(-w * 0.55, -h * 0.4), c + Vector2(w * 0.55, -h * 0.4), c + Vector2(w, -h * 0.05), c + Vector2(0, h * 0.6), c + Vector2(-w, -h * 0.05)]


static func _gem(col: Color) -> void:
	var g := _gem_pts(Vector2(0, 0.02), 0.38, 0.62)
	_poly(g, col)
	var top := Vector2(0, 0.02) + Vector2(0, -0.05 * 0.62)
	_poly([g[0], g[1], g[2], g[4]], col.lightened(0.35), false)
	_line(g[4], g[2], OL, 0.7)
	for x in [-0.12, 0.12]:
		_line(Vector2(x, -0.23), Vector2(x * 1.5, top.y), Color(OL, 0.6), 0.6)
		_line(Vector2(x * 1.5, top.y), g[3], Color(OL, 0.6), 0.6)
	_outline_only(g)
	_sparkle(Vector2(-0.18, -0.2), 0.07, WHITE)
	_sparkle(Vector2(0.3, 0.2), 0.05, WHITE)


static func _rune_stone(col: Color, tier: int) -> void:
	var pts := [Vector2(-0.28, -0.22), Vector2(-0.12, -0.36), Vector2(0.18, -0.34), Vector2(0.32, -0.12), Vector2(0.28, 0.26), Vector2(0.06, 0.36), Vector2(-0.26, 0.28), Vector2(-0.34, 0.04)]
	_poly(pts, col)
	_poly([Vector2(-0.28, -0.22), Vector2(-0.12, -0.36), Vector2(0.18, -0.34), Vector2(0.2, -0.24), Vector2(-0.22, -0.14)], col.lightened(0.35), false)
	var rune := Color(1, 1, 1) if tier < 3 else Color(1.0, 1.0, 0.85)
	var glow := col.darkened(0.35)
	_line(Vector2(0, -0.16), Vector2(0, 0.2), glow, 3.2)
	_line(Vector2(-0.18, 0.02), Vector2(0.18, 0.02), glow, 3.2)
	_line(Vector2(0, -0.16), Vector2(0, 0.2), rune, 1.8)
	_line(Vector2(-0.18, 0.02), Vector2(0.18, 0.02), rune, 1.8)
	for i in tier:
		_sparkle(Vector2(-0.3 + i * 0.12, -0.36), 0.06, Color(1.0, 0.95, 0.6))


# ---------- ตกปลา ----------

static func _rod(col: Color, v: String) -> void:
	var gold := v == "gold"
	var a := Vector2(-0.36, 0.38)
	var b := Vector2(0.34, -0.38)
	_stroke([Vector2(0.34, -0.38), Vector2(0.38, -0.1), Vector2(0.36, 0.14)], Color(1, 1, 1), 0.4)
	_stroke([a, b], col, 1.8)
	for i in 4:
		var t := 0.2 + i * 0.2
		var p := a.lerp(b, t)
		_line(p + Vector2(-0.03, -0.03), p + Vector2(0.03, 0.03), col.darkened(0.3), 1.0)
	_stroke([a, a.lerp(b, 0.22)], Color(0.92, 0.36, 0.38) if not gold else Color(0.55, 0.3, 0.6), 2.2)
	_circle(a.lerp(b, 0.16) + Vector2(0.07, 0.07), 0.065, GOLD if gold else Color(0.86, 0.86, 0.9), true, 0.7)
	# ทุ่นลอย
	_circle(Vector2(0.36, 0.2), 0.065, Color(0.98, 0.4, 0.42), true, 0.7)
	_poly(_ell(0.36, 0.2, 0.065, 0.065, 10, 0, PI), Color(1, 1, 1), false)
	_ci.draw_arc(_v(Vector2(0.36, 0.2)), 0.065 * _s, 0, TAU, 16, OL, _w(0.7), true)
	if gold:
		_sparkle(Vector2(-0.1, -0.24), 0.07, WHITE)


static func _fish(col: Color, v: String) -> void:
	var L := 0.28
	var H := 0.12
	match v:
		"siew":
			L = 0.22
			H = 0.08
		"nil":
			L = 0.3
			H = 0.18
		"chon":
			L = 0.38
			H = 0.11
		"buek":
			L = 0.42
			H = 0.17
	var cx := 0.06
	# หาง
	_poly([Vector2(cx - L + 0.04, 0), Vector2(cx - L - 0.12, -H * 0.9 - 0.04), Vector2(cx - L - 0.08, 0), Vector2(cx - L - 0.12, H * 0.9 + 0.04)], col.darkened(0.12))
	# ครีบบน
	_poly([Vector2(cx - L * 0.4, -H * 0.8), Vector2(cx - L * 0.1, -H - 0.1), Vector2(cx + L * 0.25, -H * 0.85)], col.darkened(0.1), true, 0.8)
	var body := _ell(cx, 0, L, H, 28)
	_poly(body, col)
	_fill_below(body, H * 0.25, col.lightened(0.4))
	_outline_only(body)
	if v == "nil":
		for i in 3:
			var x := cx - L * 0.45 + i * L * 0.3
			_line(Vector2(x, -H * 0.7), Vector2(x - 0.02, H * 0.5), col.darkened(0.25), 0.7)
	if v == "chon":
		for i in 4:
			_dot(Vector2(cx - L * 0.6 + i * L * 0.28, -H * 0.15), 0.025, col.darkened(0.35))
	if v == "buek":
		_stroke([Vector2(cx + L * 0.9, H * 0.2), Vector2(cx + L + 0.06, H + 0.06)], col.darkened(0.2), 0.5)
		_stroke([Vector2(cx + L * 0.85, H * 0.3), Vector2(cx + L - 0.04, H + 0.12)], col.darkened(0.2), 0.5)
	var eye := Vector2(cx + L * 0.6, -H * 0.2)
	_circle(eye, 0.045, WHITE, true, 0.6)
	_dot(eye + Vector2(0.008, 0), 0.025, OL)
	_dot(Vector2(cx + L * 0.4, H * 0.3), 0.025, Color(1.0, 0.6, 0.65, 0.8))
	_shine(Vector2(cx - L * 0.1, -H * 0.45), L * 0.25, 0.018, 0.6)


static func _amulet(col: Color, v: String) -> void:
	var frame := GOLD if v != "clay" else Color(0.9, 0.86, 0.8)
	if v == "gold":
		frame = Color(1.0, 0.92, 0.6)
	# ห่วงด้านบน
	_ci.draw_arc(_v(Vector2(0, -0.38)), 0.06 * _s, 0, TAU, 12, OL, _w(2.2), true)
	_ci.draw_arc(_v(Vector2(0, -0.38)), 0.06 * _s, 0, TAU, 12, frame, _w(1.0), true)
	var arch: Array = [Vector2(-0.25, 0.36), Vector2(0.25, 0.36)] + _ell(0, -0.06, 0.25, 0.26, 16, 0.0, -PI).slice(0, 17)
	_poly(arch, frame)
	var inner: Array = [Vector2(-0.18, 0.29), Vector2(0.18, 0.29)] + _ell(0, -0.06, 0.18, 0.2, 14, 0.0, -PI).slice(0, 15)
	_poly(inner, col, true, 0.7)
	# องค์พระนั่งสมาธิ
	var dark := col.darkened(0.3) if v != "gold" else Color(0.85, 0.55, 0.15)
	_dot(Vector2(0, -0.1), 0.06, dark)
	_dot(Vector2(0, -0.18), 0.025, dark)
	_ci.draw_colored_polygon(_pk([Vector2(-0.07, -0.04), Vector2(0.07, -0.04), Vector2(0.1, 0.12), Vector2(-0.1, 0.12)]), dark)
	_ci.draw_colored_polygon(_pk(_ell(0, 0.16, 0.14, 0.06, 14)), dark)
	_ci.draw_arc(_v(Vector2(0, -0.08)), 0.11 * _s, PI, TAU, 12, Color(1, 1, 1, 0.5), _w(0.6), true)
	if v == "gold":
		_sparkle(Vector2(0.28, -0.22), 0.08, WHITE)


# ---------- อาวุธ ----------

static func _staff(tint: Color, rarity: String) -> void:
	var a := Vector2(-0.24, 0.42)
	var b := Vector2(0.18, -0.3)
	_stroke([a, b], tint, 2.4)
	for i in 4:
		var p := a.lerp(b, 0.15 + i * 0.22)
		var n := (b - a).normalized().orthogonal() * 0.05
		_line(p - n, p + n, tint.darkened(0.3), 1.0)
	_circle(Vector2(0.22, -0.34), 0.1, GOLD)
	_shine(Vector2(0.19, -0.37), 0.025, 0.025)
	_stroke([Vector2(0.18, -0.26), Vector2(0.28, -0.14), Vector2(0.24, -0.02)], P.PINK_DEEP, 0.8)


static func _sword(tint: Color, rarity: String, v: String, rc: Color) -> void:
	var fancy := rarity in ["epic", "legendary"]
	var blade_c := tint.lerp(WHITE, 0.5)
	var length := 0.56
	var w := 0.075
	match v:
		"knife":
			length = 0.4
			w = 0.08
		"great":
			length = 0.62
			w = 0.11
		"curved":
			length = 0.56
	var g := 0.14  # ตำแหน่งการ์ด
	var off := Vector2(0, -0.0)
	var blade: Array = []
	if v == "curved":
		blade = [Vector2(-w, g), Vector2(-w * 1.1, g - length * 0.5), Vector2(-w * 0.2, g - length), Vector2(w * 1.6, g - length * 0.6), Vector2(w, g)]
	elif v == "wavy":
		blade = [Vector2(-w, g)]
		for i in 5:
			blade.append(Vector2(-w + (0.025 if i % 2 == 0 else -0.02), g - (i + 1) * length * 0.16))
		blade.append(Vector2(0, g - length))
		for i in range(4, -1, -1):
			blade.append(Vector2(w + (0.025 if i % 2 == 0 else -0.02), g - (i + 1) * length * 0.16))
		blade.append(Vector2(w, g))
	elif v == "knife":
		blade = [Vector2(-w, g), Vector2(-w, g - length * 0.6), Vector2(-w * 0.2, g - length), Vector2(w, g - length * 0.7), Vector2(w, g)]
	else:
		blade = [Vector2(-w, g), Vector2(-w, g - length + w * 1.6), Vector2(0, g - length), Vector2(w, g - length + w * 1.6), Vector2(w, g)]
	var ang := PI / 4.0
	var mid := (g - length + g + 0.3) / 2.0
	var scl := 0.98 / (length + 0.3)
	var T := func(pts: Array) -> Array:
		var out: Array = []
		for p in pts:
			out.append(((p - Vector2(0, mid)) * scl * 1.18).rotated(ang))
		return out
	_poly(T.call(blade), blade_c)
	# ร่องกลางดาบ
	var fuller: Array = T.call([Vector2(0, g - 0.02), Vector2(0, g - length * 0.75)])
	_line(fuller[0], fuller[1], tint.darkened(0.15) if v != "knife" else Color(0.9, 0.3, 0.35), 0.8)
	var gw := 0.17 if v != "great" else 0.24
	var guard: Array = [Vector2(-gw, g - 0.02), Vector2(-gw * 0.7, g - 0.06), Vector2(gw * 0.7, g - 0.06), Vector2(gw, g - 0.02), Vector2(gw * 0.7, g + 0.05), Vector2(-gw * 0.7, g + 0.05)]
	var guard_c := GOLD if fancy else tint.darkened(0.25)
	if v == "knife":
		guard_c = Color(0.92, 0.36, 0.38)
	_poly(T.call(guard), guard_c)
	var grip: Array = T.call([Vector2(-0.04, g + 0.05), Vector2(0.04, g + 0.05), Vector2(0.04, g + 0.24), Vector2(-0.04, g + 0.24)])
	_poly(grip, Color(0.62, 0.4, 0.34) if v != "knife" else Color(0.85, 0.65, 0.45))
	for k in 2:
		var line: Array = T.call([Vector2(-0.04, g + 0.1 + k * 0.07), Vector2(0.04, g + 0.13 + k * 0.07)])
		_line(line[0], line[1], Color(0.95, 0.85, 0.6), 0.7)
	var pom: Array = T.call([Vector2(0, g + 0.28)])
	_circle(pom[0], 0.055, guard_c, true, 0.8)
	if fancy:
		var gem: Array = T.call([Vector2(0, g)])
		_circle(gem[0], 0.045 if v != "great" else 0.06, rc.lightened(0.2), true, 0.7)
	var shine: Array = T.call([Vector2(-w * 0.45, g - 0.06), Vector2(-w * 0.45, g - length * 0.55)])
	_line(shine[0], shine[1], Color(1, 1, 1, 0.85), 0.8)
	if v == "great":
		_sparkle(Vector2(0.3, -0.34), 0.08, Color(1, 1, 1))


static func _bow(tint: Color, rarity: String, v: String, rc: Color) -> void:
	if v == "crossbow":
		# หน้าไม้: ด้ามตรง + คันขวาง
		_rrect(Vector2(-0.06, -0.24), Vector2(0.12, 0.62), 0.04, WOOD)
		var arm: Array = []
		for i in 9:
			var t := -1.0 + i * 0.25
			arm.append(Vector2(t * 0.38, -0.18 + t * t * 0.14))
		_stroke(arm, tint, 2.0)
		_line(arm[0], Vector2(0, -0.04), Color(1, 1, 1), 0.6)
		_line(arm[8], Vector2(0, -0.04), Color(1, 1, 1), 0.6)
		_stroke([Vector2(0, 0.02), Vector2(0, -0.38)], Color(0.95, 0.9, 0.8), 0.9)
		_poly([Vector2(0, -0.46), Vector2(0.06, -0.36), Vector2(-0.06, -0.36)], tint.lightened(0.3), true, 0.7)
		_circle(Vector2(0, -0.18), 0.05, rc, true, 0.6)
		return
	var great := v == "great"
	var wood := tint if v != "horn" else Color(0.42, 0.36, 0.36)
	var limb: Array = []
	for i in 13:
		var t := -1.0 + i / 6.0
		var x := 0.12 - (1.0 - t * t) * 0.3
		if great:
			x += t * t * t * t * 0.07  # ปลายงอนออก
		limb.append(Vector2(x, t * 0.42))
	var ang := 0.5
	limb = _rot(limb, ang)
	var top: Vector2 = limb[0]
	var bot: Vector2 = limb[12]
	_line(top, bot, OL, 1.3)
	_line(top, bot, Color(1, 0.97, 0.9), 0.6)
	# ลูกธนูพาดสาย
	var arrow := _rot([Vector2(0.14, 0), Vector2(-0.4, 0)], ang)
	_stroke(arrow, Color(0.82, 0.62, 0.45), 0.8)
	var head := _rot([Vector2(-0.48, 0), Vector2(-0.38, -0.05), Vector2(-0.38, 0.05)], ang)
	_poly(head, Color(0.88, 0.92, 1.0), true, 0.6)
	var fl := _rot([Vector2(0.08, 0), Vector2(0.16, -0.06), Vector2(0.2, -0.06), Vector2(0.14, 0), Vector2(0.2, 0.06), Vector2(0.16, 0.06)], ang)
	_poly(fl, P.PINK_DEEP, true, 0.5)
	_stroke(limb, wood, 2.2 if not great else 2.6)
	var grip: Vector2 = limb[6]
	_circle(grip, 0.055, rc if rarity != "common" else P.PINK_DEEP, true, 0.7)
	if great:
		for p in [top, bot]:
			_circle(p, 0.045, GOLD, true, 0.6)
		_sparkle(Vector2(0.32, -0.32), 0.07, WHITE)


static func _book(tint: Color, rarity: String, v: String, rc: Color) -> void:
	if v == "palm":
		# คัมภีร์ใบลาน: ใบลานยาวซ้อนกัน ร้อยด้วยเชือก
		for i in 3:
			var y := -0.2 + i * 0.13
			_rrect(Vector2(-0.4, y), Vector2(0.8, 0.12), 0.05, tint.lightened(0.08 * i))
			for k in 4:
				_line(Vector2(-0.28 + k * 0.15, y + 0.06), Vector2(-0.18 + k * 0.15, y + 0.06), Color(0.4, 0.3, 0.3), 0.6)
		_rrect(Vector2(-0.42, 0.18), Vector2(0.84, 0.08), 0.03, Color(0.86, 0.36, 0.38))
		_stroke([Vector2(-0.22, -0.24), Vector2(-0.22, 0.32)], Color(0.92, 0.3, 0.32), 0.8)
		_stroke([Vector2(0.22, -0.24), Vector2(0.22, 0.32)], Color(0.92, 0.3, 0.32), 0.8)
		return
	if v == "khoi":
		# สมุดข่อยพับไปมา
		for i in 4:
			var x := -0.36 + i * 0.18
			var up := 0.04 if i % 2 == 0 else -0.04
			_poly([Vector2(x, -0.26 + up), Vector2(x + 0.18, -0.26 - up), Vector2(x + 0.18, 0.26 - up), Vector2(x, 0.26 + up)], tint.lightened(0.1 if i % 2 == 0 else -0.05), true, 0.8)
			_line(Vector2(x + 0.04, -0.1), Vector2(x + 0.14, -0.1), Color(0.35, 0.25, 0.25), 0.6)
			_line(Vector2(x + 0.04, 0.02), Vector2(x + 0.14, 0.02), Color(0.35, 0.25, 0.25), 0.6)
		_circle(Vector2(0.24, 0.16), 0.06, rc, true, 0.6)
		return
	var dark := tint.darkened(0.25)
	# หน้ากระดาษ
	_rrect(Vector2(-0.26, -0.3), Vector2(0.58, 0.66), 0.06, Color(1.0, 0.97, 0.88))
	for k in 3:
		_line(Vector2(0.3, -0.2 + k * 0.18), Vector2(0.3, -0.12 + k * 0.18), Color(0.8, 0.72, 0.6), 0.5)
	_rrect(Vector2(-0.32, -0.36), Vector2(0.56, 0.66), 0.07, tint)
	_rrect(Vector2(-0.32, -0.36), Vector2(0.12, 0.66), 0.05, dark)
	# ตรายันต์บนปก
	var c := Vector2(0.04, -0.04)
	_circle(c, 0.13, GOLD if rarity != "common" else Color(1, 0.96, 0.85), true, 0.7)
	_poly(_star_pts(c, 0.1, 0.045, 5), tint.lightened(0.3), false)
	_dot(c, 0.03, rc if rarity != "" else dark)
	if rarity in ["epic", "legendary"]:
		for p in [Vector2(-0.14, -0.3), Vector2(0.2, -0.3), Vector2(-0.14, 0.24), Vector2(0.2, 0.24)]:
			_dot(p, 0.03, GOLD)
	# ที่คั่นหนังสือ
	_poly([Vector2(0.12, 0.28), Vector2(0.2, 0.28), Vector2(0.2, 0.44), Vector2(0.16, 0.39), Vector2(0.12, 0.44)], P.PINK_DEEP, true, 0.6)
	_shine(Vector2(-0.06, -0.26), 0.08, 0.02, 0.5)


# ---------- ชุด ----------

static func _shirt_pts(sleeves: bool) -> Array:
	if sleeves:
		return [Vector2(-0.1, -0.34), Vector2(-0.24, -0.3), Vector2(-0.42, -0.12), Vector2(-0.32, 0.0), Vector2(-0.24, -0.06), Vector2(-0.24, 0.38), Vector2(0.24, 0.38), Vector2(0.24, -0.06), Vector2(0.32, 0.0), Vector2(0.42, -0.12), Vector2(0.24, -0.3), Vector2(0.1, -0.34), Vector2(0.0, -0.26)]
	return [Vector2(-0.12, -0.34), Vector2(-0.26, -0.28), Vector2(-0.28, 0.38), Vector2(0.28, 0.38), Vector2(0.26, -0.28), Vector2(0.12, -0.34), Vector2(0.0, -0.22)]


static func _yant_marks(c: Vector2, col: Color, r: float) -> void:
	_ci.draw_arc(_v(c), r * _s, 0, TAU, 18, col, _w(0.7), true)
	_line(c + Vector2(-r, 0), c + Vector2(r, 0), col, 0.6)
	_line(c + Vector2(0, -r), c + Vector2(0, r), col, 0.6)
	_ci.draw_arc(_v(c + Vector2(0, -r * 1.5)), r * 0.5 * _s, PI, TAU, 8, col, _w(0.6), true)


static func _shirt(tint: Color, v: String, rc: Color) -> void:
	var sleeves := v != "vest"
	var body := _shirt_pts(sleeves)
	_poly(body, tint)
	match v:
		"yant":
			_yant_marks(Vector2(0, 0.06), Color(0.85, 0.25, 0.3), 0.11)
			for x in [-0.15, 0.15]:
				for y in [0.22, 0.3]:
					_line(Vector2(x - 0.05, y), Vector2(x + 0.05, y), Color(0.85, 0.25, 0.3), 0.5)
		"vest":
			_yant_marks(Vector2(0, 0.08), Color(1.0, 0.86, 0.5), 0.12)
			_line(Vector2(0, -0.22), Vector2(0, 0.38), tint.darkened(0.3), 0.8)
			for y in [-0.08, 0.1, 0.26]:
				_circle(Vector2(0.04, y), 0.025, GOLD, true, 0.4)
		"chain":
			for row in 6:
				for col in 5:
					var p := Vector2(-0.18 + col * 0.09 + (0.045 if row % 2 == 1 else 0.0), -0.16 + row * 0.09)
					if p.x < 0.22:
						_ci.draw_arc(_v(p), 0.028 * _s, 0, TAU, 8, tint.darkened(0.35), _w(0.5), true)
			_rrect(Vector2(-0.25, 0.16), Vector2(0.5, 0.07), 0.02, Color(0.62, 0.42, 0.34))
		"hunter":
			# ปกขนสัตว์ + เข็มขัด
			_poly([Vector2(-0.24, -0.3), Vector2(-0.1, -0.36), Vector2(0, -0.24), Vector2(0.1, -0.36), Vector2(0.24, -0.3), Vector2(0.18, -0.18), Vector2(0, -0.12), Vector2(-0.18, -0.18)], Color(0.82, 0.66, 0.48), true, 0.8)
			_rrect(Vector2(-0.25, 0.12), Vector2(0.5, 0.08), 0.02, Color(0.55, 0.36, 0.3))
			_poly([Vector2(0.06, 0.2), Vector2(0.18, 0.2), Vector2(0.16, 0.34), Vector2(0.08, 0.34)], Color(0.65, 0.45, 0.32), true, 0.6)
	_outline_only(body)


static func _robe(tint: Color, v: String, rc: Color) -> void:
	if v == "reaper":
		var hood := _ell(0, -0.18, 0.2, 0.2, 20)
		var body := [Vector2(-0.2, -0.16), Vector2(0.2, -0.16), Vector2(0.36, 0.4), Vector2(-0.36, 0.4)]
		_poly(body, tint)
		_poly(hood, tint.darkened(0.1))
		_poly(_ell(0, -0.15, 0.12, 0.12, 16), Color(0.16, 0.12, 0.22), false)
		_dot(Vector2(-0.045, -0.15), 0.025, Color(1.0, 0.45, 0.5))
		_dot(Vector2(0.045, -0.15), 0.025, Color(1.0, 0.45, 0.5))
		_stroke([Vector2(-0.3, 0.1), Vector2(0.0, 0.2), Vector2(0.3, 0.1)], Color(0.7, 0.62, 0.85), 0.7)
		for x in [-0.2, 0.0, 0.2]:
			_line(Vector2(x, 0.25), Vector2(x * 1.3, 0.4), tint.darkened(0.3), 0.6)
		return
	var body := [Vector2(-0.12, -0.36), Vector2(-0.3, -0.3), Vector2(-0.38, 0.4), Vector2(0.38, 0.4), Vector2(0.3, -0.3), Vector2(0.12, -0.36), Vector2(0, -0.26)]
	_poly(body, tint)
	if v == "jiwon":
		# ผ้าห่มเฉียงไหล่
		_poly([Vector2(-0.3, -0.3), Vector2(-0.12, -0.36), Vector2(0.38, 0.12), Vector2(0.38, 0.32)], tint.darkened(0.12), true, 0.8)
		for k in 3:
			_line(Vector2(-0.2 + k * 0.12, -0.24 + k * 0.1), Vector2(-0.24 + k * 0.12, 0.36), tint.darkened(0.2), 0.6)
	else:
		# ผ้ายันต์: ลายยันต์ทองหลายแถว
		_rrect(Vector2(-0.35, 0.28), Vector2(0.7, 0.08), 0.02, GOLD)
		_yant_marks(Vector2(0, 0.0), GOLD, 0.12)
		for x in [-0.22, 0.22]:
			_yant_marks(Vector2(x, 0.16), Color(1.0, 0.88, 0.6), 0.05)
	_outline_only(body)


static func _plate(tint: Color, v: String, rc: Color) -> void:
	# ตัวเกราะอก
	var chest := [Vector2(-0.24, -0.26), Vector2(0.24, -0.26), Vector2(0.26, 0.14), Vector2(0.0, 0.4), Vector2(-0.26, 0.14)]
	_poly(chest, tint)
	if v == "scale":
		for row in 4:
			for i in 4 - (row % 2):
				var p := Vector2(-0.15 + i * 0.1 + (0.05 if row % 2 == 1 else 0.0), -0.12 + row * 0.1)
				_ci.draw_arc(_v(p), 0.05 * _s, 0.0, PI, 8, tint.lightened(0.3), _w(0.7), true)
	else:
		_line(Vector2(0, -0.24), Vector2(0, 0.36), tint.darkened(0.2), 0.8)
		_poly([Vector2(-0.2, -0.22), Vector2(-0.04, -0.22), Vector2(-0.06, 0.1), Vector2(-0.2, 0.06)], tint.lightened(0.3), false)
	_circle(Vector2(0, -0.04), 0.06, rc.lightened(0.15), true, 0.7)
	_outline_only(chest)
	# เกราะไหล่
	for sgn in [-1.0, 1.0]:
		var pad: Array = _ell(sgn * 0.3, -0.2, 0.15, 0.13, 12, PI, TAU) + [Vector2(sgn * 0.3 + 0.15, -0.12), Vector2(sgn * 0.3 - 0.15, -0.12)]
		_poly(pad, tint.lightened(0.12))
		_line(Vector2(sgn * 0.3 - 0.12, -0.16), Vector2(sgn * 0.3 + 0.12, -0.16), GOLD, 0.8)


# ---------- หมวก ----------

static func _headband(tint: Color) -> void:
	# ขอบด้านหลังของวงผ้า
	_stroke(_ell(0, 0.1, 0.34, 0.16, 16, PI, TAU), tint.darkened(0.3), 1.6)
	var band: Array = _ell(0, 0.02, 0.36, 0.2, 18, PI, 0.0) + _ell(0, 0.16, 0.36, 0.2, 18, 0.0, PI)
	_poly(band, tint)
	_shine(Vector2(-0.18, 0.12), 0.08, 0.02, 0.5)
	_yant_marks(Vector2(0, 0.25), Color(1.0, 0.9, 0.55), 0.055)
	# ชายผ้าผูก
	_poly([Vector2(0.3, 0.12), Vector2(0.44, 0.38), Vector2(0.34, 0.4)], tint.darkened(0.08), true, 0.8)
	_poly([Vector2(0.3, 0.12), Vector2(0.48, 0.2), Vector2(0.44, 0.28)], tint.darkened(0.08), true, 0.8)
	_circle(Vector2(0.32, 0.14), 0.05, tint, true, 0.6)


static func _mongkol(tint: Color) -> void:
	var n := 20
	for i in n:
		var a := i * TAU / n
		var p := Vector2(cos(a) * 0.32, 0.05 + sin(a) * 0.18)
		var front := sin(a) > 0
		var r := 0.065 if front else 0.05
		_circle(p, r, (tint if i % 2 == 0 else Color(0.95, 0.42, 0.42)).darkened(0.0 if front else 0.15), true, 0.5)
	# หางมงคลด้านหลัง
	_stroke([Vector2(0, -0.12), Vector2(0.02, -0.28), Vector2(0.1, -0.38)], tint, 1.6)
	_circle(Vector2(0, -0.13), 0.06, Color(0.95, 0.42, 0.42), true, 0.6)
	_sparkle(Vector2(0.3, -0.24), 0.06, Color(1.0, 0.95, 0.6))


static func _helmet(tint: Color, v: String, rc: Color) -> void:
	if v == "plume":
		_poly([Vector2(0, -0.26), Vector2(-0.12, -0.46), Vector2(0.06, -0.4), Vector2(0.2, -0.46), Vector2(0.08, -0.24)], Color(0.94, 0.36, 0.38), true, 0.8)
	var dome: Array = _ell(0, 0.1, 0.32, 0.36, 20, PI, TAU)
	_poly(dome, tint)
	_poly(_ell(-0.1, -0.06, 0.08, 0.14, 10), tint.lightened(0.35), false)
	_rrect(Vector2(-0.4, 0.08), Vector2(0.8, 0.1), 0.04, tint.darkened(0.12))
	_poly([Vector2(-0.04, 0.16), Vector2(0.04, 0.16), Vector2(0.03, 0.34), Vector2(-0.03, 0.34)], tint.darkened(0.12), true, 0.7)
	if v != "plume":
		_poly([Vector2(-0.04, -0.24), Vector2(0, -0.38), Vector2(0.04, -0.24)], GOLD, true, 0.7)
	_circle(Vector2(0, 0.0), 0.05, rc.lightened(0.2), true, 0.6)


static func _crown(tint: Color, v: String, rc: Color) -> void:
	var base_c := GOLD if v != "spiky" else Color(0.5, 0.4, 0.55)
	var pts: Array = []
	match v:
		"tiara":
			pts = [Vector2(-0.36, 0.2), Vector2(-0.34, -0.02), Vector2(-0.18, 0.04), Vector2(0, -0.3), Vector2(0.18, 0.04), Vector2(0.34, -0.02), Vector2(0.36, 0.2)]
		"naga":
			pts = [Vector2(-0.38, 0.22), Vector2(-0.36, -0.1), Vector2(-0.26, -0.22), Vector2(-0.2, 0.0), Vector2(0, -0.36), Vector2(0.2, 0.0), Vector2(0.26, -0.22), Vector2(0.36, -0.1), Vector2(0.38, 0.22)]
		_:
			pts = [Vector2(-0.38, 0.22), Vector2(-0.4, -0.14), Vector2(-0.24, 0.0), Vector2(-0.14, -0.3), Vector2(0, -0.04), Vector2(0.14, -0.3), Vector2(0.24, 0.0), Vector2(0.4, -0.14), Vector2(0.38, 0.22)]
	_poly(pts, base_c)
	_rrect(Vector2(-0.38, 0.14), Vector2(0.76, 0.12), 0.04, tint if v != "spiky" else tint.darkened(0.1))
	var gem_c := tint if v != "spiky" else Color(1.0, 0.35, 0.4)
	if v == "tiara":
		_circle(Vector2(0, -0.08), 0.07, gem_c, true, 0.7)
		_dot(Vector2(-0.02, -0.1), 0.02, WHITE)
	for x in [-0.22, 0.0, 0.22]:
		_circle(Vector2(x, 0.2), 0.035, WHITE if v != "spiky" else Color(1.0, 0.4, 0.45), true, 0.5)
	if v == "naga":
		for p in [Vector2(-0.26, -0.22), Vector2(0.26, -0.22), Vector2(0, -0.36)]:
			_circle(p, 0.04, tint, true, 0.5)
	if v == "spiky":
		_circle(Vector2(0, 0.0), 0.06, Color(1.0, 0.35, 0.4), true, 0.6)
		for p in [Vector2(-0.14, -0.3), Vector2(0.14, -0.3)]:
			_dot(p, 0.03, Color(1.0, 0.45, 0.5))
	else:
		_sparkle(Vector2(0.32, -0.3), 0.07, WHITE)


static func _chada(tint: Color, rc: Color) -> void:
	# ชฎา: ทรงสูงเป็นชั้นๆ ยอดแหลม
	_poly([Vector2(-0.3, 0.38), Vector2(-0.38, 0.12), Vector2(-0.26, 0.14)], tint.darkened(0.08), true, 0.7)
	_poly([Vector2(0.3, 0.38), Vector2(0.38, 0.12), Vector2(0.26, 0.14)], tint.darkened(0.08), true, 0.7)
	_poly([Vector2(-0.28, 0.32), Vector2(-0.26, 0.1), Vector2(0.26, 0.1), Vector2(0.28, 0.32)], tint)
	_poly([Vector2(-0.22, 0.12), Vector2(-0.16, -0.06), Vector2(0.16, -0.06), Vector2(0.22, 0.12)], tint.lightened(0.08))
	_poly([Vector2(-0.15, -0.04), Vector2(-0.1, -0.2), Vector2(0.1, -0.2), Vector2(0.15, -0.04)], tint)
	_poly([Vector2(-0.09, -0.18), Vector2(0, -0.48), Vector2(0.09, -0.18)], tint.lightened(0.08))
	for y in [0.2, 0.02, -0.12]:
		_line(Vector2(-0.18 + y * 0.3, y), Vector2(0.18 - y * 0.3, y), Color(1, 1, 1, 0.7), 0.6)
	_circle(Vector2(0, 0.22), 0.055, rc.lightened(0.1) if rc != tint else Color(1.0, 0.4, 0.5), true, 0.6)
	_circle(Vector2(0, 0.02), 0.035, Color(1.0, 0.4, 0.5), true, 0.5)


# ---------- เครื่องราง ----------

static func _bracelet(tint: Color) -> void:
	var ring := _ell(0, 0.04, 0.3, 0.2, 24)
	ring.append(ring[0])
	_stroke(ring, tint, 1.6)
	var ring2 := _ell(0, 0.08, 0.3, 0.2, 24)
	ring2.append(ring2[0])
	_ci.draw_polyline(_pk(ring2), Color(0.95, 0.85, 0.8), _w(0.6), true)
	_circle(Vector2(0, 0.24), 0.06, tint, true, 0.7)
	_stroke([Vector2(0, 0.28), Vector2(-0.06, 0.42)], tint, 1.0)
	_stroke([Vector2(0, 0.28), Vector2(0.08, 0.4)], tint, 1.0)


static func _takrut(tint: Color) -> void:
	_stroke([Vector2(-0.42, -0.2), Vector2(-0.28, 0.0)], Color(0.92, 0.3, 0.32), 1.0)
	_stroke([Vector2(0.28, 0.0), Vector2(0.42, -0.2)], Color(0.92, 0.3, 0.32), 1.0)
	_rrect(Vector2(-0.3, -0.1), Vector2(0.6, 0.2), 0.1, tint)
	for x in [-0.12, 0.0, 0.12]:
		_line(Vector2(x, -0.08), Vector2(x + 0.04, 0.08), tint.darkened(0.3), 0.6)
	_rrect(Vector2(-0.3, -0.1), Vector2(0.06, 0.2), 0.03, tint.darkened(0.2))
	_rrect(Vector2(0.24, -0.1), Vector2(0.06, 0.2), 0.03, tint.darkened(0.2))
	_shine(Vector2(-0.06, -0.05), 0.12, 0.018, 0.7)


static func _cord(y_top: float, y_bottom: float, col: Color) -> void:
	var pts := _ell(0, y_top, 0.3, y_bottom - y_top, 16, PI, 0.0)
	_stroke(pts, col, 0.9)


static func _pendant(tint: Color, rc: Color) -> void:
	# สร้อยคอเส้นบาง ห้อยพระเครื่องกรอบทอง
	_ci.draw_arc(_v(Vector2(0, -0.42)), 0.4 * _s, PI * 0.12, PI * 0.88, 18, OL, _w(1.6), true)
	_ci.draw_arc(_v(Vector2(0, -0.42)), 0.4 * _s, PI * 0.12, PI * 0.88, 18, Color(0.95, 0.85, 0.55), _w(0.6), true)
	_circle(Vector2(0, -0.04), 0.045, tint, true, 0.6)
	var frame: Array = [Vector2(-0.17, 0.42), Vector2(0.17, 0.42)] + _ell(0, 0.14, 0.17, 0.18, 12, 0.0, -PI).slice(0, 13)
	_poly(frame, tint)
	var inner: Array = [Vector2(-0.11, 0.36), Vector2(0.11, 0.36)] + _ell(0, 0.15, 0.11, 0.12, 10, 0.0, -PI).slice(0, 11)
	_poly(inner, Color(0.92, 0.86, 0.74), true, 0.6)
	var dark := Color(0.62, 0.5, 0.4)
	_dot(Vector2(0, 0.12), 0.035, dark)
	_ci.draw_colored_polygon(_pk([Vector2(-0.04, 0.15), Vector2(0.04, 0.15), Vector2(0.06, 0.27), Vector2(-0.06, 0.27)]), dark)
	_ci.draw_colored_polygon(_pk(_ell(0, 0.29, 0.08, 0.035, 10)), dark)
	_sparkle(Vector2(0.26, 0.06), 0.06, Color(1.0, 0.95, 0.7))


static func _fang_necklace(tint: Color, v: String) -> void:
	_ci.draw_arc(_v(Vector2(0, -0.24)), 0.34 * _s, PI * 0.08, PI * 0.92, 16, OL, _w(2.4), true)
	_ci.draw_arc(_v(Vector2(0, -0.24)), 0.34 * _s, PI * 0.08, PI * 0.92, 16, Color(0.6, 0.4, 0.32), _w(1.0), true)
	var fang_c := Color(1.0, 0.97, 0.9)
	for i in 3:
		var x := -0.14 + i * 0.14
		var big := i == 1
		var h := 0.3 if big else 0.2
		var top_y := 0.06 if big else 0.04
		_poly([Vector2(x - 0.05, top_y), Vector2(x + 0.05, top_y), Vector2(x + 0.02, top_y + h * 0.7), Vector2(x - 0.01, top_y + h)], fang_c, true, 0.7)
		_circle(Vector2(x, top_y), 0.035, tint, true, 0.5)
	if v == "tiger":
		for x in [-0.24, 0.24]:
			_line(Vector2(x, 0.04), Vector2(x * 0.8, 0.12), Color(0.3, 0.2, 0.2), 0.8)
	else:
		_sparkle(Vector2(0.28, 0.24), 0.06, P.PINK)


static func _ring(tint: Color, rc: Color) -> void:
	var outer := _ell(0, 0.12, 0.26, 0.22, 24)
	outer.append(outer[0])
	_stroke(outer, GOLD, 1.8)
	_ci.draw_arc(_v(Vector2(0, 0.12)), 0.22 * _s, PI * 1.1, PI * 1.5, 8, Color(1, 1, 1, 0.8), _w(0.6), true)
	var g := _gem_pts(Vector2(0, -0.14), 0.16, 0.26)
	_poly(g, tint)
	_poly([g[0], g[1], g[2], g[4]], tint.lightened(0.4), false)
	_outline_only(g, 0.8)
	_sparkle(Vector2(0.24, -0.28), 0.06, WHITE)


static func _armband(tint: Color) -> void:
	# ประเจียด: ผ้ายันต์ผูกแขน มีชายผ้าห้อย
	_poly([Vector2(0.06, 0.04), Vector2(0.24, 0.42), Vector2(0.12, 0.42), Vector2(0.0, 0.1)], tint.darkened(0.1), true, 0.8)
	_poly([Vector2(-0.02, 0.04), Vector2(-0.24, 0.4), Vector2(-0.12, 0.42), Vector2(0.04, 0.1)], tint.darkened(0.1), true, 0.8)
	var band := _ell(0, -0.04, 0.34, 0.2, 24)
	band.append(band[0])
	_stroke(band, tint, 3.4)
	_ci.draw_arc(_v(Vector2(0, -0.04)), 0.27 * _s, 0.3, PI - 0.3, 10, GOLD, _w(0.7), true)
	_circle(Vector2(0, 0.12), 0.07, tint, true, 0.8)
	_yant_marks(Vector2(0, 0.12), GOLD, 0.035)


static func _orb(tint: Color) -> void:
	for i in 4:
		_dot(Vector2(0, -0.04), 0.46 - i * 0.06, Color(tint, 0.08 + i * 0.05))
	# ฐานรองทอง
	_poly([Vector2(-0.18, 0.2), Vector2(0.18, 0.2), Vector2(0.24, 0.36), Vector2(-0.24, 0.36)], GOLD, true, 0.8)
	_circle(Vector2(0, -0.04), 0.26, tint)
	_dot(Vector2(0.02, 0.0), 0.18, tint.lightened(0.3))
	_shine(Vector2(-0.1, -0.14), 0.07, 0.05, 0.9)
	_dot(Vector2(0.1, 0.08), 0.03, Color(1, 1, 1, 0.8))
	_sparkle(Vector2(0.3, -0.3), 0.08, WHITE)
