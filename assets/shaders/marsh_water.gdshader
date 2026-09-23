shader_type spatial;
render_mode cull_disabled;
varying vec3 world;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 float ripple = sin(world.x*2.8+world.z*1.6+TIME*0.7)*sin(world.z*3.1-TIME*0.45);
 float scum = smoothstep(0.35,0.85,sin(world.x*0.29+sin(world.z*0.24))*sin(world.z*0.32));
 ALBEDO = mix(vec3(0.065,0.145,0.145),vec3(0.19,0.25,0.13),scum*0.65)+ripple*0.012;
 ROUGHNESS = 0.36; SPECULAR = 0.7;
 NORMAL = normalize(vec3(ripple*0.05,0.0,1.0));
}
