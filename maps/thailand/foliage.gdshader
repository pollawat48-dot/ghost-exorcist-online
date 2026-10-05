shader_type spatial;
render_mode cull_disabled, diffuse_toon, specular_disabled;
// ต้นข้าวและหญ้า: ไหวตามลม สีมาจาก vertex color (โคนเข้ม ปลายอ่อน) คูณสีของแต่ละกอ

uniform float wind = 0.12;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float sway = sin(TIME * 1.8 + w.x * 0.6 + w.z * 0.4) + 0.4 * sin(TIME * 3.1 + w.x * 1.7);
	VERTEX.x += sway * wind * VERTEX.y;
	VERTEX.z += sway * wind * 0.5 * VERTEX.y;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.8;
	BACKLIGHT = vec3(0.3, 0.35, 0.15);
}
