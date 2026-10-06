extends Node
## ระบบเสียงสังเคราะห์ล้วน ไม่มีไฟล์เสียงเลย: เอฟเฟกต์ (SFX) และเพลงประกอบแต่ละแผนที่
## สร้าง AudioStreamWAV (16 บิต โมโน) ด้วยออสซิลเลเตอร์ เอนเวโลป และนอยส์ง่าย ๆ แล้วแคชไว้
## ใช้ผ่านฟังก์ชัน static: Sound.play(self, "hit"), Sound.music(self, "village")
## โหนดเดี่ยวชื่อ "Sound" ถูกสร้างเองใต้ root ตอนเรียกครั้งแรก (ไม่ใช้ autoload เพราะเทสต์รันด้วย --script)
## ตอนรันแบบ headless/ไดรเวอร์เสียง Dummy: play/music ไม่ทำอะไรเลยและไม่สังเคราะห์เสียง

const SELF_PATH := "res://client/audio/sound.gd"
const RATE := 22050
const MUSIC_RATE := 22050
const POOL_SIZE := 12
const THROTTLE_MS := 50
const FADE_TIME := 1.5
const DEFAULT_MUSIC := 0.6
const DEFAULT_SFX := 0.8

const SINE := 0
const TRI := 1
const SQUARE := 2
const SAW := 3
const NOISE := 4

const SFX_IDS := [
	"click", "open", "hit", "crit", "swing", "arrow", "magic", "fire", "holy", "heal",
	"buff", "levelup", "coin", "pickup", "potion", "hurt", "ghost_hit", "ghost_die", "boss", "warp",
	"chat", "whisper", "party", "mine", "ore", "splash", "catch", "rare", "refine_ok", "refine_fail",
	"refine_down", "error",
]
const MOODS := ["title", "village", "field", "dark", "cave", "stream"]
## เสียงที่มีโน้ตชัด สุ่มระดับเสียงน้อยกว่า จะได้ไม่เพี้ยน
const TONAL := [
	"holy", "heal", "buff", "levelup", "coin", "whisper", "party", "ore", "catch", "rare",
	"refine_ok", "boss", "open", "click",
]

## ไฟล์ตั้งค่า (เปลี่ยนได้ในเทสต์ผ่าน use_config)
static var config_path := "user://settings.cfg"
static var _sfx_cache := {}
static var _music_cache := {}
static var _settings := {}
static var _settings_loaded := false
static var _node: Node = null
static var _headless_state := -1
static var _seed := 12345

var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _last := {}
var _mus: Array[AudioStreamPlayer] = []
var _cur := 0
var _mood := ""
var _playing_mood := ""
var _tween: Tween
var _task := -1
var _task_mood := ""
var _task_result: AudioStreamWAV


# ---------------------------------------------------------------- API สาธารณะ

## เล่นเอฟเฟกต์ครั้งเดียว (สุ่มระดับเสียงนิดหน่อย, id เดียวกันเล่นได้ไม่เกิน ~1 ครั้งต่อ 50 มิลลิวินาที)
static func play(from: Node, id: String, volume_db: float = 0.0) -> void:
	if is_headless() or not SFX_IDS.has(id):
		return
	var n = _get_node(from)
	if n != null:
		n._play_sfx(id, volume_db)


## เปลี่ยนเพลงพื้นหลัง (ครอสเฟด ~1.5 วินาที), "" = หยุดเพลง
static func music(from: Node, mood: String) -> void:
	if is_headless():
		return
	if mood != "" and not MOODS.has(mood):
		return
	var n = _get_node(from)
	if n != null:
		n._mood = mood
		if n.is_inside_tree():
			n._apply_music()


## ตั้งความดังของบัส "Music" หรือ "SFX" (0..1) และบันทึกลงไฟล์ตั้งค่า
static func set_volume(_from: Node, bus: String, linear: float) -> void:
	_load_settings()
	_settings[bus] = clampf(linear, 0.0, 1.0)
	_ensure_buses()
	_apply_bus(bus)
	_save_settings()


static func get_volume(_from: Node, bus: String) -> float:
	_load_settings()
	return float(_settings.get(bus, 1.0))


## ปิดเสียงทั้งหมด (บัส Master)
static func set_muted(_from: Node, on: bool) -> void:
	_load_settings()
	_settings["muted"] = on
	_ensure_buses()
	AudioServer.set_bus_mute(0, on)
	_save_settings()


static func is_muted(_from: Node) -> bool:
	_load_settings()
	return bool(_settings.get("muted", false))


## เปลี่ยนไฟล์ตั้งค่าแล้วโหลดใหม่ (ใช้ในเทสต์)
static func use_config(path: String) -> void:
	config_path = path
	_settings_loaded = false
	_load_settings()


static func is_headless() -> bool:
	if _headless_state < 0:
		_headless_state = 0
		if DisplayServer.get_name() == "headless":
			_headless_state = 1
		var args := OS.get_cmdline_args()
		var i := args.find("--audio-driver")
		if i >= 0 and i + 1 < args.size() and args[i + 1] == "Dummy":
			_headless_state = 1
	return _headless_state == 1


## สังเคราะห์เอฟเฟกต์ (แคชไว้), id ที่ไม่รู้จักคืน null
static func synth(id: String) -> AudioStreamWAV:
	if _sfx_cache.has(id):
		return _sfx_cache[id]
	if not SFX_IDS.has(id):
		return null
	var w := _build_sfx(id)
	_sfx_cache[id] = w
	return w


## สังเคราะห์เพลงวนลูป (แคชไว้), mood ที่ไม่รู้จักคืน null
static func synth_music(mood: String) -> AudioStreamWAV:
	if _music_cache.has(mood):
		return _music_cache[mood]
	if not MOODS.has(mood):
		return null
	var w := _build_music(mood)
	_music_cache[mood] = w
	return w


# ---------------------------------------------------------------- โหนดเดี่ยว

