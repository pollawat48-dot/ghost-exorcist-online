extends SceneTree
## ถ่ายภาพหน้าจอเกม (ต้องมีหน้าจอ เช่น xvfb-run):
## godot --path . --script res://tests/screenshot.gd -- out.png [x y เวลา(0-1) ล่าผี(0/1)]

func _initialize() -> void:
	_shoot()


func _shoot() -> void:
	var out := "screenshot.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	var main: Node3D = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.set_process(false)
	var player: Node3D = main.player
	var mode := args[7] if args.size() > 7 else ""
	for part in mode.split(",", false):
		if part == "allcaves" or part == "allcaves_cn":
			var W = load("res://shared/data/world.gd")
			player.state["caves"] = W.CAVE_CANDIDATES.duplicate()
			if part == "allcaves_cn":
				player.state["caves"].append_array(W.CHINA_CAVE_CANDIDATES)
			for id in W.ORDER:
				player.state["visited"][id] = true
		if part == "strong":
			# ดันเลเวล/คลาสให้สุดก่อนเริ่มล่าผี (ใช้กับแผนที่จีนที่ผีเลเวลสูง)
			var chain: Array[String] = load("res://shared/data/classes.gd").lineage("khun_phaen")
			player.gain_exp(50000000)
			for id in chain.slice(1):
				player.state["quests_done"][player.class_change_status()["quest"]] = 1
				player.state["coins"] += player.class_change_status()["fee"]
				player.change_class(id)
			for id in player.available_skills():
				player.state["skills"][id] = 5
			player.recalc()
			player.hp = player.stats["max_hp"]
		if part.begins_with("map:"):
			main.load_map(part.substr(4))
	player.pos = Vector2(float(args[1]), float(args[2])) if args.size() > 2 else Vector2(1050, 700)
	if args.size() > 3:
		main.ambience.time_of_day = float(args[3])
		main.ambience.tick(0.0)
	var hunt := args.size() <= 4 or args[4] == "1"
	for i in (400 if hunt else 0):
		if player.attack_target == null:
			var best: Node3D = null
			for c in main.alive_ghosts():
				if best == null or player.pos.distance_to(c.pos) < player.pos.distance_to(best.pos):
					best = c
			player.command_attack(best)
		if i == 395:
			player.cast_holy_water()
		main.tick(0.05)
	if args.size() > 5:
		main.camera_rig.yaw = deg_to_rad(float(args[5]))
	if args.size() > 6:
		main.camera_rig.distance = float(args[6])
	# โหมดพิเศษ: map:<id>, job:<คลาส>, boss, char, skills, bag, class, showcase, shop, quest, questlog, auto, autoon, quests
	for part in mode.split(",", false):
		_apply_mode(main, part)
	# ให้ตัวละครหันหน้าเข้ากล้องเพื่อดูหน้าตา
	player.attack_target = null
	player.moving = false
	player.model.rotation.y = main.camera_rig.yaw
	main.camera_rig.snap()
	main.set_process(true)
	for i in 30:
		await process_frame
	# fx:<สกิล|basic>:<วินาทีเกมก่อนถ่าย> ร่ายหลังฉากพร้อมแล้ว จับภาพกลางเอฟเฟกต์
	for part in mode.split(",", false):
		if part.begins_with("fx:"):
			var bits := part.split(":")
			var g: Node3D = load("res://client/ghost.gd").new()
			g.setup(bits[3] if bits.size() > 3 else "phi_takiang", player.pos + Vector2(45, -15), player, 999)
			main.ghosts.add_child(g)
			g.data = g.data.duplicate()
			g.data["atk"] = 0
			g.hp = 999999
			for i in 3:
				await process_frame
			player.sp = 99999
			# เฟรมตอนถ่ายภาพช้า: ชะลอเวลาเกมให้จับภาพกลางเอฟเฟกต์ได้ตรงจังหวะ
			# ร่ายรอบแรกเพื่อคอมไพล์ shader ก่อน (เฟรมแรกค้างนานจนเอฟเฟกต์จบไปแล้ว) แล้วค่อยร่ายรอบจริง
			Engine.time_scale = 0.2
			for round in 2:
				if round == 1:
					await create_timer(1.0).timeout
				player.sp = 99999
				g.hp = 999999
				if bits[1] == "basic":
					player._basic_attack(g)
				else:
					player.state["skills"][bits[1]] = 5
					player.skill_cd.erase(bits[1])
					player.use_skill(bits[1], g)
			player.attack_target = null
			await create_timer(float(bits[2]) if bits.size() > 2 else 0.2).timeout
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()


