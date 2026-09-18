extends SceneTree
var session: Node
var checks: int = 0
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if value: print("PASS: ",message)
	else:
		failures.append(message)
		push_error("FAIL: "+message)
func freeze() -> void:
	for enemy: Enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		enemy.attack.cancel()
		enemy.attack.set_physics_process(false)
		if enemy.commander: enemy.commander.cancel()
func run() -> void:
	root.size=Vector2i(1440,900)
	session=load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await physics_frame
	await physics_frame
	freeze()
	var p: Player=session.player
	p.set_physics_process(false)
	p.abilities.set_physics_process(false)
	p.statuses.set_physics_process(false)
	p.combat_state.set_physics_process(false)
	var progress:=p.progression
	for id in ["raider","archer","wolf"]:
		var enemy: EnemyDefinition=load("res://content/enemies/"+id+".tres")
		check(enemy.experience==1,"Authored EXP reward: "+id)
	var darius: EnemyDefinition=load("res://content/enemies/darius.tres")
	check(darius.experience==5 and darius.is_boss,"Darius has five EXP and explicit boss immunity")
	check(EnemyDefinition.new().experience==0,"Future enemy types must opt into EXP rewards")
	check(progress.level==1 and progress.points()==0,"New character starts level one without talent points")
	session._migrate_progression({"watchtower":{"defeated":["tower_darius","tower_darius","tower_bowman_west","nonexistent"]}})
	check(progress.experience==6 and progress.level==1,"Legacy migration credits authored kills once, ignores duplicates and unknown IDs")
	progress.restore({})
	progress.grant(29)
	check(progress.level==1 and progress.experience==29,"EXP accumulates before threshold")
	progress.grant(5)
	check(progress.level==2 and progress.experience==0 and progress.points()==1,"Level-up discards overflow and grants exactly one point")
	check(not progress.learn("whirlwind"),"Dependency prevents learning child first")
	check(progress.learn("block") and progress.points()==0,"Learn Block using earned point")
	check(not progress.learn("block"),"No overspending")
	for i in range(18): progress.grant(progress.required())
	check(progress.level==20 and progress.points()==18,"All nineteen thresholds award nineteen total points")
	progress.grant(50000)
	check(progress.level==20 and progress.experience==0,"Maximum level is twenty")
	check(CenturionTalents.all().size()==14,"Both seven-talent trees registered")
	var saved:=progress.serialize()
	progress.restore(saved)
	check(progress.rank("block")==1 and progress.level==20,"Progression restore preserves ranks and level")
	check(not progress.available("whirlwind") and not progress.available("impale"),"Block 1/3 does not unlock its children")
	progress.learn("block")
	check(not progress.available("whirlwind"),"Block 2/3 still prevents advancing")
	progress.learn("block")
	check(progress.learn("whirlwind") and not progress.available("retaliate"),"Retaliate requires both connected parents")
	check(progress.learn("impale") and progress.available("retaliate"),"Both parents unlock Retaliate")
	for id in ["bloodthirst","retaliate","rampage"]: check(progress.learn(id),"Battle rank: "+id)
	check(not progress.available("bladestorm"),"Three partial parents do not unlock Bladestorm")
	for id in ["bloodthirst","bloodthirst","retaliate"]: progress.learn(id)
	check(progress.learn("bladestorm") and progress.points()==7,"Fully mastered Battle prerequisites unlock Bladestorm")
	progress.restore({"level":20})
	for id in ["momentum","momentum","momentum","leap","unshackled","iron_constitution","iron_constitution","iron_constitution","elemental_resolve","elemental_resolve","fleetfooted","fleetfooted","fleetfooted","blood_and_breath"]: check(progress.learn(id),"Pathfinder rank: "+id)
	check(progress.points()==5,"Fully learned Pathfinder costs fourteen points")
	progress.restore({"level":19,"experience":12,"ranks":{"block":1,"whirlwind":1,"bloodthirst":1}})
	check(progress.level==19 and progress.rank("block")==1 and progress.rank("whirlwind")==0 and progress.rank("bloodthirst")==0 and progress.points()==17 and progress.experience==12,"Legacy partial prerequisites refund invalid descendants without changing EXP")
	# Isolate each rank-one effect below, independently of legal build budgets.
	for talent: Dictionary in CenturionTalents.all(): progress.ranks[talent.id]=1
	p.inventory.equipment.shield=session.catalog.find_item("oak_shield")
	check(is_equal_approx(p.abilities.block_chance(),0.04),"Shield doubles Block chance")
	p.inventory.equipment.shield=null
	check(is_equal_approx(p.abilities.block_chance(),0.02),"Without shield Block remains two percent")
	p.inventory.equipment.amulet=session.catalog.find_item("guardian_amulet")
	p.inventory.changed.emit()
	check(is_equal_approx(p.health.maximum,110.5),"Iron Constitution increases only item vitality")
	p.health.revive()
	check(is_equal_approx(p.abilities.movement_multiplier(),1.23),"Momentum and high-vitality Blood and Breath combine additively")
	p.health.current=20
	p.abilities._physics_process(1)
	check(is_equal_approx(p.health.current,21.105),"Low vitality heals one percent of maximum per second")
	p.abilities.damage_dealt(50)
	check(is_equal_approx(p.health.current,21.605),"Bloodthirst heals from actual damage")
	p.health.current=60
	p.abilities.breath_tick=0
	p.abilities._physics_process(1)
	check(p.health.current==60,"Middle vitality has no conditional healing")
	p.attack.cancel()
	check(p.abilities.activate("rampage"),"Rampage activates")
	check(is_equal_approx(p.swing_seconds(),0.8/1.2),"Attack speed means twenty percent more swings per second")
	var packet:=DamagePacket.new(20,null,&"bleed")
	check(p.abilities.accept_hit(packet) and is_equal_approx(packet.taken_multiplier,1.1),"Rampage increases received damage ten percent")
	p.abilities._physics_process(10)
	check(p.abilities.rampage_left==0 and is_equal_approx(p.swing_seconds(),0.8),"Rampage expires completely")
	check(not p.abilities.activate("rampage"),"Cooldown prevents repeated use")
	p.statuses.apply("slow",10,0.5,"frost")
	p.statuses.apply("root",10)
	check(p.abilities.activate("unshackled") and not p.statuses.has("slow") and not p.statuses.has("root"),"Unshackled removes movement impairments")
	p.statuses.apply("stun",2)
	p.abilities.cooldowns["unshackled"]=0
	check(not p.abilities.activate("unshackled") and p.statuses.has("stun"),"Unshackled does not remove stun")
	p.statuses.reset()
	p.statuses.apply("poison",10,5,"poison")
	p.abilities.cooldowns["elemental_resolve"]=0
	check(p.abilities.activate("elemental_resolve"),"Elemental Resolve activates")
	check(not p.statuses.has("poison") and not p.statuses.apply("slow",10,0.5,"frost"),"Elemental ward cleanses and rejects matching statuses")
	check(not p.abilities.accept_hit(DamagePacket.new(25,null,&"fire")),"Elemental ward rejects elemental damage")
	p.statuses._physics_process(3)
	check(not p.statuses.immune("fire"),"Rank-one elemental ward lasts three seconds")
	p.abilities.block_window=0
	check(not p.abilities.activate("retaliate"),"Retaliate requires a successful block")
	p.abilities.block_window=5
	check(p.abilities.activate("retaliate") and p.abilities.block_window==0,"Retaliate consumes one block opportunity")
	p.abilities.activate("impale")
	p.abilities._swing(Vector3.FORWARD,0.2)
	check(is_equal_approx(p.attack.swing_multiplier,1.5) and p.attack.swing_stun==3,"Impale and Retaliate empower same next basic swing")
	check(p.abilities.impale_left==0 and p.abilities.retaliate_left==0,"Empowerments are consumed once per committed swing")
	p.attack.swing_multiplier=1
	p.attack.swing_stun=0
	p.actions.assign_ability(0,"whirlwind")
	var bindings:=p.actions.serialize()
	p.actions.restore(bindings,session.catalog)
	check(p.actions.slots[0].id=="whirlwind","Ability belt bindings persist")
	var cooldowns:=p.abilities.serialize()
	p.abilities.restore(cooldowns)
	check(p.abilities.remaining("impale")>0,"Cooldowns persist across save restoration")
	p.abilities.reset()
	p.statuses.reset()
	p.health.revive()
	# Full first quest -> offered second quest, no direct dungeon unlock.
	session.quest.accept()
	p.inventory.add(session.catalog.find_item("cellar_key"))
	check(session.quest.claim(p.inventory),"First quest hand-in still succeeds")
	check(session.quest.offered().id==&"warwick_rescue","Rescue is offered only after first hand-in")
	session.quest.accept()
	check(session.quest.definition.id==&"warwick_rescue" and not session.quest.cleared,"Accept second quest starts its own objective")
	check(session.hud.large_map.objective_location().position.distance_to(Vector2(74,87.4))<0.1,"Map objective matches user-marked Warwick site")
	check(session.travel.enter(&"warwick_cellars"),"Cellar instance loads through registry")
	await physics_frame
	await physics_frame
	freeze()
	var boss: Enemy=get_nodes_in_group("enemies")[0]
	check(boss.definition.id==&"brutus" and boss.health.current==120,"Brutus spawns with 120 health")
	check(boss.visual.style=="brutus" and boss.visual.weapon==null and boss.visual.fists.size()==2,"Brutus has a distinct unarmed two-fist silhouette")
	check(session.region.navigation_region.navigation_mesh.get_polygon_count()>0,"Cellar navigation is baked")
	var gate: PrisonGate=session.region.get_node("PrisonGate")
	session._interact(gate)
	check(not gate.opened,"Prison cell cannot open while Brutus lives")
	p.position=Vector3(0,0.1,5)
	p.health.revive()
	var before:=boss.health.current
	var impale:=DamagePacket.new(1,p)
	impale.stun_seconds=3
	boss.receive_damage(impale)
	check(not boss.statuses.has("stun"),"Bosses cannot be stunned by Impale")
	boss.position=Vector3(0,0.1,-2)
	p.position=Vector3(0,0.1,-0.5)
	boss.receive_damage(DamagePacket.new(59,p))
	check(boss.health.current==60 and boss.brute.rage_left==8 and boss.visual.raging,"Brutus rages once at exactly half health")
	# Avoidance remains real; deterministic seed with rank-free character for damage assertions.
	var full_progress:=progress.serialize()
	progress.restore({"level":1})
	p.inventory.equipment={}
	for entry in EquipmentSlots.DEFINITIONS: p.inventory.equipment[entry.id]=null
	p.inventory.changed.emit()
	p.health.revive()
	boss.aggro=true
	var old_hp:=p.health.current
	boss.brute.step(0.49)
	check(p.health.current==old_hp,"Rage waits for the half-second punch interval")
	boss.brute.step(0.01)
	check(p.health.current==old_hp-30 and p.abilities.push_velocity.length()>0,"Rage hits for thirty and knocks back")
	p.position=Vector3(0,0.1,4)
	old_hp=p.health.current
	boss.brute.step(0.5)
	check(p.health.current==old_hp,"Leaving rage radius avoids damage")
	boss.brute.step(7)
	check(boss.brute.rage_left==0 and not boss.visual.raging,"Rage ends after eight seconds")
	boss.receive_damage(DamagePacket.new(1,p))
	check(boss.brute.rage_left==0,"Rage does not retrigger below half health")
	# Real player click movement in the actual instance.
	p.position=Vector3(0,0.1,11)
	p.abilities.push_velocity=Vector3.ZERO
	p.input_enabled=true
	p.set_physics_process(true)
	p.navigation.target_position=Vector3(0,0,6)
	p.click_moving=true
	await create_timer(0.8).timeout
	check(p.position.z<8.5,"Player follows the cellar navigation through live physics")
	p.set_physics_process(false)
	p.click_moving=false
	var xp_before:=progress.experience
	boss.receive_damage(DamagePacket.new(500,p))
	check(progress.experience==xp_before+5 and session.quest.cleared,"Brutus grants five EXP and unlocks rescue objective")
	session._interact(gate)
	check(gate.opened and gate.body.collision_layer==0,"Defeating Brutus permits opening cell")
	var quest_snapshot: Dictionary=session.quest.serialize()
	session.quest.restore(quest_snapshot)
	check(session.quest.cleared and session.quest.flags.kasparov_cell_open,"Quest and cell-open state persist")
	while p.inventory.items.size()<Inventory.CAPACITY: p.inventory.add(session.catalog.find_item("tonic"))
	var gold:=p.inventory.gold
	var lord: Npc=session.region.get_node("NPCs/kasparov")
	session._interact(lord)
	session._service("rescue",0)
	await process_frame
	await physics_frame
	check(session.region.region_id==&"briar_march","Talking to freed lord returns player to town")
	check(session.quest.rewarded and p.inventory.gold==gold+10,"Second quest rewards exactly ten gold")
	check(p.inventory.pending_rewards.size()==1 and p.inventory.pending_rewards[0].id==&"kasparov_seal","Full pack preserves ring in reward reserve")
	check(session.region.has_node("NPCs/kasparov"),"Rescued Kasparov becomes a town NPC")
	check(session.region.get_node("NPCs/kasparov").position.distance_to(session.region.get_node("NPCs/iona").position)<3.5,"Rescued Kasparov stands beside Sister Iona")
	var inv_snapshot:=p.inventory.serialize()
	p.inventory.restore(inv_snapshot,session.catalog)
	p.inventory.items.pop_back()
	p.inventory.claim_pending()
	check(p.inventory.pending_rewards.is_empty() and p.inventory.items.back().id==&"kasparov_seal","Reserved reward survives saving and can be claimed")
	var ring: ItemDefinition=session.catalog.find_item("kasparov_seal")
	check(ring.tier=="green" and ring.vitality_bonus==5 and ring.slot=="ring","Family Seal has requested rarity, slot and vitality")
	check(not session.quest.claim(p.inventory),"Quest reward cannot be claimed twice")
	var persisted:={"inventory":p.inventory.serialize(),"quest":session.quest.serialize(),"regions":session.travel.snapshot(),"progression":progress.serialize(),"cooldowns":p.abilities.serialize(),"actions":p.actions.serialize()}
	var json_state: Dictionary=JSON.parse_string(JSON.stringify(persisted))
	var restored_quest:=QuestLog.new()
	restored_quest.definition=session.catalog.quest
	restored_quest.restore(json_state.quest)
	check(restored_quest.definition.id==&"warwick_rescue" and restored_quest.is_completed("crowbanes_key") and restored_quest.is_completed("warwick_rescue"),"Fresh quest log restores the whole completed chain through JSON")
	restored_quest.free()
	session.travel.enter(&"warwick_cellars")
	await physics_frame
	check(get_nodes_in_group("enemies").is_empty() and not session.region.has_node("NPCs/kasparov"),"Completed cellar does not respawn boss or duplicate rescued lord")
	session.travel.enter(&"briar_march")
	check(session.region.has_node("NPCs/kasparov"),"Kasparov remains in town after region revisits")
	for cue: String in ["level_up","talent_learn","brutus_punch","cell_unlock","cellar_door"]:
		check(AudioLibrary.sample(cue)!=null,"Sound cue loads: "+cue)
	print("PROGRESSION / WARWICK: %d checks, %d failures" % [checks,failures.size()])
	session.queue_free()
	await create_timer(0.3).timeout
	await process_frame
	quit(0 if failures.is_empty() else 1)
