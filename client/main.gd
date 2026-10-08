extends Node3D
## เกมหลัก (3D) — ประเทศไทย: หมู่บ้าน → ป่าช้า → กรุงเก่า → ดอย → บึงนาคา → ยมโลก (+ ลำธารตกปลา)
## บางแผนที่ถูกสุ่มให้มีถ้ำ (เก็บใน state["caves"]) เข้าไปเจอผีพิเศษและขุดแร่ได้
## ออนไลน์: เห็นผู้เล่นอื่นในแผนที่เดียวกัน แชท ปาร์ตี้ (แชร์ EXP + บัฟ) ผ่าน net (NetClient)
## ถ้าไม่มี net หรือหลุด จะเล่นต่อแบบออฟไลน์ได้ (ผีและของดรอปยังคำนวณในเครื่อง)
## ทุกอย่างขับด้วย tick() เพื่อให้ย้ายไปรันบน zone server และทดสอบแบบ headless ได้
## ตรรกะเกมอยู่บนพื้นราบ 2D (pos) ส่วนสิ่งที่เห็นเป็น 3D

const MAPS := {
	"khlong_village": preload("res://maps/thailand/khlong_village.gd"),
	"pa_cha": preload("res://maps/thailand/pa_cha.gd"),
	"krung_kao": preload("res://maps/thailand/krung_kao.gd"),
	"doi_phi": preload("res://maps/thailand/doi_phi.gd"),
	"nong_naga": preload("res://maps/thailand/nong_naga.gd"),
	"yom_lok": preload("res://maps/thailand/yom_lok.gd"),
	"lam_than": preload("res://maps/thailand/lam_than.gd"),
	"china_harbor": preload("res://maps/china/china_harbor.gd"),
	"china_bamboo": preload("res://maps/china/china_bamboo.gd"),
	"china_tomb": preload("res://maps/china/china_tomb.gd"),
	"china_wall": preload("res://maps/china/china_wall.gd"),
	"china_fengdu": preload("res://maps/china/china_fengdu.gd"),
}
const CaveMap = preload("res://maps/cave.gd")
const OreRock = preload("res://client/ore_rock.gd")
const World = preload("res://shared/data/world.gd")
const START_MAP := "khlong_village"
const Npc = preload("res://client/npc.gd")
const Portal = preload("res://client/portal.gd")
const AutoPlay = preload("res://client/auto_play.gd")
const QuestGuide = preload("res://client/quest_guide.gd")
const GhostDB = preload("res://shared/data/ghosts.gd")
const Quests = preload("res://shared/data/quests.gd")
const Ambience = preload("res://client/ambience.gd")
const Player = preload("res://client/player.gd")
const Ghost = preload("res://client/ghost.gd")
const Drop = preload("res://client/drop.gd")
const Hud = preload("res://client/hud.gd")
const CameraRig = preload("res://client/camera_rig.gd")
const ItemDB = preload("res://shared/data/items.gd")
const OcclusionFader = preload("res://client/occlusion_fader.gd")
const PerfOverlay = preload("res://client/ui/perf_overlay.gd")
const RemotePlayer = preload("res://client/remote_player.gd")
const Sound = preload("res://client/audio/sound.gd")
const Skills = preload("res://shared/data/skills.gd")
const Fishing = preload("res://shared/data/fishing.gd")
const Graphics = preload("res://client/graphics.gd")
const Fashion = preload("res://shared/data/fashion.gd")

signal logout_requested  ## กดออกจากเกม (กลับหน้าเมนู) — App เป็นคนจัดการ

const POS_INTERVAL := 0.2  ## ส่งตำแหน่งให้เซิร์ฟเวอร์ทุกๆ
const AUTOSAVE_INTERVAL := 20.0
## เพลงตามแผนที่
const MAP_MUSIC := {"khlong_village": "village", "lam_than": "stream", "pa_cha": "dark", "yom_lok": "dark"}

const RESPAWN_DELAY := 8.0
## บอสประจำถิ่นเกิดไม่บ่อย: ครั้งแรกหลังเริ่มเกม 5–8 นาที หลังโดนปราบรอ 10–15 นาที
const BOSS_FIRST_DELAY := Vector2(300, 480)
const BOSS_RESPAWN_DELAY := Vector2(600, 900)
const PICKUP_RADIUS := 20.0
const CLICK_RADIUS := 24.0
const CLICK_RADIUS_SCREEN := 45.0
const AUTO_TARGET_RADIUS := 320.0
const NPC_CLICK_SCREEN := 60.0

