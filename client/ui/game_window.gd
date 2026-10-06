extends PanelContainer
## หน้าต่างเมนูพาสเทล (ตัวละคร/สกิล/กระเป๋า/เลื่อนขั้น): มีหัวเรื่อง ปุ่มปิด และสร้างเนื้อหาใหม่ทุกครั้งที่ข้อมูลเปลี่ยน

const P = preload("res://client/ui/palette.gd")

signal closed

var player: Node3D
var content: VBoxContainer
var title_label: Label


func setup(title: String, width: float) -> void:
	add_theme_stylebox_override("panel", P.panel_style(20))
	add_to_group(P.UI_BLOCK)  # ปุ่มบนจอที่อยู่ใต้หน้าต่างจะไม่รับการกด
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var bar := HBoxContainer.new()
	root.add_child(bar)
	title_label = P.label(title, 21)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(title_label)
	var close := P.button("ปิด ✕", P.PINK)
	close.pressed.connect(hide_window)
	bar.add_child(close)
	content = VBoxContainer.new()
	content.custom_minimum_size.x = width
	content.add_theme_constant_override("separation", 6)
	root.add_child(content)
	visible = false


func bind(p: Node3D) -> void:
	player = p
	player.changed.connect(_on_player_changed)


func _on_player_changed() -> void:
	if visible:
		refresh()


func show_window() -> void:
	visible = true
	refresh()


func hide_window() -> void:
	visible = false
	closed.emit()


func refresh() -> void:
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	_build()
	reset_size()
	_recenter.call_deferred()


func _recenter() -> void:
	reset_size()
	var view := get_viewport_rect().size
	position = ((view - size) / 2.0).floor()


## ให้หน้าต่างลูกสร้างเนื้อหาในนี้
func _build() -> void:
	pass


func icon(kind: String, s: float = 30.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(s, s)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func(): P.draw_icon(c, kind, c.size / 2.0, s))
	return c


func row() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	content.add_child(h)
	return h


func section(text: String) -> void:
	var l := P.label(text, 16, P.PINK_DEEP)
	content.add_child(l)
