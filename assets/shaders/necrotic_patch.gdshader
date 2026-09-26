shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float fade : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 p = (UV - 0.5) * 2.12;
	float r = length(p);
	float swirl = sin(atan(p.y, p.x) * 7.0 + r * 14.0 - TIME * 2.6);
	float boiling = sin(p.x * 18.0 + TIME * 5.2) * sin(p.y * 16.0 - TIME * 4.1);
	float flecks = pow(max(0.0, boiling), 8.0);
	float body = 1.0 - smoothstep(0.78, 1.0, r);
	vec3 dark = vec3(0.025, 0.018, 0.038);
	vec3 pulse = vec3(0.16, 0.075, 0.20);
	ALBEDO = mix(dark, pulse, 0.34 + 0.23 * swirl + 0.23 * flecks);
	EMISSION = vec3(0.28, 0.11, 0.35) * (flecks * 0.45 + smoothstep(0.75, 0.92, r) * 0.16);
	ALPHA = body * (0.82 + 0.10 * boiling) * fade;
}
