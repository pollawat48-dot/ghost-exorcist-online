extends SceneTree
## ทดสอบแบบ headless: godot --headless --path . --script res://tests/run_tests.gd

const Combat = preload("res://shared/combat/combat.gd")
const Progression = preload("res://shared/combat/progression.gd")
const ItemDB = preload("res://shared/data/items.gd")
const GhostDB = preload("res://shared/data/ghosts.gd")

const STEP := 0.05

var failures := 0


func _initialize() -> void:
	_run_all()


func _run_all() -> void:
	print("== combat ==")
	_test_combat()
	print("== progression ==")
	_test_progression()
	print("== gameplay ==")
	await _test_gameplay()
	if failures == 0:
		print("ผ่านทั้งหมด")
	else:
		printerr("ล้มเหลว %d รายการ" % failures)
	quit(1 if failures > 0 else 0)


func check(cond: bool, name: String) -> void:
	if cond:
		print("  ok   ", name)
	else:
		failures += 1
		printerr("  FAIL ", name)


func _test_combat() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var neutral := 0
	var holy := 0
	for i in 200:
		neutral += Combat.damage(20, 2, "neutral", "spirit", rng)
		holy += Combat.damage(20, 2, "holy", "spirit", rng)
	check(holy > neutral * 2, "พลังศักดิ์สิทธิ์แรงกว่าตีธรรมดากับผีวิญญาณมาก")
	check(Combat.damage(1, 50, "neutral", "none", rng) == 1, "ดาเมจขั้นต่ำคือ 1")


func _test_progression() -> void:
	var state := {"level": 1, "exp": 0}
	check(Progression.add_exp(state, 19) == 0 and state["level"] == 1, "EXP ไม่พอยังไม่อัป")
	check(Progression.add_exp(state, 1) == 1 and state["level"] == 2 and state["exp"] == 0, "EXP ครบแล้วอัปเลเวล")
	check(Progression.add_exp(state, 1000) >= 2, "EXP เยอะอัปหลายเลเวลในครั้งเดียว")

	var full := Progression.new_state()
	Progression.add_exp(full, 50000000)
	check(full["level"] == Progression.MAX_LEVEL, "เลเวลตันที่ %d" % Progression.MAX_LEVEL)
	check(full["stat_points"] == Progression.MAX_LEVEL - 1, "ได้แต้มสเตตัส +1 ทุกเลเวล (รวม %d)" % full["stat_points"])
	check(full["skill_points"] == Progression.MAX_LEVEL / 3, "ได้แต้มสกิล +1 ทุก 3 เลเวล (รวม %d)" % full["skill_points"])
	check(Progression.add_exp(full, 1000) == 0 and full["level"] == Progression.MAX_LEVEL, "เลเวลตันแล้วไม่อัปต่อ")
	var mage := Progression.new_state()
	mage["class"] = "mo_phi"
	var archer := Progression.new_state()
	archer["class"] = "phran"
	archer["base"]["dex"] += 10
	check(Progression.derive(mage)["max_sp"] > Progression.derive(Progression.new_state())["max_sp"], "สายเวท SP มากกว่าศิษย์วัด")
	check(Progression.derive(archer)["range"] > 200.0 and Progression.derive(archer)["atk"] == Progression.derive(Progression.new_state())["atk"] + 20, "สายระยะไกลตีไกล และพลังโจมตีมาจาก DEX")


