@tool
class_name NecromanticMark
extends Node3D
@export var site_id: StringName
@export var display_name: String = "Necromantic mark"
var spent: bool = false
var glyph: Node3D
var light: OmniLight3D
func _ready() -> void:
	glyph = Node3D.new()
	add_child(glyph)
	for radius in [0.8,1.2]:
		var ring := Geometry.ring(glyph,radius,Color("705985"),0.045)
		ring.material_override = Geometry.material(Color("59466c"),0.7)
	for i in range(6):
		var a := TAU*i/6
		var line := Geometry.beam(glyph,Vector3(sin(a),0.06,cos(a))*1.1,Vector3(sin(a+2.1),0.06,cos(a+2.1))*0.8,0.04,Color("8c6ba2"))
		line.material_override = Geometry.material(Color("70518b"),0.8)
	light = OmniLight3D.new()
	light.position.y = 0.5
	light.light_color = Color("7b5c9c")
	light.omni_range = 5
	light.light_energy = 0.6
	add_child(light)
	if not Engine.is_editor_hint(): add_to_group("interactables")
func refresh(active: bool, used: bool) -> void:
	spent = used
	visible = active
	light.visible = not used
	glyph.scale = Vector3.ONE*(0.72 if used else 1.0)
	if active and not used: add_to_group("interactables")
	else: remove_from_group("interactables")
func interaction_name() -> String:
	return "Inspect the dark mark"
func _process(delta: float) -> void:
	if not spent: glyph.rotation.y += delta*0.1
