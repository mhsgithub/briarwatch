shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void fragment() {
 vec2 p=UV*2.0-1.0;
 float edge=smoothstep(1.0,0.15,length(p));
 float drift=sin(UV.x*12.0+TIME*0.13+sin(UV.y*8.0-TIME*0.09))*0.5+0.5;
 ALBEDO=vec3(0.38,0.48,0.45);
 ALPHA=edge*(0.055+drift*0.095);
}
