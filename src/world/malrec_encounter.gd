class_name MalrecEncounter
extends Node3D
## Single boss state machine; timers pause with the world, and retries reset summons.
@export var definition: MalrecDefinition
var region: Region
var session: Node
var boss: Enemy
var art: NecromancerVisual
var state: String = "idle"
var timer: float = 0
var teleport_left: float = 14
var dark_patch_left: float = 0.0
var meteor_left: float = 0
var wave_left: float = 0
var wave: int = 0
var ritual_done: bool = false
var element: StringName = &"fire"
var aim := Vector3.FORWARD
var destination := Vector3.ZERO
var cultists: Array[Enemy] = []
var beams: Dictionary = {}
var ritual: RitualVisual
var old_player_mode: int = Node.PROCESS_MODE_INHERIT
var rng := RandomNumberGenerator.new()
func _ready() -> void:
	region=get_parent() as Region
	session=region.get_parent()
	region.initialized.connect(_initialize)
	rng.randomize()
func _initialize() -> void:
	for actor in region.actors.get_children():
		if actor is Enemy and actor.spawn_id==&"darkmere_malrec": boss=actor
	if not is_instance_valid(boss):
		state="dead"
		return
	# Summons are attempt state. Reward credits are retained separately by Region.
	region.defeated_ids=region.defeated_ids.filter(func(id: String): return not id.begins_with("malrec_summon_"))
	boss.health.invulnerable=true
	boss.damage_gate=_filter_damage
	boss.health.damaged.connect(_hurt)
	boss.health.died.connect(_died)
	art=boss.visual.pivot.get_child(0) as NecromancerVisual
	art.channeling=false
	ritual=RitualVisual.new()
	ritual.energy=0
	ritual.position=Vector3(0,0,0)
	add_child(ritual)
	teleport_left=definition.teleport_cooldown
	dark_patch_left=rng.randf_range(definition.dark_patch_first_delay.x,definition.dark_patch_first_delay.y)
func music_active() -> bool:
	return state not in ["idle","dead"]
func _physics_process(delta: float) -> void:
	if state=="dead" or not is_instance_valid(boss): return
	if session.player.dead:
		if state!="idle": reset_after_player_death()
		return
	if state in ["bolts","casting","teleport","meteors"]:
		dark_patch_left-=delta
		if dark_patch_left<=0 and state=="bolts" and teleport_left>1.0: cast_dark_patch()
	match state:
		"idle":
			if session.player.global_position.distance_to(boss.global_position)<16: begin()
		"intro":
			timer-=delta
			if timer<=0:
				release_player()
				boss.health.invulnerable=false
				boss.aggro=true
				state="bolts"
				timer=0.4
		"bolts":
			teleport_left-=delta
			timer-=delta
			if teleport_left<=0: start_teleport()
			elif timer<=0: start_bolt()
		"casting":
			teleport_left-=delta
			timer-=delta
			if timer<=0:
				fire_bolt()
				art.spell=false
				state="bolts"
				timer=definition.bolt_cooldown
		"teleport":
			timer-=delta
			boss.visual.scale=Vector3.ONE*maxf(0.08,timer)
			if timer<=0:
				boss.position=destination
				boss.visual.scale=Vector3.ONE
				art.channeling=true
				state="meteors"
				meteor_left=0.2
				pulse(boss.position,Color("9273a9"))
		"meteors":
			meteor_left-=delta
			if meteor_left<=0:
				meteor_left=definition.meteor_interval
				spawn_meteor(session.player.position+Vector3(rng.randf_range(-1.5,1.5),0,rng.randf_range(-1.5,1.5)))
				for i in range(2): spawn_meteor(Vector3(rng.randf_range(-14,14),0,rng.randf_range(-11,11)))
		"ritual":
			timer-=delta
			wave_left-=delta
			ritual.energy=1.0+(1.0-timer/definition.ritual_seconds)*0.6
			if living_cultists()==0: end_ritual()
			elif timer<=0: detonate()
			elif wave_left<=0:
				wave_left=definition.summon_interval
				wave+=1
				spawn_add(definition.zombie,"wave_%d_z" % wave,Vector3(-12,0.1,9))
				spawn_add(definition.spider,"wave_%d_s" % wave,Vector3(12,0.1,-9))
