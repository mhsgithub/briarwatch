extends Node
## Composition root and lifecycle coordinator. Mechanics live in child components.
@export var catalog: ContentCatalog
@export var region_scenes: Dictionary = {}
@onready var region: Region = $Region
@onready var player: Player = $Player
@onready var quest: QuestLog = $QuestLog
@onready var hud: GameHUD = $HUD
var testing: bool = false
var initialized: bool = false
var save_pending: bool = false
var exploration: Exploration
var exploration_save_pending: bool = false
var travel: RegionTravel
var music: MusicDirector
var companion: PatrolCompanion

func _ready() -> void:
	testing = "--test" in OS.get_cmdline_user_args()
	get_tree().auto_accept_quit = false
	quest.definition = catalog.quest
	quest.bind(player.inventory)
	player.camera = $Camera
	$Camera.target = player
	player.global_position = region.player_spawn.global_position
	exploration = Exploration.new()
	exploration.configure(region.map_bounds, player)
	add_child(exploration)
	hud.large_map.exploration = exploration
	hud.large_map.quest = quest
	hud.catalog = catalog
	hud.bind(player, quest)
	hud.large_map.bind_region(region)
	hud.map_button.visible = region.map_enabled
	player.interaction_requested.connect(_interact)
	player.feedback.connect(hud.toast)
	player.died.connect(_on_player_died)
	hud.respawn_requested.connect(_respawn)
	hud.service_action.connect(_service)
	hud.save_requested.connect(save_game)
	region.encounter_cleared.connect(quest.encounter_cleared)
	region.enemy_defeated.connect(_enemy_defeated)
	player.inventory.changed.connect(_schedule_save)
	player.actions.changed.connect(_schedule_save)
	player.progression.changed.connect(_schedule_save)
	quest.changed.connect(_schedule_save)
	quest.changed.connect(func():
		if initialized: call_deferred("_sync_story"))
	var saved := {} if testing else SaveStore.read()
	travel = RegionTravel.new()
	travel.scenes = region_scenes
	travel.active = region
	travel.player = player
	travel.exploration = exploration
	travel.catalog = catalog
	add_child(travel)
	travel.restore(saved)
	travel.changed.connect(_region_changed)
	music=MusicDirector.new()
	music.session=self
	add_child(music)
	if saved.is_empty():
		player.inventory.gold = 0
		for id in ["old_sword", "oak_shield", "coat"]:
			var item := catalog.find_item(id)
			player.inventory.equipment[item.slot] = item
		player.inventory.add(catalog.find_item("tonic"))
		player.inventory.changed.emit()
	else:
		player.inventory.restore(saved.inventory, catalog)
		quest.restore(saved.quest)
		if saved.has("progression"):
			player.progression.restore(saved.get("progression",{}))
		else:
			_migrate_progression(travel.states)
		player.abilities.restore(saved.get("cooldowns",{}))
		player.actions.restore(saved.get("actions", []), catalog)
	# Loading is a safe-town recovery, including vitality supplied by saved gear.
	player.health.revive()
	var region_state := travel.state("briar_march")
	region.world_state = travel.world_state("briar_march")
	exploration.restore(region_state.get("exploration", {}))
	exploration.reveal(Vector2(player.global_position.x, player.global_position.z))
	exploration.changed.connect(_exploration_changed)
	var defeated: Variant = region_state.get("defeated", [])
	region.initialize(defeated if defeated is Array else [])
	_restore_loot(region_state.get("loot", []))
	initialized = true
	_sync_story()
	var recovery := saved_recovery_region(saved)
	if recovery != region.region_id: travel.enter(recovery)
	if not saved.is_empty() and not saved.has("progression"): _schedule_save()
	hud.toast("Welcome to %s. Speak with Warden Elric.  [E]" % region.hub_name)

func _interact(target: Node) -> void:
	if player.cinematic_locked: return
	if target is NecromanticMark:
		target.get_parent().inspect(target)
	elif target is RegionPortal:
		if player.dead or player.combat_state.knockdown_left > 0: return
		if not target.required_quest.is_empty() and not quest.is_completed(str(target.required_quest)) and (quest.definition.id!=target.required_quest or not quest.accepted):
			hud.toast(target.locked_message)
			return
		if not target.required_flag.is_empty() and not quest.flags.get(target.required_flag,false):
			hud.toast(target.locked_message)
			return
		AudioLibrary.play_world(player,player.global_position,"cellar_door")
		call_deferred("_travel_to", target.destination, target.arrival)
	elif target is ChapelLever:
		if quest.definition.id != &"drowned_patrol" or not quest.accepted or quest.stage_index == 0:
			hud.toast("Find Corvin's patrol before disturbing the chapel.")
			return
		if not target.opened:
			target.pull()
			quest.flags["chapel_open"] = true
			quest.changed.emit()
			hud.toast("Stone grinds against stone. A stair descends into the crypts.")
	elif target is TreasureChest:
		if target.open(): _schedule_save()
	elif target is PrisonGate:
		if not quest.accepted or quest.definition.id!=&"warwick_rescue" or not quest.cleared:
			hud.toast("Brutus guards the lock. Defeat him first.")
		else:
			quest.flags["kasparov_cell_open"]=true
			target.open()
			_schedule_save()
	elif target is Npc or target is PatrolCompanion:
		if target.definition.id==&"kasparov" and region.interior and not quest.flags.get("kasparov_cell_open",false):
			hud.toast("The iron bars stand between you. Unlock the cell first.")
			return
		hud.show_npc(target)
	elif target is LootDrop:
		var name_text: String = target.interaction_name()
		if target.collect(player.inventory):
			hud.toast("Collected " + name_text)
		else:
			hud.toast("Your pack is full. Sell or equip an item first.")

