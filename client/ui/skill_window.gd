extends "res://client/ui/game_window.gd"
## หน้าต่างสกิล: ใช้แต้มสกิลเรียน/อัปสกิล และดูสกิลของคลาสถัดไป

const Classes = preload("res://shared/data/classes.gd")
const Skills = preload("res://shared/data/skills.gd")


func _ready() -> void:
	setup("สกิล", 600)


func _build() -> void:
	var st: Dictionary = player.state
	var pts := P.label("แต้มสกิล: %d   (ได้ +1 ทุก 3 เลเวล)" % st["skill_points"], 17, P.PINK_DEEP if st["skill_points"] > 0 else P.TEXT)
	content.add_child(pts)
	for id in player.available_skills():
		_skill_row(id, true)
	# ตัวอย่างสกิลของคลาสถัดไป
	var upcoming: Array[String] = []
	for next_id in Classes.next_classes(st["class"]):
		for id in Skills.SKILLS:
			if Skills.SKILLS[id]["class"] == next_id:
				upcoming.append(id)
	if not upcoming.is_empty():
		section("สกิลเมื่อเลื่อนขั้นคลาส")
		for id in upcoming:
			_skill_row(id, false)


func _skill_row(id: String, unlocked: bool) -> void:
	var sk: Dictionary = Skills.SKILLS[id]
	var lv: int = player.skill_level(id)
	var r := row()
	r.add_child(icon(sk["icon"], 30))
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", -2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(info)
	var color := P.TEXT if unlocked else P.TEXT.lightened(0.45)
	var title := "%s  Lv %d/%d" % [sk["name"], lv, Skills.MAX_LEVEL]
	if not unlocked:
		title = "%s  (คลาส %s)" % [sk["name"], Classes.CLASSES[sk["class"]]["name"]]
	info.add_child(P.label(title, 15, color))
	var detail := "%s · SP %d · คูลดาวน์ %.1f วิ" % [sk["desc"], Skills.sp_cost(id, maxi(lv, 1)), sk["cooldown"]]
	info.add_child(P.label(detail, 12, color.lightened(0.15)))
	if unlocked:
		var plus := P.button("เรียน" if lv == 0 else "+", P.MINT, 15)
		plus.custom_minimum_size = Vector2(56, 0)
		plus.disabled = player.state["skill_points"] <= 0 or lv >= Skills.MAX_LEVEL
		plus.pressed.connect(func(): player.learn_skill(id))
		r.add_child(plus)