static func _get_node(from: Node):
	if is_instance_valid(_node):
		return _node
	if from == null or not from.is_inside_tree():
		return null
	_ensure_buses()
	var n: Node = load(SELF_PATH).new()
	n.name = "Sound"
	from.get_tree().root.add_child.call_deferred(n)
	_node = n
	return n


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.bus = "Music"
		m.volume_db = -60.0
		add_child(m)
		_mus.append(m)
	set_process(false)
	if _mood != "":
		_apply_music()


func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	if _node == self:
		_node = null


func _play_sfx(id: String, volume_db: float) -> void:
	if not is_inside_tree() or _pool.is_empty():
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(id, -100000)) < THROTTLE_MS:
		return
	_last[id] = now
	var stream := synth(id)
	if stream == null:
		return
	var p: AudioStreamPlayer = null
	for i in POOL_SIZE:
		var c := _pool[(_next + i) % POOL_SIZE]
		if not c.playing:
			p = c
			_next = (_next + i + 1) % POOL_SIZE
			break
	if p == null:
		p = _pool[_next]
		_next = (_next + 1) % POOL_SIZE
	var spread := 0.02 if TONAL.has(id) else 0.07
	p.stream = stream
	p.pitch_scale = randf_range(1.0 - spread, 1.0 + spread)
	p.volume_db = volume_db
	p.play()


func _apply_music() -> void:
	if _mood == _playing_mood:
		return
	if _mood == "":
		_playing_mood = ""
		_crossfade(null)
		return
	if _music_cache.has(_mood):
		_playing_mood = _mood
		_crossfade(_music_cache[_mood])
		return
	if _task >= 0:
		return
	# สร้างเพลงในเธรดเบื้องหลัง จะได้ไม่กระตุกตอนเปลี่ยนแผนที่
	_task_mood = _mood
	_task = WorkerThreadPool.add_task(_worker.bind(_task_mood), false, "Sound music")
	set_process(true)


func _worker(m: String) -> void:
	_task_result = _build_music(m)


func _process(_dt: float) -> void:
	if _task >= 0 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
		_music_cache[_task_mood] = _task_result
		_task_result = null
		_apply_music()
	if _task < 0:
		set_process(false)


func _crossfade(stream: AudioStreamWAV) -> void:
	if _mus.size() < 2:
		return
	var old := _mus[_cur]
	if stream == null and not old.playing:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	if stream != null:
		_cur = 1 - _cur
		var nw := _mus[_cur]
		nw.stop()
		nw.stream = stream
		nw.volume_db = -60.0
		nw.play()
		_tween.tween_method(_fade.bind(nw), 0.0, 1.0, FADE_TIME)
	if old.playing:
		_tween.tween_method(_fade.bind(old), db_to_linear(old.volume_db), 0.0, FADE_TIME)
		_tween.chain().tween_callback(old.stop)


func _fade(v: float, p: AudioStreamPlayer) -> void:
	p.volume_db = linear_to_db(maxf(v, 0.001))


# ---------------------------------------------------------------- บัสและการตั้งค่า

static func _ensure_buses() -> void:
	var made := false
	for b in ["Music", "SFX"]:
		if AudioServer.get_bus_index(b) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
			made = true
	if made or not _settings_loaded:
		_load_settings()
		_apply_bus("Music")
		_apply_bus("SFX")
		AudioServer.set_bus_mute(0, bool(_settings.get("muted", false)))


static func _apply_bus(bus: String) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	var v := float(_settings.get(bus, 1.0))
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))
	AudioServer.set_bus_mute(i, v <= 0.001)


static func _load_settings() -> void:
	if _settings_loaded:
		return
	_settings_loaded = true
	var cfg := ConfigFile.new()
	cfg.load(config_path)
	_settings = {
		"Music": float(cfg.get_value("audio", "music", DEFAULT_MUSIC)),
		"SFX": float(cfg.get_value("audio", "sfx", DEFAULT_SFX)),
		"muted": bool(cfg.get_value("audio", "muted", false)),
	}


static func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(config_path)  # เก็บหมวดอื่นในไฟล์ไว้ด้วย
	cfg.set_value("audio", "music", _settings.get("Music", DEFAULT_MUSIC))
	cfg.set_value("audio", "sfx", _settings.get("SFX", DEFAULT_SFX))
	cfg.set_value("audio", "muted", _settings.get("muted", false))
	cfg.save(config_path)


# ---------------------------------------------------------------- ตัวสังเคราะห์พื้นฐาน

static func _buf(sec: float, rate: int = RATE) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(sec * rate))
	b.fill(0.0)
	return b


static func _midi(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)


