shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;
void fragment() {
	vec2 uv = SCREEN_UV;
	uv.x += sin(uv.y * 65.0 + TIME * 0.65) * 0.00065;
	vec2 offset = vec2(0.0008, 0.0);
	vec3 col = vec3(texture(screen_texture, uv + offset).r, texture(screen_texture, uv).g, texture(screen_texture, uv - offset).b);
	float scan = 0.97 + 0.03 * sin(FRAGCOORD.y * 3.14159);
	vec2 v = SCREEN_UV * (1.0 - SCREEN_UV);
	float vignette = clamp(pow(v.x * v.y * 16.0, 0.18), 0.64, 1.0);
	COLOR = vec4(col * scan * vignette, 1.0);
}
