extends Node3D
## สัตว์เลี้ยงและชาวบ้านที่เดินเล่นในฉาก (ของประดับ ไม่มีผลกับเกม) ใช้โมเดลมีท่าทางจาก Kenney
## เดินสุ่มรอบจุดบ้านเฉพาะบนพื้นที่เดินได้ หยุดยืนเป็นพักๆ ทุกเครื่องเห็นไม่ตรงกันได้ (ไม่ส่งผ่านเซิร์ฟเวอร์)

const PerfOverlay = preload("res://client/ui/perf_overlay.gd")
const K = preload("res://maps/props/mesh_kit.gd")
const M = preload("res://maps/props/model_lib.gd")

## kind -> [ไฟล์, ขนาด, ความเร็ว (หน่วยเกม/วินาที), ท่าเดิน]
const KINDS := {
	"dog": ["cube-pets/animal-dog", 0.5, 50.0, "walk"],
	"cat": ["cube-pets/animal-cat", 0.45, 40.0, "walk"],
	"chick": ["cube-pets/animal-chick", 0.34, 30.0, "walk"],
	"pig": ["cube-pets/animal-pig", 0.55, 30.0, "walk"],
	"cow": ["cube-pets/animal-cow", 0.85, 22.0, "walk"],
	"elephant": ["cube-pets/animal-elephant", 1.4, 22.0, "walk"],
	"monkey": ["cube-pets/animal-monkey", 0.5, 55.0, "run"],
	"bunny": ["cube-pets/animal-bunny", 0.4, 45.0, "run"],
	"parrot": ["cube-pets/animal-parrot", 0.4, 45.0, "walk"],
	"crab": ["cube-pets/animal-crab", 0.4, 28.0, "walk"],
	"villager": ["", 1.85, 45.0, "walk"],
}
const VILLAGERS := ["character-female-a", "character-female-b", "character-female-c", "character-female-d", "character-female-e", "character-female-f",
	"character-male-a", "character-male-b", "character-male-e", "character-male-f"]

var kind := "dog"
var variant := 0
var home := Vector2.ZERO
var roam := 160.0
var map: Node  ## map_base: ใช้ is_walkable

var pos := Vector2.ZERO
var _target := Vector2.ZERO
var _wait := 0.0
var _speed := 40.0
var _walk_anim := "walk"
var _model: Node3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("no_fade")
	_rng.seed = variant * 7919 + int(home.x) * 31 + int(home.y)
	var info: Array = KINDS.get(kind, KINDS["dog"])
	var file: String = info[0]
	if kind == "villager":
		file = "mini-characters/" + VILLAGERS[variant % VILLAGERS.size()]
	_speed = info[2] * _rng.randf_range(0.85, 1.15)
	_walk_anim = info[3]
	_model = M.spawn(self, file, Vector3.ZERO, info[1])
	pos = home
	_target = home
	_wait = _rng.randf_range(0.0, 3.0)
	position = K.to3d(pos)
	rotation.y = _rng.randf() * TAU
	M.play(_model, "idle")


## ตัวจัดการระยะปิดการเดิน/ท่าทางของสัตว์ที่อยู่ไกลผู้เล่น (มองไม่เห็นอยู่แล้ว)
func set_awake(on: bool) -> void:
	set_process(on)
	var ap := _model.find_child("AnimationPlayer", true, false) as AnimationPlayer if _model != null else null
	if ap != null:
		ap.active = on


func _process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	_process_body(delta)
	PerfOverlay.add("สัตว์", Time.get_ticks_usec() - t0)


func _process_body(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			_pick_target()
		return
	var to := _target - pos
	var step := _speed * delta
	if to.length() <= step:
		pos = _target
		_wait = _rng.randf_range(1.5, 5.0)
		M.play(_model, "idle")
	else:
		var dir := to.normalized()
		pos += dir * step
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.y), minf(1.0, delta * 8.0))
	position = K.to3d(pos)


func _pick_target() -> void:
	for i in 8:
		var a := _rng.randf() * TAU
		var p := home + Vector2(cos(a), sin(a)) * _rng.randf_range(roam * 0.2, roam)
		if _clear_line(pos, p):
			_target = p
			M.play(_model, _walk_anim, 1.0)
			return
	_wait = _rng.randf_range(1.0, 3.0)


func _clear_line(a: Vector2, b: Vector2) -> bool:
	if map == null:
		return true
	var n := int(a.distance_to(b) / 16.0) + 1
	for i in range(1, n + 1):
		var p := a.lerp(b, float(i) / n)
		if not map.is_walkable(p) or map.is_water(p):
			return false
	return true