## ออสซิลเลเตอร์หนึ่งเสียง บวกทับลงบัฟเฟอร์
## f0→f1 = ไถลความถี่แบบเอ็กซ์โพเนนเชียล, atk = เวลาเฟดเข้า, dec = อัตราลดเสียง (ต่อวินาที)
## wave NOISE: นอยส์ผ่าน low-pass โดยใช้ความถี่เป็นจุดตัด
## wrap = เลยท้ายบัฟเฟอร์แล้ววนกลับไปต้น (ใช้กับเพลงให้ลูปต่อเนื่อง), fade = เฟดออกท้ายโน้ต
static func _osc(b: PackedFloat32Array, rate: int, t0: float, dur: float, f0: float, f1: float,
		amp: float, wave: int, atk: float, dec: float, vib: float = 0.0, vib_rate: float = 0.0,
		wrap: bool = false, fade: bool = true) -> void:
	var n := b.size()
	var start := int(t0 * rate)
	var cnt := int(dur * rate)
	if cnt <= 0 or n == 0:
		return
	var inv := 1.0 / float(rate)
	var fmul := pow(f1 / f0, 1.0 / float(cnt))
	var f := f0
	var ph := 0.0
	var env := 1.0
	var dmul := exp(-dec * inv)
	var atk_n := maxi(1, int(atk * rate))
	var rel_n := mini(int(0.006 * rate), cnt >> 1) if fade else 0
	var lp := 0.0
	var vph := 0.0
	var vstep := vib_rate * inv
	var s_seed := _seed
	_seed = (_seed * 1103515245 + 12345) & 0x7fffffff
	for i in cnt:
		var idx := start + i
		if idx >= n:
			if not wrap:
				break
			idx = idx % n
		var s := 0.0
		if wave == SINE:
			s = sin(TAU * ph)
		elif wave == TRI:
			s = 4.0 * absf(ph - 0.5) - 1.0
		elif wave == SQUARE:
			s = 1.0 if ph < 0.5 else -1.0
		elif wave == SAW:
			s = 2.0 * ph - 1.0
		else:
			s_seed = (s_seed * 1103515245 + 12345) & 0x7fffffff
			var a := minf(1.0, TAU * f * inv)
			lp += (float(s_seed) / 1073741824.0 - 1.0 - lp) * a
			s = lp * minf(4.0, 0.8 / sqrt(a))
		var e := env
		if i < atk_n:
			e *= float(i) / float(atk_n)
		var left := cnt - i
		if left < rel_n:
			e *= float(left) / float(rel_n)
		b[idx] += s * e * amp
		env *= dmul
		if vib > 0.0:
			ph += f * (1.0 + vib * sin(TAU * vph)) * inv
			vph += vstep
		else:
			ph += f * inv
		ph -= floorf(ph)
		f *= fmul


## ทางลัดสำหรับเอฟเฟกต์ (22050 Hz, ไม่วน)
static func _t(b: PackedFloat32Array, t0: float, dur: float, f0: float, f1: float, amp: float,
		wave: int = SINE, atk: float = 0.003, dec: float = 8.0, vib: float = 0.0, vr: float = 0.0) -> void:
	_osc(b, RATE, t0, dur, f0, f1, amp, wave, atk, dec, vib, vr)


## ระฆัง/โลหะ: ฮาร์มอนิกไม่ลงตัวที่ลดเสียงเร็วต่างกัน
static func _bell(b: PackedFloat32Array, rate: int, t0: float, f: float, amp: float, dur: float, wrap: bool = false) -> void:
	_osc(b, rate, t0, dur, f, f, amp, SINE, 0.002, 3.0, 0.0, 0.0, wrap)
	_osc(b, rate, t0, dur * 0.8, f * 2.0, f * 2.0, amp * 0.45, SINE, 0.001, 5.0, 0.0, 0.0, wrap)
	_osc(b, rate, t0, dur * 0.6, f * 2.76, f * 2.76, amp * 0.3, SINE, 0.001, 8.0, 0.0, 0.0, wrap)
	_osc(b, rate, t0, dur * 0.4, f * 5.4, f * 5.4, amp * 0.15, SINE, 0.001, 14.0, 0.0, 0.0, wrap)


## แปลงเป็น AudioStreamWAV 16 บิต, ปรับความดังสูงสุดเป็น gain
static func _to_wav(b: PackedFloat32Array, rate: int, gain: float, loop: bool) -> AudioStreamWAV:
	var n := b.size()
	var peak := 0.0001
	for i in n:
		var a := absf(b[i])
		if a > peak:
			peak = a
	var k := gain * 32767.0 / peak
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(b[i] * k))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = n
	return w


# ---------------------------------------------------------------- เอฟเฟกต์

