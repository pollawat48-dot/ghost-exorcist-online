extends SceneTree
## ทดสอบแบบ headless: godot --headless --path . --script res://tests/run_tests.gd

const Combat = preload("res://shared/combat/combat.gd")
const Progression = preload("res://shared/combat/progression.gd")
const ItemDB = preload("res://shared/data/items.gd")
const GhostDB = preload("res://shared/data/ghosts.gd")
const Drop = preload("res://client/drop.gd")
const Quests = preload("res://shared/data/quests.gd")
const World = preload("res://shared/data/world.gd")
const Crafting = preload("res://shared/data/crafting.gd")

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
	print("== ร้านค้า เควส ออโต้ แผนที่ ==")
	await _test_world()
	print("== แผนที่ถึง Lv150 ถ้ำ หลอมแร่ ตีบวก วาร์ป ==")
	_test_data()
	await _test_expansion()
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
	check(player.state["level"] >= 10 and player.class_level_reached() and not player.can_change_class(), "ถึงเลเวล 10 แล้ว แต่ยังเปลี่ยนอาชีพไม่ได้จนกว่าผ่านบททดสอบ (Lv %d)" % player.state["level"])
	check(not player.change_class("nak_rob"), "ยังไม่ผ่านบททดสอบ เปลี่ยนอาชีพไม่ได้")
	check(player.accept_quest("q_trial_1"), "รับบททดสอบจากครูใหญ่สำนัก")
	for i in 15:
		player.reward_kill("phi_takiang", 0, 0)
	check(player.complete_quest("q_trial_1"), "ปราบผีตะเกียงครบ ส่งบททดสอบได้")
	player.state["coins"] = 100
	check(not player.can_change_class(), "เงินไม่พอค่าครู เปลี่ยนอาชีพไม่ได้")
	player.state["coins"] = 1000
	var atk_before: int = player.stats["atk"]
	check(player.add_stat("str") and player.stats["atk"] == atk_before + 2, "อัป STR แล้วพลังโจมตีเพิ่ม")
	check(not player.change_class("nak_dab"), "ข้ามขั้นคลาสไม่ได้")
	check(player.change_class("nak_rob") and player.class_info()["name"] == "นักรบเวทย์" and player.coins() == 700, "จ่ายค่าครู 300 แล้วเปลี่ยนเป็นนักรบเวทย์")
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
	check(not player.change_class("nak_dab"), "ขั้น 2 ต้องปราบนางพญากระสือก่อน")
	player.state["coins"] = 100000
	for pair in [["q_trial_2", "krasue_queen"], ["q_trial_3", "pret_king"]]:
		player.accept_quest(pair[0])
		player.reward_kill(pair[1], 0, 0)
		player.complete_quest(pair[0])
		if pair[0] == "q_trial_2":
			check(player.change_class("nak_dab"), "ปราบนางพญากระสือ + จ่ายค่าครู แล้วเลื่อนขั้น 2")
	check(player.change_class("khun_phaen") and player.coins() == 100000 - 5000 - 30000, "ปราบพญาเปรต + จ่ายค่าครู แล้วเลื่อนขั้น 3 ครบ")
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


