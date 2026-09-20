@tool
class_name BeastCage
extends Node3D
var gate: Node3D
var barrier: StaticBody3D
var opened: bool = false
var motion: Tween
func _ready() -> void:
	for x in [-3.2,3.2]:
		for z in [-2.5,2.5]:
			Geometry.box(self,Vector3(x,2.1,z),Vector3(0.28,4.2,0.28),Color("353d3b"))
	for z in [-2.5,2.5]:
		for y in [0.25,3.7]:
			Geometry.box(self,Vector3(0,y,z),Vector3(6.6,0.15,0.16),Color("717364"))
	for x in [-3.2,3.2]:
		for i in range(11):
			Geometry.cylinder(self,Vector3(x,1.9,-2.5+i*0.5),0.055,3.8,Color("73786b"))
		Geometry.collider(self,Vector3(x,1.5,0),Vector3(0.2,3,5.2))
	for i in range(13):
		Geometry.cylinder(self,Vector3(-3+i*0.5,1.9,-2.5),0.055,3.8,Color("73786b"))
	Geometry.collider(self,Vector3(0,1.5,-2.5),Vector3(6.5,3,0.2))
	gate = Node3D.new()
	add_child(gate)
	gate.position = Vector3(0,0,2.5)
	for i in range(13):
		Geometry.cylinder(gate,Vector3(-3+i*0.5,1.9,0),0.065,3.8,Color("929482"))
	Geometry.box(gate,Vector3(0,1.5,0.05),Vector3(6.5,0.13,0.12),Color("777866"))
	Geometry.collider(gate,Vector3(0,1.5,0),Vector3(6.5,3,0.24))
	barrier = gate.get_child(gate.get_child_count()-1) as StaticBody3D
	if not Engine.is_editor_hint():
		barrier.collision_layer = 0
		var region := get_parent().get_parent().get_parent() as Region
		region.initialized.connect(func(): barrier.collision_layer = 0 if opened else 1)
func open(animate: bool = true) -> void:
	if opened: return
	opened = true
	# Gate is outside baked geometry; physical collision controls access.
	barrier.collision_layer = 0
	if animate:
		if motion: motion.kill()
		motion=create_tween()
		motion.tween_property(gate,"position:y",4.0,0.8)
		AudioLibrary.play_world(self,global_position,"cage_release",0.7)
	else: gate.position.y=4

func close() -> void:
	if motion: motion.kill()
	opened=false
	gate.position.y=0
	barrier.collision_layer=1