static func _build_sfx(id: String) -> AudioStreamWAV:
	var b: PackedFloat32Array
	var gain := 0.8
	match id:
		"click":
			b = _buf(0.06)
			_t(b, 0.0, 0.04, 1800, 1100, 1.0, SINE, 0.001, 90)
			_t(b, 0.0, 0.012, 5000, 5000, 0.3, NOISE, 0.001, 200)
			gain = 0.45
		"open":
			b = _buf(0.32)
			_t(b, 0.0, 0.18, 2000, 6000, 0.25, NOISE, 0.05, 12)
			_t(b, 0.0, 0.2, 660, 660, 0.6, TRI, 0.004, 18)
			_t(b, 0.06, 0.25, 990, 990, 0.6, TRI, 0.004, 14)
			gain = 0.6
		"hit":
			b = _buf(0.22)
			_t(b, 0.0, 0.18, 190, 55, 1.0, SINE, 0.001, 22)
			_t(b, 0.0, 0.07, 3500, 700, 0.6, NOISE, 0.001, 45)
			_t(b, 0.0, 0.05, 420, 200, 0.35, TRI, 0.001, 50)
		"crit":
			b = _buf(0.35)
			_t(b, 0.0, 0.2, 220, 50, 1.0, SINE, 0.001, 18)
			_t(b, 0.0, 0.08, 5000, 900, 0.7, NOISE, 0.001, 35)
			_t(b, 0.0, 0.09, 1200, 1900, 0.25, SQUARE, 0.001, 25)
			_t(b, 0.04, 0.28, 2400, 2400, 0.35, SINE, 0.002, 14)
			_t(b, 0.08, 0.25, 3200, 3200, 0.25, SINE, 0.002, 16)
			gain = 0.9
		"swing":
			b = _buf(0.24)
			_t(b, 0.0, 0.22, 500, 4500, 1.0, NOISE, 0.07, 10)
			gain = 0.6
		"arrow":
			b = _buf(0.32)
			_t(b, 0.0, 0.25, 230, 200, 0.8, TRI, 0.001, 14, 0.03, 35)
			_t(b, 0.0, 0.1, 460, 400, 0.3, SINE, 0.001, 30)
			_t(b, 0.03, 0.2, 5000, 1200, 0.6, NOISE, 0.04, 12)
		"magic":
			b = _buf(0.65)
			var notes := [72, 79, 84, 76, 88, 83, 91, 86]
			for i in notes.size():
				_t(b, i * 0.045, 0.2, _midi(notes[i]), _midi(notes[i]), 0.4, SINE, 0.002, 18)
			_t(b, 0.0, 0.6, 5000, 8000, 0.25, NOISE, 0.1, 5)
			_t(b, 0.0, 0.4, 300, 900, 0.3, TRI, 0.05, 6, 0.02, 9)
			gain = 0.7
		"fire":
			b = _buf(0.6)
			_t(b, 0.0, 0.55, 900, 250, 1.0, NOISE, 0.02, 4.5)
			_t(b, 0.0, 0.3, 130, 55, 0.6, SINE, 0.005, 9)
			for i in 6:
				_t(b, 0.04 + i * 0.07, 0.02, 3000, 3000, 0.5, NOISE, 0.001, 150)
		"holy":
			b = _buf(1.3)
			_bell(b, RATE, 0.0, 880.0, 0.8, 1.25)
			_bell(b, RATE, 0.08, 1318.5, 0.45, 1.1)
			_t(b, 0.0, 0.8, 6000, 9000, 0.12, NOISE, 0.1, 4)
			gain = 0.7
		"heal":
			b = _buf(0.75)
			var arp := [72, 76, 79, 84, 88]
			for i in arp.size():
				var f := _midi(arp[i])
				_t(b, i * 0.07, 0.4, f, f, 0.5, SINE, 0.004, 7)
				_t(b, i * 0.07, 0.3, f * 2.0, f * 2.0, 0.12, TRI, 0.004, 10)
			_t(b, 0.1, 0.6, 4000, 7000, 0.12, NOISE, 0.2, 4)
			gain = 0.7
		"buff":
			b = _buf(0.7)
			for m in [72, 76, 79]:
				_t(b, 0.0, 0.65, _midi(m), _midi(m), 0.4, SINE, 0.015, 3.5)
				_t(b, 0.0, 0.5, _midi(m) * 2.0, _midi(m) * 2.0, 0.08, TRI, 0.015, 5)
			_t(b, 0.05, 0.5, _midi(91), _midi(91), 0.2, SINE, 0.002, 8)
			_t(b, 0.0, 0.3, 300, 1200, 0.2, TRI, 0.03, 6)
			gain = 0.7
		"levelup":
			b = _buf(1.25)
			var fan := [67, 72, 76, 79]
			for i in fan.size():
				var f := _midi(fan[i])
				_t(b, i * 0.1, 0.14, f, f, 0.22, SQUARE, 0.003, 10)
				_t(b, i * 0.1, 0.16, f, f, 0.4, TRI, 0.003, 8)
			for m in [72, 76, 79, 84]:
				var f2 := _midi(m)
				_t(b, 0.42, 0.8, f2, f2, 0.18, SQUARE, 0.005, 3.2, 0.006, 6)
				_t(b, 0.42, 0.8, f2, f2, 0.3, TRI, 0.005, 3.0)
			_bell(b, RATE, 0.42, _midi(96), 0.2, 0.8)
			gain = 0.75
		"coin":
			b = _buf(0.36)
			_t(b, 0.0, 0.07, 988, 988, 0.4, SQUARE, 0.001, 8)
			_t(b, 0.07, 0.28, 1319, 1319, 0.4, SQUARE, 0.001, 9)
			_t(b, 0.07, 0.28, 2638, 2638, 0.25, SINE, 0.001, 12)
			gain = 0.55
		"pickup":
			b = _buf(0.22)
			_t(b, 0.0, 0.09, 600, 1200, 0.7, SINE, 0.002, 12)
			_t(b, 0.08, 0.12, 1200, 1500, 0.5, TRI, 0.002, 18)
			gain = 0.6
		"potion":
			b = _buf(0.42)
			for i in 3:
				_t(b, i * 0.11, 0.07, 280 + i * 60, 750 + i * 80, 0.8, SINE, 0.004, 25)
			_t(b, 0.0, 0.35, 160, 120, 0.3, SINE, 0.03, 6)
			gain = 0.65
		"hurt":
			b = _buf(0.24)
			_t(b, 0.0, 0.16, 320, 120, 0.4, SQUARE, 0.001, 14)
			_t(b, 0.0, 0.08, 1800, 600, 0.5, NOISE, 0.001, 35)
			_t(b, 0.0, 0.2, 130, 50, 0.8, SINE, 0.001, 14)
		"ghost_hit":
			b = _buf(0.22)
			_t(b, 0.0, 0.18, 760, 420, 0.7, SINE, 0.003, 12, 0.06, 18)
			_t(b, 0.0, 0.05, 2500, 1500, 0.4, NOISE, 0.001, 50)
			gain = 0.65
		"ghost_die":
			b = _buf(1.0)
			_t(b, 0.0, 0.85, 950, 210, 0.7, SINE, 0.03, 2.2, 0.05, 7)
			_t(b, 0.0, 0.85, 1900, 420, 0.15, TRI, 0.03, 3.0, 0.05, 7)
			for i in 4:
				var f := _midi(84 + i * 3)
				_t(b, 0.55 + i * 0.07, 0.25, f, f, 0.15, SINE, 0.002, 14)
			gain = 0.7
		"boss":
			b = _buf(2.6)
			_t(b, 0.0, 2.5, 68, 62, 1.0, SINE, 0.004, 1.3)
			_t(b, 0.0, 2.2, 136, 130, 0.5, SINE, 0.004, 1.6, 0.01, 3)
			_t(b, 0.0, 1.8, 157, 152, 0.35, SINE, 0.004, 2.0)
			_t(b, 0.0, 1.4, 231, 225, 0.25, SINE, 0.004, 2.6)
			_t(b, 0.0, 1.0, 307, 300, 0.18, SINE, 0.004, 3.5)
			_t(b, 0.0, 0.15, 900, 200, 0.5, NOISE, 0.001, 20)
			gain = 0.9
		"warp":
			b = _buf(0.62)
			_t(b, 0.0, 0.55, 300, 2400, 0.6, SINE, 0.05, 2.5, 0.03, 14)
			_t(b, 0.0, 0.55, 600, 4800, 0.18, TRI, 0.05, 3.0)
			_t(b, 0.0, 0.55, 800, 7000, 0.35, NOISE, 0.1, 3.0)
			gain = 0.65
		"chat":
			b = _buf(0.09)
			_t(b, 0.0, 0.07, 850, 1350, 0.8, SINE, 0.002, 40)
			gain = 0.45
		"whisper":
			b = _buf(0.55)
			_t(b, 0.0, 0.3, 1318.5, 1318.5, 0.5, SINE, 0.002, 8)
			_t(b, 0.11, 0.42, 1760, 1760, 0.5, SINE, 0.002, 7)
			_t(b, 0.11, 0.3, 3520, 3520, 0.08, SINE, 0.002, 12)
			gain = 0.5
		"party":
			b = _buf(0.75)
			var ch := [79, 83, 86, 91]
			for i in ch.size():
				var f := _midi(ch[i])
				_t(b, i * 0.07, 0.45, f, f, 0.4, TRI, 0.003, 6)
				_t(b, i * 0.07, 0.35, f * 3.0, f * 3.0, 0.05, SINE, 0.003, 10)
			gain = 0.6
		"mine":
			b = _buf(0.26)
			_t(b, 0.0, 0.22, 2150, 2150, 0.5, SINE, 0.001, 22)
			_t(b, 0.0, 0.16, 3450, 3450, 0.35, SINE, 0.001, 30)
			_t(b, 0.0, 0.1, 5150, 5150, 0.2, SINE, 0.001, 45)
			_t(b, 0.0, 0.04, 4000, 2000, 0.6, NOISE, 0.001, 60)
			_t(b, 0.0, 0.08, 200, 90, 0.4, SINE, 0.001, 30)
			gain = 0.7
		"ore":
			b = _buf(0.75)
			_t(b, 0.0, 0.2, 2150, 2150, 0.4, SINE, 0.001, 22)
			_t(b, 0.0, 0.04, 4000, 2000, 0.4, NOISE, 0.001, 60)
			var sp := [84, 88, 91, 96]
			for i in sp.size():
				_bell(b, RATE, 0.08 + i * 0.07, _midi(sp[i]), 0.25, 0.45)
			gain = 0.7
		"splash":
			b = _buf(0.62)
			_t(b, 0.0, 0.5, 3200, 500, 0.9, NOISE, 0.004, 6)
			_t(b, 0.0, 0.12, 420, 140, 0.6, SINE, 0.002, 18)
			for i in 3:
				_t(b, 0.15 + i * 0.09, 0.05, 500 + i * 120, 1100 + i * 150, 0.25, SINE, 0.003, 30)
			gain = 0.7
		"catch":
			b = _buf(0.72)
			_t(b, 0.0, 0.25, 2500, 600, 0.35, NOISE, 0.003, 10)
			var cn := [72, 76, 79, 84]
			for i in cn.size():
				var f := _midi(cn[i])
				_t(b, 0.05 + i * 0.08, 0.3, f, f, 0.35, TRI, 0.003, 7)
				_t(b, 0.05 + i * 0.08, 0.2, f, f, 0.12, SQUARE, 0.003, 12)
			_bell(b, RATE, 0.38, _midi(96), 0.18, 0.3)
			gain = 0.7
		"rare":
			b = _buf(1.15)
			var rn := [88, 91, 95, 100, 91, 95, 100, 103]
			for i in rn.size():
				_bell(b, RATE, i * 0.07, _midi(rn[i]), 0.3, 0.5)
			_t(b, 0.0, 1.0, 5000, 9000, 0.12, NOISE, 0.2, 2.5)
			gain = 0.7
		"refine_ok":
			b = _buf(1.05)
			for m in [84, 88, 91]:
				_bell(b, RATE, 0.0, _midi(m), 0.35, 0.95)
			_bell(b, RATE, 0.14, _midi(96), 0.3, 0.8)
			_t(b, 0.0, 0.25, 600, 2400, 0.2, TRI, 0.01, 6)
			gain = 0.75
		"refine_fail":
			b = _buf(0.62)
			_t(b, 0.0, 0.55, 140, 105, 0.45, SAW, 0.01, 3.0)
			_t(b, 0.0, 0.55, 147, 110, 0.4, SAW, 0.01, 3.0)
			_t(b, 0.0, 0.5, 70, 55, 0.4, SQUARE, 0.01, 4.0)
			gain = 0.55
		"refine_down":
			b = _buf(0.72)
			_t(b, 0.0, 0.06, 6000, 1500, 1.0, NOISE, 0.001, 40)
			_t(b, 0.0, 0.03, 3000, 3000, 0.4, SQUARE, 0.001, 80)
			_t(b, 0.06, 0.5, 650, 140, 0.5, SINE, 0.01, 4, 0.03, 9)
			_t(b, 0.45, 0.22, 110, 40, 0.8, SINE, 0.001, 18)
			_t(b, 0.45, 0.08, 1500, 400, 0.4, NOISE, 0.001, 40)
			gain = 0.75
		"error":
			b = _buf(0.3)
			_t(b, 0.0, 0.1, 220, 220, 0.4, SQUARE, 0.002, 6)
			_t(b, 0.12, 0.16, 165, 165, 0.4, SQUARE, 0.002, 6)
			gain = 0.45
		_:
			return null
	return _to_wav(b, RATE, gain, false)