## ร้านค้า ยา เควส NPC ออโต้ และการย้ายแผนที่ (เริ่มตัวละครใหม่)
func _test_world() -> void:
	var main: Node3D = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	var player: Node3D = main.player
	var hud: CanvasLayer = main.hud

	# ---- ร้านค้า ----
	check(main.npcs.get_child_count() == 6, "หมู่บ้านมี NPC ร้านยา หลวงตา ครูใหญ่ ร่างทรงวาร์ป ร้านอาวุธ และช่างหลอมแร่")
	for n in main.npcs.get_children():
		if n.role() == "class":
			player.pos = n.pos + Vector2(0, 40)
			main.talk_to(n)
			check(hud.windows["class"].visible and n.marker_state == "class", "คุยกับครูใหญ่สำนักแล้วเปิดหน้าต่างเปลี่ยนอาชีพ")
			hud.close_windows()
			player.pos = main.map.spawn_point
	var coins: int = player.coins()
	var sp_before: int = player.inventory.get("nam_mon", 0)
	check(player.buy("nam_mon", 2) and player.coins() == coins - 60 and player.inventory["nam_mon"] == sp_before + 2, "ซื้อน้ำมนต์ 2 ขวด เหรียญลดลง")
	check(not player.buy("nam_mon_yai", 999), "เหรียญไม่พอซื้อไม่ได้")
	player.add_item("lantern_oil", 3)
	player.add_item("spirit_shard", 4)
	coins = player.coins()
	check(player.sell("lantern_oil", 1) and player.coins() == coins + ItemDB.sell_price("lantern_oil"), "ขายของจากผีได้เหรียญ")
	coins = player.coins()
	hud.windows["shop"].player = player
	hud.windows["shop"].sell_all_loot()
	check(not player.inventory.has("lantern_oil") and not player.inventory.has("spirit_shard") and player.coins() == coins + 2 * 14 + 4 * 6, "ขายของจากผีทั้งหมดในครั้งเดียว")
	check(ItemDB.sell_price("mitmo") > ItemDB.sell_price("saisin"), "ของสวมใส่ยิ่งหายากยิ่งขายได้แพง")

	# ---- ยาเลือด / ยามานา ----
	player.hp = 5
	var hp_potions: int = player.potion_count("hp")
	check(player.use_potion("hp") and player.hp > 5 and player.potion_count("hp") == hp_potions - 1, "กดยาเลือดแล้ว HP เพิ่ม")
	player.potion_cd = 0.0
	player.sp = 0
	check(player.use_potion("sp") and player.sp > 0, "กดน้ำมนต์แล้ว SP เพิ่ม")

	# ---- คุยกับ NPC และเควส ----
	var luang_ta: Node3D = null
	for n in main.npcs.get_children():
		if n.npc_id() == "luang_ta":
			luang_ta = n
	check(luang_ta != null and luang_ta.marker_state == "available", "หลวงตามีเครื่องหมาย ! เควสใหม่")
	player.pos = luang_ta.pos + Vector2(300, 80)
	main.talk_to(luang_ta)
	_run(main, 5.0)
	check(hud.windows["quest"].visible, "เดินไปคุยกับหลวงตาแล้วหน้าต่างเควสเปิด")
	hud.close_windows()
	check(player.accept_quest("q_krasue") and player.quest_status("q_krasue") == "active", "รับเควสปราบผีกระสือ")
	check(player.quest_status("q_takiang") == "locked", "เควสต่อเนื่องยังรับไม่ได้จนกว่าทำเควสก่อนหน้า")
	var kills := 0
	var time := 0.0
	player.pos = Vector2(1800, 500)
	while time < 600.0 and player.quest_status("q_krasue") != "ready":
		if player.attack_target == null:
			var best: Node3D = null
			for g in main.alive_ghosts():
				if g.ghost_id == "krasue_noi" and (best == null or player.pos.distance_to(g.pos) < player.pos.distance_to(best.pos)):
					best = g
			player.command_attack(best)
		if player.hp < player.stats["max_hp"] * 0.4:
			player.use_potion("hp")
		main.tick(STEP)
		time += STEP
	check(player.quest_status("q_krasue") == "ready", "ปราบกระสือครบ 8 ตัว เควสพร้อมส่ง (%d วินาที)" % time)
	check(hud.quest_panel.visible and hud.quest_label.text.contains("8/8"), "รายการเควสบนจอแสดงความคืบหน้า")
	luang_ta._process(0.0)
	main._refresh_npc_markers()
	check(luang_ta.marker_state == "ready", "หลวงตาขึ้นเครื่องหมาย ? ให้กลับไปส่ง")
	coins = player.coins()
	var exp_before: int = player.state["exp"] + Progression.exp_to_next(player.state["level"]) * 0
	var lv_before: int = player.state["level"]
	check(player.complete_quest("q_krasue") and player.coins() >= coins + 120 and (player.state["level"] > lv_before or player.state["exp"] > exp_before), "ส่งเควสได้รางวัลเหรียญและ EXP")
	check(player.quest_status("q_krasue") == "done" and player.quest_status("q_thread") == "available", "ส่งแล้วปลดล็อกเควสถัดไป")
	player.accept_quest("q_thread")
	player.inventory.erase("red_thread")
	player.add_item("red_thread", 6)
	check(player.quest_status("q_thread") == "ready" and player.complete_quest("q_thread") and player.inventory.get("red_thread", 0) == 1, "เควสหาของ: ส่งแล้วหักของออกจากกระเป๋า")

	# ---- ออโต้ ----
	player.pos = Vector2(1800, 500)
	player.command_move(player.pos)
	var exp_start: int = player.state["exp"]
	var level_start: int = player.state["level"]
	var herbs_start: int = player.potion_count("hp")
	main.toggle_auto()
	check(main.auto.enabled and hud.auto_button.lit, "กดปุ่มออโต้แล้วเปิดใช้งาน")
	player.hp = int(player.stats["max_hp"] * 0.2)
	_run(main, 0.1)
	check(player.potion_count("hp") == herbs_start - 1 and player.hp > player.stats["max_hp"] * 0.2, "ออโต้กินยาเลือดเองเมื่อ HP ต่ำ")
	var kills_before: int = main.respawn_queue.size()
	_run(main, 90.0)
	check(player.state["level"] > level_start or player.state["exp"] > exp_start, "ออโต้หาผีตีเองจนได้ EXP")
	for d in main.drops.get_children():
		d.free()
	var drop: Node3D = Drop.new()
	drop.item_id = "red_thread"
	drop.pos = player.pos + Vector2(120, 40)
	for offset in [Vector2(120, 40), Vector2(-120, 40), Vector2(0, 130), Vector2(0, -130), Vector2(130, -60)]:
		if main.map.is_walkable(player.pos + offset):
			drop.pos = player.pos + offset
			break
	main.drops.add_child(drop)
	var thread_before: int = player.inventory.get("red_thread", 0)
	for g in main.alive_ghosts():
		g.free()
	main.respawn_queue.clear()
	_run(main, 6.0)
	check(player.inventory.get("red_thread", 0) > thread_before, "ออโต้เดินไปเก็บของที่ตกเอง")
	main.toggle_auto()
	check(not main.auto.enabled, "ปิดออโต้ได้")

	# ---- แผนที่ถัดไป: ป่าช้าวัดร้าง ----
	var portal: Node3D = main.portals.get_child(0)
	player.pos = portal.pos + Vector2(-200, 0)
	player.command_move(portal.pos)
	_run(main, 4.0)
	await process_frame
	check(main.map.map_id == "pa_cha" and main.map.map_name == "ป่าช้าวัดร้าง", "เดินเข้าประตูวาร์ปแล้วไปป่าช้าวัดร้าง")
	check(player.pos.distance_to(Vector2(260, 1000)) < 5.0 or player.pos.distance_to(main.map.spawn_point) < 60.0, "มาโผล่ที่ทางเข้าป่าช้า")
	var min_level := 999
	for g in main.alive_ghosts():
		min_level = mini(min_level, g.data["level"])
	check(main.alive_ghosts().size() == 21 and min_level >= 12, "ป่าช้ามีผีเลเวลสูงขึ้น (ต่ำสุด Lv %d)" % min_level)
	check(main.npcs.get_child_count() == 3 and main.map.props_root.get_child_count() > 150, "ป่าช้ามี NPC และฉากครบ (สิ่งของ %d ชิ้น)" % main.map.props_root.get_child_count())
	var route: PackedVector2Array = main.map.find_path(main.map.spawn_point, Vector2(2550, 1000))
	check(route.size() > 0 and route[route.size() - 1].distance_to(Vector2(2550, 1000)) < 40.0, "เดินจากทางเข้าไปสุดป่าช้าได้")
	var boss: Node3D = main.spawn_boss(0)
	check(boss.data["name"] == "พญาเปรต" and hud.announce_label.text.contains("พญาเปรต"), "บอสป่าช้าคือพญาเปรต มีประกาศ")
	_run(main, 2.0)
	player.pos = main.portals.get_child(0).pos + Vector2(60, 0)
	player.command_move(main.portals.get_child(0).pos)
	_run(main, 3.0)
	await process_frame
	check(main.map.map_id == "khlong_village" and player.pos.distance_to(Vector2(3040, 1100)) < 60.0, "วาร์ปกลับหมู่บ้านได้")
	main.free()


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


