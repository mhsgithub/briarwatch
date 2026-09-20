class_name DenEncounter
extends Node3D
## Coordinates both bosses; no UI text is used to announce mechanics.
@export var cage_path: NodePath
var region: Region
var cage: BeastCage
var garrick: Enemy
var bloodfang: Enemy
var released: bool = false
var started: bool = false
var resetting: bool = false
var speech: Label3D
var speech_tween: Tween

func music_active() -> bool:
	if not started: return false
	return (is_instance_valid(garrick) and garrick.health.current>0) or (released and is_instance_valid(bloodfang) and bloodfang.health.current>0)

func _physics_process(_delta: float) -> void:
	if not started and is_instance_valid(garrick) and garrick.aggro and not garrick.target.dead:
		started=true
		_say(garrick.definition.den_boss.encounter_dialogue)

func _say(line: String) -> void:
	if not is_instance_valid(garrick): return
	if speech_tween and speech_tween.is_valid(): speech_tween.kill()
	if is_instance_valid(speech): speech.queue_free()
	var label := Geometry.label(garrick,line,Vector3(0,4.1,0),Color("e8c597"),24)
	speech=label
	label.width=650
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var tween := garrick.create_tween()
	speech_tween=tween
	tween.tween_interval(5.5)
	tween.tween_property(label,"modulate:a",0.0,0.5)
	tween.tween_callback(label.queue_free)
	AudioLibrary.play_world(garrick,garrick.global_position,"human_effort",0.78)
func _ready() -> void:
	region = get_parent() as Region
	cage = get_node(cage_path) as BeastCage
	region.initialized.connect(_initialize)
func _initialize() -> void:
	for child in region.actors.get_children():
		if not child is Enemy or not child.den_combat: continue
		child.den_combat.encounter = self
		if child.definition.den_boss.role=="garrick": garrick=child
		else: bloodfang=child
	released = bool(region.world_state.get("bloodfang_released",false)) or "woods_garrick" in region.defeated_ids
	if released:
		release(false)
	elif is_instance_valid(bloodfang):
		bloodfang.dormant = true
		bloodfang.health.invulnerable = true
		bloodfang.remove_from_group("enemies")
	if is_instance_valid(garrick): garrick.health.damaged.connect(_garrick_damaged)
func _garrick_damaged(_amount: float) -> void:
	if released or garrick.health.current > garrick.health.maximum*garrick.definition.den_boss.release_threshold: return
	# Even a lethal threshold-crossing hit cannot strand the quest behind a cage.
	if garrick.health.current<=0:
		release()
	else:
		garrick.den_combat.releasing = true
		garrick.attack.cancel()
func release(animate: bool = true) -> void:
	if animate and is_instance_valid(garrick) and garrick.health.current>0:
		_say(garrick.definition.den_boss.release_dialogue)
	released = true
	region.world_state["bloodfang_released"] = true
	cage.open(animate)
	if is_instance_valid(bloodfang) and bloodfang.health.current>0:
		bloodfang.dormant = false
		bloodfang.health.invulnerable = false
		if not bloodfang.is_in_group("enemies"): bloodfang.add_to_group("enemies")
		bloodfang.aggro = animate
		bloodfang.home = global_position
		if animate:
			bloodfang.visual.special_started("howl",0.9)
			AudioLibrary.play_world(bloodfang,bloodfang.global_position,"bloodfang_howl",0.67)
func summon_wave(wave: int, definition: EnemyDefinition) -> void:
	for i in range(2):
		var id := "woods_howl_%d_%d" % [wave,i]
		if id in region.defeated_ids: continue
		var enemy: Enemy = preload("res://scenes/entities/enemy.tscn").instantiate()
		enemy.definition = definition
		enemy.spawn_id = StringName(id)
		enemy.encounter_id = &"bloodfang_pack"
		enemy.position = global_position+Vector3(-8 if i==0 else 8,0.1,1)
		region.actors.add_child(enemy)
		enemy.aggro = true
		region.register_summon(enemy)

func reset_after_player_death() -> bool:
	if resetting: return false
	var garrick_alive := is_instance_valid(garrick) and garrick.health.current>0
	var beast_alive := is_instance_valid(bloodfang) and bloodfang.health.current>0
	if not (garrick_alive or beast_alive) or not (started or released or (garrick_alive and garrick.aggro)): return false
	resetting=true
	region.world_state["bloodfang_released"]=false
	# Death reset is queued before Session's autosave. Maze and chest stay cleared;
	# recorded reward credits survive, so repeated attempts cannot farm boss loot.
	call_deferred("_reset_fight")
	return true

func _reset_fight() -> void:
	for actor in region.actors.get_children():
		var encounter_actor := actor is Enemy and (actor.definition.den_boss!=null or str(actor.spawn_id).begins_with("woods_howl_"))
		if encounter_actor or actor is GroundFire or actor is TorchThrow:
			region.actors.remove_child(actor)
			actor.queue_free()
	region.defeated_ids=region.defeated_ids.filter(func(id: String): return id!="woods_garrick" and id!="woods_bloodfang" and not id.begins_with("woods_howl_"))
	region.encounter_counts[&"bloodfang_pack"]=0
	garrick=null
	bloodfang=null
	cage.close()
	released=false
	started=false
	for id in ["garrick","bloodfang"]:
		var encounter := region.get_node("Encounters/"+id) as Encounter
		region.encounter_counts[encounter.encounter_id]=0
		for marker in encounter.markers():
			var actor := marker.spawn(region.actors,encounter.encounter_id)
			region.register_summon(actor)
	_initialize()
	resetting=false