# ---------------------------------------------------------------- เพลง

## เพลงแต่ละอารมณ์ประกอบจากโน้ตเครื่องดนตรีที่เรนเดอร์ครั้งเดียวต่อระดับเสียงแล้วนำมาวางซ้ำ
## ทุกโน้ตที่ล้นท้ายจะวนไปต้นเพลง ลูปจึงต่อเนื่องไม่มีรอยต่อ
class Song:
	var rate: int
	var spb: float
	var b: PackedFloat32Array
	var notes := {}
	var rng := RandomNumberGenerator.new()

	func _init(bpm: float, beats: int, r: int, seed_v: int) -> void:
		rate = r
		spb = 60.0 / bpm
		b = PackedFloat32Array()
		b.resize(int(round(beats * spb * rate)))
		b.fill(0.0)
		rng.seed = seed_v

	func length() -> float:
		return float(b.size()) / rate

	## วางโน้ตของเครื่องดนตรี inst ที่จังหวะ beat (นับจาก 0)
	func put(inst: String, m: float, beat: float, gain: float) -> void:
		var src := note(inst, m)
		var n := b.size()
		var j := int(beat * spb * rate) % n
		for i in src.size():
			b[j] += src[i] * gain
			j += 1
			if j >= n:
				j = 0

	func note(inst: String, m: float) -> PackedFloat32Array:
		var key := "%s:%d" % [inst, int(m * 10.0)]
		if notes.has(key):
			return notes[key]
		var f: float = 440.0 * pow(2.0, (m - 69.0) / 12.0)
		var S = load(SELF_PATH)
		var x := PackedFloat32Array()
		match inst:
			"ranat":
				x = _mk(0.55)
				S._osc(x, rate, 0.0, 0.55, f, f, 1.0, SINE, 0.002, 8.0)
				S._osc(x, rate, 0.0, 0.12, f * 3.93, f * 3.93, 0.35, SINE, 0.001, 35.0)
				S._osc(x, rate, 0.0, 0.03, f * 9.0, f * 9.0, 0.15, SINE, 0.001, 90.0)
			"khim":
				x = S._karplus(f, 0.9, rate, 0.995, int(m * 7.0))
			"box":
				x = _mk(1.1)
				S._osc(x, rate, 0.0, 1.1, f, f, 0.8, SINE, 0.002, 3.5)
				S._osc(x, rate, 0.0, 0.6, f * 2.0, f * 2.0, 0.2, SINE, 0.002, 6.0)
				S._osc(x, rate, 0.0, 0.3, f * 4.0, f * 4.0, 0.07, SINE, 0.001, 12.0)
			"pizz":
				x = _mk(0.3)
				S._osc(x, rate, 0.0, 0.3, f, f, 0.8, TRI, 0.002, 14.0)
				S._osc(x, rate, 0.0, 0.15, f * 2.0, f * 2.0, 0.2, SINE, 0.001, 22.0)
			"bass":
				x = _mk(0.6)
				S._osc(x, rate, 0.0, 0.6, f, f, 0.9, SINE, 0.006, 4.0)
				S._osc(x, rate, 0.0, 0.35, f * 2.0, f * 2.0, 0.2, TRI, 0.006, 8.0)
			"pad":
				x = _mk(spb * 4.0)
				S._osc(x, rate, 0.0, spb * 4.0, f, f, 0.5, TRI, spb * 1.2, 0.4, 0.004, 4.5)
			"bell":
				x = _mk(2.2)
				S._bell(x, rate, 0.0, f, 0.8, 2.2)
			"kick":
				x = _mk(0.3)
				S._osc(x, rate, 0.0, 0.3, 120.0, 48.0, 1.0, SINE, 0.002, 12.0)
			"heart":
				x = _mk(0.25)
				S._osc(x, rate, 0.0, 0.25, 70.0, 45.0, 1.0, SINE, 0.004, 14.0)
			"ching":
				x = _mk(0.45)
				for p in [3150.0, 4720.0, 6080.0]:
					S._osc(x, rate, 0.0, 0.45, p, p, 0.25, SINE, 0.001, 9.0)
				S._osc(x, rate, 0.0, 0.08, 8000.0, 8000.0, 0.3, NOISE, 0.001, 50.0)
			"chap":
				x = _mk(0.08)
				S._osc(x, rate, 0.0, 0.08, 3150.0, 3150.0, 0.3, SINE, 0.001, 50.0)
				S._osc(x, rate, 0.0, 0.06, 6000.0, 6000.0, 0.6, NOISE, 0.001, 70.0)
			"shaker":
				x = _mk(0.07)
				S._osc(x, rate, 0.0, 0.07, 7000.0, 7000.0, 1.0, NOISE, 0.02, 40.0)
			"drip":
				x = _mk(0.12)
				S._osc(x, rate, 0.0, 0.1, f, f * 2.2, 1.0, SINE, 0.001, 35.0)
			"bubble":
				x = _mk(0.08)
				S._osc(x, rate, 0.0, 0.08, f, f * 1.8, 1.0, SINE, 0.004, 30.0)
			"ghost":
				x = _mk(spb * 3.0)
				S._osc(x, rate, 0.0, spb * 3.0, f, f * 0.94, 0.6, SINE, spb, 0.8, 0.012, 5.0)
		notes[key] = x
		return x

	func _mk(sec: float) -> PackedFloat32Array:
		var x := PackedFloat32Array()
		x.resize(int(sec * rate))
		x.fill(0.0)
		return x

	## เสียงต่อเนื่องตลอดเพลง (ปรับความถี่ให้ครบรอบพอดีลูป)
	func drone(m: float, amp: float, wave: int) -> void:
		var f: float = 440.0 * pow(2.0, (m - 69.0) / 12.0)
		var n := b.size()
		f = maxf(1.0, round(f * n / rate)) * rate / n
		var S = load(SELF_PATH)
		S._osc(b, rate, 0.0, float(n) / rate, f, f, amp, wave, 0.0, 0.0, 0.0, 0.0, true, false)

	## เสียงก้องแบบวน (ดีเลย์ป้อนกลับ) สองรอบเพื่อให้หางเสียงท้ายเพลงไปต่อที่ต้นเพลง
	func echo(delay_beats: float, fb: float) -> void:
		var n := b.size()
		var d := int(delay_beats * spb * rate)
		for pass_i in 2:
			var k := fb if pass_i == 0 else fb * 0.5
			for i in n:
				var j := i - d
				if j < 0:
					j += n
				b[i] += b[j] * k


