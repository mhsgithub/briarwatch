@tool
class_name ChapelLever
extends Node3D
var arm: Node3D
var opened: bool = false

func _ready() -> void:
	Geometry.box(self,Vector3(0,0.35,0),Vector3(0.8,0.7,0.65),Color("4c5650"))
	arm = Node3D.new()
	arm.position.y = 0.65
	add_child(arm)
	Geometry.beam(arm,Vector3.ZERO,Vector3(0,0.75,0),0.09,Color("877d5c"))
	Geometry.box(arm,Vector3(0,0.78,0),Vector3(0.5,0.11,0.14),Color("baa378"))
	Geometry.label(self,"Old chapel lever",Vector3(0,1.9,0),Color("d4c096"),22)
	if not Engine.is_editor_hint(): add_to_group("interactables")

func interaction_name() -> String:
	return "The stair is open" if opened else "Pull the chapel lever"

func restore(value: bool) -> void:
	opened = value
	arm.rotation.x = 0.85 if value else -0.6

func pull() -> void:
	opened = true
	create_tween().tween_property(arm,"rotation:x",0.85,0.5)
	AudioLibrary.play_world(self,global_position,"crypt_lever")