var map: Node3D
var world: Node3D
var ambience: Node3D
var camera_rig: Node3D
var player: Node3D
var ghosts: Node3D
var drops: Node3D
var hud: CanvasLayer
var respawn_queue: Array[Dictionary] = []  # {"spawn": index ใน map.spawns, "time": วินาทีที่เหลือ}
var rng := RandomNumberGenerator.new()
var next_ghost_seed := 1
var boss: Node3D = null
var boss_timer := 0.0
var boss_place := ""
var npcs: Node3D
var portals: Node3D
var rocks: Node3D
var props: Node3D
var fader: Node
var auto: RefCounted
var guide: RefCounted  ## นำทางเควส (กดเควสแล้วเดินไปหาผี/กลับไปส่ง)
var talk_target: Node3D = null  ## NPC ที่กำลังเดินไปคุย
var portal_lock := 0.0  ## กันวาร์ปเด้งไปมาทันทีหลังเปลี่ยนแผนที่
## ตัวละครที่เลือกจากหน้าเมนู {"name", "look", "data", "guest": bool} (ว่าง = เล่นทดสอบแบบเดิม)
var session := {}
var net: Node = null  ## NetClient (null = ออฟไลน์)
var store: RefCounted = null  ## LocalStore สำหรับ guest (บันทึกในเครื่อง)
var remotes: Node3D
var pos_timer := 0.0
var save_timer := 0.0
var fish_pending := Vector2.INF  ## จุดน้ำที่กำลังเดินไปตกปลา


func _ready() -> void:
	Graphics.level()  # ตั้งความละเอียดโมเดลก่อนสร้างฉาก
	add_to_group("graphics_listener")
	rng.seed = 12345
	world = Node3D.new()
	world.name = "World"
	add_child(world)
	drops = Node3D.new()
	drops.name = "Drops"
	world.add_child(drops)
	ghosts = Node3D.new()
	ghosts.name = "Ghosts"
	world.add_child(ghosts)
	npcs = Node3D.new()
	npcs.name = "Npcs"
	world.add_child(npcs)
	portals = Node3D.new()
	portals.name = "Portals"
	world.add_child(portals)
	rocks = Node3D.new()
	rocks.name = "OreRocks"
	world.add_child(rocks)

	remotes = Node3D.new()
	remotes.name = "Remotes"
	world.add_child(remotes)

	player = Player.new()
	player.ghosts = ghosts
	if not session.is_empty():
		player.player_name = session["name"]
		player.look = session.get("look", {})
		player.apply_save(session.get("data", {}))
	world.add_child(player)

	camera_rig = CameraRig.new()
	camera_rig.target = player
	add_child(camera_rig)

	ambience = Ambience.new()
	add_child(ambience)
	fader = OcclusionFader.new()
	add_child(fader)
	auto = AutoPlay.new(self)
	guide = QuestGuide.new(self)

	hud = Hud.new()
	add_child(hud)
	add_child(PerfOverlay.new())
	hud.bind(player)
	hud.bind_auto(auto)
	hud.track(camera_rig.camera, ghosts)
	hud.action.connect(do_action)
	ambience.phase_changed.connect(hud.set_phase)
	player.changed.connect(_refresh_npc_markers)
	player.open_refine.connect(hud.open_refine)
	player.sfx.connect(func(id: String): Sound.play(self, id))
	player.party_cast.connect(_on_party_cast)
	player.caught.connect(func(_id: String): hud.refresh_fishing())
	hud.chat_sent.connect(_on_chat_sent)
	hud.party_request.connect(_on_party_request)
	hud.quest_clicked.connect(guide_quest)
	hud.bind_net(net)
	_bind_net()

	# โลกใหม่: สุ่มว่าแผนที่ไหนมีถ้ำ (ทุกโลกไม่เหมือนกัน)
	var cave_rng := RandomNumberGenerator.new()
	cave_rng.randomize()
	if player.state["caves"].is_empty():
		player.state["caves"] = World.pick_caves(cave_rng)
	else:
		World.ensure_china_caves(player.state["caves"], cave_rng)
	var data: Dictionary = session.get("data", {})
	var start: String = data.get("map", START_MAP)
	if not MAPS.has(start):
		start = START_MAP
	var at: Vector2 = Vector2(float(data.get("x", 0.0)), float(data.get("y", 0.0))) if data.has("x") else Vector2.INF
	load_map(start, at)
	hud.add_log("ยินดีต้อนรับสู่%s! คุยกับหลวงตาเพื่อรับเควส ซื้อยาที่ร้านยาย แล้วข้ามสะพานไปล่าผี" % map.map_name)
	if is_online():
		hud.add_log("เชื่อมต่อเซิร์ฟเวอร์แล้ว: กด Enter เพื่อแชท · ชวนเพื่อนเข้าปาร์ตี้ได้ที่เมนูปาร์ตี้")


