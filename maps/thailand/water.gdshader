shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_always;
// น้ำในคลอง: สะท้อนท้องฟ้า มีคลื่นเล็กๆ

uniform vec3 deep_color : source_color = vec3(0.06, 0.22, 0.24);
uniform vec3 shallow_color : source_color = vec3(0.22, 0.42, 0.36);

float wave(vec2 p, float t) {
	return sin(p.x * 1.7 + t * 1.3) * 0.5 + sin(p.y * 2.3 - t * 1.1) * 0.5
		+ sin((p.x + p.y) * 3.1 + t * 2.0) * 0.25;
}

void fragment() {
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME;
	float e = 0.05;
	float hx = wave(w.xz + vec2(e, 0.0), t) - wave(w.xz - vec2(e, 0.0), t);
	float hz = wave(w.xz + vec2(0.0, e), t) - wave(w.xz - vec2(0.0, e), t);
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(vec3(-hx * 0.15, 1.0, -hz * 0.15)), 0.0)).xyz);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = mix(deep_color, shallow_color, 0.4 + 0.3 * fres);
	ALPHA = 0.88;
	ROUGHNESS = 0.06;
	METALLIC = 0.1;
	SPECULAR = 0.7;
}
