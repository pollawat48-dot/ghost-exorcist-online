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
	# โหมดพิเศษ: job:<คลาส>, boss, char, skills, bag, class, showcase
	var mode := args[7] if args.size() > 7 else ""
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
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()


func _apply_mode(main: Node3D, mode: String) -> void:
	var player: Node3D = main.player
	if mode.begins_with("job:"):
		var target := mode.substr(4)
		var chain: Array[String] = load("res://shared/data/classes.gd").lineage(target)
		player.gain_exp(50000000)
		for id in chain.slice(1):
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
	elif mode in ["char", "skills", "bag", "class"]:
		main.hud.toggle_window(mode)