## ข้อมูลทั้งหมดอ้างอิงกันถูกต้อง (ไอเทมที่ดรอป เป้าหมายเควส ของในร้าน)
func _test_data() -> void:
	var missing: Array[String] = []
	var max_level := 0
	for gid in GhostDB.GHOSTS:
		max_level = maxi(max_level, GhostDB.GHOSTS[gid]["level"])
		for d in GhostDB.GHOSTS[gid]["drops"]:
			if not ItemDB.ITEMS.has(d["item"]):
				missing.append(d["item"])
	check(missing.is_empty(), "ของที่ผีดรอปมีอยู่ในฐานข้อมูลครบ %s" % str(missing))
	check(max_level == 150, "มีผีถึงเลเวล 150")
	for id in World.MAPS:
		var boss_id: String = World.MAPS[id]["boss"]
		check(GhostDB.GHOSTS.has(boss_id) and GhostDB.GHOSTS[boss_id].get("boss", false), "%s มีบอส %s Lv %d" % [World.MAPS[id]["name"], GhostDB.GHOSTS[boss_id]["name"], GhostDB.GHOSTS[boss_id]["level"]])
	var bad_quests: Array[String] = []
	for qid in Quests.QUESTS:
		var q: Dictionary = Quests.QUESTS[qid]
		var target_ok: bool = GhostDB.GHOSTS.has(q["target"]) if q["type"] == "kill" else ItemDB.ITEMS.has(q["target"])
		var r := Quests.reward(qid, "melee")
		for item in r["items"]:
			target_ok = target_ok and ItemDB.ITEMS.has(item)
		if not target_ok or r["exp"] <= 0:
			bad_quests.append(qid)
	check(bad_quests.is_empty(), "เควสทุกอันมีเป้าหมายและรางวัลถูกต้อง %s" % str(bad_quests))
	# รางวัลเยอะขึ้นตามความเก่งของผี
	var low := Quests.reward("q_tai_hong", "melee")
	var high := Quests.reward("q_asura", "melee")
	check(high["exp"] > low["exp"] * 5, "ผีเก่งกว่าให้ EXP เควสมากกว่า (%d vs %d)" % [high["exp"], low["exp"]])
	check(Quests.reward("q_thahan")["coins"] > Quests.reward("q_tai_hong")["coins"], "เควสรางวัลเงินให้เหรียญตามความเก่งของผี")
	check(Quests.reward("q_tai_hong")["items"].has("ya_hom_thong") and Quests.reward("q_asura")["items"].has("ya_thip"), "เควสรางวัลยาให้ยาขวดใหญ่ขึ้นในแผนที่สูง")
	var gear_melee: Dictionary = Quests.reward("q_khun_suek", "melee")["items"]
	var gear_magic: Dictionary = Quests.reward("q_khun_suek", "magic")["items"]
	check(gear_melee.has("dab_krung") and gear_magic.has("khoi_boran"), "เควสบอสให้อาวุธล้ำค่าตามสายผู้เล่น")
	check(Quests.reward("q_hua_khat", "ranged")["items"].size() == 1, "เควสรางวัลของสวมใส่ให้ของ 1 ชิ้น")
	var stock_ok := true
	for map_script in [load("res://maps/thailand/khlong_village.gd"), load("res://maps/thailand/krung_kao.gd"), load("res://maps/thailand/nong_naga.gd")]:
		var m: Node3D = map_script.new()
		for n in m.npcs:
			for item in n.get("stock", []):
				stock_ok = stock_ok and ItemDB.ITEMS.has(item) and ItemDB.ITEMS[item].get("buy", 0) > 0
		m.free()
	check(stock_ok, "ของในร้านทุกชิ้นมีราคาขาย")
	# แร่: สังกะสีออกบ่อยสุด เพชรยากสุด ราคาเรียงกลับกัน
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var counts := {}
	for i in 20000:
		var ore := World.roll_ore(1, rng)
		counts[ore] = counts.get(ore, 0) + 1
	check(counts["ore_zinc"] > counts["ore_iron"] and counts["ore_iron"] > counts["ore_gold"] and counts["ore_gold"] > counts["ore_diamond"] and counts["ore_diamond"] > 0,
		"สุ่มแร่: สังกะสี %d > เหล็ก %d > ทอง %d > เพชร %d" % [counts["ore_zinc"], counts["ore_iron"], counts["ore_gold"], counts["ore_diamond"]])
	check(ItemDB.sell_price("ore_zinc") < ItemDB.sell_price("ore_iron") and ItemDB.sell_price("ore_iron") < ItemDB.sell_price("ore_gold") and ItemDB.sell_price("ore_gold") < ItemDB.sell_price("ore_diamond"), "ราคาแร่: สังกะสีถูกสุด เพชรแพงสุด")
	var w5 := World.ore_weights(5)
	check(w5[3] > World.ore_weights(1)[3] and w5[0] > w5[1] and w5[1] > w5[2] and w5[2] > w5[3], "ถ้ำลึกได้เพชรบ่อยขึ้น แต่ยังเรียงสังกะสี > เหล็ก > ทอง > เพชร")
	# ตีบวก: ค่าพลังเพิ่มขึ้นเรื่อยๆ และยากขึ้นเรื่อยๆ
	var prev := 0
	var rising := true
	for lv in range(0, 11):
		var atk: int = ItemDB.bonus_of(ItemDB.refined_key("mitmo", lv))["atk"]
		rising = rising and atk > prev
		prev = atk
	check(rising, "ตีบวก +0 ถึง +10 ค่า ATK เพิ่มทุกขั้น (มีดหมอ +10 ATK %d)" % prev)
	var harder := true
	for lv in range(1, 10):
		harder = harder and ItemDB.REFINE_CHANCE[lv] < ItemDB.REFINE_CHANCE[lv - 1] and ItemDB.refine_fee(lv) > ItemDB.refine_fee(lv - 1)
	check(harder, "ตีบวกขั้นสูงขึ้น โอกาสสำเร็จลดลงและค่าตีแพงขึ้น")
	check(ItemDB.display_name("mitmo+7") == "+7 มีดหมอลงอาคม" and ItemDB.base_id("mitmo+7") == "mitmo" and ItemDB.sell_price("mitmo+7") > ItemDB.sell_price("mitmo"), "ของตีบวกมีชื่อ +N และขายได้แพงขึ้น")