## โหลดแผนที่ใหม่ (ตอนเริ่มเกมหรือเดินเข้าประตูวาร์ป) ตัวละครและของในกระเป๋าคงเดิม
func load_map(map_id: String, entry: Vector2 = Vector2.INF) -> void:
	if map != null:
		map.queue_free()
		props.queue_free()
		for root in [ghosts, drops, npcs, portals, rocks]:
			for c in root.get_children():
				root.remove_child(c)
				c.queue_free()
	for c in remotes.get_children():
		remotes.remove_child(c)
		c.queue_free()
	respawn_queue.clear()
	boss = null
	talk_target = null
	fish_pending = Vector2.INF
	if World.is_cave(map_id):
		var parent := World.cave_parent(map_id)
		var probe: Node3D = MAPS[parent].new()
		var parent_spot: Vector2 = probe.cave_spot
		probe.free()
		map = CaveMap.new()
		map.configure(parent, parent_spot + Vector2(0, -90))
	else:
		map = MAPS[map_id].new()
		player.state["visited"][map_id] = true
		# แผนที่ที่ถูกสุ่มให้มีถ้ำ: เพิ่มปากถ้ำเป็นประตูอีกบาน
		if map_id in player.state["caves"] and map.cave_spot != Vector2.INF:
			map.portals.append({"pos": map.cave_spot, "to": World.CAVE_PREFIX + map_id, "to_pos": CaveMap.ENTRANCE + Vector2(130, 0),
				"name": World.map_name(World.CAVE_PREFIX + map_id), "style": "cave"})
	add_child(map)
	props = map.build_props()
	world.add_child(props)
	ambience.setup(map)
	ambience.tick(0.0)
	fader.setup(camera_rig.camera, player, map.props_root)

	player.current_map = map.map_id
	player.pos = map.spawn_point if entry == Vector2.INF else entry
	player.spawn_point = map.spawn_point
	player.bounds = map.world_rect
	player.nav = map
	player.command_move(player.pos)
	player.attack_target = null
	camera_rig.snap()

	for entry_npc in map.npcs:
		var n := Npc.new()
		n.setup(entry_npc)
		npcs.add_child(n)
	for entry_portal in map.portals:
		var w := Portal.new()
		w.setup(entry_portal)
		portals.add_child(w)
	for p in map.ore_rocks:
		var r := OreRock.new()
		# ถ้ำจีนมีโอกาสเจอหินพิเศษ (หินหยกวิญญาณ) ที่ให้แร่ดีกว่า
		var special: bool = World.country_of(map_id) == "cn" and rng.randf() < World.SPECIAL_ROCK_CHANCE
		r.setup(p, map.cave_tier, rocks.get_child_count(), special)
		rocks.add_child(r)
	boss_timer = rng.randf_range(BOSS_FIRST_DELAY.x, BOSS_FIRST_DELAY.y)
	for i in map.spawns.size():
		for n in map.spawns[i]["count"]:
			_spawn_ghost(i)
	portal_lock = 1.0
	hud.set_location(map.country, map.map_name)
	hud.set_map_id(map.map_id)
	if World.is_cave(map.map_id):
		hud.add_log("ในถ้ำมืดมีผีพิเศษ และมีหินแร่ให้ขุด (คลิกที่หิน) แร่ที่ได้เอาไปหลอมเป็นหินตี+ ได้")
	hud.setup_minimap(map, npcs, portals, remotes)
	hud.close_windows()
	hud.set_fishing_map(map.fishing)
	_refresh_npc_markers()
	Sound.music(self, "cave" if World.is_cave(map.map_id) else MAP_MUSIC.get(map.map_id, "field"))
	pos_timer = 0.0
	if not session.is_empty():
		save_now()


func _process(delta: float) -> void:
	player.stick = Vector2.ZERO if hud.typing() else _stick_world()
	if player.stick != Vector2.ZERO:
		auto.pause(1.5)
		guide.stop()
	tick(delta)


## ทิศเดินจากจอยบนจอหรือ WASD แปลงตามมุมกล้อง (ขึ้นจอ = เดินไปข้างหน้ากล้อง)
func _stick_world() -> Vector2:
	var v: Vector2 = hud.stick.value
	if v == Vector2.ZERO:
		v = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
		var keys := Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		if keys != Vector2.ZERO:
			v = keys.normalized()
	if v == Vector2.ZERO:
		return v
	var basis: Basis = camera_rig.camera.global_basis
	var right := Vector2(basis.x.x, basis.x.z).normalized()
	var forward := Vector2(-basis.z.x, -basis.z.z).normalized()
	return right * v.x - forward * v.y


