shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D tex : source_color, filter_nearest, repeat_enable;
uniform float pulse = 0.0;
uniform float fold = 0.0;
uniform bool floor_warp = false;
uniform vec3 tint : source_color = vec3(1.0);
void vertex() {
	VERTEX.x += sin(VERTEX.z * 0.5 + TIME) * fold * 0.3;
	VERTEX.y += sin(VERTEX.x * 0.6 + TIME) * fold * 0.18;
}
void fragment() {
	vec2 uv = UV;
	if (floor_warp) {
		uv += vec2(sin(UV.y * 3.0 + TIME * 0.18), cos(UV.x * 3.0)) * (0.025 + pulse * 0.035);
	}
	vec3 col = texture(tex, uv).rgb * tint;
	float d = length(VERTEX);
	float checker = mod(floor(FRAGCOORD.x) + floor(FRAGCOORD.y), 2.0);
	float light = clamp(1.1 - d * 0.038 + (checker - 0.5) * 0.045, 0.27, 1.0);
	col *= light;
	col = mix(col, col.brg * vec3(1.2, 0.7, 1.1), pulse * 0.32);
	col = floor(col * 26.0 + checker * 0.45) / 26.0;
	ALBEDO = mix(col, vec3(0.035, 0.012, 0.045), smoothstep(8.0, 28.0, d) * 0.85);
}