func _test_expansion() -> void:
	var main: Node3D = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	var player: Node3D = main.player
	var hud: CanvasLayer = main.hud
	check(player.state["caves"].size() == World.CAVE_COUNT, "เริ่มโลกใหม่สุ่มแผนที่ที่มีถ้ำ %s" % str(player.state["caves"]))

	# ---- แผนที่ใหม่ทุกแผนที่โหลดได้ มีผีตามช่วงเลเวล มีทางเดินถึงประตูถัดไป ----
	player.state["caves"] = ["krung_kao", "doi_phi", "yom_lok"]
	var expected := {"krung_kao": [32, 50], "doi_phi": [62, 85], "nong_naga": [96, 122], "yom_lok": [132, 148]}
	for id in expected:
		main.load_map(id)
		await process_frame
		var lo := 999
		var hi := 0
		for g in main.alive_ghosts():
			lo = mini(lo, g.data["level"])
			hi = maxi(hi, g.data["level"])
		var range_ok: bool = lo == expected[id][0] and hi == expected[id][1]
		check(range_ok and main.alive_ghosts().size() >= 15, "%s: ผี %d ตัว Lv %d–%d" % [main.map.map_name, main.alive_ghosts().size(), lo, hi])
		var far := Vector2(2600, 1000)
		var route: PackedVector2Array = main.map.find_path(main.map.spawn_point, far)
		check(route.size() > 0 and route[route.size() - 1].distance_to(far) < 50.0, "%s: เดินจากแคมป์ไปสุดทางตะวันออกได้" % main.map.map_name)
		var roles := []
		for n in main.npcs.get_children():
			roles.append(n.role())
		check("quest" in roles and "shop" in roles and "warp" in roles, "%s: แคมป์มี NPC เควส ร้านยา และวาร์ป" % main.map.map_name)
		var has_cave := false
		for w in main.portals.get_children():
			has_cave = has_cave or w.data.get("style", "") == "cave"
		check(has_cave == (id in player.state["caves"]), "%s: %s" % [main.map.map_name, "มีปากถ้ำ (ถูกสุ่ม)" if has_cave else "ไม่มีถ้ำ"])
		var boss: Node3D = main.spawn_boss(0)
		check(boss != null and boss.is_boss() and boss.data["level"] >= 70, "%s: บอส %s Lv %d" % [main.map.map_name, boss.data["name"], boss.data["level"]])
		_run(main, 1.0)
	check(main.map.portals.size() >= 1 and main.map.portals[0]["to"] == "nong_naga", "ยมโลกเป็นแผนที่สุดท้าย มีประตูกลับบึงนาคา")

	# ---- วาร์ป ----
	player.state["coins"] = 100000
	var coins: int = player.coins()
	check(main.warp_to("krung_kao") and main.map.map_id == "krung_kao" and player.coins() == coins - World.MAPS["krung_kao"]["fee"], "ร่างทรงวาร์ปไปกรุงเก่าได้ (จ่ายค่าวาร์ป)")
	player.state["visited"].erase("doi_phi")
	check(not main.warp_to("doi_phi") and main.map.map_id == "krung_kao", "แผนที่ที่ยังไม่เคยไปวาร์ปไม่ได้")
	for n in main.npcs.get_children():
		if n.role() == "warp":
			player.pos = n.pos + Vector2(0, 40)
			main.talk_to(n)
	check(hud.windows["warp"].visible, "คุยกับร่างทรงแล้วเปิดหน้าต่างวาร์ป")
	hud.windows["warp"].warp_requested.emit("khlong_village")
	await process_frame
	check(main.map.map_id == "khlong_village", "กดวาร์ปในหน้าต่างแล้วกลับหมู่บ้าน")

	# ---- ร้านอาวุธ + ร้านหลอม ----
	for n in main.npcs.get_children():
		if n.npc_id() == "lung_lek":
			player.pos = n.pos + Vector2(0, 40)
			main.talk_to(n)
	check(hud.windows["shop"].visible and hud.windows["shop"].title_label.text.contains("ร้านอาวุธ"), "เปิดร้านอาวุธในหมู่บ้านได้")
	coins = player.coins()
	check(player.buy("mitmo") and player.inventory.get("mitmo", 0) == 1 and player.coins() == coins - ItemDB.ITEMS["mitmo"]["buy"], "ซื้อมีดหมอจากร้านอาวุธ")
	hud.close_windows()
	for ore in World.ORE_ORDER:
		player.inventory[ore] = 30
	for n in main.npcs.get_children():
		if n.role() == "smith":
			player.pos = n.pos + Vector2(0, 40)
			main.talk_to(n)
	check(hud.windows["smith"].visible, "คุยกับช่างหลอมแร่แล้วเปิดหน้าต่างหลอม")
	coins = player.coins()
	check(player.craft("hin_ti_1", 2) and player.inventory["hin_ti_1"] == 2 and player.inventory["ore_zinc"] == 20 and player.inventory["ore_iron"] == 28 and player.coins() == coins - 100, "หลอมหินตี+ ขั้นต้น 2 ก้อน ใช้แร่และเหรียญ")
	check(player.craft("hin_ti_3", 1) and player.inventory["ore_diamond"] == 29, "หลอมหินตี+ ขั้นสูง ใช้เพชร")
	player.inventory["ore_diamond"] = 0
	check(not player.craft("hin_ti_3", 1), "แร่ไม่พอหลอมไม่ได้")
	hud.close_windows()

	# ---- ตีบวก ----
	player.use_item("hin_ti_1")
	check(hud.windows["refine"].visible, "กดใช้หินตี+ แล้วเปิดหน้าต่างตีบวก")
	coins = player.coins()
	var res: Dictionary = player.refine("mitmo", "hin_ti_1")
	check(res["result"] == "success" and player.inventory.get("mitmo+1", 0) == 1 and not player.inventory.has("mitmo") and player.coins() == coins - ItemDB.refine_fee(0) and player.inventory["hin_ti_1"] == 1, "ตี +1 สำเร็จแน่นอน (ใช้หิน 1 ก้อน + เหรียญ)")
	check(player.refine_stones_for(4).is_empty() == false and not "hin_ti_1" in player.refine_stones_for(4), "หินขั้นต้นตีเกิน +4 ไม่ได้ ต้องใช้หินขั้นสูงกว่า")
	player.inventory["hin_ti_3"] = 400
	player.state["coins"] = 50000000
	# สวมแล้วตีของที่สวมอยู่ ค่าพลังต้องขึ้นตาม
	player.state["class"] = "nak_rob"
	player.recalc()
	check(player.equip("mitmo+1"), "สวมมีดหมอ +1 ได้")
	var atk_before: int = player.stats["atk"]
	var lv := 1
	var downs := 0
	var tries := 0
	var max_seen := 0
	var risky_safe := true
	while lv < 10 and tries < 400:
		var before := lv
		var r: Dictionary = player.refine(player.state["equipment"]["weapon"], "hin_ti_3", "weapon")
		lv = r["level"]
		max_seen = maxi(max_seen, lv)
		if r["result"] == "down":
			downs += 1
			risky_safe = risky_safe and before >= ItemDB.REFINE_RISKY_FROM and before - lv >= 1 and before - lv <= 2
		elif r["result"] == "fail":
			risky_safe = risky_safe and before < ItemDB.REFINE_RISKY_FROM and lv == before
		tries += 1
	check(lv == 10 and player.state["equipment"]["weapon"] == "mitmo+10", "ตีจนถึง +10 ได้ (ลอง %d ครั้ง ลดขั้น %d ครั้ง)" % [tries, downs])
	check(risky_safe, "ล้มเหลวก่อน +7 ไม่ลดขั้น ตั้งแต่ +7 ลดขั้น 1–2")
	check(player.stats["atk"] > atk_before, "ของที่สวมอยู่ตีบวกแล้ว ATK เพิ่ม (%d -> %d)" % [atk_before, player.stats["atk"]])
	var stones: int = player.inventory["hin_ti_3"]
	check(not player.refine("mitmo+10", "hin_ti_3", "weapon")["ok"] and player.inventory["hin_ti_3"] == stones, "ตีเกิน +10 ไม่ได้ (ไม่เสียหิน)")
	hud.open_refine("hin_ti_3")
	check(hud.windows["refine"].visible, "หน้าต่างตีบวกแสดงของ +10 ได้")
	hud.close_windows()

	# ---- ถ้ำ: ผีพิเศษ + ขุดแร่ ----
	main.load_map("krung_kao")
	await process_frame
	var cave_gate: Node3D = null
	for w in main.portals.get_children():
		if w.data.get("style", "") == "cave":
			cave_gate = w
	player.pos = cave_gate.pos + Vector2(0, -80)
	player.command_move(cave_gate.pos)
	_run(main, 3.0)
	await process_frame
	check(main.map.map_id == "cave:krung_kao" and main.map.map_name == "ถ้ำใต้กรุงเก่าร้าง", "เดินเข้าปากถ้ำแล้วลงไปในถ้ำ")
	var special := true
	for g in main.alive_ghosts():
		special = special and g.ghost_id == "cave_krung_kao"
	check(special and main.alive_ghosts().size() == 11, "ในถ้ำมีผีพิเศษ (%s)" % GhostDB.GHOSTS["cave_krung_kao"]["name"])
	check(main.rocks.get_child_count() == 14, "ในถ้ำมีหินแร่ 14 ก้อน")
	for g in main.alive_ghosts():
		g.free()
	main.respawn_queue.clear()
	var ores_before := 0
	for ore in World.ORE_ORDER:
		ores_before += player.inventory.get(ore, 0)
	var rock: Node3D = main.nearest_rock(2000.0)
	player.pos = main.map.spawn_point
	player.command_mine(rock)
	_run(main, 20.0)
	var ores_after := 0
	for ore in World.ORE_ORDER:
		ores_after += player.inventory.get(ore, 0)
	check(ores_after - ores_before == rock.CHARGES and not rock.has_ore(), "เดินไปขุดหินจนหมด ได้แร่ %d ก้อน" % (ores_after - ores_before))
	_run(main, rock.RESPAWN + 1.0)
	check(rock.has_ore(), "หินแร่งอกใหม่หลังรอสักพัก")
	player.pos = main.portals.get_child(0).pos + Vector2(80, 0)
	player.command_move(main.portals.get_child(0).pos)
	_run(main, 3.0)
	await process_frame
	check(main.map.map_id == "krung_kao", "ออกจากถ้ำกลับกรุงเก่า")
	main.free()
