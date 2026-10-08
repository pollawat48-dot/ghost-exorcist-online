extends RefCounted
## นำทางเควส (กดเควสในรายการ/สมุดเควส):
## - ยังทำไม่ครบ: เดินไปแผนที่ที่มีผีเป้าหมาย (ผ่านประตูวาร์ปให้เอง) แล้วตีผีตัวนั้นให้ เควสหาของจะเก็บของที่ตกด้วย
## - ทำครบแล้ว: เดินกลับไปหา NPC ผู้ให้เควส แล้วเปิดหน้าส่งเควส
## หยุดเองเมื่อผู้เล่นบังคับเอง (คลิกพื้น/จอย/วาร์ป) หรือเมื่อเควสทำครบ

const Quests = preload("res://shared/data/quests.gd")
const GhostDB = preload("res://shared/data/ghosts.gd")
const World = preload("res://shared/data/world.gd")
const CaveMap = preload("res://maps/cave.gd")

const THINK_INTERVAL := 0.4
const LOOT_RADIUS := 260.0

var main: Node3D
var quest_id := ""
var mode := ""  ## "hunt" = ไปล่าผี, "return" = กลับไปส่งเควส
var goal_map := ""
var ghost_ids: Array[String] = []
var loot_item := ""  ## เควสหาของ: เดินไปเก็บของชิ้นนี้ที่ตกใกล้ๆ
var think_timer := 0.0
var _maps := {}  ## map_id -> {"ghosts", "npcs", "portals"} อ่านจากสคริปต์แผนที่ครั้งเดียว


func _init(main_ref: Node3D) -> void:
	main = main_ref


func active() -> bool:
	return quest_id != ""


func stop() -> void:
	quest_id = ""
	mode = ""


## เริ่มนำทางเควส คืนข้อความบอกผู้เล่น
func start(id: String) -> String:
	stop()
	var p: Node3D = main.player
	var q: Dictionary = Quests.QUESTS[id]
	var st: String = p.quest_status(id)
	if st == "ready":
		var where := _find_map(func(info: Dictionary): return q["giver"] in info["npcs"])
		if where == "":
			return "ไม่พบผู้ให้เควสนี้"
		quest_id = id
		mode = "return"
		goal_map = where
		think_timer = 0.0
		return "กำลังเดินกลับไปส่งเควส \"%s\" ที่%s" % [q["name"], World.map_name(where)]
	if st != "active":
		return ""
	ghost_ids = targets(id)
	loot_item = q["target"] if q["type"] == "collect" else ""
	var where := _find_map(func(info: Dictionary):
		for g in ghost_ids:
			if g in info["ghosts"]:
				return true
		return false)
	if where == "":
		return "ไม่รู้ว่าจะไปหา%sได้ที่ไหน" % Quests.target_name(id)
	quest_id = id
	mode = "hunt"
	goal_map = where
	think_timer = 0.0
	return "กำลังเดินไปล่า%s ที่%s" % [GhostDB.GHOSTS[ghost_ids[0]]["name"], World.map_name(where)]


## ผีที่ต้องปราบเพื่อทำเควสนี้ (เควสหาของ = ผีที่ดรอปของชิ้นนั้น)
static func targets(id: String) -> Array[String]:
	var q: Dictionary = Quests.QUESTS[id]
	var out: Array[String] = []
	if q["type"] == "kill":
		out.append(q["target"])
		return out
	if q.has("source"):
		out.append(q["source"])
		return out
	for g in GhostDB.GHOSTS:
		for d in GhostDB.GHOSTS[g].get("drops", []):
			if d["item"] == q["target"]:
				out.append(g)
				break
	return out


func tick(delta: float) -> void:
	if not active():
		return
	var p: Node3D = main.player
	var st: String = p.quest_status(quest_id)
	if mode == "hunt" and st != "active":
		var q_name: String = Quests.QUESTS[quest_id]["name"]
		stop()
		if st == "ready":
			main.hud.add_log("เควส \"%s\" ครบแล้ว! กดที่เควสอีกครั้งเพื่อเดินกลับไปส่ง" % q_name)
		return
	if mode == "return" and st != "ready":
		stop()
		return
	main.auto.pause(THINK_INTERVAL * 2.0)
	if p.hp <= 0:
		return
	think_timer -= delta
	if think_timer > 0.0:
		return
	think_timer = THINK_INTERVAL
	if main.map.map_id != goal_map:
		_walk_to_portal(p)
	elif mode == "return":
		_go_to_giver(p)
	else:
		_hunt(p)


func _walk_to_portal(p: Node3D) -> void:
	var hop := next_hop(main.map.map_id, goal_map)
	for w in main.portals.get_children():
		if w.data["to"] == hop:
			if not _heading_to(p, w.pos):
				p.attack_target = null
				p.command_move(w.pos)
			return
	# ข้ามประเทศ: เดินไปหาไต้ก๋งที่ท่าเรือแล้วขึ้นเรือสำเภา
	if hop == World.PORTS.get(World.country_of(hop), ""):
		for n in main.npcs.get_children():
			if n.role() == "boat":
				if p.pos.distance_to(n.pos) <= 70.0:
					p.attack_target = null
					main.sail_to(hop)
				elif not _heading_to(p, n.pos):
					p.attack_target = null
					p.command_move(n.pos)
				return
	main.hud.add_log("หาทางไป%sไม่เจอ" % World.map_name(goal_map))
	stop()


