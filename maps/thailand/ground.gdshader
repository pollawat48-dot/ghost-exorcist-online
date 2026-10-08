shader_type spatial;
render_mode cull_back, diffuse_toon, specular_disabled;
// พื้นดิน 3D ของแผนที่ไทย: หญ้า, ลานวัด, ทางดิน, ทุ่งนา, ป่ากล้วย, ป่าช้า, ตลิ่งคลอง

#include "res://maps/thailand/terrain.gdshaderinc"

varying vec2 wp;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wp = w.xz * 32.0;
	float h = ground_height(wp);
	VERTEX.y += h;
	float e = 8.0;
	float hx = ground_height(wp + vec2(e, 0.0)) - ground_height(wp - vec2(e, 0.0));
	float hz = ground_height(wp + vec2(0.0, e)) - ground_height(wp - vec2(0.0, e));
	NORMAL = normalize(vec3(-hx, 2.0 * e / 32.0, -hz));
}

void fragment() {
	vec2 p = wp;
	float n = fbm_d(p * 0.004);
	float d = hash(floor(p / 3.0));
	float fine = fbm_d(p * 0.08);

	// โทนพาสเทลแบบภาพวาดสีเทียน: สีอ่อน มีลายกระดาษ/ฝีแปรงจางๆ
	vec3 col = mix(vec3(0.6, 0.8, 0.44), vec3(0.74, 0.88, 0.54), smoothstep(0.3, 0.7, n));
	col *= 0.93 + 0.1 * fine;

	float gv = 1.0 - smoothstep(-60.0, 40.0, rect_sdf(p, grove) + (fbm_d(p * 0.015) - 0.5) * 120.0);
	col = mix(col, vec3(0.48, 0.7, 0.4) * (0.92 + 0.12 * fine), 0.7 * gv);

	float gd = length(p - grave_center);
	float dry = (1.0 - smoothstep(grave_r - 140.0, grave_r + fbm_d(p * 0.02) * 60.0, gd)) * 0.85;
	col = mix(col, vec3(0.86, 0.78, 0.62) * (0.92 + 0.12 * fine), dry);

	if (in_rect(p, courtyard)) {
		vec2 t = mod(p - courtyard.xy, 32.0);
		col = vec3(1.0, 0.95, 0.88) * (0.96 + 0.04 * d);
		if (t.x < 1.5 || t.y < 1.5) {
			col = vec3(0.93, 0.82, 0.78);
		}
	}

	if (in_rect(p, paddy)) {
		vec2 c = mod(p - paddy.xy, plot);
		if (c.x < 16.0 || c.y < 16.0) {
			col = vec3(0.8, 0.82, 0.55) * (0.92 + 0.12 * fine);
		} else {
			col = mix(vec3(0.55, 0.72, 0.62), vec3(0.65, 0.8, 0.7), fine);
		}
	}

	float pd = path_dist(p) + (fine - 0.5) * 10.0;
	vec3 dirt = vec3(0.97, 0.87, 0.68) * (0.94 + 0.08 * fine);
	col = mix(dirt, col, smoothstep(path_w - 10.0, path_w, pd));

	float dx = abs(p.x - canal_center(p.y));
	col = mix(vec3(0.9, 0.78, 0.6) * (0.92 + 0.1 * fine), col, smoothstep(canal_bank - 12.0, canal_bank + 4.0, dx));

	// ฝีแปรงจางๆ ให้ดูเป็นภาพวาด
	float stroke = sin(p.x * 0.35 + fbm_d(p * 0.05) * 6.0) * 0.5 + 0.5;
	col *= 0.97 + 0.04 * stroke;
	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}
