extends SceneTree
## Story, navigation, combat and persistence through the real session components.
var session: Node
var checks: int = 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ",label)
	else:
		failures.append(label)
		push_error("FAIL: "+label)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func freeze() -> void:
	for child in session.region.actors.get_children():
		if child is Enemy:
			child.set_physics_process(false)
			child.attack.set_physics_process(false)
			child.attack.cancel()
			if child.commander: child.commander.special.set_physics_process(false)
			if child.risen_combat: child.risen_combat.set_physics_process(false)
		elif child is CorruptionField: child.set_physics_process(false)
func find_enemy(id: StringName) -> Enemy:
	for child in session.region.actors.get_children():
		if child is Enemy and child.definition.id == id and child.health.current > 0: return child
	return null
func reinforcements() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for child in session.region.actors.get_children():
		if child is Enemy and child.spawn_id == &"crypt_half_health_archer": result.append(child)
	return result
func run() -> void:
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await frames(2)
	freeze()
	var p: Player = session.player
	p.set_physics_process(false)
	p.abilities.set_physics_process(false)
	p.statuses.set_physics_process(false)
	p.combat_state.set_physics_process(false)
	var q: QuestLog = session.quest
	q.restore({"id":"lions_den","accepted":true,"cleared":true,"rewarded":true,"completed":["warwick_rescue","lions_den"]})
	check(q.offered().id == &"drowned_patrol","Old completed quest-three saves expose quest four")
	session.hud.show_npc(session.region.get_node("NPCs/elric"))
	session._service("accept",0)
	check(q.definition.id == &"lions_den","Quest four cannot be accepted from Briarwatch Elric")
	session._service("travel",0)
	await frames(2)
	freeze()
	check(session.region.region_id == &"hollowmere","Elric travels to the quest's camp")
	session._interact(session.region.get_node("Portals/ChapelCrypts"))
	await frames(1)
	check(session.region.region_id == &"hollowmere","Crypt descent is locked before the patrol investigation")
	session.hud.show_npc(session.region.get_node("NPCs/elric"))
	session._service("accept",0)
	session.hud.close_panel()
	await frames(2)
	check(q.definition.id == &"drowned_patrol" and q.stage().id == &"find_patrol","Elric offers the missing patrol as the first stage")
	check(is_instance_valid(session.companion) and not session.companion.following,"Injured Corvin appears at the patrol site")
	check(not session.companion.is_in_group("enemies") and not session.companion.has_node("Attack"),"Friendly Corvin never fights or receives enemy targeting")
	var map: RID = session.region.navigation_region.get_navigation_map()
	for destination: Node3D in [session.companion,session.region.get_node("PatrolSite/ChapelLever"),session.region.get_node("Portals/ChapelCrypts")]:
		var route := NavigationServer3D.map_get_path(map,p.position,destination.global_position,true)
		check(not route.is_empty() and route[-1].distance_to(destination.global_position)<1.5,"Reachable marsh story interaction: "+str(destination.name))
	check(session.hud.large_map.objective_location().label == "The missing patrol","Quest map points to Siltwater Landing")
	session._interact(session.region.get_node("PatrolSite/ChapelLever"))
	check(not q.flags.get("chapel_open",false),"Lever waits for Corvin's account")
	p.position = session.companion.position+Vector3(2,0,1)
	session._interact(session.companion)
	session._service("patrol_report",0)
	check(q.stage().id == &"enter_crypts" and session.companion.following,"Corvin's dialogue advances the objective and starts the escort")
	var start: Vector3 = session.companion.position
	p.position += Vector3(0,0,10)
	Engine.time_scale = 4
	await frames(55)
	Engine.time_scale = 1
	check(session.companion.position.distance_to(start)>3 and session.companion.position.distance_to(p.position)<4,"Corvin physically follows along the marsh navigation mesh")
	var saved_quest: Dictionary = q.serialize()
	var restored := QuestLog.new()
	restored.definition = session.catalog.quest
	restored.restore(saved_quest)
	check(restored.stage().id == &"enter_crypts","Quest stage serializes by stable content ID")
	restored.free()
	session.travel.enter(&"briar_march")
	session.travel.enter(&"hollowmere")
	freeze()
	check(is_instance_valid(session.companion) and session.companion.following,"Escort survives region travel")
	session._interact(session.region.get_node("PatrolSite/ChapelLever"))
	check(q.flags.get("chapel_open",false),"Pulling the chapel lever opens the crypt stair")
	session._interact(session.region.get_node("Portals/ChapelCrypts"))
	await frames(2)
	freeze()
	check(session.region.region_id == &"chapel_crypts" and q.stage().id == &"witness_ritual","Descent loads a separate crypt instance and advances the investigation")
	check(session.region.recovery_region == &"hollowmere","Crypt death recovers to Lanternwatch")
	check(session.music.requested_track() == &"chapel_crypts","Crypt exploration uses its own music")
	var crypt_music := load("res://assets/music/chapel_crypts.ogg") as AudioStream
	check(crypt_music != null and crypt_music.get_length()>30,"Crypt soundtrack decodes for offline playback")
	map = session.region.navigation_region.get_navigation_map()
	var counts := {"zombie":0,"skeletal_archer":0,"risen_soldier":0}
	for actor in session.region.actors.get_children():
		if not actor is Enemy: continue
		counts[str(actor.definition.id)] += 1
		var route := NavigationServer3D.map_get_path(map,p.position,actor.position,true)
		check(not route.is_empty() and route[-1].distance_to(actor.position)<1.15,"Connected crypt spawn: "+str(actor.spawn_id))
	check(counts.zombie==20 and counts.skeletal_archer==4,"Crypt contains twenty zombies and four archers before the reinforcement")
	check(session.hud.large_map.chambers.size()==5,"Crypt chart derives all five rooms from authored geometry")
	var z := find_enemy(&"zombie")
	var a := find_enemy(&"skeletal_archer")
	var b := find_enemy(&"risen_soldier")
	check(z.health.maximum==120 and z.attack.definition.damage==24 and z.attack.hit_chance==0.8 and z.definition.experience==2,"Zombie has requested health, damage, accuracy and EXP")
	check(a.health.maximum==100 and a.attack.definition.damage==30 and a.definition.behavior=="archer" and a.attack.definition.projectile and a.definition.experience==3,"Skeletal archers use the bowman behavior and requested stats")
	check(z.definition.loot_table==load("res://content/loot/marsh_wildlife.tres") and a.definition.loot_table==z.definition.loot_table,"Both undead types share the existing marsh loot table")
	check(b.dormant and not b.visible and b.health.invulnerable and not b.is_in_group("enemies"),"The soldier cannot be attacked before the ritual")
	check(b.health.maximum==270 and b.attack.definition.damage==35 and b.attack.hit_chance==1 and b.definition.experience==12,"Risen Soldier has all requested base stats")
	for actor: Enemy in [z,a]:
		p.position = actor.position+Vector3(0,0,3)
		var audio: GameAudio = actor.get_node("Audio")
		for event in ["attack","hurt","death"]:
			AudioLibrary.last_played.clear()
			audio.hurt_cooldown = 0
			if event == "hurt": audio._hurt(1)
			else: audio.call("_"+event)
			check(AudioLibrary.last_played.has(str(actor.definition.audio_profile)+"_"+event),"Dedicated undead cue: "+str(actor.definition.audio_profile)+" "+event)
	for cue in ["ritual_loop","bone_rise","crypt_lever","malrec_presence","malrec_death_spell","malrec_teleport","rotting_warning","rotting_cleave","corruption_spread","corruption_hurt"]:
		var clip := AudioLibrary.sample(cue)
		check(clip != null and clip.get_length()>.1,"New ability cue decodes: "+cue)
	# Real movement through a side-room doorway, using player collision and pathing.
	p.position = Vector3(-12,0.1,11)
	p.navigation.target_position = Vector3(0,0.1,11)
	p.click_moving = true
	p.set_physics_process(true)
	p.recovery_time = 999
	Engine.time_scale = 3
	await frames(70)
	Engine.time_scale = 1
	p.set_physics_process(false)
	check(p.position.distance_to(Vector3(0,0.1,11))<1.2,"Player walks out of the reliquary through its doorway")
	# Approach triggers the complete timed sequence; damage, movement and menus lock.
	p.position = Vector3(0,0.1,-34)
	var ritual: CryptRitual = session.region.get_node("CryptRitual")
	await frames(2)
	check(ritual.playing and p.cinematic_locked,"Approaching Malrec begins the roleplay and locks player control")
	var hp := p.health.current
	p.receive_damage(DamagePacket.new(999))
	session.hud.show_inventory()
	check(p.health.current==hp and session.hud.mode.is_empty(),"Frozen combat cannot damage the player or open inventory")
	check(not session.travel.enter(&"hollowmere"),"Travel cannot interrupt the staged roleplay")
	check(session.hud.cinematic_text.text.contains("At last...") and session.music.requested_track()==&"chapel_crypts","The crypt roleplay and miniboss retain exploration music")
	session.hud.show_pause()
	var before_pause := ritual.elapsed
	await process_frame
	check(paused and ritual.elapsed==before_pause,"Escape pause remains available during the cutscene")
	session.hud.close_panel()
	Engine.time_scale = 5
	for i in range(400):
		await physics_frame
		if not ritual.playing: break
	Engine.time_scale = 1
	freeze()
	await frames(2)
	check(not ritual.playing and not p.cinematic_locked and p.process_mode!=Node.PROCESS_MODE_DISABLED,"Timed ritual restores player control")
	check(q.stage().id==&"defeat_soldier" and q.flags.get("corvin_fallen",false),"Corvin's death is persisted at the completed story boundary")
	check(not is_instance_valid(session.companion) and not ritual.malrec.visible and ritual.ritual.energy==0,"Corvin is removed and Malrec has disappeared")
	check(b.visible and not b.dormant and b.is_in_group("enemies") and b.aggro,"Corvin rises as the hostile miniboss")
	# Pool lifetime, overlap, exact tick, armor bypass and reinforcements.
	p.recovery_time = 0
	p.health.invulnerable = false
	p.health.configure(1000,100)
	p.position = b.position+Vector3(0,0,0.6)
	b.risen_combat._physics_process(.7)
	var field: CorruptionField = b.risen_combat.field
	field.set_physics_process(false)
	field.spread(b.position+Vector3(1.2,0,0))
	hp = p.health.current
	field._physics_process(.49)
	check(p.health.current==hp,"Corruption waits for its half-second tick")
	field._physics_process(.01)
	check(p.health.current==hp-20,"Overlapping corruption deals twenty damage once per tick, bypassing armor")
	p.position = Vector3(12,0.1,-40)
	hp = p.health.current
	field._physics_process(20)
	check(field.points.size()==2 and p.health.current==hp,"Pools persist indefinitely and spare a player standing outside")
	b.health.receive(DamagePacket.new(135,p))
	check(reinforcements().size()==1 and reinforcements()[0].definition.id==&"skeletal_archer","Exactly one archer emerges from the corridor at fifty percent")
	b.health.receive(DamagePacket.new(1,p))
	check(reinforcements().size()==1,"Further damage does not duplicate the reinforcement")
	freeze()
	var snapshot: Dictionary = session.travel.snapshot()
	check(snapshot.chapel_crypts.corruption.size()==1 and snapshot.chapel_crypts.world.crypt_reinforcement,"Pools and reinforcement state are included in region saves")
	session.travel.enter(&"hollowmere",&"chapel")
	session.travel.enter(&"chapel_crypts")
	freeze()
	b = find_enemy(&"risen_soldier")
	ritual = session.region.get_node("CryptRitual")
	check(not ritual.malrec.visible and not b.dormant and not is_instance_valid(session.companion),"Re-entering after the ritual never replays Corvin's death")
	check(reinforcements().size()==1 and b.risen_combat.field.points.size()==2,"A living reinforcement and corruption survive re-entry")
	# Cleave locks its cone at wind-up; side movement avoids it.
	p.inventory.equipment.shield = null
	p.health.configure(1000,0)
	p.position = b.position+Vector3(0,0,2)
	p.recovery_time = 0
	var cmd: CommanderCombat = b.commander
	cmd.start("cleave",Vector3.BACK)
	check(cmd.special.windup_left==1 and b.visual.special_kind=="cleave" and is_instance_valid(cmd.warning),"Rotting Cleave has a one-second weapon-raise telegraph")
	hp = p.health.current
	p.position = b.position+Vector3(2,0,0)
	cmd.special._physics_process(1.01)
	check(p.health.current==hp,"Sidestepping the committed cone avoids Rotting Cleave")
	p.position = b.position+Vector3(0,0,2)
	cmd.start("cleave",Vector3.BACK)
	cmd.special._physics_process(1.01)
	check(p.health.current==hp-60,"Remaining in the frontal cone takes sixty base damage")
	check(b.definition.commander.cleave_cooldown==Vector2(8,12),"Cleave cooldown is eight to twelve seconds")
	# Player death preserves the boss story boundary and returns to the correct hub.
	p.health.receive(DamagePacket.new(9999))
	session.hud.close_panel()
	session._respawn()
	freeze()
	check(not p.dead and session.region.region_id==&"hollowmere" and not is_instance_valid(session.companion),"Death recovery returns to Lanternwatch without reviving Corvin")
	session.travel.enter(&"chapel_crypts")
	freeze()
	b = find_enemy(&"risen_soldier")
	check(not b.dormant and b.health.current==270 and b.risen_combat.field.points.size()==2,"A retry restores the boss with existing corruption until his death")
	var experience: int = p.progression.experience
	b.health.receive(DamagePacket.new(999,p))
	check(q.cleared and not q.rewarded,"Killing the Risen Soldier changes the quest to reporting to Elric")
	check(p.progression.experience==experience+12,"Soldier kill grants exactly twelve EXP")
	check(get_nodes_in_group("corruption_fields").is_empty(),"Every corruption pool clears immediately on the soldier's death")
	var plate: ItemDefinition
	for child in session.region.actors.get_children():
		if child is LootDrop and child.item and child.item.id==&"captains_breastplate": plate=child.item
	check(plate!=null and plate.tier=="green" and plate.slot=="body" and plate.armor_bonus==5 and plate.vitality_bonus==5 and plate.crit_rating==1,"Guaranteed Captain's Breastplate has the requested quality and stats")
	check(session.catalog.find_item("captains_breastplate")==plate and plate.icon!=null,"Breastplate has inventory art and a stable catalog entry")
	# The living archer persists even after the boss is dead, without rewarding twice.
	session.travel.enter(&"hollowmere")
	session.travel.enter(&"chapel_crypts")
	freeze()
	check(find_enemy(&"risen_soldier")==null and reinforcements().size()==1,"Completed boss remains dead while his surviving reinforcement persists")
	reinforcements()[0].health.receive(DamagePacket.new(999,p))
	session.travel.enter(&"hollowmere")
	freeze()
	var gold := p.inventory.gold
	session.hud.show_npc(session.region.get_node("NPCs/elric"))
	session._service("claim",0)
	session._service("claim",0)
	check(q.rewarded and p.inventory.gold==gold+50,"Elric awards fifty gold exactly once")
	session.hud.close_panel()
	session.travel.enter(&"chapel_crypts")
	freeze()
	check(reinforcements().is_empty() and get_nodes_in_group("corruption_fields").is_empty(),"Defeated reinforcement and cleared corruption remain absent")
	print("DROWNED PATROL: %d checks, %d failures" % [checks,failures.size()])
	session.queue_free()
	await process_frame
	await create_timer(.2).timeout
	quit(0 if failures.is_empty() else 1)
