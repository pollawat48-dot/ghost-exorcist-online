extends RefCounted
## คุณภาพภาพ 3D: ต่ำ / กลาง / สูง / สูงสุด (เลือกในหน้าต่างตั้งค่า เก็บใน settings.cfg [graphics])
## - ความคม: ลบรอยหยัก MSAA (ไม่ใช้ TAA/FXAA ที่ทำให้ภาพเบลอ), เงาละเอียด (กรองพื้นผิว anisotropic 16x ตั้งใน project.godot)
## - ความสวย: เงาตามซอก (SSAO), แสงสะท้อนระหว่างวัตถุ (SSIL), เงาสะท้อนบนน้ำ (SSR), หมอกมีแสง
## - ความละเอียดโมเดล: จำนวนเหลี่ยมของทรงกลม/ทรงกระบอก (mesh_kit.detail) มีผลกับโมเดลที่สร้างใหม่
## ตัวที่อยู่ในกลุ่ม "graphics_listener" จะถูกเรียก _on_graphics_changed() เมื่อเปลี่ยนระดับ

const K = preload("res://maps/props/mesh_kit.gd")

const LEVELS := ["lowest", "low", "medium", "high", "ultra"]
const NAMES := {"lowest": "ประหยัด", "low": "ต่ำ", "medium": "กลาง", "high": "สูง", "ultra": "สูงสุด"}
const PRESETS := {
	# ประหยัด (ค่าเริ่มต้นมือถือ): ไม่มีเงาแดด ไม่มีแสงฟุ้ง แสงรอบข้างเป็นสีคงที่ เรนเดอร์ 60% ของจอ
	"lowest": {"msaa": Viewport.MSAA_DISABLED, "fxaa": false, "scale": 0.6,
		"shadow_size": 1024, "shadow_q": RenderingServer.SHADOW_QUALITY_HARD, "splits": 0, "shadow_dist": 20.0,
		"ssao": false, "ssil": false, "ssr": false, "vol_fog": false, "detail": 0.6, "glow": false, "sky_light": false},
	"low": {"msaa": Viewport.MSAA_DISABLED, "fxaa": false, "scale": 0.75,
		"shadow_size": 2048, "shadow_q": RenderingServer.SHADOW_QUALITY_HARD, "splits": 1, "shadow_dist": 28.0,
		"ssao": false, "ssil": false, "ssr": false, "vol_fog": false, "detail": 0.75, "glow": false, "sky_light": false},
	"medium": {"msaa": Viewport.MSAA_2X, "fxaa": false, "scale": 1.0,
		"shadow_size": 4096, "shadow_q": RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM, "splits": 4, "shadow_dist": 55.0,
		"ssao": true, "ssil": false, "ssr": false, "vol_fog": false, "detail": 1.5},
	"high": {"msaa": Viewport.MSAA_4X, "fxaa": false, "scale": 1.0,
		"shadow_size": 4096, "shadow_q": RenderingServer.SHADOW_QUALITY_SOFT_HIGH, "splits": 4, "shadow_dist": 60.0,
		"ssao": true, "ssil": true, "ssr": true, "vol_fog": false, "detail": 2.0},
	"ultra": {"msaa": Viewport.MSAA_8X, "fxaa": false, "scale": 1.0,
		"shadow_size": 8192, "shadow_q": RenderingServer.SHADOW_QUALITY_SOFT_ULTRA, "splits": 4, "shadow_dist": 70.0,
		"ssao": true, "ssil": true, "ssr": true, "vol_fog": true, "detail": 2.5},
}

static var config_path := "user://settings.cfg"
static var _level := ""


## ระดับเริ่มต้น: มือถือ = ต่ำ (จอมือถือความละเอียดสูง วาดหนักกว่า PC), PC = สูง
static func default_level() -> String:
	return "lowest" if OS.has_feature("mobile") else "high"


static func level() -> String:
	if _level == "":
		var cfg := ConfigFile.new()
		cfg.load(config_path)
		_level = str(cfg.get_value("graphics", "level", default_level()))
		if not _level in LEVELS:
			_level = default_level()
		K.detail = PRESETS[_level]["detail"]
	return _level


static func preset() -> Dictionary:
	return PRESETS[level()]