func _go_to_giver(p: Node3D) -> void:
	var giver: String = Quests.QUESTS[quest_id]["giver"]
	for n in main.npcs.get_children():
		if n.npc_id() == giver:
			p.attack_target = null
			main.talk_to(n)
			stop()
			return
	stop()


func _hunt(p: Node3D) -> void:
	# ผีที่ตีอยู่อาจถูกลบไปแล้ว (ตายแล้วหายไป) ห้ามเก็บลงตัวแปรแบบมีชนิดก่อนเช็ก
	if is_instance_valid(p.attack_target):
		if p.attack_target.alive:
			return
	p.attack_target = null
	if loot_item != "":
		var drop := _nearest_drop(p)
		if drop != null:
			if not _heading_to(p, drop.pos):
				p.command_move(drop.pos)
			return
	var best: Node3D = null
	for g in main.alive_ghosts():
		if g.ghost_id in ghost_ids and (best == null or p.pos.distance_to(g.pos) < p.pos.distance_to(best.pos)):
			best = g
	if best != null:
		p.command_attack(best)
		return
	# ผีเป้าหมายตายหมด (รอเกิดใหม่): เดินไปรอแถวจุดเกิด
	var spot := _spawn_spot(p)
	if spot != Vector2.INF and p.pos.distance_to(spot) > 120.0 and not p.moving:
		p.command_move(spot)


## กำลังเดินไปจุดนี้อยู่แล้วหรือยัง (ไม่ต้องสั่งเดินซ้ำทุกรอบ)
func _heading_to(p: Node3D, dest: Vector2) -> bool:
	return p.moving and not p.path.is_empty() and p.path[p.path.size() - 1].distance_to(dest) < 40.0


func _nearest_drop(p: Node3D) -> Node3D:
	var best: Node3D = null
	var best_dist := LOOT_RADIUS
	for d in main.drops.get_children():
		if d.item_id == loot_item and not d.is_queued_for_deletion():
			var dist: float = p.pos.distance_to(d.pos)
			if dist < best_dist:
				best = d
				best_dist = dist
	return best


func _spawn_spot(p: Node3D) -> Vector2:
	var best := Vector2.INF
	var spots: Array[Vector2] = []
	for s in main.map.spawns:
		if s["id"] in ghost_ids:
			spots.append(s["rect"].get_center())
	if main.map.boss_id in ghost_ids:
		for b in main.map.boss_spawns:
			spots.append(b["pos"])
	for s in spots:
		if best == Vector2.INF or p.pos.distance_to(s) < p.pos.distance_to(best):
			best = s
	return best


func _boat_ready() -> bool:
	return Quests.has_boat_pass(main.player.state) and main.player.state["level"] >= World.BOAT_LEVEL


# ---------- เส้นทางระหว่างแผนที่ ----------

## แผนที่ที่ตรงเงื่อนไข: แผนที่ปัจจุบันก่อน แล้วไล่ตามลำดับโลก (รวมถ้ำที่ค้นพบแล้ว)
func _find_map(pred: Callable) -> String:
	var order: Array = [main.map.map_id]
	order.append_array(World.ORDER)
	for c in main.player.state["caves"]:
		order.append(World.CAVE_PREFIX + c)
	for id in order:
		if pred.call(info(id)) and (id == main.map.map_id or next_hop(main.map.map_id, id) != ""):
			return id
	return ""


## แผนที่ถัดไปที่ต้องเดินผ่านประตูเพื่อไปถึง to ("" = ไปไม่ได้)
func next_hop(from: String, to: String) -> String:
	if from == to:
		return to
	var prev := {from: ""}
	var queue: Array = [from]
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		if cur == to:
			break
		for nb in info(cur)["portals"]:
			if not prev.has(nb):
				prev[nb] = cur
				queue.append(nb)
	if not prev.has(to):
		return ""
	var step := to
	while prev[step] != from:
		step = prev[step]
	return step


## ข้อมูลย่อของแผนที่ (ผี / NPC / ประตูไปไหนบ้าง)
func info(map_id: String) -> Dictionary:
	if _maps.has(map_id):
		return _maps[map_id]
	var m: Node3D
	if World.is_cave(map_id):
		m = CaveMap.new()
		m.configure(World.cave_parent(map_id), Vector2.ZERO)
	elif main.MAPS.has(map_id):
		m = main.MAPS[map_id].new()
	else:
		return {"ghosts": [], "npcs": [], "portals": []}
	var ghosts: Array[String] = []
	for s in m.spawns:
		if not s["id"] in ghosts:
			ghosts.append(s["id"])
	if m.boss_id != "":
		ghosts.append(m.boss_id)
	var npc_ids: Array[String] = []
	for n in m.npcs:
		npc_ids.append(n["id"])
	var links: Array[String] = []
	for w in m.portals:
		links.append(w["to"])
	if not World.is_cave(map_id) and map_id in main.player.state["caves"] and m.cave_spot != Vector2.INF:
		links.append(World.CAVE_PREFIX + map_id)
	# ท่าเรือ: ถ้าผ่านเควสขึ้นเรือแล้ว นับว่าเชื่อมไปท่าเรือของอีกประเทศได้
	for n in m.npcs:
		if n.get("role", "") == "boat" and _boat_ready():
			var other: String = "cn" if World.country_of(map_id) == "th" else "th"
			links.append(World.PORTS[other])
	m.free()
	_maps[map_id] = {"ghosts": ghosts, "npcs": npc_ids, "portals": links}
	return _maps[map_id]
