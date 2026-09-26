extends SceneTree
var session: Node
var checks: int=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS: ",label)
	else:
		failures.append(label)
		push_error("FAIL: "+label)
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func freeze() -> void:
	for actor in session.region.actors.get_children():
		if actor is Enemy:
			actor.set_physics_process(false)
			actor.attack.set_physics_process(false)
			actor.attack.cancel()
func ambushers() -> Array[Enemy]:
	var result: Array[Enemy]=[]
	for actor in session.region.actors.get_children():
		if actor is Enemy and str(actor.spawn_id).begins_with("mark_"): result.append(actor)
	return result
func run() -> void:
	session=load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await frames(2)
	var p: Player=session.player
	p.set_physics_process(false)
	p.abilities.set_physics_process(false)
	p.statuses.set_physics_process(false)
	p.health.invulnerable=true
	var q: QuestLog=session.quest
	q.restore({"id":"drowned_patrol","accepted":true,"cleared":true,"rewarded":true,"completed":["lions_den","drowned_patrol"]})
	check(q.offered().id==&"unseen_hand","Quest five follows the fourth hand-in")
	session.travel.enter(&"hollowmere")
	await frames(2)
	freeze()
	session.hud.show_npc(session.region.get_node("NPCs/elric"))
	session._service("accept",0)
	session.hud.close_panel()
	check(q.definition.id==&"unseen_hand" and q.accepted,"Elric offers and accepts The Unseen Hand")
	check(session.hud.large_map.objective_location().is_empty(),"Investigation has no objective pins")
	var investigation: MarkInvestigation=session.region.get_node("MarkInvestigation")
	var map: RID=session.region.navigation_region.get_navigation_map()
	for target: Node3D in investigation.get_children()+[session.region.get_node("Portals/DarkmereHold")]:
		var route:=NavigationServer3D.map_get_path(map,p.position,target.global_position,true)
		check(not route.is_empty() and route[-1].distance_to(target.global_position)<1.5,"Reachable outdoor addition: "+str(target.name))
	var first: NecromanticMark=investigation.get_node("beacon")
	session._interact(first)
	freeze()
	check(ambushers().size()==6,"First mark summons four zombies and two archers")
	session._interact(first)
	check(ambushers().size()==6,"Repeated interaction cannot duplicate an ambush")
	var kill_id:=str(ambushers()[0].spawn_id)
	ambushers()[0].health.receive(DamagePacket.new(999,p))
	session.travel.enter(&"chapel_crypts")
	session.travel.enter(&"hollowmere")
	freeze()
	investigation=session.region.get_node("MarkInvestigation")
	check(ambushers().size()==5 and kill_id in session.region.defeated_ids,"Ambush survivors and defeated IDs persist across travel")
	session._interact(investigation.get_node("graves"))
	session._interact(investigation.get_node("tollhouse"))
	freeze()
	var brute: Enemy
	var counts: Dictionary={}
	for actor in ambushers():
		counts[actor.definition.id]=int(counts.get(actor.definition.id,0))+1
		if actor.definition.id==&"zombie_brute": brute=actor
	check(counts.get(&"zombie",0)==10 and counts.get(&"skeletal_archer",0)==4 and brute!=null,"Third mark replaces the archer wave with three zombies and one brute")
	check(brute.health.maximum==200 and brute.attack.definition.damage==40 and brute.attack.hit_chance==1,"Brute has requested health, damage and accuracy")
	# Resolve a telegraphed charge with real collision, without a random basic attack.
	brute.position=Vector3(-103,0.1,92)
	p.position=Vector3(-103,0.1,86)
	brute.aggro=true
	brute.returning=false
	brute.charge_combat.cooldown=0
	brute.charge_combat.step(.01)
	check(brute.charge_combat.warning>0,"Brute charge begins with an aim-locked wind-up")
	brute.charge_combat.step(.81)
	for i in range(50):
		brute.charge_combat.step(1.0/60)
		await physics_frame
	check(p.statuses.has("stun") and is_equal_approx(float(p.statuses.effects.stun.remaining),1),"Charge contact applies exactly one second of stun")
	p.statuses.reset()
	brute.health.receive(DamagePacket.new(999,p))
	var note: LootDrop
	for child in session.region.actors.get_children():
		if child is LootDrop and child.item and child.item.id==&"veyne_letter": note=child
	check(note!=null and not q.cleared,"Brute drops the dark note; killing alone does not finish the objective")
	session._interact(note)
	check(q.cleared and "veyne_letter" in p.inventory.quest_items,"Picking up the note enables hand-in")
	session.hud.show_npc(session.region.get_node("NPCs/elric"))
	session._service("claim",0)
	session.hud.close_panel()
	var pauldrons:=session.catalog.find_item("soldiers_pauldrons") as ItemDefinition
	check(q.rewarded and not "veyne_letter" in p.inventory.quest_items and pauldrons in p.inventory.items,"Hand-in consumes the note and grants Soldier's Pauldrons")
	check(pauldrons.tier=="green" and pauldrons.armor_bonus==4 and pauldrons.strength_bonus==1 and pauldrons.crit_rating==1,"Pauldrons have all requested stats")
	# All other permutations use the same controller and stable resource types.
	for sequence in [["graves","tollhouse","beacon"],["graves","beacon","tollhouse"],["tollhouse","graves","beacon"],["tollhouse","beacon","graves"],["beacon","tollhouse","graves"]]:
		for actor in ambushers():
			actor.get_parent().remove_child(actor)
			actor.queue_free()
		session.region.world_state.erase("mark_order")
		session.region.defeated_ids=session.region.defeated_ids.filter(func(id: String): return not id.begins_with("mark_"))
		q.rewarded=false
		for id in sequence: investigation.inspect(investigation.get_node(id))
		freeze()
		var brutes:=0
		for actor in ambushers():
			if actor.definition.id==&"zombie_brute" and str(actor.spawn_id).begins_with("mark_"+sequence[2]): brutes+=1
		check(ambushers().size()==16 and brutes==1,"Any-order investigation: "+str(sequence))
	q.rewarded=true
	session.hud.show_npc(session.region.get_node("NPCs/elric"))
	session._service("accept",0)
	session.hud.close_panel()
	check(q.definition.id==&"darkmere","Quest six follows the evidence hand-in")
	session._interact(session.region.get_node("Portals/DarkmereHold"))
	await frames(2)
	freeze()
	check(session.region.region_id==&"darkmere_halls","Keep doorway enters the lower-floor instance")
	map=session.region.navigation_region.get_navigation_map()
	for actor in session.region.actors.get_children():
		if actor is Enemy:
			var route:=NavigationServer3D.map_get_path(map,p.position,actor.position,true)
			check(not route.is_empty() and route[-1].distance_to(actor.position)<1.2,"Reachable lower-floor encounter: "+str(actor.spawn_id))
	check(session.region.actors.get_child_count()==18,"Lower floor has authored undead and spider encounters")
	session._interact(session.region.get_node("Portals/UpperFloor"))
	await frames(2)
	freeze()
	var encounter: MalrecEncounter=session.region.get_node("MalrecEncounter")
	encounter.set_physics_process(false)
	var boss: Enemy=encounter.boss
	check(boss.health.maximum==500 and boss.definition.experience==25 and boss.definition.passive,"Malrec has 500 health, twenty-five EXP and no basic melee AI")
	p.position=Vector3(0,0.1,6)
	encounter._physics_process(.01)
	check(p.cinematic_locked and encounter.state=="intro","Boss approach starts the opening dialogue")
	encounter._physics_process(10.1)
	check(not p.cinematic_locked and session.music.requested_track()==&"vanes_den","Dialogue returns control with boss music active")
	p.health.invulnerable=false
	p.health.configure(1000,100)
	p.inventory.equipment.shield=null
	for element in [&"fire",&"poison"]:
		var before:=p.health.current
		encounter.start_bolt()
		encounter.element=element
		encounter.fire_bolt()
		var opening_bolts:=0
		for child in session.region.actors.get_children():
			if child is ElementalBolt: opening_bolts+=1
		check(opening_bolts==1,"Before the ritual each cast launches one "+str(element)+" bolt")
		await frames(65)
		p.statuses._physics_process(3)
		check(p.health.current==before-31,"Live elemental bolt hits, bypasses armor and applies three damage ticks: "+str(element))
	p.position=boss.position+Vector3(1,0,0)
	encounter.state="bolts"
	encounter.timer=100
	encounter.teleport_left=100
	encounter.dark_patch_left=0
	encounter._physics_process(.01)
	var patch: NecroticPatch
	for child in session.region.actors.get_children():
		if child is NecroticPatch: patch=child
	check(patch!=null and patch.position.distance_to(Vector3(boss.position.x,0,boss.position.z))<0.01 and patch.radius==3.2,"Malrec forms a large dark patch at his position")
	check(encounter.dark_patch_left>=12 and encounter.dark_patch_left<=17,"Patch cooldown is randomized with a twelve-second minimum")
	if patch:
		patch.set_physics_process(false)
		var patch_hp:=p.health.current
		patch._physics_process(.99)
		check(p.health.current==patch_hp,"New patch telegraphs before the first one-second tick")
		patch._physics_process(.01)
		patch._physics_process(1.0)
		check(p.health.current==patch_hp-20,"Standing in the patch takes ten magic damage each second")
		p.position=boss.position+Vector3(8,0,0)
		patch._physics_process(1.0)
		check(p.health.current==patch_hp-20,"Leaving the patch avoids the next damage tick")
		p.position=boss.position+Vector3(1,0,0)
		patch._physics_process(2.0)
		await frames(2)
		check(p.health.current==patch_hp-40 and not is_instance_valid(patch),"The patch expires after five seconds, with damage only while inside")
	encounter._physics_process(11.99)
	var early_patch:=false
	for child in session.region.actors.get_children():
		if child is NecroticPatch: early_patch=true
	check(not early_patch,"Malrec cannot create another patch before twelve seconds")
	encounter.dark_patch_left=100
	encounter.teleport_left=encounter.definition.teleport_cooldown
	p.position=Vector3(0,0.1,6)
	var meteor:=MeteorImpact.new()
	meteor.position=p.position
	meteor.source=boss
	session.region.actors.add_child(meteor)
	meteor.set_physics_process(false)
	var meteor_hp:=p.health.current
	meteor._physics_process(1.2)
	p.statuses._physics_process(3)
	check(p.health.current==meteor_hp-46,"Meteor impact deals forty fire damage plus six burn damage")
	meteor.queue_free()
	encounter.start_teleport()
	var intended:=encounter.destination
	encounter._physics_process(1)
	check(encounter.state=="meteors" and boss.position==intended and boss.position.distance_to(p.position)>14,"Teleport chooses the far side and starts channeling")
	encounter._physics_process(.3)
	check(get_nodes_in_group("malrec_hazards").size()>=3,"Meteor channel rains several telegraphed impacts")
	encounter._physics_process(2)
	check(encounter.state=="meteors","Meteor channel continues without an automatic timeout")
	boss.receive_damage(DamagePacket.new(1,p))
	check(encounter.state=="bolts" and encounter.teleport_left==14,"A hit interrupts meteors and begins the fourteen-second cooldown")
	encounter.clear_hazards()
	# Even a lethal strike must enter the single 40% ritual phase.
	boss.receive_damage(DamagePacket.new(9999,p))
	freeze()
	check(encounter.state=="ritual" and boss.health.current==200 and boss.health.invulnerable,"Threshold-crossing damage starts the immune ritual at forty percent")
	check(encounter.living_cultists()==4 and encounter.timer==60,"Four eighty-health cultists channel under the agreed sixty-second deadline")
	for cultist in encounter.cultists: check(cultist.health.maximum==80 and cultist.definition.passive,"Cultist only channels and has eighty health")
	map=session.region.navigation_region.get_navigation_map()
	for cultist in encounter.cultists:
		var route:=NavigationServer3D.map_get_path(map,p.position,cultist.position,true)
		check(not route.is_empty() and route[-1].distance_to(cultist.position)<1,"Cultist is reachable around the ritual")
	encounter._physics_process(6)
	freeze()
	check(encounter.wave==1,"Ritual periodically summons a zombie and a spider")
	for cultist in encounter.cultists: cultist.receive_damage(DamagePacket.new(999,p))
	encounter.timer=8
	encounter._physics_process(.01)
	check(encounter.state=="bolts" and not boss.health.invulnerable,"Killing all cultists succeeds even after forty-five seconds")
	encounter.start_bolt()
	encounter.fire_bolt()
	var post_ritual_bolts: Array[ElementalBolt]=[]
	for child in session.region.actors.get_children():
		if child is ElementalBolt: post_ritual_bolts.append(child)
	check(post_ritual_bolts.size()==2,"After the ritual each cast launches two bolts")
	if post_ritual_bolts.size()==2:
		check(absf(rad_to_deg(post_ritual_bolts[0].direction.angle_to(post_ritual_bolts[1].direction))-6)<0.1 and post_ritual_bolts[0].direction.angle_to(encounter.aim)<0.001 and post_ritual_bolts[0].element==post_ritual_bolts[1].element,"One bolt stays aimed at the player while the other fans out six degrees")
	encounter.clear_hazards()
	# A failed attempt resets cleanly, including dead cultists on the next attempt.
	encounter.cast_dark_patch()
	encounter.ritual_done=false
	encounter.start_ritual()
	var ritual_patch:=false
	for child in session.region.actors.get_children():
		if child is NecroticPatch and not child.is_queued_for_deletion(): ritual_patch=true
	check(ritual_patch,"A patch keeps its five-second lifetime when the ritual begins")
	freeze()
	encounter.timer=.01
	encounter._physics_process(.02)
	check(p.dead and encounter.state=="idle" and boss.health.current==500,"Timeout explosion kills the player and resets the boss")
	await frames(2)
	var retry_patch:=false
	for child in session.region.actors.get_children():
		if child is NecroticPatch: retry_patch=true
	check(not retry_patch,"Death recovery clears the previous attempt's dark magic patch")
	session.hud.close_panel()
	session._respawn()
	session.travel.enter(&"darkmere_sanctum")
	freeze()
	encounter=session.region.get_node("MalrecEncounter")
	encounter.set_physics_process(false)
	boss=encounter.boss
	p.position=Vector3(0,0.1,6)
	encounter.begin()
	encounter._physics_process(10.1)
	boss.receive_damage(DamagePacket.new(9999,p))
	freeze()
	check(encounter.living_cultists()==4,"All four cultists respawn on a retry")
	for cultist in encounter.cultists: cultist.receive_damage(DamagePacket.new(999,p))
	encounter._physics_process(.01)
	boss.receive_damage(DamagePacket.new(9999,p))
	check(q.cleared and encounter.state=="dead" and session.music.requested_track()==&"chapel_crypts","Malrec's death completes the objective and ends boss music")
	var ring: ItemDefinition=session.catalog.find_item("black_reliquary")
	var dropped:=false
	for child in session.region.actors.get_children():
		if child is LootDrop and child.item==ring: dropped=true
	check(dropped and ring.tier=="blue" and ring.strength_bonus==2 and ring.vitality_bonus==20,"Boss drops the Blue Black Reliquary with requested stats")
	p.inventory.equipment.ring_left=ring
	p.health.configure(100000)
	p.health.current=1
	p.abilities.rng.seed=92351
	for i in range(10000): p.abilities.damage_dealt(10)
	var stolen:=p.health.current-1
	check(stolen>1300 and stolen<1700,"Equipped relic procs near five percent and heals three vitality")
	p.inventory.equipment.ring_left=null
	var before:=p.health.current
	for i in range(100): p.abilities.damage_dealt(10)
	check(p.health.current==before,"Removing the ring removes its on-hit effect")
	session.travel.enter(&"hollowmere")
	freeze()
	var gold:=p.inventory.gold
	session.hud.show_npc(session.region.get_node("NPCs/elric"))
	session._service("claim",0)
	session._service("claim",0)
	check(q.rewarded and p.inventory.gold==gold+50,"Final hand-in awards exactly fifty gold once")
	q.rewarded=false
	q.completed.erase("darkmere")
	check(q.claim(p.inventory) and p.inventory.gold==gold+50,"Replaying a previously rewarded quest does not pay its reward twice")
	session.hud.close_panel()
	var loot: LootTable=load("res://content/loot/marsh_wildlife.tres")
	var tonic:=false
	for entry in loot.entries:
		if entry.item.id==&"tonic": tonic=is_equal_approx(entry.chance,.02)
	check(tonic,"Shared map-two ordinary loot has a two-percent Tonic roll")
	session.travel.enter(&"darkmere_sanctum")
	check(session.region.get_node("MalrecEncounter").state=="dead","Completed Malrec does not respawn on revisiting")
	for cue in ["brute_charge_warning","brute_charge","brute_charge_impact","mark_ambush","meteor_warning","meteor_impact","cultist_ritual","ritual_break","ritual_detonation","occult_hurt","occult_death","reliquary_siphon","malrec_dark_patch"]:
		var clip:=AudioLibrary.sample(cue)
		check(clip!=null and clip.get_length()>0.1,"Offline encounter sound decodes: "+cue)
	print("DARKMERE: %d checks, %d failures" % [checks,failures.size()])
	session.queue_free()
	await process_frame
	# Allow the audio thread to release stopped playback before headless shutdown.
	await create_timer(0.3).timeout
	quit(0 if failures.is_empty() else 1)
