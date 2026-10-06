extends SceneTree
## ภาพเล่นออนไลน์: เปิดเซิร์ฟเวอร์ในตัว + ผู้เล่นจำลอง 3 คน (ปาร์ตี้ แชท บัฟ)
## godot --path . --script res://tests/online_shot.gd -- out.png [party]

const Server = preload("res://server/server.gd")
const NetClient = preload("res://client/net/net_client.gd")

var clients: Array = []


func _initialize() -> void:
	_shoot()


func _wait(cond: Callable, seconds: float = 5.0) -> void:
	var end := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end and not cond.call():
		await process_frame


func _shoot() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "online.png"
	var mode := args[1] if args.size() > 1 else ""
	var server: Node = Server.new()
	root.add_child(server)
	var port := 30000 + randi() % 20000
	server.start(port, "user://shot_server_%d" % randi())
	var names := ["มะลิ", "บ๊อบ", "ต้นกล้า", "น้ำฝน"]
	var looks := [{"gender": "f", "hair": 3, "skin": 0}, {"gender": "m", "hair": 1, "skin": 1}, {"gender": "m", "hair": 2, "skin": 2}, {"gender": "f", "hair": 4, "skin": 0}]
	var entered := {}
	for i in names.size():
		var c: Node = NetClient.new()
		root.add_child(c)
		clients.append(c)
		var idx := i
		c.entered.connect(func(n: String, _l: Dictionary, d: Dictionary): entered[idx] = d)
		c.party_invited.connect(func(from: String): c.party_reply(from, true))
		c.connect_to("127.0.0.1", port)
	await _wait(func(): return clients.all(func(c): return c.ready_ok))
	for i in clients.size():
		clients[i].register("user%d_x" % i, "secret%d" % i)
	await _wait(func(): return false, 0.3)
	for i in clients.size():
		clients[i].login("user%d_x" % i, "secret%d" % i)
	await _wait(func(): return clients.all(func(c): return c.user != ""))
	for i in clients.size():
		clients[i].create_char(names[i], looks[i])
	await _wait(func(): return clients.all(func(c): return c.chars.size() == 1))
	for i in clients.size():
		clients[i].enter(names[i])
	await _wait(func(): return entered.size() == names.size())
	var main: Node3D = load("res://main.tscn").instantiate()
	main.session = {"name": names[0], "look": looks[0], "data": {}, "guest": false}
	main.net = clients[0]
	root.add_child(main)
	await process_frame
	var player: Node3D = main.player
	# ตัวเรา: อาจารย์สักยันต์ ใส่ของชุดบึงนาคา
	var gear := {"weapon": "khamphi_badan+7", "armor": "kraphan_naga", "head": "mongkut_naki", "accessory": "kaeo_naga"}
	player.gain_exp(3000000)
	for id in ["mo_phi", "ajarn_yant"]:
		player.state["quests_done"][player.class_change_status()["quest"]] = 1
		player.state["coins"] += player.class_change_status()["fee"]
		player.change_class(id)
	for slot in gear:
		player.add_item(gear[slot])
		player.equip(gear[slot])
	player.state["skills"]["samathi"] = 4
	player.state["skills"]["nam_mon_chalom"] = 3
	player.recalc()
	player.hp = player.stats["max_hp"]
	player.sp = player.stats["max_sp"]
	player.pos = Vector2(560, 1200)
	var others := [
		[Vector2(630, 1150), "khun_phaen", 112, {"weapon": "dab_matchu+10", "armor": "chut_yom", "head": "chada_khun", "accessory": "prajiat_khun"}],
		[Vector2(640, 1260), "phran_ratri", 64, {"weapon": "thanu_krung", "armor": "chut_phran", "head": "muak_boran"}],
		[Vector2(490, 1250), "novice", 8, {"weapon": "maipai_staff", "armor": "suea_yant", "head": "pha_khat_hua"}],
	]
	for i in others.size():
		var o: Array = others[i]
		clients[i + 1].send_pos("khlong_village", o[0], {"cls": o[1], "lv": o[2], "hp": 900, "mhp": 1000, "equip": o[3]})
	main.hud.party_request.emit("invite:บ๊อบ")
	await _wait(func(): return clients[0].in_party(), 3.0)
	main.hud.party_request.emit("invite:ต้นกล้า")
	await _wait(func(): return clients[0].party_members.size() >= 3, 3.0)
	clients[1].send_chat("world", "มีใครไปยมโลกบ้าง ขาดฮีลเลอร์ 1 ที่ค้าบ", "")
	clients[3].send_chat("world", "สวัสดีค่ะ มือใหม่ฝากตัวด้วยนะคะ", "")
	await _wait(func(): return false, 0.3)
	clients[2].send_chat("party", "เดี๋ยวบัฟตีเร็วให้นะ", "")
	clients[3].send_chat("whisper", "พี่มะลิ ขอยาสักขวดได้ไหมคะ", "มะลิ")
	player.use_skill("samathi")
	clients[2].send_buff({"t": "buff", "skill": "ta_thip", "lv": 4, "power": 0.2, "duration": 60.0, "effect": "aspd", "x": 560, "y": 1200})
	await _wait(func(): return false, 1.0)
	for i in others.size():
		var o: Array = others[i]
		clients[i + 1].send_pos("khlong_village", o[0], {"cls": o[1], "lv": o[2], "hp": 700 + i * 100, "mhp": 1000, "equip": o[3]})
	await _wait(func(): return main.remotes.get_child_count() == 3, 3.0)
	await _wait(func(): return false, 1.0)
	main.camera_rig.yaw = deg_to_rad(20)
	main.camera_rig.distance = 13.0
	main.ambience.time_of_day = 0.42
	main.ambience.tick(0.0)
	player.model.rotation.y = main.camera_rig.yaw
	if mode == "party":
		main.hud.toggle_window("party")
	for i in 25:
		await process_frame
	root.get_texture().get_image().save_png(out)
	print("saved ", out)
	quit()