func _test_gameplay() -> void:
	var main: Node3D = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	# ปิดเฟรมจริง แล้วขับเกมด้วย tick() เองเพื่อให้ผลแน่นอน
	main.set_process(false)
	var player: Node3D = main.player
	check(player != null, "โหลดฉากหลักได้")
	if player == null:
		return

	check(player.hp == player.stats["max_hp"], "ผู้เล่นเริ่มด้วย HP เต็ม")
	check(main.alive_ghosts().size() == 12, "ผีเกิดครบ 12 ตัว")

	var dest: Vector2 = player.pos + Vector2(100, 0)
	player.command_move(dest)
	_run(main, 2.0)
	check(player.pos.distance_to(dest) < 1.0, "คลิกแล้วเดินไปถึงจุดหมาย")

	var map: Node3D = main.map
	var canal_mid := Vector2(map.canal_center(500.0), 500.0)
	check(not map.is_walkable(canal_mid), "เดินลงคลองไม่ได้")
	check(map.is_walkable(Vector2(map.canal_center(1000.0), 1000.0)), "เดินบนสะพานได้")
	var route: PackedVector2Array = map.find_path(map.spawn_point, Vector2(1800, 500))
	var crossed_on_bridge := true
	var prev: Vector2 = map.spawn_point
	for p in route:
		if not map.is_walkable(p):
			crossed_on_bridge = false
		if (prev.x - map.canal_center(prev.y)) * (p.x - map.canal_center(p.y)) < 0.0 and absf(p.y - 1000.0) > 48.0:
			crossed_on_bridge = false
		prev = p
	check(route.size() > 0 and crossed_on_bridge, "หาทางจากหมู่บ้านไปทุ่งนาโดยข้ามทางสะพาน")
	player.command_move(Vector2(1800, 500))
	_run(main, 30.0)
	check(player.pos.distance_to(Vector2(1800, 500)) < 40.0, "เดินจากวัดข้ามสะพานไปถึงทุ่งนา")
	player.pos = map.spawn_point

	var ghost: Node3D = main.alive_ghosts()[0]
	check(main.ghost_at(ghost.pos + Vector2(5, 5)) == ghost, "คลิกโดนผีแล้วเลือกเป็นเป้าหมาย")

	# ล่าผีแบบที่ผู้เล่นทั่วไปทำ: ตีตัวที่ใกล้ที่สุด, ใช้สกิลตอนประชิด, กินยาตอนเลือดน้อย
	var time := 0.0
	var casts := 0
	while time < 900.0 and player.state["level"] < 3:
		if player.attack_target == null:
			player.command_attack(_nearest(main, player.pos))
		elif player.pos.distance_to(player.attack_target.pos) < 50.0 and player.sp >= 20:
			if player.cast_holy_water():
				casts += 1
		if player.hp < player.stats["max_hp"] * 0.35:
			player.use_herb()
		main.tick(STEP)
		time += STEP
	check(player.state["level"] >= 3, "ล่าผีจนถึงเลเวล 3 (เวลาในเกม %d วินาที, ใช้สกิล %d ครั้ง)" % [time, casts])

	_run(main, 9.0)
	check(main.alive_ghosts().size() == 12, "ผีที่ตายแล้วเกิดใหม่ครบ")

	var drop: Node3D = null
	for d in main.drops.get_children():
		if not d.is_queued_for_deletion():
			drop = d
			break
	check(drop != null, "ผีดรอปไอเทม")
	if drop != null:
		var before := _item_count(player)
		player.command_move(drop.pos)
		_run(main, 20.0)
		check(_item_count(player) > before, "เดินทับไอเทมแล้วเก็บเข้ากระเป๋า")

	var herbs: int = player.inventory.get("herb_potion", 0)
	player.hp = 10
	if herbs > 0:
		check(player.use_herb() and player.hp > 10, "ใช้ยาหอมสมุนไพรแล้ว HP เพิ่ม")

	player.take_damage(9999)
	check(player.hp == player.stats["max_hp"] and player.pos == player.spawn_point, "สลบแล้วฟื้นที่วัดพร้อม HP เต็ม")
	check(map.props_root.get_child_count() > 100, "สร้างฉาก 3D ครบ (สิ่งของ %d ชิ้น)" % map.props_root.get_child_count())

	# จอยบนจอ (มือถือ): ดันจอยแล้วเดินต่อเนื่อง และเดินลงคลองไม่ได้
	var start: Vector2 = player.pos
	player.stick = Vector2(0, 1)
	_run(main, 1.0)
	player.stick = Vector2.ZERO
	check(player.pos.y - start.y > player.SPEED * 0.8, "ดันจอยแล้วตัวละครเดินตาม")
	player.pos = Vector2(map.canal_center(600.0) - 120.0, 600.0)
	player.stick = Vector2(1, 0)
	_run(main, 3.0)
	player.stick = Vector2.ZERO
	check(not map.is_water(player.pos), "ดันจอยเข้าหาคลองแล้วไม่ตกน้ำ")

	# ปุ่มโจมตีบนจอ: เลือกผีที่ใกล้ที่สุดเป็นเป้าหมายเอง
	var near_ghost := _nearest(main, player.pos)
	player.pos = near_ghost.pos + Vector2(60, 0)
	main.do_action("attack")
	check(player.attack_target == near_ghost, "กดปุ่มโจมตีแล้วล็อกผีตัวที่ใกล้ที่สุด")

	await _test_character(main)
	main.free()