## คาร์พลัส-สตรอง: เสียงดีดสายราคาถูก (ขิม/พิณ)
static func _karplus(f: float, dur: float, rate: int, damp: float, seed_v: int) -> PackedFloat32Array:
	var cnt := int(dur * rate)
	var out := PackedFloat32Array()
	out.resize(cnt)
	var p := maxi(2, int(round(rate / f)))
	var ring := PackedFloat32Array()
	ring.resize(p)
	var s := (seed_v * 7919 + 17) & 0x7fffffff
	for i in p:
		s = (s * 1103515245 + 12345) & 0x7fffffff
		ring[i] = float(s) / 1073741824.0 - 1.0
	var idx := 0
	var fade_n := mini(400, cnt >> 2)
	for i in cnt:
		var nx := idx + 1
		if nx >= p:
			nx = 0
		var cur := ring[idx]
		ring[idx] = (cur + ring[nx]) * 0.5 * damp
		var e := 1.0
		if cnt - i < fade_n:
			e = float(cnt - i) / float(fade_n)
		out[i] = cur * 0.6 * e
		idx = nx
	return out


## ระดับเสียง midi จากขั้นของสเกล (ขั้นติดลบ/เกินได้ ข้ามอ็อกเทฟให้เอง)
static func _deg(root: int, scale: Array, d: int) -> float:
	var n := scale.size()
	var o := floori(float(d) / n)
	return float(root + int(scale[d - o * n]) + 12 * o)