## ปุ่มบนจอ/แถบสกิล/คีย์ลัด เรียกมาที่นี่ที่เดียว
func do_action(name: String) -> void:
	match name:
		"attack":
			var npc := nearest_npc(Npc.TALK_RADIUS + 30.0)
			if npc != null:
				talk_to(npc)
				return
			var target := nearest_ghost(AUTO_TARGET_RADIUS)
			if target != null:
				auto.pause()
				player.command_attack(target)
				return
			var rock := nearest_rock(160.0)
			if rock != null:
				auto.pause()
				player.command_mine(rock)
			elif map.fishing:
				start_fishing()
			else:
				hud.add_log("ไม่มีผีอยู่ใกล้ๆ")
		"holy_water":
			player.cast_holy_water()
		"herb", "potion_hp":
			player.use_potion("hp")
		"potion_sp":
			player.use_potion("sp")
		"auto":
			toggle_auto()
		"fish":
			start_fishing()
		"respawn":
			player.respawn()
			camera_rig.snap()
		"logout":
			save_now()
			logout_requested.emit()
		_:
			if name.begins_with("sail:"):
				sail_to(name.substr(5))
			elif name.begins_with("warp:"):
				warp_to(name.substr(5))
			elif name.begins_with("skill:"):
				player.use_skill(name.substr(6))


## กดเควสในรายการ: ยังไม่ครบ = เดินไปล่าผีเป้าหมาย, ครบแล้ว = เดินกลับไปส่งที่ NPC
func guide_quest(id: String) -> void:
	hud.close_windows()
	var msg: String = guide.start(id)
	if msg != "":
		hud.add_log(msg)
		Sound.play(self, "click")


## เปลี่ยนคุณภาพภาพ: สร้างฉากและตัวละครใหม่ด้วยความละเอียดโมเดลระดับใหม่ (ยืนที่เดิม)
func _on_graphics_changed() -> void:
	if map == null or player == null:
		return
	load_map(map.map_id, player.pos)
	player._build_model()


func toggle_auto() -> void:
	auto.set_enabled(not auto.enabled)
	hud.add_log("เปิดระบบออโต้: ตีผี ใช้สกิล เก็บของ และกินยาเอง" if auto.enabled else "ปิดระบบออโต้แล้ว")
	hud.refresh_auto()


## ร่างทรงนำทาง: จ่ายค่าวาร์ปแล้วไปจุดเริ่มของแผนที่นั้น
## ขึ้นเรือสำเภาข้ามประเทศ (ไทย ↔ จีน) ไม่เสียค่าวาร์ป แต่ต้องทำเควสขึ้นเรือครบก่อน
func sail_to(map_id: String) -> bool:
	if not Quests.has_boat_pass(player.state) or player.state["level"] < World.BOAT_LEVEL:
		hud.add_log("ยังขึ้นเรือไม่ได้: ต้องเลเวล %d ขึ้นไป และทำเควสเตรียมเรือให้ครบ" % World.BOAT_LEVEL)
		return false
	guide.stop()
	auto.set_enabled(false)
	hud.refresh_auto()
	load_map(map_id)
	Sound.play(self, "warp")
	hud.add_log("เรือสำเภาเทียบท่า%s แล้ว" % map.map_name)
	return true


func warp_to(map_id: String) -> bool:
	if map_id == map.map_id or not player.pay_warp(map_id):
		return false
	guide.stop()
	auto.set_enabled(false)
	hud.refresh_auto()
	load_map(map_id)
	Sound.play(self, "warp")
	hud.add_log("วาร์ปมาถึง%s" % map.map_name)
	return true


# ---------- ตกปลา ----------

## ตกปลาตรงนี้ถ้ายืนริมน้ำ ไม่งั้นเดินไปริมน้ำที่ใกล้ที่สุดก่อน
func start_fishing() -> void:
	if not map.fishing:
		hud.add_log("แผนที่นี้ตกปลาไม่ได้ ไปที่ลำธารใสเย็นทางใต้ของหมู่บ้าน")
		return
	if player.best_rod() == "":
		hud.add_log("ต้องมีคันเบ็ดก่อน ซื้อได้ที่ร้านตาม่อง")
		return
	auto.set_enabled(false)
	hud.refresh_auto()
	var spot: Vector2 = map.water_near(player.pos, Fishing.REACH)
	if spot != Vector2.INF:
		player.command_fish(spot)
		return
	var far: Vector2 = map.water_near(player.pos, 900.0)
	if far == Vector2.INF:
		hud.add_log("ไม่มีน้ำอยู่ใกล้ๆ")
		return
	fish_toward(far)


