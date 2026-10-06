extends Node3D
## กล้องมุมสูงแบบ RO: ตามผู้เล่น, ล้อเมาส์ซูม, คลิกขวาลากเพื่อหมุน

var target: Node3D
var yaw := 0.0
var pitch := deg_to_rad(50.0)
var distance := 20.0
var camera: Camera3D
var _dragging := false


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 45.0
	camera.far = 300.0
	add_child(camera)
	snap()


func snap() -> void:
	if target != null:
		position = target.global_position
	_update_camera()


func _process(delta: float) -> void:
	if target != null:
		position = position.lerp(target.global_position, 1.0 - exp(-delta * 8.0))
	_update_camera()


func _update_camera() -> void:
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
	camera.position = offset + Vector3(0, 1.0, 0)
	camera.look_at(global_position + Vector3(0, 1.0, 0), Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			distance = maxf(7.0, distance - 1.2)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			distance = minf(32.0, distance + 1.2)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		yaw -= event.relative.x * 0.008
		pitch = clampf(pitch + event.relative.y * 0.005, deg_to_rad(25.0), deg_to_rad(75.0))


## จุดบนพื้น (หน่วยตรรกะเกม) ที่เมาส์ชี้
func ground_point(screen: Vector2) -> Vector2:
	var from := camera.project_ray_origin(screen)
	var dir := camera.project_ray_normal(screen)
	if absf(dir.y) < 0.0001:
		return Vector2(from.x, from.z) * 32.0
	var hit := from + dir * (-from.y / dir.y)
	return Vector2(hit.x, hit.z) * 32.0
