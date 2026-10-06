extends Node
## ทำให้บ้าน/ต้นไม้ที่บังตัวผู้เล่นโปร่งใสลง (แบบเกม RO) เพื่อให้เห็นตัวละครเสมอ
## ใช้ GeometryInstance3D.transparency จึงไม่ต้องแยกวัสดุของแต่ละชิ้น

const CHECK_RADIUS := 16.0  ## เมตร: ตรวจเฉพาะของที่อยู่ใกล้ผู้เล่น
const FADED := 0.65
const SCREEN_MARGIN := 24.0

var camera: Camera3D
var player: Node3D
var props: Node3D
var _cache := {}  ## prop -> {"meshes": Array, "aabb": AABB, "fade": float}


func setup(cam: Camera3D, player_ref: Node3D, props_root: Node3D) -> void:
	camera = cam
	player = player_ref
	props = props_root
	_cache.clear()


func _process(delta: float) -> void:
	if camera == null or player == null or props == null:
		return
	var target := player.global_position + Vector3(0, 0.8, 0)
	var screen := camera.unproject_position(target)
	var player_depth := camera.global_position.distance_to(target)
	var step := delta * 5.0
	for prop in props.get_children():
		var near := Vector2(prop.global_position.x - target.x, prop.global_position.z - target.z).length() < CHECK_RADIUS
		var entry: Dictionary = _cache.get(prop, {})
		if not near and entry.is_empty():
			continue
		if entry.is_empty():
			entry = _build_entry(prop)
			_cache[prop] = entry
		var goal := 0.0
		if near and _covers(entry["aabb"], screen, player_depth):
			goal = FADED
		var fade: float = move_toward(entry["fade"], goal, step)
		if fade != entry["fade"]:
			entry["fade"] = fade
			for m in entry["meshes"]:
				m.transparency = fade


func _covers(box: AABB, screen: Vector2, player_depth: float) -> bool:
	var rect := Rect2()
	var first := true
	var closest := INF
	for i in 8:
		var corner := box.get_endpoint(i)
		if camera.is_position_behind(corner):
			return false
		closest = minf(closest, camera.global_position.distance_to(corner))
		var p := camera.unproject_position(corner)
		if first:
			rect = Rect2(p, Vector2.ZERO)
			first = false
		else:
			rect = rect.expand(p)
	# ต้องอยู่ระหว่างกล้องกับผู้เล่น และคลุมตำแหน่งผู้เล่นบนจอ
	if rect.size.x < SCREEN_MARGIN * 2.0 or rect.size.y < SCREEN_MARGIN * 2.0:
		return false
	return closest < player_depth - 0.5 and rect.grow(-SCREEN_MARGIN).has_point(screen)


func _build_entry(prop: Node3D) -> Dictionary:
	var meshes: Array[GeometryInstance3D] = []
	var box := AABB()
	var first := true
	for n in prop.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		meshes.append(mi)
		var b := mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return {"meshes": meshes, "aabb": box, "fade": 0.0}
