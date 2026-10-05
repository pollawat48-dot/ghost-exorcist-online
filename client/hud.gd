extends CanvasLayer
## หน้าจอข้อมูลผู้เล่น: HP/SP/EXP, กระเป๋า, ชื่อแผนที่, เวลา, ข้อความ, ปุ่มลัด

const ItemDB = preload("res://shared/data/items.gd")
const Progression = preload("res://shared/combat/progression.gd")

const MAX_LOG_LINES := 5

var player: Node3D
var camera: Camera3D
var ghosts: Node
var bars: Control
var info: Label
var hp_bar: ProgressBar
var sp_bar: ProgressBar
var exp_bar: ProgressBar
var inv_label: Label
var log_label: Label
var location_label: Label
var phase_label: Label
var lines: Array[String] = []


func _ready() -> void:
	layer = 5
	var view := Vector2(1280, 720)
	bars = Control.new()
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.draw.connect(_draw_bars)
	add_child(bars)

	var status := _panel(Vector2(12, 12), 260)
	info = Label.new()
	status.add_child(info)
	hp_bar = _bar(status, Color(0.85, 0.2, 0.2))
	sp_bar = _bar(status, Color(0.25, 0.5, 0.95))
	exp_bar = _bar(status, Color(0.95, 0.8, 0.25))

	var inv := _panel(Vector2(view.x - 268, 12), 240)
	inv_label = Label.new()
	inv.add_child(inv_label)

	var log_box := _panel(Vector2(12, view.y - 196), 460)
	log_label = Label.new()
	log_label.custom_minimum_size = Vector2(460, 140)
	log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	log_box.add_child(log_label)

	var banner := _panel(Vector2(view.x / 2.0 - 140, 12), 280)
	location_label = Label.new()
	location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location_label.add_theme_color_override("font_color", Color(1, 0.88, 0.55))
	banner.add_child(location_label)
	phase_label = Label.new()
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_child(phase_label)

	var help := Label.new()
	help.text = "คลิกซ้าย: เดิน / โจมตีผี    1: โปรยน้ำมนต์    Q: ใช้ยาหอมสมุนไพร"
	help.position = Vector2(12, view.y - 30)
	help.add_theme_color_override("font_outline_color", Color.BLACK)
	help.add_theme_constant_override("outline_size", 4)
	add_child(help)


## วาดหลอด HP เหนือหัวผีที่โดนตี
func track(cam: Camera3D, ghost_root: Node) -> void:
	camera = cam
	ghosts = ghost_root


func _process(_delta: float) -> void:
	if bars != null:
		bars.queue_redraw()


func _draw_bars() -> void:
	if camera == null:
		return
	for g in ghosts.get_children():
		if not g.has_method("take_damage") or not g.alive or g.hp >= g.data["hp"]:
			continue
		var p3: Vector3 = g.global_position + Vector3(0, 1.85, 0)
		if camera.is_position_behind(p3):
			continue
		var p := camera.unproject_position(p3)
		var ratio := float(g.hp) / float(g.data["hp"])
		bars.draw_rect(Rect2(p.x - 24, p.y, 48, 6), Color(0, 0, 0, 0.7))
		bars.draw_rect(Rect2(p.x - 23, p.y + 1, 46 * ratio, 4), Color(0.9, 0.2, 0.2))


func bind(p: Node3D) -> void:
	player = p
	player.changed.connect(refresh)
	player.message.connect(add_log)
	refresh()


func refresh() -> void:
	var s: Dictionary = player.stats
	var level: int = player.state["level"]
	var need := Progression.exp_to_next(level)
	info.text = "%s  Lv.%d\nHP %d/%d   SP %d/%d   EXP %d/%d" % [
		player.player_name, level, player.hp, s["max_hp"], player.sp, s["max_sp"], player.state["exp"], need]
	hp_bar.max_value = s["max_hp"]
	hp_bar.value = player.hp
	sp_bar.max_value = s["max_sp"]
	sp_bar.value = player.sp
	exp_bar.max_value = need
	exp_bar.value = player.state["exp"]

	var text := "กระเป๋า"
	for item_id in player.inventory:
		text += "\n• %s x%d" % [ItemDB.ITEMS[item_id]["name"], player.inventory[item_id]]
	inv_label.text = text


func set_location(country: String, map_name: String) -> void:
	location_label.text = "%s · %s" % [country, map_name]


func set_phase(text: String) -> void:
	phase_label.text = text
	phase_label.add_theme_color_override("font_color",
		Color(0.7, 0.8, 1.0) if text == "กลางคืน" else Color(1, 1, 0.85))


func add_log(text: String) -> void:
	lines.append(text)
	if lines.size() > MAX_LOG_LINES:
		lines.pop_front()
	log_label.text = "\n".join(lines)


func _panel(pos: Vector2, width: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.08, 0.75)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(width, 0)
	panel.add_child(box)
	return box


func _bar(parent: Control, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 12)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	parent.add_child(bar)
	return bar