## ทำนองสุ่มเดินทีละขั้นในสเกล (กำหนดซีดได้ จึงได้เพลงเดิมทุกครั้ง)
static func _walk(rng: RandomNumberGenerator, count: int, lo: int, hi: int, start: int) -> Array:
	var out := []
	var d := start
	for i in count:
		out.append(d)
		var step := rng.randi_range(-2, 2)
		if step == 0 and rng.randf() < 0.5:
			step = 1
		d = clampi(d + step, lo, hi)
	return out


static func _build_music(mood: String) -> AudioStreamWAV:
	var s: Song
	var gain := 0.7
	match mood:
		"title":
			s = _m_title()
			gain = 0.6
		"village":
			s = _m_village()
		"field":
			s = _m_field()
		"dark":
			s = _m_dark()
			gain = 0.65
		"cave":
			s = _m_cave()
			gain = 0.6
		"stream":
			s = _m_stream()
			gain = 0.55
		_:
			return null
	return _to_wav(s.b, s.rate, gain, true)


## หน้าแรก: นุ่มนวล ฝันละมุน กล่องดนตรีบนคอร์ดแพด
static func _m_title() -> Song:
	var s := Song.new(84, 32, MUSIC_RATE, 101)
	var chords := [[60, 64, 67, 71], [57, 60, 64, 67], [53, 57, 60, 64], [55, 59, 62, 67]]
	for bar in 8:
		var c: Array = chords[bar % 4]
		for m in c.slice(0, 3):
			s.put("pad", m - 12, bar * 4, 0.16)
		s.put("bass", c[0] - 24, bar * 4, 0.35)
		s.put("bass", c[0] - 24, bar * 4 + 2.5, 0.2)
		for k in 8:
			var mm: int = c[[0, 1, 2, 3, 2, 1, 3, 2][k]] + 12
			s.put("box", mm, bar * 4 + k * 0.5, 0.18 if k % 2 == 0 else 0.12)
		if bar % 2 == 0:
			s.put("box", c[s.rng.randi_range(1, 3)] + 24, bar * 4 + 1.5, 0.12)
	s.echo(0.75, 0.3)
	return s


## หมู่บ้าน: สนุกแบบไทย ระนาดเล่นเพนทาโทนิกบนจังหวะฉิ่ง-ฉาบ-กลองเบา ๆ 96 bpm
static func _m_village() -> Song:
	var s := Song.new(96, 32, MUSIC_RATE, 202)
	var sc := [0, 2, 4, 7, 9]
	var root := 62
	var bass := [0, 0, 5, 5, 0, 0, 7, 0]
	var a := _walk(s.rng, 16, 3, 9, 5)
	var bb := _walk(s.rng, 16, 4, 10, 7)
	var phrase: Array = a + a.duplicate() + bb + a.duplicate()
	phrase[31] = 5
	phrase[63] = 5
	for i in 64:
		var bt := i * 0.5
		var d: int = phrase[i]
		var m := _deg(root, sc, d)
		s.put("ranat", m, bt, 0.32)
		# ระนาดตีคู่แปด และรัวเป็นช่วง ๆ
		if i % 4 == 0:
			s.put("ranat", m - 12, bt, 0.16)
		if i % 8 == 6 and i < 56:
			s.put("ranat", _deg(root, sc, d + 1), bt + 0.25, 0.22)
	for bar in 8:
		var r: int = root - 24 + bass[bar]
		s.put("bass", r, bar * 4, 0.5)
		s.put("bass", r + 7, bar * 4 + 2, 0.35)
		s.put("khim", r + 24, bar * 4 + 1, 0.3)
		s.put("khim", r + 28 if bass[bar] == 0 else r + 31, bar * 4 + 3, 0.25)
		# ฉิ่งเปิดจังหวะหนัก ฉับจังหวะเบา
		s.put("ching", 0, bar * 4 + 1, 0.12)
		s.put("ching", 0, bar * 4 + 3, 0.12)
		s.put("chap", 0, bar * 4 + 0, 0.18)
		s.put("chap", 0, bar * 4 + 2, 0.18)
		s.put("kick", 0, bar * 4, 0.5)
		s.put("kick", 0, bar * 4 + 1.5, 0.3)
		s.put("kick", 0, bar * 4 + 2.5, 0.35)
	return s


