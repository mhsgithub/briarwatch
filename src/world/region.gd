class_name Region
extends Node3D

signal enemy_defeated(enemy: Enemy)
signal encounter_cleared(id: StringName)
signal initialized
@export var display_name: String = "The Briar March"
@export var region_id: StringName = &"briar_march"
@export var interior: bool = false
@export var map_enabled: bool = true
@export var music_track: StringName = &"wilderness"
@export var local_music_track: StringName
@export var local_music_bounds: Rect2
@export var encounter_music_track: StringName
@export var interior_ambient: float = 0.42
@export var interior_sun: float = 0.35
@export var map_bounds := Rect2(-80, -72, 160, 144)
@onready var navigation_region: NavigationRegion3D = $NavigationRegion
@onready var actors: Node3D = $Actors
@onready var player_spawn: Marker3D = $PlayerSpawn
var defeated_ids: Array[String] = []
var encounter_counts: Dictionary = {}
var rng := RandomNumberGenerator.new()
var world_state: Dictionary = {}

func _enter_tree() -> void:
	# The active region owns the world map's rasterization settings. Configure
	# before its NavigationRegion enters, including cached meshes on re-entry.
	var nav := get_node("NavigationRegion") as NavigationRegion3D
	var map := get_world_3d().navigation_map
	NavigationServer3D.map_set_cell_size(map, nav.navigation_mesh.cell_size)
	NavigationServer3D.map_set_cell_height(map, nav.navigation_mesh.cell_height)

func initialize(defeated: Array) -> void:
	rng.randomize()
	for id in defeated:
		if id is String and not defeated_ids.has(id):
			defeated_ids.append(id)
	# Collision geometry is already ready when the session calls this method.
	# Startup must finish synchronization before exposing a playable map. For this
	# single static region, a synchronous map avoids an async first-query race.
	NavigationServer3D.map_set_use_async_iterations(navigation_region.get_navigation_map(), false)
	navigation_region.bake_navigation_mesh(false)
	NavigationServer3D.map_force_update(navigation_region.get_navigation_map())
	for encounter in $Encounters.get_children():
		if not encounter is Encounter:
			continue
		encounter_counts[encounter.encounter_id] = 0
		for marker in encounter.markers():
			if str(marker.spawn_id) in defeated_ids:
				continue
			var enemy: Enemy = marker.spawn(actors, encounter.encounter_id)
			if enemy:
				encounter_counts[encounter.encounter_id] += 1
				enemy.defeated.connect(_on_defeated)
		if encounter_counts[encounter.encounter_id] == 0:
			encounter_cleared.emit(encounter.encounter_id)
	initialized.emit()

func register_summon(enemy: Enemy) -> void:
	encounter_counts[enemy.encounter_id] = int(encounter_counts.get(enemy.encounter_id,0)) + 1
	enemy.defeated.connect(_on_defeated)

func _on_defeated(enemy: Enemy) -> void:
	var credited: Array = world_state.get("credited_defeats",defeated_ids.duplicate())
	var new_reward := not str(enemy.spawn_id) in credited
	if new_reward: credited.append(str(enemy.spawn_id))
	world_state["credited_defeats"] = credited
	defeated_ids.append(str(enemy.spawn_id))
	encounter_counts[enemy.encounter_id] -= 1
	var table := enemy.definition.loot_table
	if table and new_reward:
		var rolled := table.roll(rng)
		if rolled.gold > 0:
			var drop := LootDrop.new()
			drop.gold = rolled.gold
			drop.source_id = str(enemy.spawn_id)
			actors.add_child(drop)
			drop.global_position = enemy.global_position
			GameAudio.play_drop(actors, drop.global_position, false)
		for item in rolled.items:
			var item_drop := LootDrop.new()
			item_drop.item = item
			item_drop.source_id = str(enemy.spawn_id)
			actors.add_child(item_drop)
			item_drop.global_position = enemy.global_position + Vector3(rng.randf_range(-0.8, 0.8), 0, 0.8)
			GameAudio.play_drop(actors, item_drop.global_position, true)
	if encounter_counts[enemy.encounter_id] <= 0:
		encounter_cleared.emit(enemy.encounter_id)
	if new_reward: enemy_defeated.emit(enemy)

func reset_encounters() -> void:
	for actor in actors.get_children():
		actors.remove_child(actor)
		actor.queue_free()
	defeated_ids.clear()
	encounter_counts.clear()
	world_state.erase("credited_defeats")
	initialize([])
