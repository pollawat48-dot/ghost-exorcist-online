extends Node3D
## M1: ต้นแบบเล่นคนเดียว (3D) — ประเทศไทย: หมู่บ้านริมคลอง
## ทุกอย่างขับด้วย tick() เพื่อให้ย้ายไปรันบน zone server และทดสอบแบบ headless ได้
## ตรรกะเกมอยู่บนพื้นราบ 2D (pos) ส่วนสิ่งที่เห็นเป็น 3D

const StartMap = preload("res://maps/thailand/khlong_village.gd")
const Ambience = preload("res://client/ambience.gd")
const Player = preload("res://client/player.gd")
const Ghost = preload("res://client/ghost.gd")
const Drop = preload("res://client/drop.gd")
const Hud = preload("res://client/hud.gd")
const CameraRig = preload("res://client/camera_rig.gd")

const RESPAWN_DELAY := 8.0
const PICKUP_RADIUS := 20.0
const CLICK_RADIUS := 24.0
const CLICK_RADIUS_SCREEN := 45.0

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


func _ready() -> void:
	rng.seed = 12345
	map = StartMap.new()
	add_child(map)
	ambience = Ambience.new()
	ambience.setup(map)
	add_child(ambience)

	world = Node3D.new()
	world.name = "World"
	add_child(world)
	world.add_child(map.build_props())
	drops = Node3D.new()
	drops.name = "Drops"
	world.add_child(drops)
	ghosts = Node3D.new()
	ghosts.name = "Ghosts"
	world.add_child(ghosts)

	player = Player.new()
	player.pos = map.spawn_point
	player.spawn_point = map.spawn_point
	player.bounds = map.world_rect
	player.ghosts = ghosts
	player.nav = map
	world.add_child(player)

	camera_rig = CameraRig.new()
	camera_rig.target = player
	add_child(camera_rig)

	hud = Hud.new()
	add_child(hud)
	hud.bind(player)
	hud.set_location(map.country, map.map_name)
	hud.set_phase(ambience.phase)
	hud.track(camera_rig.camera, ghosts)
	ambience.phase_changed.connect(hud.set_phase)

	for i in map.spawns.size():
		for n in map.spawns[i]["count"]:
			_spawn_ghost(i)
	ambience.tick(0.0)
	hud.add_log("ยินดีต้อนรับสู่%s! ข้ามสะพานไปทางขวาเพื่อล่าผีที่ทุ่งนาและป่าช้า" % map.map_name)


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	player.tick(delta)
	for g in ghosts.get_children():
		if g.has_method("tick"):
			g.tick(delta)
	_tick_respawns(delta)
	_tick_pickups()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var ghost := ghost_at_screen(event.position)
		if ghost != null:
			player.command_attack(ghost)
		else:
			player.command_move(camera_rig.ground_point(event.position))
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				player.cast_holy_water()
			KEY_Q:
				player.use_herb()


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
	player.gain_exp(g.data["exp"])
	for d in g.data["drops"]:
		if rng.randf() < d["chance"]:
			var drop := Drop.new()
			drop.item_id = d["item"]
			drop.pos = g.pos + Vector2(rng.randf_range(-14, 14), rng.randf_range(-10, 10))
			drops.add_child(drop)
	respawn_queue.append({"spawn": g.get_meta("spawn_index"), "time": RESPAWN_DELAY})


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
