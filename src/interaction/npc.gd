@tool
class_name Npc
extends Node3D
@export var definition: NpcDefinition:
	set(value):
		definition = value
		if is_inside_tree():
			call_deferred("_build")

func _ready() -> void:
	_build()
	if not Engine.is_editor_hint():
		add_to_group("interactables")

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if not definition:
		return
	var visual := ActorVisual.new()
	visual.style = "npc"
	visual.tint = definition.tint
	add_child(visual)
	Geometry.label(self, "%s\n%s" % [definition.display_name, definition.title], Vector3(0, 2.5, 0), Color("ecd39b"), 25)

func interaction_name() -> String:
	return "Speak with " + definition.display_name