## เดินไปริมน้ำตรงจุดที่คลิก แล้วเริ่มตกปลาเมื่อถึง
func fish_toward(water_point: Vector2) -> void:
	var bank := water_point
	var dir: Vector2 = (player.pos - water_point).normalized()
	for i in 40:
		if map.is_walkable(bank) and not map.is_water(bank):
			break
		bank += dir * 12.0
	player.command_move(bank)
	fish_pending = water_point


func _tick_fish_pending() -> void:
	if fish_pending == Vector2.INF or player.moving:
		return
	var spot: Vector2 = map.water_near(player.pos, Fishing.REACH)
	fish_pending = Vector2.INF
	if spot != Vector2.INF:
		player.command_fish(spot)


# ---------- ออนไลน์: ผู้เล่นอื่น แชท ปาร์ตี้ ----------

func is_online() -> bool:
	return net != null and net.is_online()


func _bind_net() -> void:
	if net == null:
		return
	net.players_updated.connect(_on_players)
	net.chat_received.connect(hud.add_chat)
	net.party_updated.connect(_on_party_updated)
	net.party_invited.connect(hud.show_invite)
	net.exp_shared.connect(_on_exp_shared)
	net.buff_received.connect(_on_buff_received)
	net.heal_received.connect(func(amount: int, from: String): player.receive_heal(amount, from))
	net.notice.connect(func(text: String): hud.add_chat("system", "", "", text))
	net.disconnected.connect(_on_disconnected)


## บันทึกตัวละคร: ไอดีที่สมัคร = เซิร์ฟเวอร์, guest = ในเครื่อง
func save_now() -> void:
	if session.is_empty():
		return
	save_timer = 0.0
	var data: Dictionary = player.save_data()
	var where: String = map.map_id if not World.is_cave(map.map_id) else World.cave_parent(map.map_id)
	data["map"] = where
	if where == map.map_id:
		data["x"] = player.pos.x
		data["y"] = player.pos.y
	if session.get("guest", false):
		if store != null:
			store.save(session.get("store_name", session["name"]), data)
	elif is_online():
		net.save(data)


func _on_players(list: Array) -> void:
	var seen := {}
	for d in list:
		if not d is Dictionary:
			continue
		var id := int(d.get("id", 0))
		seen[id] = true
		var r: Node3D = remotes.get_node_or_null(str(id))
		if r == null:
			r = RemotePlayer.new()
			r.name = str(id)
			remotes.add_child(r)
			r.setup(d)
		else:
			r.apply(d)
	for r in remotes.get_children():
		if not seen.has(int(str(r.name))):
			remotes.remove_child(r)
			r.queue_free()


func _on_party_updated(_leader: String, members: Array) -> void:
	hud.refresh_party()
	if members.size() >= 2:
		Sound.play(self, "party")


func _on_exp_shared(amount: int, ghost_id: String, from: String, members: int) -> void:
	if members >= 2:
		player.message.emit("EXP ปาร์ตี้ (%d คน โบนัส +%d%%) จาก%s" % [members, members * 5, GhostDB.GHOSTS.get(ghost_id, {}).get("name", "ผี")] if from == player.player_name else "%s ปราบ%s แชร์ EXP ให้ (%d คน)" % [from, GhostDB.GHOSTS.get(ghost_id, {}).get("name", "ผี"), members])
	player.gain_exp(amount)


func _on_buff_received(msg: Dictionary) -> void:
	var id: String = str(msg.get("skill", ""))
	var buff_name: String = Skills.SKILLS[id]["name"] if Skills.SKILLS.has(id) else "บัฟ"
	player.apply_buff(str(msg.get("effect", "")), float(msg.get("power", 0.0)), float(msg.get("duration", 0.0)), buff_name, str(msg.get("from", "เพื่อน")))


func _on_party_cast(fields: Dictionary) -> void:
	if not is_online() or not net.in_party():
		return
	if fields["t"] == "heal":
		net.send_heal(fields["amount"], Vector2(fields["x"], fields["y"]))
	else:
		net.send_buff(fields)


func _on_chat_sent(ch: String, text: String, to: String) -> void:
	if not is_online():
		hud.add_chat("system", "", "", "ยังไม่ได้เชื่อมต่อเซิร์ฟเวอร์ (เล่นออฟไลน์) แชทได้เมื่อออนไลน์")
		return
	net.send_chat(ch, text, to)


