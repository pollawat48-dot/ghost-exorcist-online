shader_type canvas_item;
// พื้นของแผนที่ไทย วาดบน GPU แบบพิกเซลอาร์ต: หญ้า, ลานวัด, ทางดิน, ทุ่งนา, ป่ากล้วย, ป่าช้า, คลอง
// ค่าตำแหน่งทั้งหมดส่งมาจาก khlong_village.gd เพื่อให้ตรงกับระบบเดิน

uniform float px = 4.0;
uniform float canal_x = 1220.0;
uniform float canal_water = 62.0;
uniform float canal_bank = 80.0;
uniform vec4 courtyard;
uniform vec4 paddy;
uniform vec2 plot = vec2(230.0, 160.0);
uniform vec4 grove;
uniform vec2 grave_center;
uniform float grave_r = 330.0;
uniform vec2 path_segs[24];
uniform int seg_count = 0;
uniform float path_w = 30.0;

varying vec2 wpos;

void vertex() {
	wpos = VERTEX;
}

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

// ระยะจากขอบสี่เหลี่ยม (ติดลบ = อยู่ข้างใน)
float rect_sdf(vec2 p, vec4 r) {
	vec2 c = r.xy + r.zw * 0.5;
	vec2 q = abs(p - c) - r.zw * 0.5;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}

bool in_rect(vec2 p, vec4 r) {
	return p.x >= r.x && p.y >= r.y && p.x < r.x + r.z && p.y < r.y + r.w;
}

void fragment() {
	vec2 p = (floor(wpos / px) + 0.5) * px;
	float n = fbm(p * 0.004);
	float d = hash(floor(p / px));

	// หญ้า + ดอกไม้เล็กๆ
	vec3 col = mix(vec3(0.26, 0.47, 0.2), vec3(0.42, 0.63, 0.26), smoothstep(0.3, 0.7, n));
	col *= 0.93 + 0.1 * d;
	if (d > 0.998) {
		col = vec3(1.0, 0.88, 0.45);
	}

	// ป่ากล้วย: เขียวเข้มชื้น
	float gv = 1.0 - smoothstep(-60.0, 40.0, rect_sdf(p, grove) + (fbm(p * 0.015) - 0.5) * 120.0);
	col = mix(col, vec3(0.17, 0.36, 0.15) * (0.88 + 0.16 * d), 0.7 * gv);

	// ป่าช้า: หญ้าแห้ง
	float gd = length(p - grave_center);
	float dry = (1.0 - smoothstep(grave_r - 140.0, grave_r + fbm(p * 0.02) * 60.0, gd)) * 0.85;
	col = mix(col, vec3(0.5, 0.45, 0.31) * (0.85 + 0.2 * n + 0.08 * d), dry);

	// ลานวัด: แผ่นหิน
	if (in_rect(p, courtyard)) {
		vec2 t = mod(p - courtyard.xy, 32.0);
		col = vec3(0.86, 0.82, 0.74) * (0.94 + 0.06 * d);
		if (t.x < 4.0 || t.y < 4.0) {
			col *= 0.86;
		}
	}

	// ทุ่งนา: คันนา + ต้นข้าวเป็นแถว (บางแปลงข้าวสุกสีทอง)
	if (in_rect(p, paddy)) {
		vec2 q = p - paddy.xy;
		vec2 c = mod(q, plot);
		if (c.x < 16.0 || c.y < 16.0) {
			col = vec3(0.42, 0.5, 0.24) * (0.9 + 0.12 * d);
		} else {
			float ripe = step(0.72, hash(floor(q / plot) + 3.0));
			vec3 rice = mix(vec3(0.46, 0.74, 0.26), vec3(0.88, 0.74, 0.3), ripe);
			float row = step(4.0, mod(c.x, 10.0) + d * 2.0);
			vec3 water = mix(vec3(0.34, 0.5, 0.36), rice * 0.7, 0.35) + 0.04 * sin(TIME * 2.0 + p.y * 0.1);
			col = mix(water, rice * (0.88 + 0.16 * d), row);
		}
	}

	// ทางดิน
	float pd = 1e6;
	for (int i = 0; i < seg_count; i++) {
		pd = min(pd, seg_dist(p, path_segs[i * 2], path_segs[i * 2 + 1]));
	}
	if (pd < path_w + 8.0) {
		vec3 dirt = vec3(0.68, 0.56, 0.38) * (0.88 + 0.14 * d);
		if (d > 0.96) {
			dirt *= 0.75;
		}
		col = mix(dirt, col, smoothstep(path_w - 10.0, path_w, pd + d * 6.0));
	}

	// คลอง: ตลิ่งโคลน, น้ำเป็นประกาย, ใบบัว
	float dx = abs(p.x - canal_center(p.y));
	if (dx < canal_bank + 8.0) {
		col = mix(vec3(0.42, 0.34, 0.22) * (0.9 + 0.12 * d), col, smoothstep(canal_bank - 8.0, canal_bank, dx + d * 4.0));
	}
	if (dx < canal_water) {
		float depth = 1.0 - dx / canal_water;
		col = mix(vec3(0.3, 0.55, 0.5), vec3(0.1, 0.3, 0.36), depth);
		float wave = sin(p.y * 0.045 + TIME * 1.3 + sin(p.x * 0.05 + TIME) * 2.0);
		if (wave > 0.93 && hash(floor(p / vec2(20.0, 8.0))) > 0.45) {
			col += vec3(0.18, 0.22, 0.2);
		}
		vec2 cell = floor(p / 28.0);
		if (dx > canal_water - 26.0 && hash(cell) > 0.8) {
			float r = length(p - (cell + 0.5) * 28.0);
			if (r < 10.0) {
				col = vec3(0.25, 0.55, 0.22) * (0.9 + 0.1 * d);
			}
			if (hash(cell + 7.0) > 0.8 && r < 4.0) {
				col = vec3(0.98, 0.6, 0.75);
			}
		}
	}

	COLOR = vec4(col, 1.0);
}
