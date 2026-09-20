@tool
extends Node3D
func _ready() -> void:
	var earth := Geometry.cylinder(self,Vector3(0,0.04,0),18.5,0.04,Color("49463a"),18.5,64)
	earth.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Geometry.ring(self,16.4,Color("696654"),0.16)
	for i in range(24):
		var a := i*TAU/24
		var stone := Geometry.box(self,Vector3(sin(a)*16.4,0.12,cos(a)*16.4),Vector3(0.5,0.24,0.75),Color("59615b"))
		stone.rotation.y=a
	for x in [-11,11]:
		for z in [-8,6]:
			Geometry.cylinder(self,Vector3(x,0.35,z),0.65,0.7,Color("3d4643"),0.75,8)
			var fire := FireVisual.new()
			fire.position=Vector3(x,0.7,z)
			fire.light_energy=1
			fire.flame_height=0.7
			add_child(fire)
	for i in range(8):
		var a := i*TAU/8
		Geometry.beam(self,Vector3(sin(a)*5,0.08,cos(a)*5),Vector3(sin(a+0.5)*7,0.08,cos(a+0.5)*7),0.055,Color("652d28"))