## คำสั่งปาร์ตี้จากหน้าต่าง/เมนูผู้เล่น: invite:<ชื่อ>, kick:<ชื่อ>, leave, accept:<ชื่อ>, decline:<ชื่อ>
func _on_party_request(what: String) -> void:
	if not is_online():
		hud.add_chat("system", "", "", "ปาร์ตี้ใช้ได้เมื่อเชื่อมต่อเซิร์ฟเวอร์")
		return
	var i := what.find(":")
	var cmd := what if i < 0 else what.substr(0, i)
	var arg := "" if i < 0 else what.substr(i + 1)
	match cmd:
		"invite":
			net.party_invite(arg)
			hud.add_chat("system", "", "", "ส่งคำชวนเข้าปาร์ตี้ให้ %s แล้ว" % arg)
		"kick":
			net.party_kick(arg)
		"leave":
			net.party_leave()
		"accept", "decline":
			net.party_reply(arg, cmd == "accept")


func _on_disconnected() -> void:
	for c in remotes.get_children():
		c.queue_free()
	hud.show_disconnected()


func _tick_net(delta: float) -> void:
	if session.is_empty():
		return
	save_timer += delta
	if save_timer >= AUTOSAVE_INTERVAL:
		save_now()
	if not is_online():
		return
	pos_timer -= delta
	if pos_timer <= 0.0:
		pos_timer = POS_INTERVAL
		net.send_pos(map.map_id, player.pos, {"cls": player.state["class"], "lv": player.state["level"], "hp": player.hp, "mhp": player.stats["max_hp"], "equip": player.look_items()})


func remote_at_screen(screen: Vector2) -> Node3D:
	var cam: Camera3D = camera_rig.camera
	var best: Node3D = null
	var best_dist := CLICK_RADIUS_SCREEN
	for r in remotes.get_children():
		var wp: Vector3 = r.global_position + Vector3(0, 1.0, 0)
		if cam.is_position_behind(wp):
			continue
		var d := screen.distance_to(cam.unproject_position(wp))
		if d < best_dist:
			best = r
			best_dist = d
	return best


func nearest_rock(radius: float) -> Node3D:
	var best: Node3D = null
	var best_dist := radius
	for r in rocks.get_children():
		var d: float = player.pos.distance_to(r.pos)
		if r.has_ore() and d < best_dist:
			best = r
			best_dist = d
	return best


func rock_at_screen(screen: Vector2) -> Node3D:
	var cam: Camera3D = camera_rig.camera
	var best: Node3D = null
	var best_dist := CLICK_RADIUS_SCREEN
	for r in rocks.get_children():
		if not r.has_ore():
			continue
		var wp: Vector3 = r.global_position + Vector3(0, 0.4, 0)
		if cam.is_position_behind(wp):
			continue
		var d := screen.distance_to(cam.unproject_position(wp))
		if d < best_dist:
			best = r
			best_dist = d
	return best


func nearest_npc(radius: float) -> Node3D:
	var best: Node3D = null
	var best_dist := radius
	for n in npcs.get_children():
		var d: float = player.pos.distance_to(n.pos)
		if d < best_dist:
			best = n
			best_dist = d
	return best


## คุยกับ NPC: ถ้าอยู่ไกลจะเดินไปหาก่อน แล้วเปิดหน้าต่างร้านค้า/เควส
func talk_to(npc: Node3D) -> void:
	if player.pos.distance_to(npc.pos) <= Npc.TALK_RADIUS:
		talk_target = null
		player.command_move(player.pos)
		hud.open_npc(npc.data)
		return
	talk_target = npc
	player.command_move(npc.pos + Vector2(0, 46))


## เครื่องหมายเหนือหัว NPC: ! มีเควสใหม่ ? มีเควสส่งได้
func _refresh_npc_markers() -> void:
	if npcs == null:
		return
	for n in npcs.get_children():
		if n.role() in ["shop", "warp", "smith"]:
			n.set_marker(n.role())
			continue
		var mark := "ready" if (n.role() == "class" and player.can_change_class()) or (n.role() == "pet" and player.can_evolve_pet()) else ""
		for id in Quests.for_giver(n.npc_id()):
			if mark == "ready":
				break
			var st: String = player.quest_status(id)
			if st == "ready":
				mark = "ready"
				break
			if st == "available":
				mark = "available"
		if mark == "" and n.role() in ["class", "pet", "boat"]:
			mark = n.role()
		n.set_marker(mark)


func nearest_ghost(radius: float) -> Node3D:
	if player.attack_target != null and is_instance_valid(player.attack_target) and player.attack_target.alive:
		return player.attack_target
	var best: Node3D = null
	var best_dist := radius
	for g in alive_ghosts():
		var d: float = player.pos.distance_to(g.pos)
		if d < best_dist:
			best = g
			best_dist = d
	return best


