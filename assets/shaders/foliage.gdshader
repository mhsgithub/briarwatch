shader_type spatial;
render_mode cull_disabled, specular_disabled;
varying vec4 instance_color;
void vertex() {
 vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 VERTEX.x+=sin(TIME*1.4+world.x*0.7+world.z*0.2)*VERTEX.y*0.12;
 instance_color=COLOR;
}
void fragment() {
 ALBEDO=instance_color.rgb;
 ROUGHNESS=1.0;
}
