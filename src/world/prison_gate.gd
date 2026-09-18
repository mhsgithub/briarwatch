@tool
class_name PrisonGate
extends Node3D
var opened: bool = false
var bars: Node3D
var body: StaticBody3D
func _ready() -> void:
	bars=Node3D.new()
	add_child(bars)
	for i in range(7):
		Geometry.box(bars,Vector3(-1.05+i*0.35,1.3,0),Vector3(0.07,2.6,0.09),Color("394446"))
	for y in [0.2,1.4,2.5]: Geometry.box(bars,Vector3(0,y,0),Vector3(2.3,0.09,0.13),Color("505b59"))
	Geometry.box(bars,Vector3(0.65,1.2,-0.12),Vector3(0.22,0.32,0.12),Color("a28652"))
	body=StaticBody3D.new()
	add_child(body)
	var shape:=CollisionShape3D.new()
	var box:=BoxShape3D.new()
	box.size=Vector3(2.45,3,0.2)
	shape.shape=box
	shape.position.y=1.5
	body.add_child(shape)
	if not Engine.is_editor_hint(): add_to_group("interactables")
func interaction_name() -> String:
	return "Unlock Kasparov's cell"
func open(with_sound: bool = true) -> void:
	if opened: return
	opened=true
	body.collision_layer=0
	body.collision_mask=0
	remove_from_group("interactables")
	if with_sound: AudioLibrary.play_world(self,global_position,"cell_unlock",0.85)
	var tween:=create_tween()
	tween.tween_property(bars,"position:x",2.4,0.5)

