// ฟังก์ชันพื้นที่ใช้ร่วมกันระหว่างพื้นดินกับต้นไม้/หญ้า (หน่วย = หน่วยตรรกะเกม, 32 = 1 เมตร)

uniform float canal_x = 1220.0;
uniform float canal_water = 62.0;
uniform float canal_bank = 80.0;
uniform float canal_depth = 1.3;
uniform float bridge_y = 1000.0;
uniform vec4 courtyard;
uniform vec4 paddy;
uniform vec2 plot = vec2(230.0, 160.0);
uniform vec4 grove;
uniform vec2 grave_center;
uniform float grave_r = 330.0;
uniform vec2 path_segs[24];
uniform int seg_count = 0;
uniform float path_w = 30.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
}

float canal_center(float y) {
	return canal_x + sin(y * 0.0035) * 45.0 + sin(y * 0.011) * 12.0;
}

float seg_dist(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

float rect_sdf(vec2 p, vec4 r) {
	vec2 c = r.xy + r.zw * 0.5;
	vec2 q = abs(p - c) - r.zw * 0.5;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

bool in_rect(vec2 p, vec4 r) {
	return p.x >= r.x && p.y >= r.y && p.x < r.x + r.z && p.y < r.y + r.w;
}

float path_dist(vec2 p) {
	float pd = 1e6;
	for (int i = 0; i < seg_count; i++) {
		pd = min(pd, seg_dist(p, path_segs[i * 2], path_segs[i * 2 + 1]));
	}
	return pd;
}

// ความสูงพื้น (เมตร): คลองเป็นร่องลึก ทุ่งนาต่ำกว่าคันนาเล็กน้อย พื้นหญ้าเป็นเนินนุ่มๆ
float ground_height(vec2 p) {
	float h = (fbm(p * 0.003) - 0.5) * 0.2;
	float dx = abs(p.x - canal_center(p.y));
	h -= (1.0 - smoothstep(canal_water - 10.0, canal_bank + 6.0, dx)) * canal_depth;
	if (in_rect(p, paddy)) {
		vec2 c = mod(p - paddy.xy, plot);
		float bund = min(min(c.x, c.y), min(plot.x - c.x, plot.y - c.y));
		h -= smoothstep(4.0, 14.0, bund) * 0.12;
	}
	if (in_rect(p, courtyard)) {
		h = max(h, 0.04);
	}
	return h;
}
