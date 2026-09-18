shader_type canvas_item;
void fragment() {
 vec2 p=UV*2.0-1.0;
 float shade=smoothstep(0.35,1.45,length(p*vec2(0.8,1.0)))*0.32;
 COLOR=vec4(0.018,0.025,0.028,shade);
}
