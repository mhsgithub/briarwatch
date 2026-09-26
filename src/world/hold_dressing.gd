@tool
class_name HoldDressing
extends Node3D
@export var upper: bool = false
func _ready() -> void:
	var stone:=Color("4c514e")
	var wood:=Color("302c28")
	if upper:
		for x in [-17,17]:
			for z in [-8,7]:
				var fire:=FireVisual.new()
				fire.position=Vector3(x,2.0,z)
				fire.flame_height=0.6
				fire.light_range=7
				fire.light_energy=0.9
				fire.sound_enabled=false
				fire.embers_enabled=false
				add_child(fire)
				Geometry.beam(self,Vector3(x,1.5,z),Vector3(x,2,z),0.12,Color("675d44"))
		# A ruined dais, empty throne and torn hanging banners.
		Geometry.box(self,Vector3(0,0.15,-13),Vector3(9,0.3,3),stone)
		Geometry.box(self,Vector3(0,1.4,-13.5),Vector3(1.5,2.8,0.45),wood)
		Geometry.box(self,Vector3(0,0.7,-13),Vector3(1.5,0.35,1.1),wood)
		for x in [-11,11]:
			Geometry.box(self,Vector3(x,2.8,-15.6),Vector3(1.8,3.2,0.04),Color("453647"))
			for i in range(3): Geometry.box(self,Vector3(x-0.6+i*0.6,1.03-(i%2)*0.3,-15.6),Vector3(0.55,0.8,0.04),Color("453647"))
	else:
		for p in [Vector3(-17.6,0,14),Vector3(-17.6,0,9),Vector3(-17.6,0,-24)]:
			Geometry.box(self,p+Vector3(0,0.42,0),Vector3(1.6,0.22,2.7),wood)
			Geometry.box(self,p+Vector3(0,0.57,0),Vector3(1.4,0.15,2.5),Color("393f39"))
			for z in [-1.1,1.1]: Geometry.box(self,p+Vector3(0,0.2,z),Vector3(1.5,0.4,0.12),wood)
		for p in [Vector3(19,0,-13),Vector3(19,0,-3),Vector3(17.7,0,-13)]:
			Geometry.cylinder(self,p+Vector3.UP*0.5,0.5,1,wood,0.45,9)
			for y in [0.15,0.8]:
				var band:=Geometry.ring(self,0.51,Color("4d504a"),0.035)
				band.position=p+Vector3.UP*y
		for p in [Vector3(-18,2.5,18),Vector3(20,2.8,-15),Vector3(-18,2.5,-29)]:
			for i in range(5):
				Geometry.beam(self,p,p+Vector3(2.2-i*0.45,-i*0.24,1.5),0.012,Color("747a71"))
			Geometry.beam(self,p+Vector3(1.8,-0.2,1.3),p+Vector3(0.4,-1,1.3),0.012,Color("747a71"))
		for z in [17,-12]:
			Geometry.box(self,Vector3(-3,0.65,z),Vector3(1.3,0.16,3.7),wood)
			Geometry.collider(self,Vector3(-3,0.4,z),Vector3(1.3,0.8,3.7))
			for side in [-1,1]: Geometry.box(self,Vector3(-3+side*0.48,0.32,z),Vector3(0.12,0.64,3.2),wood)
		for p in [Vector3(-11,0,9),Vector3(12,0,-10),Vector3(-12,0,-23)]:
			for i in range(3):
				Geometry.box(self,p+Vector3(i*0.7,0.15,i*0.4),Vector3(0.7,0.3,0.5),stone)
			Geometry.beam(self,p+Vector3(-1,0.1,-2),p+Vector3(2,0.3,1),0.15,wood)
		# Cool light from broken high windows; no torches on this floor.
		for z in [14,-7,-25]:
			var light:=OmniLight3D.new()
			light.position=Vector3(0,3,z)
			light.light_color=Color("718b9b")
			light.light_energy=0.45
			light.omni_range=12
			add_child(light)
	for i in range(10):
		var step:=Vector3(0,i*0.13,(-13 if upper else -29)-i*0.35)
		Geometry.box(self,step,Vector3(3,0.22,0.34),stone)
