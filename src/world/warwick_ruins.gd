@tool
extends Node3D
## Broken keep at the user-marked southeast site. Clear entrances remain navigable.
func _ready() -> void:
	var stone:=Color("61685e")
	var ground:=Geometry.box(self,Vector3(0,0.025,0),Vector3(22,0.04,21),Color("424e40"))
	ground.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var paving:=ShaderMaterial.new()
	paving.shader=preload("res://assets/shaders/tower_stone.gdshader")
	ground.material_override=paving
	for side in [-1,1]:
		for z in [-7.0,-3.0,3.0,7.0]:
			var height:=2.2 if z<0 else 0.8
			Geometry.collider(self,Vector3(side*10,height/2,z),Vector3(1.2,height,3.5))
			for row in range(int(height/0.4)):
				Geometry.box(self,Vector3(side*10,0.2+row*0.4,z),Vector3(1.3,0.36,3.4),stone.darkened(row%2*0.05))
		for x in [-7.0,-3.5,3.5,7.0]:
			Geometry.box(self,Vector3(x,0.45,side*9.5),Vector3(3.1,0.9,1.15),stone)
			Geometry.collider(self,Vector3(x,0.45,side*9.5),Vector3(3.1,0.9,1.15))
	for x in [-9.6,9.6]:
		for z in [-9.4,9.4]:
			Geometry.cylinder(self,Vector3(x,1.2,z),1.7,2.4,stone,1.6,8)
			Geometry.collider(self,Vector3(x,1.2,z),Vector3(2.5,2.4,2.5))
			for i in range(4):
				var angle:=i*PI/2
				Geometry.box(self,Vector3(x+sin(angle)*1.1,2.5+0.14*(i%2),z+cos(angle)*1.1),Vector3(0.65,0.6,0.65),stone)
	# Ruined chapel arch and the hood over the cellar stair.
	var hood:=Node3D.new()
	add_child(hood)
	for x in [-1.65,1.65]:
		Geometry.box(hood,Vector3(x,1.4,1.0),Vector3(0.6,2.8,3.3),stone)
		Geometry.collider(self,Vector3(x,1.4,1.0),Vector3(0.6,2.8,3.3))
	Geometry.box(hood,Vector3(0,3,-0.6),Vector3(4,0.4,0.6),stone.darkened(0.1))
	Geometry.box(hood,Vector3(-0.9,2.9,2.5),Vector3(2.1,0.3,0.6),stone.darkened(0.1))
	if not Engine.is_editor_hint(): hood.add_child(ProximityFade.new())
	for i in range(5):
		Geometry.box(self,Vector3(-6+i*0.4,0.12,5+i*0.7),Vector3(1.0,0.22,0.8),stone.darkened(0.13))
	for x in [-4.2,4.2]:
		var fire:=FireVisual.new()
		fire.position=Vector3(x,0.6,-2)
		fire.flame_height=0.6
		fire.light_energy=1.1
		add_child(fire)
		Geometry.cylinder(self,Vector3(x,0.3,-2),0.4,0.6,Color("373b34"),0.5)
	Geometry.box(self,Vector3(-5,0.3,-5),Vector3(2.3,0.6,1.2),Color("5d4a37"))