## สเตตัส สกิล คลาส ของสวมใส่ และบอสประจำถิ่น
func _test_character(main: Node3D) -> void:
	var player: Node3D = main.player
	var hud: CanvasLayer = main.hud
	player.command_move(player.pos)
	player.gain_exp(9000)
	check(player.state["level"] >= 10 and player.can_change_class(), "ถึงเลเวล 10 แล้วเลื่อนขั้นคลาสได้ (Lv %d)" % player.state["level"])
	var atk_before: int = player.stats["atk"]
	check(player.add_stat("str") and player.stats["atk"] == atk_before + 2, "อัป STR แล้วพลังโจมตีเพิ่ม")
	check(not player.change_class("nak_dab"), "ข้ามขั้นคลาสไม่ได้")
	check(player.change_class("nak_rob") and player.class_info()["name"] == "นักรบเวทย์", "เปลี่ยนคลาสเป็นนักรบเวทย์")
	check(not player.can_change_class(), "เลื่อนขั้นต่อไม่ได้จนกว่าจะถึงเลเวล 50")
	check("fan_khatha" in player.available_skills() and not "ying_son" in player.available_skills(), "เรียนได้เฉพาะสกิลของสายตัวเอง")
	check(player.learn_skill("fan_khatha") and player.skill_level("fan_khatha") == 1, "ใช้แต้มสกิลเรียนฟันคาถา")
	hud.refresh()
	check(hud.slot_actions[1] == "skill:fan_khatha", "สกิลที่เรียนแล้วขึ้นแถบสกิลเอง")

	var ghost := _nearest(main, player.pos)
	player.pos = ghost.pos + Vector2(30, 0)
	var hp_before: int = ghost.hp
	player.sp = player.stats["max_sp"]
	check(player.use_skill("fan_khatha", ghost) and (ghost.hp < hp_before or not ghost.alive), "ใช้สกิลฟันคาถาใส่ผี")
	player.sp = player.stats["max_sp"]
	var far_ghost := _nearest(main, Vector2(2700, 850))
	player.pos = far_ghost.pos + Vector2(250, 0)
	player.use_skill("fan_khatha", far_ghost)
	_run(main, 4.0)
	check(far_ghost.hp < far_ghost.data["hp"] or not far_ghost.alive, "ผีอยู่ไกล ตัวละครเดินเข้าไปแล้วร่ายสกิลเอง")

	player.add_item("mitmo")
	var atk_plain: int = player.stats["atk"]
	check(player.equip("mitmo") and player.stats["atk"] == atk_plain + 18 + 2 * 2, "สวมมีดหมอแล้ว ATK เพิ่ม")
	player.add_item("khan_thanu")
	check(not player.equip("khan_thanu"), "สายประชิดสวมธนูไม่ได้")
	check(player.unequip("weapon") and player.inventory.get("mitmo", 0) == 1, "ถอดอาวุธกลับเข้ากระเป๋า")

	player.gain_exp(50000000)
	check(player.state["level"] == 150, "เลเวลตันที่ 150")
	check(player.change_class("nak_dab") and player.change_class("khun_phaen"), "เลื่อนขั้นคลาสครบ 3 ครั้ง")
	check(not player.can_change_class(), "ขั้นสุดท้ายแล้วเลื่อนต่อไม่ได้")

	# บอสประจำถิ่น
	var boss: Node3D = main.spawn_boss(0)
	check(boss != null and boss.is_boss() and boss in main.alive_ghosts(), "บอสประจำถิ่นเกิด")
	check(hud.announce_panel.visible and hud.announce_label.text.contains(boss.data["name"]), "มีประกาศเมื่อบอสเกิด")
	var drops_before: int = main.drops.get_child_count()
	boss.take_damage(999999, player)
	await process_frame
	var equips := 0
	for d in main.drops.get_children():
		if ItemDB.ITEMS[d.item_id]["type"] == "equip":
			equips += 1
	check(main.drops.get_child_count() - drops_before >= 3 and equips >= 1, "ปราบบอสแล้วของตกเยอะ (ของสวมใส่ %d ชิ้น)" % equips)
	check(main.boss == null and main.boss_timer >= main.BOSS_RESPAWN_DELAY.x, "บอสเกิดใหม่อีกครั้งหลังรอนาน")

	# ผีทั่วไปดรอปของสวมใส่ยาก
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var total := 0
	for d in GhostDB.GHOSTS["krasue_noi"]["drops"]:
		if ItemDB.ITEMS[d["item"]]["type"] == "equip":
			total += 1
			check(d["chance"] <= 0.02, "ของสวมใส่จากผีทั่วไปดรอปยาก (%s %.1f%%)" % [d["item"], d["chance"] * 100.0])
			break


func _run(main: Node3D, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		main.tick(STEP)
		t += STEP


func _nearest(main: Node3D, pos: Vector2) -> Node3D:
	var best: Node3D = null
	for g in main.alive_ghosts():
		if best == null or pos.distance_to(g.pos) < pos.distance_to(best.pos):
			best = g
	return best


func _item_count(player: Node3D) -> int:
	var n := 0
	for id in player.inventory:
		n += player.inventory[id]
	return n
