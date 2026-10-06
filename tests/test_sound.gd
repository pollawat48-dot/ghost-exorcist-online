extends SceneTree
## ทดสอบระบบเสียงสังเคราะห์: godot --headless --path . --script res://tests/test_sound.gd

const Sound = preload("res://client/audio/sound.gd")

var failures := 0


func _initialize() -> void:
	_run_all()


func check(cond: bool, name: String) -> void:
	if cond:
		print("  ok   ", name)
	else:
		failures += 1
		printerr("  FAIL ", name)


func _run_all() -> void:
	print("== headless: play/music ไม่ทำอะไร ==")
	check(Sound.is_headless(), "ตรวจพบโหมด headless")
	Sound.play(root, "hit")
	Sound.play(root, "ไม่มีจริง")
	Sound.music(root, "village")
	Sound.music(root, "")
	check(Sound._sfx_cache.is_empty() and Sound._music_cache.is_empty(), "play/music ใน headless ไม่สังเคราะห์เสียง")
	check(root.get_node_or_null("Sound") == null, "play/music ใน headless ไม่สร้างโหนด")
	check(Sound.synth("ไม่มีจริง") == null, "id ที่ไม่รู้จักคืน null")

	print("== เอฟเฟกต์ ==")
	var t0 := Time.get_ticks_usec()
	for id in Sound.SFX_IDS:
		var w: AudioStreamWAV = Sound.synth(id)
		var ok := w != null and w.data.size() > 0 and w.format == AudioStreamWAV.FORMAT_16_BITS
		var sec := 0.0
		if ok:
			sec = w.data.size() / 2.0 / w.mix_rate
			ok = sec > 0.02 and sec < 3.0 and w.loop_mode == AudioStreamWAV.LOOP_DISABLED and _has_signal(w)
		check(ok, "sfx %s (%.2f s)" % [id, sec])
	print("  สร้างเอฟเฟกต์ทั้งหมด %d เสียง ใช้ %.0f ms" % [Sound.SFX_IDS.size(), (Time.get_ticks_usec() - t0) / 1000.0])
	check(Sound.synth("hit") == Sound.synth("hit"), "แคชเอฟเฟกต์")

	print("== เพลง ==")
	for mood in Sound.MOODS:
		var t := Time.get_ticks_usec()
		var w: AudioStreamWAV = Sound.synth_music(mood)
		var ms := (Time.get_ticks_usec() - t) / 1000.0
		var ok := w != null and w.loop_mode == AudioStreamWAV.LOOP_FORWARD and w.data.size() > 0
		var sec := 0.0
		if ok:
			sec = w.data.size() / 2.0 / w.mix_rate
			ok = sec >= 10.0 and sec <= 30.0 and w.loop_end == w.data.size() / 2 and _has_signal(w)
		check(ok, "เพลง %s วนลูป %.1f s" % [mood, sec])
		check(ms < 2000.0, "เพลง %s สร้างเสร็จใน %.0f ms" % [mood, ms])
	check(Sound.synth_music("ไม่มี") == null, "mood ที่ไม่รู้จักคืน null")

	print("== ความดัง ==")
	var path := "user://test_sound_settings.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var old_path: String = Sound.config_path
	Sound.use_config(path)
	check(is_equal_approx(Sound.get_volume(root, "Music"), 0.6), "ค่าเริ่มต้นเพลง 0.6")
	check(is_equal_approx(Sound.get_volume(root, "SFX"), 0.8), "ค่าเริ่มต้นเอฟเฟกต์ 0.8")
	Sound.set_volume(root, "Music", 0.25)
	Sound.set_volume(root, "SFX", 0.5)
	Sound.set_muted(root, true)
	check(AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("SFX") >= 0, "สร้างบัส Music/SFX")
	check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), linear_to_db(0.25)), "ตั้งความดังบัส Music แล้ว")
	Sound.use_config(path)  # โหลดจากไฟล์ใหม่
	check(is_equal_approx(Sound.get_volume(root, "Music"), 0.25), "บันทึก/โหลดความดังเพลง")
	check(is_equal_approx(Sound.get_volume(root, "SFX"), 0.5), "บันทึก/โหลดความดังเอฟเฟกต์")
	check(Sound.is_muted(root), "บันทึก/โหลดปิดเสียง")
	Sound.set_muted(root, false)
	check(not Sound.is_muted(root), "เปิดเสียงคืน")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Sound.use_config(old_path)

	if failures == 0:
		print("ผ่านทั้งหมด")
	else:
		printerr("ล้มเหลว %d รายการ" % failures)
	quit(1 if failures > 0 else 0)


func _has_signal(w: AudioStreamWAV) -> bool:
	var d := w.data
	var peak := 0
	for i in range(0, d.size(), 64):
		peak = maxi(peak, absi(d.decode_s16(i)))
	return peak > 1000
