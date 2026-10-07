extends "res://client/ui/game_window.gd"
## หน้าต่างแฟชั่น: ช่องชุด หมวก ปีก สัตว์เลี้ยง (แยกจากของสวมใส่) + ข้อมูลสัตว์เลี้ยง/พัฒนาร่าง + ตีบวกแฟชั่น

const ItemDB = preload("res://shared/data/items.gd")
const ItemIcons = preload("res://client/ui/item_icons.gd")
const Fashion = preload("res://shared/data/fashion.gd")
const Quests = preload("res://shared/data/quests.gd")

var selected := {}  ## แฟชั่นที่เลือกตีบวก {"key", "slot"}
var last_result := ""


func _ready() -> void:
	setup("แฟชั่น & สัตว์เลี้ยง", 760)


func _build() -> void:
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	content.add_child(cols)
	var left := _column(cols, 370)
	var right := _column(cols, 370)
	_build_worn(left)
	_build_pet(left)
	_build_bag(right)
	_build_refine(right)


func _column(parent: Control, width: float) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = width
	v.add_theme_constant_override("separation", 4)
	parent.add_child(v)
	return v


func _build_worn(col: VBoxContainer) -> void:
	col.add_child(P.label("ที่ใส่อยู่ (ค่าพลังรวมกับตัวละคร)", 16, P.PINK_DEEP))
	var worn: Dictionary = player.fashion()
	for slot in Fashion.SLOTS:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		col.add_child(r)
		var sl := P.label(Fashion.SLOT_NAMES[slot] + ":", 14)
		sl.custom_minimum_size.x = 76
		r.add_child(sl)
		if worn.has(slot):
			var key: String = worn[slot]
			r.add_child(ItemIcons.make(key, 34))
			var info := VBoxContainer.new()
			info.add_theme_constant_override("separation", -3)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r.add_child(info)
			info.add_child(P.label(ItemDB.display_name(key), 14, ItemDB.color_of(key).darkened(0.3)))
			info.add_child(P.label(_bonus_line(key), 11, P.TEXT.lightened(0.2)))
			var off := P.button("ถอด", P.LEMON, 13)
			off.pressed.connect(func(): player.remove_fashion(slot))
			r.add_child(off)
		else:
			r.add_child(ItemIcons.make_empty("", 34))
			r.add_child(P.label("- (สุ่มได้จากกาชาปอง ร้าน CC)", 12, P.TEXT.lightened(0.4)))


func _bonus_line(key: String) -> String:
	var sp := Fashion.pet_of(key)
	if sp != "":
		var d := Fashion.pet_data(player.state, sp)
		var parts: Array[String] = []
		var b := Fashion.pet_bonus(sp, d["lv"], d["stage"])
		for k in b:
			parts.append("%s +%d" % [ItemDB.STAT_NAMES[k], b[k]])
		return "Lv.%d · %s" % [d["lv"], " · ".join(parts) if not parts.is_empty() else "สเตตัสเพิ่มตามเลเวล"]
	return ItemDB.bonus_text(key)


func _build_pet(col: VBoxContainer) -> void:
	col.add_child(P.label("สัตว์เลี้ยง", 16, P.PINK_DEEP))
	var sp: String = player.pet_species()
	if sp == "":
		col.add_child(P.label("ยังไม่มีสัตว์เลี้ยงออกมา ใส่สัตว์เลี้ยงจากกระเป๋าแล้วจะเดินตาม\nช่วยตีผีและใช้สกิลเอง เลเวลขึ้นพร้อมกับคุณ", 12, P.TEXT.lightened(0.2)))
		return
	var d := Fashion.pet_data(player.state, sp)
	var info: Dictionary = Fashion.PETS[sp]
	var sk: Dictionary = info["skill"]
	col.add_child(P.label("%s  Lv.%d / %d  (ร่าง %d/3)" % [Fashion.pet_name(sp, d["stage"]), d["lv"], Fashion.PET_MAX_LEVEL, d["stage"] + 1], 15))
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(360, 14)
	var ratio := float(d["exp"]) / Fashion.pet_exp_to_next(d["lv"]) if d["lv"] < Fashion.PET_MAX_LEVEL else 1.0
	bar.draw.connect(func(): P.draw_round_bar(bar, Rect2(Vector2.ZERO, bar.size), ratio, P.EXP))
	col.add_child(bar)
	var kind_text := {"bite": "กัดเป้าหมายแรง x%.1f", "combo": "ข่วนรัว 3 ครั้ง", "heal": "ฮีลเจ้าของ %d%% ของ HP", "holy": "เวทศักดิ์สิทธิ์ใส่ผีเป็นวง", "aoe": "กระแทกผีรอบตัว"}
	var desc: String = kind_text[sk["kind"]]
	if sk["kind"] == "bite":
		desc = desc % sk["power"]
	elif sk["kind"] == "heal":
		desc = desc % int(sk["power"] * 100 * Fashion.STAGE_MULT[d["stage"]])
	col.add_child(P.label("พลังโจมตี %d · สกิลออโต้: %s (%s ทุก %d วิ)" % [Fashion.pet_atk(sp, d["lv"], d["stage"]), sk["name"], desc, int(sk["cooldown"])], 12))
	if d["stage"] >= 2:
		col.add_child(P.label("พัฒนาร่างครบ 3 ร่างแล้ว ✨", 13, P.PINK_DEEP))
		return
	var need: int = Fashion.EVOLVE_LEVEL[d["stage"]]
	var fee: int = Fashion.EVOLVE_FEE[d["stage"]]
	col.add_child(P.label("ร่างต่อไป: %s · ต้อง Lv.%d · ค่าพัฒนา %d เหรียญ" % [Fashion.pet_name(sp, d["stage"] + 1), need, fee], 12, Color(0.3, 0.55, 0.4) if d["lv"] >= need else P.TEXT))
	var trial := "ผ่านบททดสอบแล้ว" if player.pet_trial_passed() else "ต้องผ่านบททดสอบ \"%s\"" % Quests.QUESTS[player.pet_trial_quest()]["name"]
	col.add_child(P.label("%s · พัฒนาร่างได้ที่ครูฝึกสัตว์ หมู่บ้านริมคลอง" % trial, 12, P.PINK_DEEP))