func tick(delta: float) -> void:
	var t := Time.get_ticks_usec()
	auto.tick(delta)
	guide.tick(delta)
	t = _mark("ออโต้", t)
	player.tick(delta)
	t = _mark("ผู้เล่น", t)
	_tick_talk()
	_tick_portals(delta)
	for g in ghosts.get_children():
		if g.has_method("tick"):
			g.tick(delta)
	t = _mark("ผี", t)
	_tick_respawns(delta)
	_tick_boss(delta)
	for r in rocks.get_children():
		r.tick(delta)
	_tick_pickups()
	_tick_fish_pending()
	t = _mark("อื่นๆ", t)
	_tick_net(delta)
	_mark("เน็ต", t)


## จับเวลาส่วนของเกมให้ตัวบอก FPS แสดงว่าส่วนไหนหนัก
func _mark(section: String, since: int) -> int:
	var now := Time.get_ticks_usec()
	PerfOverlay.add(section, now - since)
	return now


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		auto.pause()
		guide.stop()
		var npc := npc_at_screen(event.position)
		if npc != null:
			talk_to(npc)
			return
		talk_target = null
		var ghost := ghost_at_screen(event.position)
		var rock := rock_at_screen(event.position)
		var other := remote_at_screen(event.position) if ghost == null else null
		fish_pending = Vector2.INF
		if ghost != null:
			player.command_attack(ghost)
		elif rock != null:
			player.command_mine(rock)
		elif other != null:
			hud.show_player_menu(other.player_name, event.position)
		else:
			var ground: Vector2 = camera_rig.ground_point(event.position)
			if map.fishing and map.is_water(ground):
				fish_toward(ground)
			else:
				player.command_move(ground)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			hud.press_slot(event.keycode - KEY_1)
			return
		match event.keycode:
			KEY_0, KEY_Q:
				do_action("potion_hp")
			KEY_E:
				do_action("potion_sp")
			KEY_F:
				var npc := nearest_npc(Npc.TALK_RADIUS + 60.0)
				if npc != null:
					talk_to(npc)
			KEY_V:
				toggle_auto()
			KEY_SPACE:
				do_action("attack")
			KEY_C:
				hud.toggle_window("char")
			KEY_K:
				hud.toggle_window("skills")
			KEY_I, KEY_B:
				hud.toggle_window("bag")
			KEY_J:
				hud.toggle_window("questlog")
			KEY_P:
				hud.toggle_window("party")
			KEY_G:
				do_action("fish")
			KEY_ENTER, KEY_KP_ENTER:
				hud.focus_chat()
			KEY_ESCAPE:
				hud.close_windows()


func npc_at_screen(screen: Vector2) -> Node3D:
	var cam: Camera3D = camera_rig.camera
	var best: Node3D = null
	var best_dist := NPC_CLICK_SCREEN
	for n in npcs.get_children():
		var world_pos: Vector3 = n.global_position + Vector3(0, 1.0, 0)
		if cam.is_position_behind(world_pos):
			continue
		var d := screen.distance_to(cam.unproject_position(world_pos))
		if d < best_dist:
			best = n
			best_dist = d
	return best


## ผีที่อยู่ใต้เมาส์บนหน้าจอ (เทียบกับตัวผีที่ลอยอยู่ ไม่ใช่เงาบนพื้น)
func ghost_at_screen(screen: Vector2) -> Node3D:
	var cam: Camera3D = camera_rig.camera
	var best: Node3D = null
	var best_dist := CLICK_RADIUS_SCREEN
	for g in alive_ghosts():
		var world_pos: Vector3 = g.global_position + Vector3(0, 1.25, 0)
		if cam.is_position_behind(world_pos):
			continue
		var d := screen.distance_to(cam.unproject_position(world_pos))
		if d < best_dist:
			best = g
			best_dist = d
	return best


func ghost_at(pos: Vector2) -> Node3D:
	var best: Node3D = null
	var best_dist := CLICK_RADIUS
	for g in alive_ghosts():
		var d: float = pos.distance_to(g.pos)
		if d < best_dist:
			best = g
			best_dist = d
	return best


func alive_ghosts() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for g in ghosts.get_children():
		if g.has_method("take_damage") and g.alive:
			result.append(g)
	return result


func _spawn_ghost(spawn_index: int) -> void:
	var entry: Dictionary = map.spawns[spawn_index]
	var r: Rect2 = entry["rect"]
	var g := Ghost.new()
	var pos := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
	g.setup(entry["id"], pos, player, next_ghost_seed)
	g.set_meta("spawn_index", spawn_index)
	next_ghost_seed += 1
	g.died.connect(_on_ghost_died)
	ghosts.add_child(g)


