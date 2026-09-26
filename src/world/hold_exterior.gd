@tool
class_name HoldExterior
extends Node3D
## Roofless gate keep, drawn around an open approach at the northwest road end.
func _ready() -> void:
	var stone:=Color("4b5753")
	for x in [-9,9]:
		Geometry.cylinder(self,Vector3(x,3.5,0),3.1,7,stone,3.0,10)
		Geometry.collider(self,Vector3(x,3.3,0),Vector3(5.4,6.6,5.4))
		for i in range(7):
			var a:=TAU*i/8
			Geometry.box(self,Vector3(x+sin(a)*2.6,7.3+(i%3)*0.22,cos(a)*2.6),Vector3(0.9,0.9,0.9),stone)
		for y in [2.0,4.5]: Geometry.box(self,Vector3(x,y,3.03),Vector3(0.28,1.2,0.08),Color("171e20"))
	Geometry.box(self,Vector3(0,4.0,-7),Vector3(20,8,0.9),stone)
	Geometry.collider(self,Vector3(0,3,-7),Vector3(20,6,0.9))
	for x in [-4,4]:
		Geometry.box(self,Vector3(x,2.1,0),Vector3(4.2,4.2,0.8),stone)
		Geometry.collider(self,Vector3(x,2,0),Vector3(4.2,4,0.8))
	Geometry.box(self,Vector3(0,4.45,0),Vector3(5,0.6,1.2),stone.lightened(0.08))
	for i in range(5):
		Geometry.box(self,Vector3(-7+i*3.5,8.3,-7),Vector3(1.4,0.7+(i%2)*0.7,1.1),stone)
	Geometry.box(self,Vector3(0,1.7,-6.45),Vector3(3.0,3.4,0.1),Color("101819"))
	for i in range(7):
		var p:=Vector3(4.7+i*0.7,0.3,3.8+(i%3)*0.7)
		var rubble:=Geometry.box(self,p,Vector3(1,0.6,0.8),stone)
		rubble.rotation.y=i*0.7