## ทุ่งหญ้า: ลึกลับแต่น่ารัก พิซซิคาโตเดินเบส ทำนองเป็นห้วง ๆ ไมเนอร์
static func _m_field() -> Song:
	var s := Song.new(108, 32, MUSIC_RATE, 303)
	var chords := [[57, 60, 64], [53, 57, 60], [50, 53, 57], [52, 56, 59]]
	var sc := [0, 2, 3, 7, 8]
	var mel := _walk(s.rng, 16, 4, 10, 5)
	for bar in 8:
		var c: Array = chords[bar % 4]
		s.put("pizz", c[0] - 12, bar * 4, 0.5)
		s.put("pizz", c[2] - 12, bar * 4 + 1, 0.35)
		s.put("pizz", c[1] - 12, bar * 4 + 2, 0.4)
		s.put("pizz", c[2] - 12, bar * 4 + 3, 0.35)
		s.put("pad", c[0], bar * 4, 0.07)
		s.put("pad", c[1], bar * 4, 0.07)
		for k in 8:
			s.put("shaker", 0, bar * 4 + k * 0.5, 0.05 if k % 2 == 0 else 0.03)
		s.put("kick", 0, bar * 4, 0.35)
		s.put("kick", 0, bar * 4 + 2.5, 0.2)
		# ทำนองระนาดเบา ๆ เว้นช่วงหายใจ
		for k in 4:
			if (bar * 4 + k) % 7 == 3:
				continue
			var d: int = mel[(bar % 4) * 4 + k]
			var m := _deg(57, sc, d)
			if bar % 4 == 3 and k == 2:
				m = 68  # G# ให้ความลึกลับ
			s.put("ranat", m, bar * 4 + k + (0.5 if k % 2 == 1 else 0.0), 0.22)
		if bar % 2 == 1:
			s.put("box", _deg(57, sc, mel[bar] + 5), bar * 4 + 3.5, 0.1)
	s.echo(0.5, 0.18)
	return s


## มืด (ป่าช้า ยมโลก): โดรนต่ำ จังหวะหัวใจ ระฆังห่าง ๆ เสียงผีหวีดหวิว แต่ยังมีกล่องดนตรีน่ารัก
static func _m_dark() -> Song:
	var s := Song.new(72, 24, MUSIC_RATE, 404)
	var sc := [0, 1, 3, 5, 7, 8, 10]
	s.drone(38, 0.18, SINE)
	s.drone(45.1, 0.1, SINE)
	s.drone(50, 0.05, TRI)
	var mel := _walk(s.rng, 12, 5, 11, 7)
	for bar in 6:
		s.put("heart", 0, bar * 4, 0.6)
		s.put("heart", 0, bar * 4 + 0.4, 0.4)
		if bar % 3 == 0:
			s.put("bell", 50, bar * 4 + 2, 0.35)
		if bar % 2 == 1:
			s.put("ghost", 74 + (bar % 3), bar * 4 + 0.5, 0.12)
		for k in 2:
			var d: int = mel[(bar * 2 + k) % 12]
			s.put("box", _deg(62, sc, d), bar * 4 + k * 2 + 1, 0.14)
			s.put("box", _deg(62, sc, d) + 1, bar * 4 + k * 2 + 1.5, 0.05)
	s.echo(1.0, 0.3)
	return s


## ถ้ำ: น้ำหยด เสียงโดรนต่ำมืด ๆ ระนาดทุ้มนาน ๆ ครั้ง
static func _m_cave() -> Song:
	var s := Song.new(64, 16, MUSIC_RATE, 505)
	s.drone(33, 0.2, SINE)
	s.drone(33.15, 0.15, SINE)
	s.drone(40, 0.06, TRI)
	for i in 14:
		var bt := s.rng.randf_range(0.0, 16.0)
		s.put("drip", s.rng.randi_range(80, 92), bt, 0.18)
	var sc := [0, 3, 5, 7, 10]
	for bar in 4:
		var d := s.rng.randi_range(0, 6)
		s.put("ranat", _deg(45, sc, d), bar * 4 + 0.5, 0.25)
		s.put("ranat", _deg(45, sc, d + 2), bar * 4 + 2.5, 0.18)
		s.put("ghost", _deg(57, sc, d + 1), bar * 4 + 1, 0.05)
	s.echo(1.5, 0.35)
	return s


## ลำธาร (แผนที่ตกปลา): สบาย ๆ เสียงน้ำไหล พิณดีดอาร์เปจโจ ฟองอากาศเบา ๆ
static func _m_stream() -> Song:
	var s := Song.new(84, 32, MUSIC_RATE, 606)
	# เสียงน้ำ: นอยส์ low-pass ต่อเนื่องทั้งเพลง
	_osc(s.b, s.rate, 0.0, s.length(), 700.0, 700.0, 0.07, NOISE, 0.0, 0.0, 0.0, 0.0, true, false)
	var chords := [[53, 57, 60, 64], [52, 55, 59, 62], [50, 53, 57, 60], [48, 52, 55, 59]]
	for bar in 8:
		var c: Array = chords[bar % 4]
		s.put("bass", c[0] - 12, bar * 4, 0.3)
		for k in 8:
			var m: int = c[[0, 1, 2, 3, 2, 3, 1, 2][k]]
			s.put("khim", m, bar * 4 + k * 0.5, 0.4 if k % 4 == 0 else 0.28)
		s.put("pad", c[1], bar * 4, 0.06)
		if bar % 2 == 0:
			s.put("box", c[3] + 12, bar * 4 + 1, 0.12)
			s.put("box", c[2] + 12, bar * 4 + 2.5, 0.09)
		s.put("bubble", s.rng.randi_range(72, 84), bar * 4 + s.rng.randf_range(0.0, 4.0), 0.06)
	s.echo(0.75, 0.22)
	return s