func begin() -> void:
	if state!="idle": return
	session.hud.close_panel()
	session.player.cinematic_locked=true
	session.player.click_moving=false
	session.player.attack.cancel()
	session.player.attack_target=null
	session.player.interact_target=null
	session.player.velocity=Vector3.ZERO
	old_player_mode=session.player.process_mode
	session.player.process_mode=Node.PROCESS_MODE_DISABLED
	session.hud.roleplay_line("MALREC VEYNE",definition.dialogue)
	state="intro"
	timer=10
	AudioLibrary.play_world(self,boss.position,"malrec_presence")
func release_player() -> void:
	session.player.cinematic_locked=false
	session.player.process_mode=old_player_mode
	session.hud.roleplay_line("","")
func start_bolt() -> void:
	element=&"fire" if rng.randf()<0.5 else &"poison"
	aim=(session.player.position-boss.position).normalized()
	aim.y=0
	boss._face(aim)
	art.spell=true
	art.spell_color=Color("de8c47") if element==&"fire" else Color("78a74e")
	state="casting"
	timer=definition.cast_seconds
func fire_bolt() -> void:
	var count := definition.post_ritual_bolt_count if ritual_done else 1
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	for i in range(count):
		var offset := 0.0 if count == 1 else float(i) / float(count - 1) * definition.post_ritual_cone_degrees * side
		var heading := aim.rotated(Vector3.UP, deg_to_rad(offset))
		var bolt:=ElementalBolt.new()
		bolt.element=element
		bolt.direction=heading
		bolt.damage=definition.bolt_damage
		bolt.speed=definition.bolt_speed
		bolt.dot_damage=definition.affliction_damage
		bolt.dot_seconds=definition.affliction_seconds
		bolt.source=boss
		bolt.position=boss.position+Vector3.UP*0.9+heading*0.9
		region.actors.add_child(bolt)
func cast_dark_patch() -> void:
	var patch:=NecroticPatch.new()
	patch.position=Vector3(boss.position.x,0,boss.position.z)
	patch.duration=definition.dark_patch_duration
	patch.radius=definition.dark_patch_radius
	patch.tick_seconds=definition.dark_patch_tick
	patch.damage=definition.dark_patch_damage
	patch.source=boss
	region.actors.add_child(patch)
	dark_patch_left=rng.randf_range(definition.dark_patch_cooldown.x,definition.dark_patch_cooldown.y)
func start_teleport() -> void:
	var farthest: float=-1
	for marker: Marker3D in $TeleportPoints.get_children():
		var distance: float=marker.position.distance_squared_to(session.player.position)
		if distance>farthest:
			farthest=distance
			destination=marker.position
	state="teleport"
	timer=0.9
	art.spell=false
	pulse(boss.position,Color("9371a7"))
	AudioLibrary.play_world(self,boss.position,"malrec_teleport")
func spawn_meteor(point: Vector3) -> void:
	var meteor:=MeteorImpact.new()
	meteor.position=Vector3(clampf(point.x,-14,14),0,clampf(point.z,-11,11))
	meteor.source=boss
	meteor.damage=definition.meteor_damage
	meteor.radius=definition.meteor_radius
	meteor.warning_seconds=definition.meteor_warning
	region.actors.add_child(meteor)
func _filter_damage(packet: DamagePacket) -> void:
	if ritual_done or state in ["ritual","dead"]: return
	var available:=maxf(0,boss.health.current-boss.health.maximum*definition.ritual_threshold)
	packet.amount=minf(packet.amount,available/(2.0 if packet.critical else 1.0))
func _hurt(_amount: float) -> void:
	if not ritual_done and boss.health.current<=boss.health.maximum*definition.ritual_threshold+0.001:
		start_ritual()
	elif state=="meteors":
		state="bolts"
		art.channeling=false
		teleport_left=definition.teleport_cooldown
		timer=0.7
		AudioLibrary.play_world(self,boss.position,"ritual_break")
