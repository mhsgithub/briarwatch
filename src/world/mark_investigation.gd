class_name MarkInvestigation
extends Node3D
## Site order and stable ambush IDs survive travel, death and loading.
@export var quest_id: StringName = &"unseen_hand"
@export var zombie: EnemyDefinition
@export var archer: EnemyDefinition
@export var brute: EnemyDefinition
@export var note: ItemDefinition
var region: Region
var session: Node
func _ready() -> void:
	region = get_parent() as Region
	session = region.get_parent()
	region.initialized.connect(restore)
	region.enemy_defeated.connect(_defeated)
	session.quest.changed.connect(refresh)
	refresh()
func order() -> Array:
	return region.world_state.get("mark_order",[]).duplicate()
func refresh() -> void:
	var active: bool = session.quest.definition.id==quest_id and session.quest.accepted and not session.quest.rewarded
	for site: NecromanticMark in get_children(): site.refresh(active,str(site.site_id) in order())
func inspect(site: NecromanticMark) -> void:
	if session.quest.definition.id!=quest_id or not session.quest.accepted or session.quest.rewarded: return
	var visited := order()
	if str(site.site_id) in visited: return
	visited.append(str(site.site_id))
	region.world_state["mark_order"] = visited
	spawn_ambush(site,visited.size(),true)
	AudioLibrary.play_world(self,site.global_position,"mark_ambush")
	refresh()
	session.hud.toast("The mark answers. Something stirs beneath the mire.")
	session._schedule_save()
func restore() -> void:
	var visited := order()
	for i in range(visited.size()):
		for site: NecromanticMark in get_children():
			if str(site.site_id)==str(visited[i]): spawn_ambush(site,i+1,false)
	refresh()
func spawn_ambush(site: NecromanticMark, ordinal: int, alert: bool) -> void:
	var types: Array = [zombie,zombie,zombie,brute] if ordinal==3 else [zombie,zombie,zombie,zombie,archer,archer]
	for i in range(types.size()):
		var id := "mark_%s_%d" % [site.site_id,i]
		if id in region.defeated_ids: continue
		var exists := false
		for child in region.actors.get_children():
			if child is Enemy and str(child.spawn_id)==id: exists=true
		if exists: continue
		var actor: Enemy = preload("res://scenes/entities/enemy.tscn").instantiate()
		actor.definition = types[i]
		actor.spawn_id = StringName(id)
		actor.encounter_id = StringName("mark_"+str(site.site_id))
		var angle := TAU*i/types.size()
		var point := site.global_position+Vector3(sin(angle)*6,0,cos(angle)*6)
		actor.position = NavigationServer3D.map_get_closest_point(region.get_world_3d().navigation_map,point)+Vector3.UP*0.1
		region.actors.add_child(actor)
		actor.aggro = alert
		region.register_summon(actor)
func _defeated(actor: Enemy) -> void:
	if actor.definition != brute or not str(actor.spawn_id).begins_with("mark_"): return
	if region.world_state.get("dark_note_dropped",false): return
	region.world_state["dark_note_dropped"] = true
	var drop := LootDrop.new()
	drop.item = note
	drop.source_id = str(actor.spawn_id)
	region.actors.add_child(drop)
	drop.global_position = actor.global_position+Vector3(0,0,0.7)
