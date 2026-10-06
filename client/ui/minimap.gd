extends Control
## แผนที่ย่อมุมขวาบน: วาดภาพพื้นจากข้อมูลแผนที่ครั้งเดียว แล้วจุดผู้เล่น/ผีทุกเฟรม

const P = preload("res://client/ui/palette.gd")
const PX := 20.0  ## หน่วยเกมต่อ 1 พิกเซลของภาพแผนที่

var map: Node3D
var player: Node3D
var ghosts: Node
var npcs: Node
var portals: Node
var tex: ImageTexture


func setup(m: Node3D, p: Node3D, g: Node, npc_root: Node = null, portal_root: Node = null) -> void:
	map = m
	player = p
	ghosts = g
	npcs = npc_root
	portals = portal_root
	var w := int(map.world_rect.size.x / PX)
	var h := int(map.world_rect.size.y / PX)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var wp: Vector2 = map.world_rect.position + Vector2(x + 0.5, y + 0.5) * PX
			img.set_pixel(x, y, _color_at(wp))
	tex = ImageTexture.create_from_image(img)
	queue_redraw()


func _color_at(p: Vector2) -> Color:
	return map.minimap_color(p)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var frame := Rect2(Vector2.ZERO, size)
	draw_style_box(P.panel_style(16), frame)
	if tex == null:
		return
	var inner := frame.grow(-7)
	draw_texture_rect(tex, inner, false)
	draw_rect(inner, Color(P.LAVENDER, 0.6), false, 2.0)
	var to_map := func(wp: Vector2) -> Vector2:
		return inner.position + (wp - map.world_rect.position) / map.world_rect.size * inner.size
	if portals != null:
		for gate in portals.get_children():
			var gp: Vector2 = to_map.call(gate.pos)
			draw_circle(gp, 6.0, Color(0.6, 0.85, 1.0))
			draw_arc(gp, 6.0, 0, TAU, 20, Color.WHITE, 2.0, true)
	if npcs != null:
		for n in npcs.get_children():
			var np: Vector2 = to_map.call(n.pos)
			draw_circle(np, 4.5, Color(0.45, 0.85, 0.55) if n.role() == "quest" else Color(1.0, 0.75, 0.3))
			draw_arc(np, 4.5, 0, TAU, 16, Color.WHITE, 1.5, true)
	var boss: Node3D = null
	for g in ghosts.get_children():
		if g.has_method("take_damage") and g.alive:
			if g.is_boss():
				boss = g
			else:
				draw_circle(to_map.call(g.pos), 3.0, Color(0.62, 0.42, 0.85))
	if boss != null:
		# บอส: วงกระพริบสีชมพู + มงกุฎ
		var bp: Vector2 = to_map.call(boss.pos)
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0)
		draw_circle(bp, 9.0 + pulse * 5.0, Color(1.0, 0.35, 0.55, 0.35))
		draw_circle(bp, 8.0, Color(1.0, 0.45, 0.6))
		draw_arc(bp, 8.0, 0, TAU, 24, Color.WHITE, 2.0, true)
		P.draw_icon(self, "crown", bp + Vector2(0, -1), 12.0)
	if player != null:
		var pp: Vector2 = to_map.call(player.pos)
		draw_circle(pp, 6.0, Color.WHITE)
		draw_circle(pp, 4.5, P.PINK_DEEP)
