extends "res://client/ui/game_window.gd"
## หน้าต่างตั้งค่า: ความดังเพลง/เสียงเอฟเฟกต์ ปิดเสียง คุณภาพภาพ และออกไปหน้าเมนู (บันทึกตัวละครก่อน)

const Sound = preload("res://client/audio/sound.gd")
const Graphics = preload("res://client/graphics.gd")
const PerfOverlay = preload("res://client/ui/perf_overlay.gd")

signal logout_requested


func _ready() -> void:
	setup("ตั้งค่า", 420)


func _build() -> void:
	section("เสียง")
	for entry in [["Music", "เพลง"], ["SFX", "เสียงเอฟเฟกต์"]]:
		var bus: String = entry[0]
		var r := row()
		r.add_child(icon("music" if bus == "Music" else "water", 26))
		var l := P.label(entry[1], 15)
		l.custom_minimum_size.x = 120
		r.add_child(l)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = Sound.get_volume(self, bus)
		slider.custom_minimum_size = Vector2(200, 28)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value_changed.connect(func(v: float): Sound.set_volume(self, bus, v))
		r.add_child(slider)
	var mute := CheckBox.new()
	mute.text = "ปิดเสียงทั้งหมด"
	mute.add_theme_color_override("font_color", P.TEXT)
	mute.button_pressed = Sound.is_muted(self)
	mute.toggled.connect(func(on: bool): Sound.set_muted(self, on))
	content.add_child(mute)
	section("คุณภาพภาพ")
	var gr := row()
	for l in Graphics.LEVELS:
		var b := P.button(Graphics.NAMES[l], P.PINK if l == Graphics.level() else Color(1, 1, 1, 0.9), 14)
		b.custom_minimum_size.x = 72
		b.pressed.connect(func():
			Graphics.set_level(get_tree(), l)
			refresh())
		gr.add_child(b)
	var hint := P.label("สูง/สูงสุด: ภาพคม เงาละเอียด แสงสะท้อน โมเดลเนียน (ใช้เครื่องแรงขึ้น)\nมือถือแนะนำ ประหยัด หรือ ต่ำ", 12, P.TEXT.lightened(0.2))
	content.add_child(hint)
	var fps := CheckBox.new()
	fps.text = "แสดง FPS และภาระเครื่อง (มุมซ้ายบน)"
	fps.add_theme_color_override("font_color", P.TEXT)
	fps.button_pressed = PerfOverlay.enabled()
	fps.toggled.connect(func(on: bool): PerfOverlay.set_enabled(get_tree(), on))
	content.add_child(fps)
	section("บัญชี")
	content.add_child(P.label("ตัวละครจะถูกบันทึกก่อนออก", 13, P.TEXT.lightened(0.2)))
	var out := P.button("ออกไปหน้าเมนู / เปลี่ยนตัวละคร", P.PINK, 15)
	out.pressed.connect(func():
		hide_window()
		logout_requested.emit())
	content.add_child(out)
