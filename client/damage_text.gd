extends Node2D
## ตัวเลขดาเมจ/ข้อความลอยขึ้นแล้วจางหาย

var text := ""
var color := Color.WHITE
var life := 0.9


static func spawn(parent: Node, pos: Vector2, t: String, c: Color) -> void:
	var node: Node2D = load("res://client/damage_text.gd").new()
	node.text = t
	node.color = c
	node.position = pos
	node.z_index = 10
	parent.add_child(node)


func _process(delta: float) -> void:
	life -= delta
	position.y -= 35.0 * delta
	modulate.a = clampf(life / 0.5, 0.0, 1.0)
	if life <= 0.0:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string_outline(font, Vector2(-40, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 80, 16, 4, Color.BLACK)
	draw_string(font, Vector2(-40, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 80, 16, color)
