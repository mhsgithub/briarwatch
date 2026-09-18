shader_type spatial;
render_mode diffuse_burley;
varying vec3 local_position;
void vertex() { local_position = VERTEX; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 p = local_position.xz * 0.72;
	p.x += mod(floor(p.y), 2.0) * 0.5;
	vec2 cell = floor(p);
	vec2 edge = min(fract(p), 1.0 - fract(p));
	float grout = smoothstep(0.012, 0.038, min(edge.x, edge.y));
	float grain = hash(floor(local_position.xz * 90.0));
	vec3 stone = mix(vec3(0.24, 0.28, 0.29), vec3(0.38, 0.40, 0.37), hash(cell));
	float ring = 1.0 - smoothstep(0.035, 0.065, abs(length(local_position.xz) - 8.4));
	stone = mix(stone, vec3(0.49, 0.43, 0.30), ring * 0.7);
	ALBEDO = mix(vec3(0.11, 0.14, 0.15), stone * (0.91 + grain * 0.12), grout);
	ROUGHNESS = 0.94;
}