func _on_ghost_died(g: Node3D) -> void:
	Sound.play(self, "ghost_die")
	if is_online() and net.in_party():
		# อยู่ในปาร์ตี้: EXP ส่งไปให้เซิร์ฟเวอร์แบ่งกับเพื่อนในแผนที่เดียวกัน (+5% ต่อคน)
		player.reward_kill(g.ghost_id, 0, g.data.get("coins", 0))
		net.report_kill(g.ghost_id, map.map_id)
	else:
		player.reward_kill(g.ghost_id, g.data["exp"], g.data.get("coins", 0))
	var spread := 60.0 if g.is_boss() else 14.0
	var dropped_equip := false
	var equip_pool: Array[String] = []
	for d in g.data["drops"]:
		var is_equip: bool = ItemDB.ITEMS[d["item"]]["type"] == "equip"
		if is_equip:
			equip_pool.append(d["item"])
		if rng.randf() < d["chance"]:
			_drop(d["item"], g.pos, spread)
			dropped_equip = dropped_equip or is_equip
	if g.is_boss():
		# บอสรับประกันของสวมใส่อย่างน้อย 1 ชิ้น
		if not dropped_equip and not equip_pool.is_empty():
			_drop(equip_pool[rng.randi() % equip_pool.size()], g.pos, spread)
		boss = null
		boss_timer = rng.randf_range(BOSS_RESPAWN_DELAY.x, BOSS_RESPAWN_DELAY.y)
		player.add_cc(Fashion.CC_PER_BOSS, "ปราบบอส")
		hud.announce("ปราบ%sสำเร็จ! ของรางวัลตกอยู่เต็มพื้น" % g.data["name"])
		return
	respawn_queue.append({"spawn": g.get_meta("spawn_index"), "time": RESPAWN_DELAY})


func _drop(item_id: String, at: Vector2, spread: float) -> void:
	var drop := Drop.new()
	drop.item_id = item_id
	drop.pos = at + Vector2(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread) * 0.7)
	drops.add_child(drop)


## นับถอยหลังแล้วเรียกบอสประจำถิ่น
func _tick_boss(delta: float) -> void:
	if map.boss_id == "":
		return
	if boss != null:
		if not is_instance_valid(boss) or not boss.alive:
			boss = null
		return
	boss_timer -= delta
	if boss_timer <= 0.0:
		spawn_boss()


func spawn_boss(place_index: int = -1) -> Node3D:
	if boss != null and is_instance_valid(boss) and boss.alive:
		return boss
	if map.boss_spawns.is_empty():
		return null
	if place_index < 0:
		place_index = rng.randi() % map.boss_spawns.size()
	var place: Dictionary = map.boss_spawns[place_index]
	boss = Ghost.new()
	boss.setup(map.boss_id, place["pos"], player, next_ghost_seed)
	next_ghost_seed += 1
	boss.died.connect(_on_ghost_died)
	ghosts.add_child(boss)
	boss_place = place["name"]
	Sound.play(self, "boss")
	hud.announce("%s ปรากฏตัวที่%s! ดูตำแหน่งบนแผนที่ย่อ" % [boss.data["name"], boss_place])
	return boss


func _tick_respawns(delta: float) -> void:
	var due: Array[Dictionary] = []
	for entry in respawn_queue:
		entry["time"] -= delta
		if entry["time"] <= 0.0:
			due.append(entry)
	for entry in due:
		respawn_queue.erase(entry)
		_spawn_ghost(entry["spawn"])


func _tick_pickups() -> void:
	for d in drops.get_children():
		if d.is_queued_for_deletion():
			continue
		if player.pos.distance_to(d.pos) < PICKUP_RADIUS:
			player.add_item(d.item_id)
			Sound.play(self, "pickup")
			d.queue_free()


func _tick_talk() -> void:
	if talk_target == null:
		return
	if not is_instance_valid(talk_target) or player.attack_target != null:
		talk_target = null
		return
	if player.pos.distance_to(talk_target.pos) <= Npc.TALK_RADIUS:
		var npc := talk_target
		talk_target = null
		talk_to(npc)
	elif not player.moving:
		talk_target = null


## เหยียบประตูวาร์ปแล้วย้ายแผนที่ (ระหว่างออโต้ทำงานจะไม่วาร์ปเอง กันหลงไปแผนที่อื่น)
func _tick_portals(delta: float) -> void:
	portal_lock = maxf(0.0, portal_lock - delta)
	if portal_lock > 0.0 or (auto.enabled and not auto.is_paused()):
		return
	for w in portals.get_children():
		if player.pos.distance_to(w.pos) < Portal.RADIUS:
			var to: String = w.data["to"]
			var at: Vector2 = w.data["to_pos"]
			load_map(to, at)
			Sound.play(self, "warp")
			hud.add_log("เดินทางมาถึง%s" % map.map_name)
			return
