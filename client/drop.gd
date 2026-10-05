extends Node2D
## ไอเทมที่ตกอยู่บนพื้น เดินทับเพื่อเก็บ

const ItemDB = preload("res://shared/data/items.gd")

var item_id := ""
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var y := sin(t * 4.0) * 2.0
	var c: Color = ItemDB.ITEMS[item_id]["color"]
	if ItemDB.ITEMS[item_id]["type"] == "soul":
		draw_circle(Vector2(0, y), 12.0, Color(c, 0.3))
	draw_circle(Vector2(0, 7), 5.0, Color(0, 0, 0, 0.25))
	var pts := PackedVector2Array([Vector2(0, y - 7), Vector2(6, y), Vector2(0, y + 7), Vector2(-6, y)])
	draw_colored_polygon(pts, c)
	pts.append(pts[0])
	draw_polyline(pts, Color(0, 0, 0, 0.6), 1.0)
