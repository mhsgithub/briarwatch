@tool
class_name TreasureChest
extends Node3D
@export var chest_id: String = "woods_cache"
@export var gold: int = 15
@export var display_name: String = "bandit chest"
@export var items: Array[ItemDefinition] = []
var lid: Node3D
var opened: bool = false
var region: Region
func _ready() -> void:
	Geometry.box(self,Vector3(0,0.43,0),Vector3(1.5,0.85,0.95),Color("49392d"))
	for x in [-0.56,0.56]:
		Geometry.box(self,Vector3(x,0.43,0),Vector3(0.12,0.91,1.02),Color("777c70"))
	lid = Node3D.new()
	add_child(lid)
	lid.position = Vector3(0,0.83,0.46)
	Geometry.box(lid,Vector3(0,0,-0.46),Vector3(1.55,0.18,1.0),Color("66503a"))
	for x in [-0.56,0.56]:
		Geometry.box(lid,Vector3(x,0.09,-0.46),Vector3(0.12,0.04,1.0),Color("8c886b"))
	Geometry.box(lid,Vector3(0,-0.12,-0.99),Vector3(0.23,0.3,0.07),Color("b39350"))
	if Engine.is_editor_hint(): return
	region = get_parent() as Region
	opened = bool(region.world_state.get(chest_id,false))
	lid.rotation.x = -1.6 if opened else 0.0
	if not opened: add_to_group("interactables")
func interaction_name() -> String:
	return "Open " + display_name
func open() -> bool:
	if opened: return false
	opened = true
	region.world_state[chest_id] = true
	remove_from_group("interactables")
	create_tween().tween_property(lid,"rotation:x",-1.6,0.45)
	if gold>0:
		var coins := LootDrop.new()
		coins.gold = gold
		region.actors.add_child(coins)
		coins.global_position = global_position+Vector3(0,0,1.1)
		GameAudio.play_drop(region.actors,coins.global_position,false)
	for i in range(items.size()):
		var drop := LootDrop.new()
		drop.item = items[i]
		region.actors.add_child(drop)
		drop.global_position = global_position+Vector3(-0.8+i*0.65,0,1.6)
		GameAudio.play_drop(region.actors,drop.global_position,true)
	AudioLibrary.play_world(self,global_position,"chest_open")
	return true
