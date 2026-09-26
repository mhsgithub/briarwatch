@tool
class_name RegionPortal
extends Node3D
## Authored interaction doorway. Destinations resolve through RegionTravel's registry.
@export var display_name: String = "Enter watchtower"
@export var destination: StringName
@export var arrival: StringName
@export var required_quest: StringName
@export var required_flag: String
@export var locked_message: String = "Speak with Warden Elric about Kasparov's rescue first."
@export_enum("door", "woods", "stairs") var appearance: String = "door"

func _ready() -> void:
	if not Engine.is_editor_hint(): add_to_group("interactables")
	if appearance == "stairs":
		Geometry.box(self,Vector3(0,0.025,0),Vector3(2.6,0.05,3.0),Color("0b1213"))
		for i in range(5):
			Geometry.box(self,Vector3(0,0.07,1.1-i*0.5),Vector3(2.4,0.08,0.38),Color("72786b").darkened(i*0.15))
		for side in [-1,1]: Geometry.box(self,Vector3(side*1.4,0.23,0),Vector3(0.25,0.46,3.25),Color("5c655d"))
		Geometry.label(self,display_name+"  [E]",Vector3(0,1.7,0),Color("d6bc85"),23)
		return
	if appearance == "woods":
		Geometry.label(self, display_name + "  [E]", Vector3(0, 2.3, 0), Color("d6bc85"), 23)
		return
	for side in [-1, 1]:
		Geometry.box(self, Vector3(side * 1.12, 1.45, 0.06), Vector3(0.32, 2.9, 0.4), Color("64716a"))
	Geometry.box(self, Vector3(0, 2.92, 0.06), Vector3(2.55, 0.35, 0.45), Color("748076"))
	Geometry.box(self, Vector3(0, 1.4, 0.1), Vector3(1.94, 2.8, 0.17), Color("201f1c"))
	for i in range(6):
		Geometry.box(self, Vector3(-0.80 + i * 0.32, 1.38, -0.04), Vector3(0.30, 2.68, 0.18), Color("4d4133").lightened((i % 2) * 0.04))
	for y in [0.6, 2.15]:
		Geometry.box(self, Vector3(0, y, -0.15), Vector3(1.88, 0.13, 0.07), Color("252e2d"))
	var handle := Geometry.ring(self, 0.13, Color("bc9e65"), 0.027)
	handle.position = Vector3(0.55, 1.2, -0.22)
	handle.rotation.x = PI / 2
	Geometry.label(self, display_name + "  [E]", Vector3(0, 3.5, 0), Color("d6bc85"), 23)

func interaction_name() -> String:
	return display_name
