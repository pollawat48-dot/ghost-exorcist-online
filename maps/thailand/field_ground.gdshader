shader_type spatial;
render_mode cull_back, diffuse_toon, specular_disabled;
// พื้นแผนที่ทั่วไปที่ปรับสีตามธีมได้: หญ้าสองโทน + หย่อมสีรอง, ลานดินตามจุดต่างๆ,
// ลานหินโบราณ (plaza), ลานแคมป์, ทางดิน และแอ่งน้ำ (ponds)

uniform vec2 path_segs[24];
uniform int seg_count = 0;
uniform float path_w = 30.0;
uniform vec3 patches[10];  // x, y, รัศมี
uniform int patch_count = 0;
uniform vec3 ponds[32];
uniform int pond_count = 0;
uniform vec4 plaza = vec4(-1.0, -1.0, 0.0, 0.0);
uniform vec4 camp;
uniform vec3 grass_a : source_color = vec3(0.36, 0.56, 0.48);
uniform vec3 grass_b : source_color = vec3(0.5, 0.66, 0.5);
uniform vec3 tint : source_color = vec3(0.52, 0.47, 0.7);
uniform vec3 patch_col : source_color = vec3(0.7, 0.6, 0.6);
uniform vec3 path_col : source_color = vec3(0.8, 0.68, 0.6);
uniform vec3 camp_col : source_color = vec3(0.86, 0.76, 0.62);
uniform vec3 plaza_col : source_color = vec3(0.76, 0.72, 0.82);
uniform vec3 water_col : source_color = vec3(0.45, 0.72, 0.85);
uniform float tint_amount = 0.7;

varying vec2 wp;

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

// ลายละเอียดบนพื้น ระดับประหยัดใช้ชั้นน้อยลง ลดงานการ์ดจอมือถือ
uniform int detail_octaves = 4;

float fbm_d(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * (i < detail_octaves ? vnoise(p) : 0.5);
		p *= 2.0;
		a *= 0.5;
	}
	return v;
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

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wp = w.xz * 32.0;
	VERTEX.y += (fbm(wp * 0.003) - 0.5) * 0.25;
}

void fragment() {
	vec2 p = wp;
	float n = fbm_d(p * 0.004);
	float fine = fbm_d(p * 0.08);

	vec3 col = mix(grass_a, grass_b, smoothstep(0.3, 0.7, n));
	col = mix(col, tint, smoothstep(0.5, 0.78, fbm_d(p * 0.002 + 7.0)) * tint_amount);
	col *= 0.93 + 0.1 * fine;

	for (int i = 0; i < patch_count; i++) {
		float gd = length(p - patches[i].xy);
		float dry = 1.0 - smoothstep(patches[i].z - 120.0, patches[i].z + fbm_d(p * 0.02) * 60.0, gd);
		col = mix(col, patch_col * (0.92 + 0.12 * fine), dry * 0.8);
	}

	if (plaza.z > 0.0) {
		float td = rect_sdf(p, plaza) + (fbm_d(p * 0.03) - 0.5) * 40.0;
		if (td < 0.0) {
			vec2 t = mod(p - plaza.xy, 40.0);
			vec3 stone = plaza_col * (0.94 + 0.08 * hash(floor((p - plaza.xy) / 40.0)));
			if (t.x < 2.0 || t.y < 2.0) {
				stone *= 0.8;
			}
			stone = mix(stone, grass_b, smoothstep(0.55, 0.75, fbm_d(p * 0.02)) * 0.6);
			col = stone;
		}
	}

	float cd = rect_sdf(p, camp) + (fbm_d(p * 0.03) - 0.5) * 50.0;
	col = mix(camp_col * (0.94 + 0.08 * fine), col, smoothstep(-20.0, 10.0, cd));

	float pd = 1e6;
	for (int i = 0; i < seg_count; i++) {
		pd = min(pd, seg_dist(p, path_segs[i * 2], path_segs[i * 2 + 1]));
	}
	pd += (fine - 0.5) * 10.0;
	col = mix(path_col * (0.94 + 0.08 * fine), col, smoothstep(path_w - 10.0, path_w, pd));

	float rough = 0.95;
	for (int i = 0; i < pond_count; i++) {
		float wd = length(p - ponds[i].xy) + (fbm_d(p * 0.015) - 0.5) * 40.0;
		float bank = 1.0 - smoothstep(ponds[i].z - 10.0, ponds[i].z + 14.0, wd);
		col = mix(col, patch_col * 0.85, bank * 0.6);
		if (wd < ponds[i].z - 12.0) {
			float ripple = sin(wd * 0.25 - TIME * 1.5) * 0.5 + 0.5;
			col = water_col * (0.92 + 0.12 * ripple) + vec3(0.15) * smoothstep(0.7, 1.0, fbm_d(p * 0.01 + TIME * 0.05));
			rough = 0.25;
		}
	}

	float stroke = sin(p.x * 0.35 + fbm_d(p * 0.05) * 6.0) * 0.5 + 0.5;
	col *= 0.97 + 0.04 * stroke;
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = 0.2;
}
