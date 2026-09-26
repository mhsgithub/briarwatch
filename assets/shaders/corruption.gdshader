shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void fragment() {
	vec2 p = (UV-0.5)*2.15;
	float r = length(p);
	float ripple = sin(r*24.0-TIME*3.0+sin(p.x*9.0+p.y*7.0)*1.4);
	float veins = pow(max(0.0,sin(p.x*21.0+sin(p.y*14.0+TIME)*2.0)),8.0);
	float edge = smoothstep(0.98,0.76,r);
	vec3 ink = mix(vec3(0.035,0.025,0.045),vec3(0.13,0.23,0.055),ripple*0.3+0.5);
	ALBEDO = ink + vec3(0.20,0.31,0.07)*(veins*0.18+smoothstep(0.7,0.88,r)*0.28);
	ALPHA = edge*0.9;
}
