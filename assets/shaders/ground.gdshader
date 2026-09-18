shader_type spatial;
render_mode diffuse_burley, specular_disabled, cull_disabled;
uniform vec4 base_color : source_color = vec4(0.17, 0.24, 0.19, 1.0);
uniform bool road = false;
uniform bool paving = false;
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p=world_position.xz;
 float patches=noise(p*0.17)*0.5+noise(p*0.63)*0.3+noise(p*2.7)*0.2;
 vec3 earth=mix(vec3(0.115,0.16,0.145),vec3(0.30,0.34,0.20),patches);
 if (road) {
   float edge=smoothstep(0.0,0.13,UV.y)*smoothstep(0.0,0.13,1.0-UV.y);
   edge *= smoothstep(0.12,0.4,noise(p*3.0)+min(UV.y,1.0-UV.y)*2.0);
   earth=mix(earth, base_color.rgb*(0.68+patches*0.7),edge);
   if (paving) {
     vec2 q=p*vec2(1.55,1.85); q.x+=mod(floor(q.y),2.0)*0.5;
     q+=vec2(noise(p*5.0),noise(p*5.0+8.0))*0.065;
     vec2 f=abs(fract(q)-0.5);
     float stone=1.0-smoothstep(0.39,0.47,max(f.x,f.y));
     float bevel=1.0-smoothstep(0.27,0.44,max(f.x,f.y));
     earth=mix(earth*0.53,earth*(0.72+hash(floor(q))*0.32+bevel*0.10),stone);
   } else {
     earth*=0.90+noise(p*12.0)*0.14;
   }
 } else { earth*=0.85+noise(p*13.0)*0.26; }
 ALBEDO=earth; ROUGHNESS=1.0;
}