func start_ritual() -> void:
	ritual_done=true
	state="ritual"
	timer=definition.ritual_seconds
	wave_left=5
	wave=0
	boss.health.invulnerable=true
	boss.position=Vector3(0,0.1,0)
	boss.visual.scale=Vector3.ONE
	art.spell=false
	art.channeling=true
	clear_hazards(true)
	ritual.energy=1
	cultists.clear()
	for marker: Marker3D in $CultistPoints.get_children():
		var cultist:=spawn_add(definition.cultist,"cultist_"+str(marker.name),marker.position)
		cultists.append(cultist)
		var beam:=Geometry.beam(self,cultist.position+Vector3.UP*1.7,boss.position+Vector3.UP*2.0,0.06,Color("9b719f"))
		beam.material_override=Geometry.material(Color("9667ac"),1.0)
		beams[cultist]=beam
		cultist.health.died.connect(func():
			if is_instance_valid(beam): beam.queue_free())
	AudioLibrary.play_world(self,boss.position,"cultist_ritual")
func spawn_add(type: EnemyDefinition, suffix: String, point: Vector3) -> Enemy:
	var actor: Enemy=preload("res://scenes/entities/enemy.tscn").instantiate()
	actor.definition=type
	actor.spawn_id=StringName("malrec_summon_"+suffix)
	actor.encounter_id=&"malrec_adds"
	actor.position=point
	region.actors.add_child(actor)
	actor.aggro=true
	region.register_summon(actor)
	pulse(point,Color("6d855e"))
	return actor
func living_cultists() -> int:
	var count:=0
	for actor in cultists:
		if is_instance_valid(actor) and actor.health.current>0: count+=1
	return count
func end_ritual() -> void:
	state="bolts"
	boss.health.invulnerable=false
	ritual.energy=0
	art.channeling=false
	teleport_left=definition.teleport_cooldown
	timer=0.8
	AudioLibrary.play_world(self,boss.position,"ritual_break")
func detonate() -> void:
	pulse(Vector3.ZERO,Color("c79bca"),18)
	AudioLibrary.play_world(self,Vector3.ZERO,"ritual_detonation")
	# Ritual failure is an encounter wipe, independent of armor and elemental wards.
	session.player.health.invulnerable=false
	session.player.health.receive(DamagePacket.new(session.player.health.maximum*2,null,&"ritual"))
func _died() -> void:
	state="dead"
	boss.damage_gate=Callable()
	clear_hazards()
	ritual.energy=0
	for beam in beams.values():
		if is_instance_valid(beam): beam.queue_free()
	beams.clear()
	AudioLibrary.play_world(self,boss.position,"malrec_death")
func clear_hazards(keep_patches: bool=false) -> void:
	for node in get_tree().get_nodes_in_group("malrec_hazards"):
		if region.is_ancestor_of(node):
			if keep_patches and node is NecroticPatch: continue
			node.set_physics_process(false)
			node.queue_free()
func reset_after_player_death() -> bool:
	if state in ["idle","dead"]: return false
	if state=="intro": release_player()
	state="idle"
	clear_hazards()
	for actor in region.actors.get_children():
		if actor is Enemy and str(actor.spawn_id).begins_with("malrec_summon_"):
			region.actors.remove_child(actor)
			actor.queue_free()
	for beam in beams.values():
		if is_instance_valid(beam): beam.queue_free()
	beams.clear()
	cultists.clear()
	ritual.energy=0
	ritual_done=false
	boss.health.current=boss.health.maximum
	boss.health.invulnerable=true
	boss.position=Vector3(0,0.1,-6)
	boss.visual.scale=Vector3.ONE
	boss.aggro=false
	art.channeling=false
	art.spell=false
	teleport_left=definition.teleport_cooldown
	dark_patch_left=rng.randf_range(definition.dark_patch_first_delay.x,definition.dark_patch_first_delay.y)
	region.defeated_ids=region.defeated_ids.filter(func(id: String): return not id.begins_with("malrec_summon_"))
	region.encounter_counts[&"malrec_adds"]=0
	return true
func pulse(point: Vector3, color: Color, radius: float=1.6) -> void:
	var ring:=Geometry.ring(self,radius,color,0.05)
	ring.position=point+Vector3.UP*0.15
	ring.material_override=Geometry.material(color,1.1)
	var tween:=ring.create_tween()
	tween.tween_property(ring,"scale",Vector3.ONE*0.01,0.8)
	tween.tween_callback(ring.queue_free)
func _exit_tree() -> void:
	if state=="intro" and is_instance_valid(session) and not session.is_queued_for_deletion(): release_player()
