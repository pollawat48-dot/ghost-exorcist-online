extends Node2D
## แผนที่แรก: หมู่บ้านวัดป่า (ซ้าย) + ทุ่งป่าช้า (ขวา)
## วาดด้วยโค้ดเป็นภาพชั่วคราว จะเปลี่ยนเป็น TileMap + sprite จริงทีหลัง

const WORLD_RECT := Rect2(0, 0, 2400, 1600)
const TOWN_RECT := Rect2(0, 0, 800, 1600)
const FIELD_RECT := Rect2(950, 150, 1350, 1300)
const TEMPLE_RECT := Rect2(320, 640, 200, 150)
const SPAWN_POINT := Vector2(420, 860)
const SPAWNS := [
	{"id": "krasue_noi", "count": 7},
	{"id": "phi_takiang", "count": 5},
]

var decor: Array[Dictionary] = []


func _ready() -> void:
	z_index = -10
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 70:
		var pos := Vector2(rng.randf_range(20, 2380), rng.randf_range(20, 1580))
		if TEMPLE_RECT.grow(60).has_point(pos) or absf(pos.y - 900) < 70:
			continue
		var in_field := pos.x > 850
		decor.append({"pos": pos, "type": "grave" if in_field and rng.randf() < 0.45 else "tree"})


func _draw() -> void:
	draw_rect(WORLD_RECT, Color(0.16, 0.28, 0.19))
	draw_rect(TOWN_RECT, Color(0.52, 0.47, 0.38))
	draw_rect(Rect2(800, 0, 40, 1600), Color(0.35, 0.3, 0.24))
	draw_rect(Rect2(450, 860, 1950, 80), Color(0.42, 0.36, 0.27))

	# วัด
	draw_rect(TEMPLE_RECT, Color(0.88, 0.83, 0.72))
	var roof := PackedVector2Array([
		TEMPLE_RECT.position + Vector2(-25, 0),
		TEMPLE_RECT.position + Vector2(TEMPLE_RECT.size.x + 25, 0),
		TEMPLE_RECT.position + Vector2(TEMPLE_RECT.size.x / 2.0, -90)])
	draw_colored_polygon(roof, Color(0.75, 0.2, 0.12))
	draw_rect(Rect2(TEMPLE_RECT.get_center().x - 18, TEMPLE_RECT.end.y - 50, 36, 50), Color(0.45, 0.25, 0.1))

	for d in decor:
		var p: Vector2 = d["pos"]
		if d["type"] == "tree":
			draw_circle(p + Vector2(0, 14), 14.0, Color(0, 0, 0, 0.25))
			draw_rect(Rect2(p.x - 3, p.y, 6, 14), Color(0.35, 0.22, 0.1))
			draw_circle(p, 16.0, Color(0.12, 0.38, 0.18))
		else:
			draw_rect(Rect2(p.x - 7, p.y - 12, 14, 18), Color(0.55, 0.55, 0.58))
			draw_line(p + Vector2(-4, -6), p + Vector2(4, -6), Color(0.3, 0.3, 0.32), 1.5)

	var font := ThemeDB.fallback_font
	draw_string_outline(font, Vector2(220, 540), "วัดป่า", HORIZONTAL_ALIGNMENT_CENTER, 400, 28, 5, Color.BLACK)
	draw_string(font, Vector2(220, 540), "วัดป่า", HORIZONTAL_ALIGNMENT_CENTER, 400, 28, Color(1, 0.9, 0.6))
	draw_string_outline(font, Vector2(1400, 120), "ทุ่งป่าช้า", HORIZONTAL_ALIGNMENT_CENTER, 400, 28, 5, Color.BLACK)
	draw_string(font, Vector2(1400, 120), "ทุ่งป่าช้า", HORIZONTAL_ALIGNMENT_CENTER, 400, 28, Color(0.8, 0.9, 1))