func _service(action: String, index: int) -> void:
	if player.cinematic_locked: return
	var npc := hud.current_npc
	if not is_instance_valid(npc):
		return
	match action:
		"patrol_report":
			if npc is PatrolCompanion and quest.advance(&"find_patrol"):
				npc.set_following(true)
				hud.close_panel()
				hud.toast("Corvin follows you. Investigate the Sunken Chapel.")
				return
		"travel":
			if npc.definition.id != &"elric" or not quest.is_completed("lions_den"): return
			var destination: StringName = &"briar_march" if region.region_id == &"hollowmere" else &"hollowmere"
			hud.close_panel()
			call_deferred("_travel_to", destination, &"")
			return
		"reset_talents":
			if npc.definition.service != "trainer": return
			if player.reset_talents():
				hud.toast("Your talents have been reset. All spent points are available again.")
				AudioLibrary.play_ui(self,"gold_pickup")
			else:
				hud.toast("You need learned talents and 100 gold.")
		"buy":
			if index >= 0 and index < npc.definition.stock.size():
				if not player.inventory.buy(npc.definition.stock[index]):
					hud.toast("Not enough gold or pack space.")
				else:
					AudioLibrary.play_ui(self,"gold_pickup")
		"sell":
			if player.inventory.sell(index): AudioLibrary.play_ui(self,"gold_pickup")
		"heal":
			player.health.heal(player.health.maximum)
			hud.toast("Your wounds are healed.")
		"accept":
			if str(npc.definition.id) == quest.offered().giver_npc and region.region_id == quest.offered().giver_region: quest.accept()
		"claim":
			if quest.definition.handin_npc==str(npc.definition.id) and region.region_id==quest.definition.handin_region and quest.claim(player.inventory):
				hud.toast(quest.definition.completion_text)
				AudioLibrary.play_ui(self,"gold_pickup")
			else:
				hud.toast(quest.status_text())
		"rescue":
			if npc.definition.id==&"kasparov" and quest.definition.id==&"warwick_rescue" and quest.flags.get("kasparov_cell_open",false) and quest.claim(player.inventory):
				hud.close_panel()
				call_deferred("_finish_rescue")
				return
	hud.show_npc(npc)
	_schedule_save()

func _on_player_died() -> void:
	var malrec := region.get_node_or_null("MalrecEncounter") as MalrecEncounter
	if malrec: malrec.reset_after_player_death()
	var den := region.get_node_or_null("DenEncounter") as DenEncounter
	if den and den.reset_after_player_death():
		if quest.definition.target_encounter==&"bloodfang" and not quest.rewarded:
			quest.cleared=false
			quest.changed.emit()
	player.inventory.gold -= int(ceil(player.inventory.gold * 0.1))
	player.inventory.changed.emit()
	hud.show_death()
	_schedule_save()

func _respawn() -> void:
	if region.region_id != region.recovery_region: travel.enter(region.recovery_region)
	player.respawn(region.player_spawn.global_position)
	$Camera.initialized = false
	_schedule_save()

func _travel_to(destination: StringName, arrival: StringName) -> void:
	if player.dead or player.cinematic_locked: return
	hud.close_panel()
	if travel.enter(destination, arrival):
		hud.toast(region.display_name)
		_schedule_save()

func _region_changed(value: Region) -> void:
	region = value
	player.navigation.path_height_offset = region.navigation_region.navigation_mesh.cell_height
	region.encounter_cleared.connect(quest.encounter_cleared)
	region.enemy_defeated.connect(_enemy_defeated)
	hud.large_map.bind_region(region)
	hud.map_button.visible = region.map_enabled
	$Camera.initialized = false
	$Sun.light_energy = region.interior_sun if region.interior else region.outdoor_sun
	$Environment.environment.ambient_light_energy = region.interior_ambient if region.interior else region.outdoor_ambient
	$Environment.environment.fog_light_color = region.fog_color
	$Environment.environment.fog_density = region.fog_density
	$Environment.environment.fog_enabled = not region.interior
	$Environment.environment.background_color = Color("0c1218") if region.interior else Color(0.075, 0.105, 0.115, 1)
	_sync_story()
	if region.region_id == &"chapel_crypts": quest.advance(&"enter_crypts")
	if region.region_id == &"darkmere_halls": quest.advance(&"enter_hold")
	if region.region_id == &"darkmere_sanctum": quest.advance(&"ascend_hold")

