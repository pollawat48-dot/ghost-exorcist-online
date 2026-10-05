extends Node2D
## M1: ต้นแบบเล่นคนเดียว — หมู่บ้านวัดป่า + ทุ่งป่าช้า
## ทุกอย่างขับด้วย tick() เพื่อให้ย้ายไปรันบน zone server และทดสอบแบบ headless ได้

const TownMap = preload("res://maps/town_map.gd")
const Player = preload("res://client/player.gd")
const Ghost = preload("res://client/ghost.gd")
const Drop = preload("res://client/drop.gd")
const Hud = preload("res://client/hud.gd")

const RESPAWN_DELAY := 8.0
const PICKUP_RADIUS := 20.0
const CLICK_RADIUS := 24.0

var map: Node2D
var player: Node2D
var ghosts: Node2D
var drops: Node2D
var hud: CanvasLayer
var respawn_queue: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var next_ghost_seed := 1


func _ready() -> void:
	rng.seed = 12345
	map = TownMap.new()
	add_child(map)
	drops = Node2D.new()
	drops.name = "Drops"
	add_child(drops)
	ghosts = Node2D.new()
	ghosts.name = "Ghosts"
	add_child(ghosts)

	player = Player.new()
	player.position = TownMap.SPAWN_POINT
	player.spawn_point = TownMap.SPAWN_POINT
	player.bounds = TownMap.WORLD_RECT
	player.ghosts = ghosts
	add_child(player)

	var camera := Camera2D.new()
	camera.limit_right = int(TownMap.WORLD_RECT.end.x)
	camera.limit_bottom = int(TownMap.WORLD_RECT.end.y)
	camera.position_smoothing_enabled = true
	player.add_child(camera)

	hud = Hud.new()
	add_child(hud)
	hud.bind(player)

	for entry in TownMap.SPAWNS:
		for i in entry["count"]:
			_spawn_ghost(entry["id"])
	hud.add_log("ยินดีต้อนรับสู่หมู่บ้านวัดป่า! เดินไปทางขวาเพื่อล่าผีที่ทุ่งป่าช้า")


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
		var pos := get_global_mouse_position()
		var ghost := ghost_at(pos)
		if ghost != null:
			player.command_attack(ghost)
		else:
			player.command_move(pos)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				player.cast_holy_water()
			KEY_Q:
				player.use_herb()


func ghost_at(pos: Vector2) -> Node2D:
	var best: Node2D = null
	var best_dist := CLICK_RADIUS
	for g in alive_ghosts():
		var d: float = pos.distance_to(g.position)
		if d < best_dist:
			best = g
			best_dist = d
	return best


func alive_ghosts() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for g in ghosts.get_children():
		if g.has_method("take_damage") and g.alive:
			result.append(g)
	return result


func _spawn_ghost(id: String) -> void:
	var g := Ghost.new()
	var r := TownMap.FIELD_RECT
	var pos := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
	g.setup(id, pos, player, next_ghost_seed)
	next_ghost_seed += 1
	g.died.connect(_on_ghost_died)
	ghosts.add_child(g)


func _on_ghost_died(g: Node2D) -> void:
	player.gain_exp(g.data["exp"])
	for d in g.data["drops"]:
		if rng.randf() < d["chance"]:
			var drop := Drop.new()
			drop.item_id = d["item"]
			drop.position = g.position + Vector2(rng.randf_range(-14, 14), rng.randf_range(-10, 10))
			drops.add_child(drop)
	respawn_queue.append({"id": g.ghost_id, "time": RESPAWN_DELAY})


func _tick_respawns(delta: float) -> void:
	var due: Array[Dictionary] = []
	for entry in respawn_queue:
		entry["time"] -= delta
		if entry["time"] <= 0.0:
			due.append(entry)
	for entry in due:
		respawn_queue.erase(entry)
		_spawn_ghost(entry["id"])


func _tick_pickups() -> void:
	for d in drops.get_children():
		if d.is_queued_for_deletion():
			continue
		if player.position.distance_to(d.position) < PICKUP_RADIUS:
			player.add_item(d.item_id)
			d.queue_free()
