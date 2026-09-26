@tool
extends Node3D
## Authored environmental storytelling, never an enemy or edible corpse.
@export var variation: int = 0
func _ready() -> void:
	var soldier := ActorVisual.new()
	soldier.style = "corvin"
	soldier.rotation = Vector3(0,variation*1.7,1.55)
	soldier.position = Vector3(0,0.18,0)
	add_child(soldier)
	Geometry.cylinder(self,Vector3(0,0.025,0),0.75,0.018,Color("262420"),0.75,12)
	var shaft := Geometry.beam(self,Vector3(-0.6,0.1,0.6),Vector3(0.7,0.12,1.1),0.05,Color("66513c"))
	shaft.rotation.y = variation
	var lantern := Geometry.box(self,Vector3(0.6,0.17,-0.6),Vector3(0.25,0.28,0.25),Color("4c4537"))
	lantern.rotation.z = 1.4
