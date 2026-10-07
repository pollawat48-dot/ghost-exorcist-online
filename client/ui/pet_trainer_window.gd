extends "res://client/ui/quest_window.gd"
## ครูฝึกสัตว์ (หมู่บ้านริมคลอง): ดูสัตว์เลี้ยงที่ออกมา รับ/ส่งบททดสอบ แล้วพัฒนาร่างได้ที่นี่
## พัฒนาร่างต้อง: สัตว์เลี้ยงถึงเลเวล + ผ่านบททดสอบของร่างนั้น + จ่ายค่าพัฒนา

const Fashion = preload("res://shared/data/fashion.gd")


func _ready() -> void:
	setup("ครูฝึกสัตว์", 600)


func _greeting() -> String:
	return "\"สัตว์เลี้ยงจะเปลี่ยนร่างได้ ต้องเติบโตพร้อมเจ้าของและผ่านศึกจริงด้วยกัน\""


func _build() -> void:
	_build_pet()
	section("บททดสอบพัฒนาร่าง")
	super._build()


func _build_pet() -> void:
	section("สัตว์เลี้ยงของคุณ")
	var sp: String = player.pet_species()
	if sp == "":
		content.add_child(P.label("ยังไม่มีสัตว์เลี้ยงออกมา ใส่สัตว์เลี้ยงในช่องแฟชั่นก่อนแล้วพามาหาครู", 14, P.TEXT.lightened(0.2)))
		return
	var d := Fashion.pet_data(player.state, sp)
	var r := row()
	r.add_child(ItemIcons.make(Fashion.PETS[sp]["item"], 40))
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(info)
	info.add_child(P.label("%s  Lv.%d  (ร่าง %d/3)" % [Fashion.pet_name(sp, d["stage"]), d["lv"], d["stage"] + 1], 16))
	if d["stage"] >= 2:
		info.add_child(P.label("พัฒนาครบ 3 ร่างแล้ว ✨ ครูไม่มีอะไรจะสอนอีก", 13, P.PINK_DEEP))
		return
	var stage: int = d["stage"]
	info.add_child(P.label("ร่างต่อไป: %s" % Fashion.pet_name(sp, stage + 1), 13, P.PINK_DEEP))
	var lines: Array = [
		[d["lv"] >= Fashion.EVOLVE_LEVEL[stage], "สัตว์เลี้ยง Lv.%d (ตอนนี้ %d)" % [Fashion.EVOLVE_LEVEL[stage], d["lv"]]],
		[player.pet_trial_passed(), "ผ่านบททดสอบ \"%s\"" % Quests.QUESTS[player.pet_trial_quest()]["name"]],
		[player.state["coins"] >= Fashion.EVOLVE_FEE[stage], "ค่าพัฒนา %d เหรียญ" % Fashion.EVOLVE_FEE[stage]],
	]
	for l in lines:
		content.add_child(P.label(("[ผ่าน] " if l[0] else "[ยังไม่ผ่าน] ") + l[1], 13, Color(0.3, 0.55, 0.4) if l[0] else P.TEXT))
	var evo := P.button("พัฒนาร่างเป็น %s" % Fashion.pet_name(sp, stage + 1), P.MINT, 15)
	evo.disabled = not player.can_evolve_pet()
	evo.pressed.connect(func(): player.evolve_pet())
	content.add_child(evo)