func _apply_mode(main: Node3D, mode: String) -> void:
	var player: Node3D = main.player
	if mode.begins_with("map:"):
		pass
	elif mode.begins_with("job:"):
		var target := mode.substr(4)
		var chain: Array[String] = load("res://shared/data/classes.gd").lineage(target)
		player.gain_exp(50000000)
		for id in chain.slice(1):
			player.state["quests_done"][player.class_change_status()["quest"]] = 1
			player.state["coins"] += player.class_change_status()["fee"]
			player.change_class(id)
		for id in player.available_skills():
			while player.state["skill_points"] > 0 and player.learn_skill(id):
				if player.skill_level(id) >= 3:
					break
		for i in 40:
			player.add_stat(["str", "agi", "vit", "int", "dex", "luk"][i % 6])
	elif mode.begins_with("lv:"):
		player.gain_exp(int(mode.substr(3)))
	elif mode == "boss":
		var boss: Node3D = main.spawn_boss(0)
		boss.pos = player.pos + Vector2(0, -150)
		boss.home = boss.pos
		boss.take_damage(700, player)
	elif mode == "showcase":
		# เรียงตัวละครทุกคลาสไว้ข้างผู้เล่น
		var Classes = load("res://shared/data/classes.gd")
		var Player = load("res://client/player.gd")
		var i := 0
		for id in Classes.CLASSES:
			if id == "novice":
				continue
			var p: Node3D = Player.new()
			p.state["class"] = id
			p.player_name = Classes.CLASSES[id]["name"]
			p.pos = player.pos + Vector2(-260 + (i % 3) * 130 + (i / 3) * 0, -120 + (i / 3) * 110)
			p.ghosts = main.ghosts
			main.world.add_child(p)
			i += 1
		player.pos += Vector2(-130, 150)
	elif mode == "gear":
		for id in ["suea_kraphan", "mongkhon", "takrut", "mitmo", "khan_thanu", "khamphi_queen", "phra_khrueang"]:
			player.add_item(id)
		for id in ["suea_kraphan", "mongkhon", "takrut", "mitmo"]:
			player.equip(id)
	elif mode in ["char", "skills", "bag", "class", "questlog", "auto"]:
		main.hud.toggle_window(mode)
	elif mode in ["shop", "quest", "master", "warp", "smith"]:
		for n in main.npcs.get_children():
			if n.role() == ("class" if mode == "master" else mode) and n.data.get("sign", "") == "":
				main.hud.open_npc(n.data)
				break
	elif mode == "gearshop":
		player.state["coins"] = 9000
		for n in main.npcs.get_children():
			if n.data.get("sign", "") == "ร้านอาวุธ":
				main.hud.open_npc(n.data)
	elif mode == "ores":
		player.state["coins"] = 25000
		var ores := {"ore_zinc": 23, "ore_iron": 9, "ore_gold": 3, "ore_diamond": 1}
		for ore in ores:
			player.inventory[ore] = ores[ore]
	elif mode == "refine":
		player.state["coins"] = 120000
		player.state["class"] = "nak_rob"
		player.inventory["mitmo+7"] = 1
		player.inventory["dab_krung+3"] = 1
		player.inventory["suea_kraphan"] = 1
		player.inventory["hin_ti_2"] = 4
		player.inventory["hin_ti_3"] = 2
		player.inventory["phra_din"] = 3
		player.inventory["phra_phong"] = 1
		player.inventory["phra_thong"] = 1
		player.recalc()
		main.hud.open_refine("hin_ti_3")
		var w: Control = main.hud.windows["refine"]
		w.selected = {"key": "mitmo+7", "slot": ""}
		w.amulet = "phra_phong"
		w.refresh()
	elif mode == "fishing":
		# ยืนตกปลาบนท่าน้ำลำธาร ได้ของมาแล้วหลายอย่าง
		player.add_item("bet_mai")
		for id in ["pla_siew", "pla_nil", "pla_chon", "phra_din"]:
			player.add_item(id)
		var x := 1560.0
		player.pos = Vector2(x, main.map.stream_y(x) + main.map.STREAM_R + 24.0)
		main.start_fishing()
		player.fish_count = 4
		for i in 70:
			main.tick(0.05)
	elif mode == "menufold":
		main.hud.set_menu_collapsed(true, false)
	elif mode == "settings":
		main.hud.toggle_window("settings")
	elif mode == "partywin":
		main.hud.toggle_window("party")
	elif mode == "bagall":
		for id in ["hin_ti_1", "hin_ti_2", "ore_zinc", "ore_gold", "ore_diamond", "dab_krung+5"]:
			player.add_item(id, 2)
		main.hud.toggle_window("bag")
	elif mode == "autoon":
		main.toggle_auto()
	elif mode == "quests":
		# รับเควสไว้ 2 อันให้เห็นรายการเควสบนจอ
		for n in main.npcs.get_children():
			if n.role() == "quest":
				for id in load("res://shared/data/quests.gd").for_giver(n.npc_id()):
					player.accept_quest(id)
		main._refresh_npc_markers()
	elif mode.begins_with("fashion:"):
		# fashion:<ชุด>,<หมวก>,<ปีก> คั่นด้วย / เช่น fashion:f_chut_thewada+7/f_chada_thep/f_pik_kinnari
		for key in mode.substr(8).split("/", false):
			player.inventory[key] = 1
			player.wear_fashion(key)
	elif mode.begins_with("pet:"):
		# pet:<ชนิด>:<ร่าง 0-2>:<เลเวล>
		var bits := mode.split(":")
		var Fashion = load("res://shared/data/fashion.gd")
		var sp: String = bits[1]
		var d: Dictionary = Fashion.pet_data(player.state, sp)
		d["stage"] = int(bits[2]) if bits.size() > 2 else 0
		d["lv"] = int(bits[3]) if bits.size() > 3 else 1
		player.inventory[Fashion.PETS[sp]["item"]] = 1
		player.wear_fashion(Fashion.PETS[sp]["item"])
		player.pet.pos = player.pos + Vector2(-60, 30)
		player.pet.rebuild()
	elif mode.begins_with("weapon:"):
		# weapon:<คีย์> เช่น weapon:maipai_staff+10
		player.add_item(mode.substr(7))
		player.equip(mode.substr(7))
	elif mode == "fashionwin":
		player.inventory["hin_ti_fashion"] = 6
		for id in ["f_hu_maeo", "f_pik_phisuea", "pet_krathai"]:
			player.inventory[id] = 1
		main.hud.toggle_window("fashion")
	elif mode == "pettrial":
		# ผ่านบททดสอบครูฝึกสัตว์ของร่างถัดไปแล้ว (ใช้คู่กับ pet:... และ pettrainer)
		var qid: String = player.pet_trial_quest()
		player.accept_quest(qid)
		for i in 40:
			player.reward_kill(load("res://shared/data/quests.gd").QUESTS[qid]["target"], 0, 0)
		player.complete_quest(qid)
		player.state["coins"] = 5000
	elif mode == "buffs":
		player.apply_buff("atk", 0.2, 600.0, "ปลุกพลังกล้า")
		player.apply_buff("speed", 0.2, 600.0, "ลมพัดไว")
		player.guard_timer = 600.0
		player.recalc()
	elif mode == "boat":
		# หน้าต่างไต้ก๋งเรือสำเภา (ผ่านเควสเรือครบแล้ว เลเวลถึงเกณฑ์)
		var World = load("res://shared/data/world.gd")
		player.state["level"] = World.BOAT_LEVEL
		for qid in ["q_boat_1", "q_boat_2", "q_boat_3"]:
			player.state["quests_done"][qid] = 1
		player.recalc()
		for n in main.npcs.get_children():
			if n.role() == "boat":
				main.hud.open_npc(n.data)
	elif mode == "boatnpc":
		# ยืนข้างไต้ก๋งที่ท่าไม้ริมคลอง
		for n in main.npcs.get_children():
			if n.role() == "boat":
				player.pos = n.pos + Vector2(-20, 90)
				main.camera_rig.snap()
	elif mode == "pettrainer":
		for n in main.npcs.get_children():
			if n.npc_id() == "khru_fuek_sat":
				main.hud.open_npc(n.data)
	elif mode == "ccshop":
		player.state["cc"] = 340
		player.rng.seed = 21
		main.hud.toggle_window("ccshop")
		player.buy_gacha(10)
		main.hud.windows["ccshop"].open(10)
	elif mode == "dead":
		player.take_damage(999999, "ผีกระสือ")
	elif mode == "mining":
		var Rock = load("res://client/ore_rock.gd")
		var rock: Node3D = Rock.new()
		rock.setup(player.pos + Vector2(26, -6), 1, 0)
		main.rocks.add_child(rock)
		player.command_mine(rock)
		for i in 26:
			main.tick(0.05)
	elif mode == "loot":
		for id in ["red_thread", "spirit_shard", "lantern_oil", "soul_krasue", "khamot_ember", "mitmo"]:
			player.add_item(id, 3)
