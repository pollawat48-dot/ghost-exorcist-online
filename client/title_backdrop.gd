extends Node3D
## ฉากหลังหน้าเมนู: หมู่บ้านริมคลองยามเย็น กล้องหมุนช้าๆ และตัวละครตัวอย่างยืนให้ดูตอนสร้างตัวละคร

const K = preload("res://maps/props/mesh_kit.gd")
const Village = preload("res://maps/thailand/khlong_village.gd")
const Ambience = preload("res://client/ambience.gd")
const Avatar = preload("res://client/avatar.gd")

const FOCUS := Vector2(550, 1090)  ## ทางดินหน้าวัด (กล้องมองจากทางเดินทิศใต้)

var map: Node3D
var ambience: Node3D
var camera: Camera3D
var avatar: Node3D
var yaw := 0.6
var close_up := false  ## ซูมเข้าหาตัวละคร (หน้าสร้าง/เลือกตัวละคร)
var _zoom := 0.0


func _ready() -> void:
	load("res://client/graphics.gd").level()  # ตั้งความละเอียดโมเดลก่อนสร้างฉาก
	map = Village.new()
	add_child(map)
	add_child(map.build_props())
	ambience = Ambience.new()
	add_child(ambience)
	ambience.setup(map)
	ambience.time_of_day = 0.7
	ambience.tick(0.0)
	camera = Camera3D.new()
	camera.fov = 42.0
	camera.far = 300.0
	add_child(camera)
	avatar = Avatar.new()
	avatar.position = K.to3d(FOCUS)
	avatar.visible = false
	add_child(avatar)
	_update_camera(0.0)


## แสดงตัวละครตัวอย่าง (class_id ว่าง = ซ่อน)
func show_avatar(class_id: String, look: Dictionary, equipment: Dictionary = {}, display_name: String = "") -> void:
	if class_id == "":
		avatar.visible = false
		close_up = false
		return
	avatar.build(class_id, look, equipment, display_name)
	avatar.visible = true
	close_up = true


func _process(delta: float) -> void:
	_update_camera(delta)
	if avatar.visible:
		avatar.animate(delta, false, Vector2.ZERO, 0.0, false, 0.0)


func _update_camera(delta: float) -> void:
	yaw += delta * (0.05 if not close_up else 0.0)
	_zoom = move_toward(_zoom, 1.0 if close_up else 0.0, delta * 1.5)
	var center := K.to3d(FOCUS) + Vector3(0, 1.0, 0)
	var dist := lerpf(26.0, 6.5, _zoom)
	var pitch := lerpf(deg_to_rad(32.0), deg_to_rad(12.0), _zoom)
	var y := lerpf(yaw, 0.0, _zoom)
	camera.position = center + Vector3(sin(y) * cos(pitch), sin(pitch), cos(y) * cos(pitch)) * dist
	# ซูมใกล้: เลื่อนกล้องให้ตัวละครอยู่ฝั่งซ้ายของจอ (แผงเมนูอยู่ขวา)
	camera.look_at(center + Vector3(1.6 * _zoom, 0.1 * _zoom, 0), Vector3.UP)
	if avatar.visible:
		avatar.model.rotation.y = lerp_angle(avatar.model.rotation.y, 0.25 + sin(Time.get_ticks_msec() / 1400.0) * 0.25, 0.1)
