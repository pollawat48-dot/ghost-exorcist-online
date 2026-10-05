extends Label3D
## ตัวเลขดาเมจ/ข้อความลอยขึ้นเหนือหัวแล้วจางหาย

var life := 0.9


static func spawn(parent: Node, pos: Vector3, t: String, c: Color) -> void:
	var node: Label3D = load("res://client/damage_text.gd").new()
	node.text = t
	node.modulate = c
	node.position = pos
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.font_size = 56
	node.outline_size = 14
	node.outline_modulate = Color(0, 0, 0, 0.9)
	node.pixel_size = 0.007
	node.no_depth_test = true
	node.render_priority = 10
	node.outline_render_priority = 9
	parent.add_child(node)


func _process(delta: float) -> void:
	life -= delta
	position.y += 1.2 * delta
	var a := clampf(life / 0.5, 0.0, 1.0)
	modulate.a = a
	outline_modulate.a = a * 0.9
	if life <= 0.0:
		queue_free()
