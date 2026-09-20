shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform vec3 player_position = vec3(10000.0);
varying vec3 world_position;
void vertex() {
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	VERTEX.x+=sin(TIME*0.8+world_position.x*0.4+world_position.z)*0.014*max(0.0,VERTEX.y-2.0);
}
void fragment() {
	ALBEDO=COLOR.rgb;
	ROUGHNESS=1.0;
	float near_player=smoothstep(2.1,3.5,distance(world_position.xz,player_position.xz));
	float opacity=mix(0.23,1.0,max(near_player,1.0-smoothstep(0.4,1.0,world_position.y)));
	float grain=fract(sin(dot(floor(world_position.xz*19.0+world_position.y*13.0),vec2(12.9898,78.233)))*43758.5453);
	ALPHA=step(grain,opacity);
	ALPHA_SCISSOR_THRESHOLD=0.5;
}