## เปลี่ยนระดับ บันทึก แล้วแจ้งทุกตัวที่ฟังอยู่ (บรรยากาศ/แผนที่) ให้ปรับทันที
static func set_level(tree: SceneTree, l: String) -> void:
	if not l in LEVELS:
		return
	_level = l
	K.detail = PRESETS[l]["detail"]
	var cfg := ConfigFile.new()
	cfg.load(config_path)
	cfg.set_value("graphics", "level", l)
	cfg.save(config_path)
	if tree != null:
		tree.call_group("graphics_listener", "_on_graphics_changed")


## ตั้งค่าหน้าจอ 3D: ลบรอยหยัก ความละเอียดเรนเดอร์ การกรองพื้นผิว และขนาดแผนที่เงา
static func apply_viewport(vp: Viewport) -> void:
	var p := preset()
	vp.msaa_3d = p["msaa"]
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if p["fxaa"] else Viewport.SCREEN_SPACE_AA_DISABLED
	vp.use_taa = false
	vp.use_debanding = true
	vp.scaling_3d_scale = p["scale"]
	# ความละเอียดต่ำกว่าจอ: ขยายด้วย FSR แล้วเพิ่มความคมกลับ
	# มือถือใช้ตัวเรนเดอร์ Compatibility (OpenGL ES) ที่ไม่มี FSR จึงขยายแบบ bilinear
	var fsr: bool = p["scale"] < 1.0 and not OS.has_feature("mobile")
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if fsr else Viewport.SCALING_3D_MODE_BILINEAR
	vp.fsr_sharpness = 0.3
	RenderingServer.directional_shadow_atlas_set_size(p["shadow_size"], true)
	RenderingServer.directional_soft_shadow_filter_set_quality(p["shadow_q"])
	RenderingServer.positional_soft_shadow_filter_set_quality(p["shadow_q"])


## ตั้งค่าแสงและเอฟเฟกต์ของฉาก
static func apply_environment(env: Environment, sun: DirectionalLight3D) -> void:
	var p := preset()
	env.ssao_enabled = p["ssao"]
	env.ssao_radius = 1.1
	env.ssao_intensity = 1.1
	env.ssao_detail = 0.6
	env.ssao_horizon = 0.05
	env.ssao_light_affect = 0.15
	env.ssil_enabled = p["ssil"]
	env.ssil_radius = 4.0
	env.ssil_intensity = 0.7
	env.ssr_enabled = p["ssr"]
	env.ssr_max_steps = 48
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0
	env.volumetric_fog_enabled = p["vol_fog"]
	env.glow_enabled = p.get("glow", true)
	# แสงรอบข้างจากท้องฟ้าต้องวาดแผนที่แสงท้องฟ้าใหม่ทุกครั้งที่ฟ้าเปลี่ยนสี ระดับต่ำใช้สีคงที่แทน
	var sky_light: bool = p.get("sky_light", true)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY if sky_light else Environment.AMBIENT_SOURCE_COLOR
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG if sky_light else Environment.REFLECTION_SOURCE_DISABLED
	env.volumetric_fog_density = 0.004
	env.volumetric_fog_length = 48.0
	env.volumetric_fog_detail_spread = 2.0
	env.volumetric_fog_anisotropy = 0.4
	if sun != null:
		sun.shadow_enabled = p["splits"] > 0
		# ระดับต่ำ: เงาชั้นเดียว (orthogonal) วาดของที่ทอดเงาเพียงรอบเดียว
		sun.directional_shadow_mode = {1: DirectionalLight3D.SHADOW_ORTHOGONAL, 2: DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS}.get(p["splits"], DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS)
		sun.directional_shadow_max_distance = p["shadow_dist"]
		sun.directional_shadow_blend_splits = p["splits"] == 4
		# เงาขอบคมแต่ไม่แตก: เบลอน้อย และใช้ขนาดดวงอาทิตย์ทำให้ขอบเงานุ่มตามระยะ (เฉพาะระดับสูง)
		sun.shadow_blur = 1.0 if p["splits"] == 4 else 1.6
		sun.light_angular_distance = 0.6 if level() in ["high", "ultra"] else 0.0
		sun.shadow_normal_bias = 1.2
		sun.shadow_bias = 0.03
		sun.light_volumetric_fog_energy = 0.6
