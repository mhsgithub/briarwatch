@tool
extends Node3D
## Cutaway vaulted prison. Collision never follows visual cutaways.
const STONE:=Color("424c4d")
const IRON:=Color("303c3e")
func _ready() -> void:
	var floor_mesh:=Geometry.box(self,Vector3(0,-0.25,0),Vector3(20,0.5,30),STONE)
	var material:=ShaderMaterial.new()
	material.shader=preload("res://assets/shaders/tower_stone.gdshader")
	floor_mesh.material_override=material
	Geometry.collider(self,Vector3(0,-0.25,0),Vector3(20,0.5,30))
	for side in [-1,1]:
		Geometry.collider(self,Vector3(side*10,2,0),Vector3(0.7,4,30))
		Geometry.collider(self,Vector3(0,2,side*15),Vector3(20,4,0.7))
		for z in range(-14,15,2):
			var height:=3.6 if side<0 else 0.7
			Geometry.box(self,Vector3(side*9.85,height/2,z),Vector3(0.9,height,1.92),STONE.lightened((z%3)*0.015))
		for x in range(-9,10,2):
			var height:=3.6 if side<0 else 0.65
			Geometry.box(self,Vector3(x,height/2,side*14.85),Vector3(1.92,height,0.9),STONE)
		# Side cells: bars let the player see the unfortunate former captives.
		for z in [-5.5,1.5,8.5]:
			_bars(Vector3(side*5,0,z),Vector3(0.15,2.7,6))
			Geometry.collider(self,Vector3(side*5,1.5,z),Vector3(0.2,3,6))
			Geometry.box(self,Vector3(side*7.4,0.4,z-3.3),Vector3(4.8,0.8,0.4),STONE)
			Geometry.collider(self,Vector3(side*7.4,1.5,z-3.3),Vector3(4.8,3,0.4))
			_skeleton(Vector3(side*7.3,0.1,z))
			Geometry.box(self,Vector3(side*8.4,0.07,z+1.4),Vector3(1.1,0.1,2.1),Color("6e6347"))
		for z in [-8.3,3.8,11.8]:
			var fire:=FireVisual.new()
			fire.position=Vector3(side*4.3,1.55,z)
			fire.flame_height=0.6
			fire.light_energy=1.2
			fire.light_range=9
			add_child(fire)
			Geometry.box(self,Vector3(side*4.3,0.7,z),Vector3(0.24,1.4,0.24),IRON)
	# Back cell: central gap is occupied by the independently interactive gate.
	for side in [-1,1]:
		_bars(Vector3(side*3.1,0,-9),Vector3(3.7,2.7,0.15))
		Geometry.collider(self,Vector3(side*3.1,1.5,-9),Vector3(3.7,3,0.2))
		Geometry.box(self,Vector3(side*5,1.6,-11.8),Vector3(0.35,3.2,5.7),STONE)
		Geometry.collider(self,Vector3(side*5,1.6,-11.8),Vector3(0.35,3.2,5.7))
	Geometry.box(self,Vector3(2.9,0.3,-12.5),Vector3(1.3,0.6,2.5),Color("40382c"))
	Geometry.box(self,Vector3(2.9,0.66,-12.5),Vector3(1.2,0.12,2.3),Color("786a4a"))
	Geometry.cylinder(self,Vector3(-3.5,0.2,-12),0.35,0.4,Color("4f4639"))
	# Wall ribs suggest the vanished roof without covering the combat floor.
	for z in [-12.0,-5.0,2.0,9.0]:
		for side in [-1,1]:
			Geometry.box(self,Vector3(side*9.4,1.8,z),Vector3(0.65,3.6,0.6),Color("64706b"))
			Geometry.beam(self,Vector3(side*9.3,3.5,z),Vector3(side*7.7,4.8,z),0.4,Color("58655f"))
	# Drain, damp patches and discarded chains.
	for z in range(-7,13,3):
		Geometry.box(self,Vector3(0,0.013,z),Vector3(0.4,0.025,1.3),Color("1c2e2b"))
		for i in range(4): Geometry.box(self,Vector3(0,0.032,z-0.45+i*0.3),Vector3(0.42,0.025,0.05),IRON)
	for i in range(8):
		var ring:=Geometry.ring(self,0.11,IRON,0.025)
		ring.position=Vector3(-3.6+i*0.12,0.08,5.7+sin(i)*0.09)
func _bars(point: Vector3, size_value: Vector3) -> void:
	var along_x:=size_value.x>size_value.z
	var length:=maxf(size_value.x,size_value.z)
	for i in range(int(length/0.35)+1):
		var offset:=-length/2+i*0.35
		Geometry.box(self,point+Vector3(offset if along_x else 0,1.35,0 if along_x else offset),Vector3(0.065,2.7,0.065),IRON)
	for y in [0.22,2.6]:
		Geometry.box(self,point+Vector3(0,y,0),Vector3(size_value.x,0.08,size_value.z),Color("52605b"))
func _skeleton(point: Vector3) -> void:
	var bone:=Color("a5a18b")
	Geometry.sphere(self,point+Vector3(0,0.15,-0.65),Vector3(0.32,0.31,0.36),bone)
	for side in [-1,1]:
		Geometry.sphere(self,point+Vector3(side*0.09,0.24,-0.79),Vector3(0.07,0.07,0.05),Color("242b28"))
		Geometry.beam(self,point+Vector3(side*0.17,0,0.2),point+Vector3(side*0.35,0,1.1),0.075,bone)
		Geometry.beam(self,point+Vector3(side*0.28,0,-0.3),point+Vector3(side*0.6,0,0.3),0.065,bone)
	Geometry.beam(self,point+Vector3(0,0,-0.4),point+Vector3(0,0,0.3),0.09,bone)
	for i in range(5): Geometry.box(self,point+Vector3(0,0.035,-0.35+i*0.13),Vector3(0.48,0.06,0.05),bone)

