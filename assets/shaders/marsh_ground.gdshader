shader_type spatial;
render_mode specular_disabled;
varying vec3 world;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p=world.xz;
 float peat=noise(p*0.16)*0.65+noise(p*0.6)*0.35;
 float moss=smoothstep(0.43,0.72,peat);
 vec3 mud=mix(vec3(0.115,0.14,0.125),vec3(0.23,0.225,0.17),noise(p*1.7));
 ALBEDO=mix(mud,vec3(0.21,0.27,0.17),moss)*(0.85+noise(p*13.0)*0.3);
 ROUGHNESS=mix(0.7,1.0,moss);
}