func _build_bag(col: VBoxContainer) -> void:
	col.add_child(P.label("แฟชั่นในกระเป๋า", 16, P.PINK_DEEP))
	var ids: Array = []
	for key in player.inventory:
		if Fashion.is_fashion(key):
			ids.append(key)
	if ids.is_empty():
		col.add_child(P.label("ไม่มี (เปิดกาชาปองที่ร้าน CC)", 12, P.TEXT.lightened(0.3)))
		return
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(370, mini(170, 42 * ids.size()))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for key in ids:
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 6)
		list.add_child(r)
		r.add_child(ItemIcons.make(key, 32))
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", -3)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(info)
		info.add_child(P.label("%s x%d" % [ItemDB.display_name(key), player.inventory[key]], 13, ItemDB.color_of(key).darkened(0.3)))
		info.add_child(P.label("%s · %s" % [Fashion.SLOT_NAMES[Fashion.slot_of(key)], _bonus_line(key)], 11, P.TEXT.lightened(0.2)))
		var b := P.button("ใส่", P.MINT, 13)
		b.pressed.connect(func(): player.wear_fashion(key))
		r.add_child(b)


func _still_owned(entry: Dictionary) -> bool:
	for e in player.fashion_refinable():
		if e["key"] == entry["key"] and e["slot"] == entry["slot"]:
			return true
	return false


func _build_refine(col: VBoxContainer) -> void:
	col.add_child(P.label("ตีบวกแฟชั่น (ใช้หินตี+ แฟชั่น มี %d ก้อน)" % player.inventory.get(Fashion.STONE_ID, 0), 16, P.PINK_DEEP))
	var items: Array = player.fashion_refinable()
	if items.is_empty():
		col.add_child(P.label("ไม่มีแฟชั่นให้ตีบวก (สัตว์เลี้ยงเก่งขึ้นด้วยเลเวลแทน)", 12, P.TEXT.lightened(0.3)))
		return
	if selected.is_empty() or not _still_owned(selected):
		selected = items[0]
	var pick := HFlowContainer.new()
	pick.add_theme_constant_override("h_separation", 4)
	pick.add_theme_constant_override("v_separation", 4)
	col.add_child(pick)
	for e in items:
		var key: String = e["key"]
		var b := P.button(ItemDB.display_name(key) + (" (ใส่อยู่)" if e["slot"] != "" else ""), P.LEMON if e == selected else Color(1, 1, 1, 0.9), 11)
		b.pressed.connect(func():
			selected = e
			last_result = ""
			refresh())
		pick.add_child(b)
	var key: String = selected["key"]
	var lv := ItemDB.refine_of(key)
	col.add_child(P.label("ตอนนี้: %s" % ItemDB.bonus_text(key), 12))
	if lv >= Fashion.REFINE_MAX:
		col.add_child(P.label("ตีถึง +%d สูงสุดแล้ว" % Fashion.REFINE_MAX, 14, P.PINK_DEEP))
	else:
		var next := ItemDB.refined_key(ItemDB.base_id(key), lv + 1)
		col.add_child(P.label("ถ้าสำเร็จ (+%d): %s" % [lv + 1, ItemDB.bonus_text(next)], 12, Color(0.3, 0.6, 0.35)))
		var risk := "ถ้าพลาดลดลง 1 ขั้น" if lv >= Fashion.REFINE_RISKY_FROM else "ถ้าพลาดของอยู่ขั้นเดิม"
		col.add_child(P.label("โอกาสสำเร็จ %d%% · ใช้หิน 1 ก้อน · %s" % [int(round(Fashion.REFINE_CHANCE[lv] * 100)), risk], 12))
		var go := P.button("ตี +%d" % (lv + 1), P.PINK, 15)
		go.disabled = player.inventory.get(Fashion.STONE_ID, 0) <= 0
		go.pressed.connect(_do_refine)
		col.add_child(go)
	if last_result != "":
		col.add_child(P.label(last_result, 14, P.PINK_DEEP))


func _do_refine() -> void:
	var res: Dictionary = player.refine_fashion(selected["key"], selected["slot"])
	match res["result"]:
		"success":
			last_result = "สำเร็จ! ได้ %s" % ItemDB.display_name(res["key"])
		"down":
			last_result = "ล้มเหลว... ลดเหลือ +%d" % res["level"]
		"fail":
			last_result = "ล้มเหลว ยังอยู่ +%d" % res["level"]
		_:
			last_result = ""
	if res["result"] != "error":
		selected = {"key": res["key"], "slot": selected["slot"]}
	refresh()