func _sync_story() -> void:
	_sync_companion()
	var lever := region.get_node_or_null("PatrolSite/ChapelLever") as ChapelLever
	if lever: lever.restore(bool(quest.flags.get("chapel_open",false)))
	var gate:=region.get_node_or_null("PrisonGate") as PrisonGate
	if gate and quest.flags.get("kasparov_cell_open",false): gate.open(false)
	if region.region_id==&"briar_march" and quest.is_completed("warwick_rescue") and not region.has_node("NPCs/kasparov"):
		var lord:=Npc.new()
		lord.name="kasparov"
		lord.definition=preload("res://content/npcs/kasparov.tres")
		lord.position=region.get_node("NPCs/iona").position+Vector3(3,0.1,0)
		region.get_node("NPCs").add_child(lord)
	elif region.region_id==&"warwick_cellars" and quest.is_completed("warwick_rescue"):
		var prisoner:=region.get_node_or_null("NPCs/kasparov")
		if prisoner:
			region.get_node("NPCs").remove_child(prisoner)
			prisoner.queue_free()

func _sync_companion() -> void:
	var relevant: bool = quest.definition.id == &"drowned_patrol" and quest.accepted and not quest.rewarded and not quest.flags.get("corvin_fallen",false)
	var escort: bool = relevant and quest.stage_index > 0
	var present: bool = relevant and (region.region_id == &"hollowmere" or escort)
	if not present:
		if is_instance_valid(companion):
			companion.get_parent().remove_child(companion)
			companion.queue_free()
		companion = null
		return
	if not is_instance_valid(companion) or not region.is_ancestor_of(companion):
		companion = PatrolCompanion.new()
		companion.name = "Corvin"
		companion.player = player
		companion.following = escort
		var arrival := region.get_node_or_null("PatrolSite/CorvinArrival") as Marker3D
		companion.position = player.position+Vector3(1,0,1) if escort else arrival.position
		region.get_node("NPCs").add_child(companion)
	companion.set_following(escort)

func _finish_rescue() -> void:
	travel.enter(&"briar_march")
	player.respawn(region.player_spawn.global_position)
	$Camera.initialized=false
	_sync_story()
	hud.toast("Kasparov is safe. Reward received. The lord now waits in Briarwatch.")
	AudioLibrary.play_ui(self,"gold_pickup")
	_schedule_save()

func _schedule_save() -> void:
	if not initialized or testing or save_pending:
		return
	save_pending = true
	call_deferred("_autosave")

func _enemy_defeated(enemy: Enemy) -> void:
	player.progression.grant(enemy.definition.experience)
	_schedule_save()

func _migrate_progression(states: Dictionary) -> void:
	# Credit old recorded defeats exactly once. Read authored SceneState, without
	# spawning historical regions, executing AI, or granting loot again.
	for id: String in region_scenes:
		var region_state: Variant=states.get(id,{})
		if not region_state is Dictionary: continue
		var defeated: Variant=region_state.get("defeated",[])
		if not defeated is Array: continue
		var packed:=load(str(region_scenes[id])) as PackedScene
		if not packed: continue
		var state:=packed.get_state()
		var rewards: Dictionary={}
		for i in range(state.get_node_count()):
			var spawn_id: String=""
			var enemy: EnemyDefinition
			for j in range(state.get_node_property_count(i)):
				match str(state.get_node_property_name(i,j)):
					"spawn_id": spawn_id=str(state.get_node_property_value(i,j))
					"definition": enemy=state.get_node_property_value(i,j) as EnemyDefinition
			if enemy and not spawn_id.is_empty(): rewards[spawn_id]=enemy.experience
		var credited: Dictionary={}
		for spawn_id in defeated:
			if rewards.has(spawn_id) and not credited.has(spawn_id):
				credited[spawn_id]=true
				player.progression.grant(int(rewards[spawn_id]))

func _exploration_changed() -> void:
	if testing or exploration_save_pending: return
	exploration_save_pending=true
	get_tree().create_timer(4.0).timeout.connect(func():
		exploration_save_pending=false
		_schedule_save())

func _autosave() -> void:
	save_pending = false
	_save(false)

func save_game() -> void:
	_save(true)

func _save(notify: bool) -> void:
	if testing:
		return
	var data := {"inventory": player.inventory.serialize(), "quest": quest.serialize(), "regions": travel.snapshot(), "actions": player.actions.serialize(), "progression":player.progression.serialize(), "cooldowns":player.abilities.serialize()}
	data["recovery_region"] = str(region.recovery_region)
	var error := SaveStore.write(data)
	if error != OK:
		hud.toast("Save failed (%d). Your session is still running." % error)
	elif notify:
		hud.toast("Journey saved.")

func _serialize_loot() -> Array:
	return travel.serialize_loot()

func saved_recovery_region(saved: Dictionary) -> StringName:
	var id := str(saved.get("recovery_region", "briar_march"))
	if id == "hollowmere" and quest.is_completed("lions_den"): return &"hollowmere"
	return &"briar_march"

func _restore_loot(data: Variant) -> void:
	travel.restore_loot(data)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save(false)
		get_tree().quit()
