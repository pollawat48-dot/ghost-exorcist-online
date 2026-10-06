extends Node3D
## M1: ต้นแบบเล่นคนเดียว (3D) — ประเทศไทย: หมู่บ้านริมคลอง → ป่าช้าวัดร้าง
## ทุกอย่างขับด้วย tick() เพื่อให้ย้ายไปรันบน zone server และทดสอบแบบ headless ได้
## ตรรกะเกมอยู่บนพื้นราบ 2D (pos) ส่วนสิ่งที่เห็นเป็น 3D

const MAPS := {
	"khlong_village": preload("res://maps/thailand/khlong_village.gd"),
	"pa_cha": preload("res://maps/thailand/pa_cha.gd"),
}
const START_MAP := "khlong_village"
const Npc = preload("res://client/npc.gd")
const Portal = preload("res://client/portal.gd")
const AutoPlay = preload("res://client/auto_play.gd")
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
var props: Node3D
var fader: Node
var auto: RefCounted
var talk_target: Node3D = null  ## NPC ที่กำลังเดินไปคุย
var portal_lock := 0.0  ## กันวาร์ปเด้งไปมาทันทีหลังเปลี่ยนแผนที่


func _ready() -> void:
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

	player = Player.new()
	player.ghosts = ghosts
	world.add_child(player)

	camera_rig = CameraRig.new()
	camera_rig.target = player
	add_child(camera_rig)

	ambience = Ambience.new()
	add_child(ambience)
	fader = OcclusionFader.new()
	add_child(fader)
	auto = AutoPlay.new(self)

	hud = Hud.new()
	add_child(hud)
	hud.bind(player)
	hud.bind_auto(auto)
	hud.track(camera_rig.camera, ghosts)
	hud.action.connect(do_action)
	ambience.phase_changed.connect(hud.set_phase)
	player.changed.connect(_refresh_npc_markers)

	load_map(START_MAP)
	hud.add_log("ยินดีต้อนรับสู่%s! คุยกับหลวงตาเพื่อรับเควส ซื้อยาที่ร้านยาย แล้วข้ามสะพานไปล่าผี" % map.map_name)


## โหลดแผนที่ใหม่ (ตอนเริ่มเกมหรือเดินเข้าประตูวาร์ป) ตัวละครและของในกระเป๋าคงเดิม
func load_map(map_id: String, entry: Vector2 = Vector2.INF) -> void:
	if map != null:
		map.queue_free()
		props.queue_free()
		for root in [ghosts, drops, npcs, portals]:
			for c in root.get_children():
				root.remove_child(c)
				c.queue_free()
	respawn_queue.clear()
	boss = null
	talk_target = null
	map = MAPS[map_id].new()
	add_child(map)
	props = map.build_props()
	world.add_child(props)
	ambience.setup(map)
	ambience.tick(0.0)
	fader.setup(camera_rig.camera, player, map.props_root)

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
	boss_timer = rng.randf_range(BOSS_FIRST_DELAY.x, BOSS_FIRST_DELAY.y)
	for i in map.spawns.size():
		for n in map.spawns[i]["count"]:
			_spawn_ghost(i)
	portal_lock = 1.0
	hud.set_location(map.country, map.map_name)
	hud.setup_minimap(map, npcs, portals)
	hud.close_windows()
	_refresh_npc_markers()


func _process(delta: float) -> void:
	player.stick = _stick_world()
	if player.stick != Vector2.ZERO:
		auto.pause(1.5)
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
		_:
			if name.begins_with("skill:"):
				player.use_skill(name.substr(6))


func toggle_auto() -> void:
	auto.set_enabled(not auto.enabled)
	hud.add_log("เปิดระบบออโต้: ตีผี ใช้สกิล เก็บของ และกินยาเอง" if auto.enabled else "ปิดระบบออโต้แล้ว")
	hud.refresh_auto()


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
		if n.role() == "shop":
			n.set_marker("shop")
			continue
		var mark := ""
		for id in Quests.for_giver(n.npc_id()):
			var st: String = player.quest_status(id)
			if st == "ready":
				mark = "ready"
				break
			if st == "available":
				mark = "available"
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
	auto.tick(delta)
	player.tick(delta)
	_tick_talk()
	_tick_portals(delta)
	for g in ghosts.get_children():
		if g.has_method("tick"):
			g.tick(delta)
	_tick_respawns(delta)
	_tick_boss(delta)
	_tick_pickups()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		auto.pause()
		var npc := npc_at_screen(event.position)
		if npc != null:
			talk_to(npc)
			return
		talk_target = null
		var ghost := ghost_at_screen(event.position)
		if ghost != null:
			player.command_attack(ghost)
		else:
			player.command_move(camera_rig.ground_point(event.position))
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
	if place_index < 0:
		place_index = rng.randi() % map.boss_spawns.size()
	var place: Dictionary = map.boss_spawns[place_index]
	boss = Ghost.new()
	boss.setup(map.boss_id, place["pos"], player, next_ghost_seed)
	next_ghost_seed += 1
	boss.died.connect(_on_ghost_died)
	ghosts.add_child(boss)
	boss_place = place["name"]
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
			hud.add_log("เดินทางมาถึง%s" % map.map_name)
			return
