extends SceneTree
var session: Node
var checks: int = 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if value: print("PASS: ",message)
	else:
		failures.append(message)
		push_error("FAIL: "+message)
func freeze() -> void:
	for child in session.region.actors.get_children():
		if child is Enemy:
			child.set_physics_process(false)
			child.attack.set_physics_process(false)
			child.attack.cancel()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	session=load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await frames(2)
	freeze()
	var p: Player=session.player
	p.set_physics_process(false)
	p.combat_state.set_physics_process(false)
	p.abilities.set_physics_process(false)
	p.statuses.set_physics_process(false)
	p.health.invulnerable=false
	var quest: QuestLog=session.quest
	var entrance: Node3D=session.region.get_node("Portals/DarkWoods")
	var approach:=NavigationServer3D.map_get_path(session.region.navigation_region.get_navigation_map(),p.position,entrance.global_position,true)
	check(not approach.is_empty() and approach[-1].distance_to(entrance.global_position)<1,"Town navigation reaches the portal through the irregular forest edge")
	check(quest.definition.next_quest.next_quest.id==&"lions_den","Third quest follows Kasparov's rescue")
	session._interact(session.region.get_node("Portals/DarkWoods"))
	check(session.region.region_id==&"briar_march","Northwest portal is gated by Kasparov's quest")
	quest.accept()
	p.inventory.add(session.catalog.find_item("cellar_key"))
	quest.claim(p.inventory)
	quest.accept()
	quest.encounter_cleared(&"brutus")
	quest.flags["kasparov_cell_open"]=true
	quest.claim(p.inventory)
	session._finish_rescue()
	var lord := session.region.get_node("NPCs/kasparov") as Npc
	check(is_instance_valid(lord),"Rescued Kasparov remains the town quest NPC")
	session.hud.show_npc(lord)
	session._service("accept",0)
	session.hud.close_panel()
	check(quest.definition.id==&"lions_den" and quest.accepted,"Kasparov offers and accepts the third quest")
	var saved_quest := quest.serialize()
	quest.restore(saved_quest)
	check(quest.definition.id==&"lions_den" and quest.accepted,"Quest three survives save restore")
	var belt: ItemDefinition = session.catalog.find_item("blackroad_belt")
	var sword: ItemDefinition = session.catalog.find_item("bloodclaw")
	p.inventory.equipment.belt=belt
	p.inventory.equipment.weapon=sword
	p.inventory.changed.emit()
	check(p.strength()==1 and p.melee_damage()==11 and p.attack.damage_bonus==11,"Strength adds one damage to displayed and actual melee")
	check(p.swing_seconds()==0.8 and p.health.maximum==110,"Bloodclaw swing speed and belt vitality aggregate")
	check(belt.tier=="green" and belt.armor_bonus==2 and sword.tier=="green" and not sword.two_handed,"Both unique Green items retain requested properties")
	check("strength" in ArtTheme.item_properties(sword),"Item inspection explains Strength")
	var inventory_save := p.inventory.serialize()
	p.inventory.restore(inventory_save,session.catalog)
	check(p.inventory.equipment.weapon==sword and p.strength()==1,"New loot restores through the stable catalog")
	check(session.travel.enter(&"dark_woods"),"Dark Woods instance loads")
	await frames(3)
	freeze()
	var region: Region=session.region
	var den: DenEncounter=region.get_node("DenEncounter")
	var g: Enemy=den.garrick
	var b: Enemy=den.bloodfang
	check(region.map_bounds.size.x>100 and region.map_bounds.size.y>140,"Dark Woods is a substantial instance")
	check(region.actors.get_child_count()==20,"Maze has eighteen patrols and exactly two bosses")
	check(g.health.maximum==160 and b.health.maximum==200,"Boss health matches the encounter")
	var elite: EnemyDefinition=load("res://content/enemies/elite_bandit.tres")
	check(elite.max_health==80 and elite.attack.damage==15 and elite.hit_chance==0.8 and elite.experience==2,"Elite Bandit balance and EXP")
	check(elite.loot_table==load("res://content/loot/march_enemies.tres"),"Elite Bandit shares ordinary loot")
	check(b.dormant and b.health.invulnerable and not b.is_in_group("enemies"),"Caged Bloodfang cannot be targeted or activated")
	b.receive_damage(DamagePacket.new(500,p))
	check(b.health.current==200,"Cage prevents premature damage")
	var map := region.navigation_region.get_navigation_map()
	var route := NavigationServer3D.map_get_path(map,p.position,Vector3(0,0,-40),true)
	var route_length: float=0
	for i in range(1,route.size()): route_length+=route[i-1].distance_to(route[i])
	print("Maze route length: ",route_length)
	check(route.size()>12 and route_length>200 and route[-1].distance_to(Vector3(0,0,-40))<1,"Navigation reaches the clearing through the maze, without a shortcut")
	for enemy in region.actors.get_children():
		if not enemy is Enemy: continue
		var path := NavigationServer3D.map_get_path(map,p.position,enemy.position,true)
		check(not path.is_empty() and path[-1].distance_to(enemy.position)<1,"Authored spawn reachable: "+str(enemy.spawn_id))
	var cache: TreasureChest=region.get_node("Cache")
	var cache_path := NavigationServer3D.map_get_path(map,p.position,cache.position,true)
	check(not cache_path.is_empty() and cache_path[-1].distance_to(cache.position)<1,"Deep side-branch chest is reachable")
	# Traverse the native route with actual CharacterBody collision. Remove only
	# frozen actors' collision for this environmental navigation check.
	for child in region.actors.get_children():
		if child is Enemy: child.collision_layer=0
	p.set_physics_process(true)
	p.move_speed=9.92
	p.navigation.target_position=Vector3(0,0,-40)
	p.click_moving=true
	Engine.time_scale=4
	for i in range(1000):
		await physics_frame
		if p.position.distance_to(Vector3(0,0,-40))<1.3: break
	Engine.time_scale=1
	check(p.position.distance_to(Vector3(0,0,-40))<1.3,"Player physically traverses the entire maze into the clearing")
	p.set_physics_process(false)
	p.move_speed=4.96
	p.health.invulnerable=false
	for child in region.actors.get_children():
		if child is Enemy: child.collision_layer=4
	var wall: DarkThicket=region.get_node("NavigationRegion/Scenery/Thicket0")
	p.position=wall.to_global(Vector3(0,0.1,3))
	var crossing:=p.move_and_collide(wall.global_basis*Vector3(0,0,-6))
	check(crossing!=null,"Solid tree thickets prevent walking across maze walls")
	var gold_before:=p.inventory.gold
	session._interact(cache)
	session._interact(cache)
	check(p.inventory.gold==gold_before,"Opening the chest leaves gold on the floor")
	session.travel.enter(&"briar_march",&"dark_woods")
	check(p.position.distance_to(Vector3(-104,0.1,-84))<0.1,"Exit returns at the marked northwest entrance")
	session.travel.enter(&"dark_woods")
	await frames(3)
	freeze()
	region=session.region
	den=region.get_node("DenEncounter")
	g=den.garrick
	b=den.bloodfang
	check(region.get_node("Cache").opened and not region.get_node("Cache").open(),"Chest remains open across region snapshots")
	var coins: LootDrop
	for actor in region.actors.get_children():
		if actor is LootDrop and actor.gold==15: coins=actor
	check(coins!=null and coins.collect(p.inventory) and p.inventory.gold==gold_before+15,"Uncollected chest gold persists and is collected once from the floor")
	p.position=Vector3(0,0.1,-43)
	g.position=Vector3(0,0.1,-46)
	g.aggro=true
	g.den_combat.fire_left=0
	g.den_combat.step(0.01)
	check(g.den_combat.warning_kind=="fire","Garrick telegraphs ground fire")
	g.den_combat.step(0.9)
	var thrown: TorchThrow
	for actor in region.actors.get_children():
		if actor is TorchThrow: thrown=actor
	check(thrown!=null and get_nodes_in_group("ground_fires").is_empty(),"Vane throws a visible torch before the ground ignites")
	thrown._physics_process(0.45)
	var fire: GroundFire=get_nodes_in_group("ground_fires")[0]
	fire.set_physics_process(false)
	check(fire.radius>=2.5 and fire.remaining==40,"Fire has a substantial radius and forty-second lifetime")
	p.position=fire.position+Vector3.UP*0.1
	p.health.configure(1000,999)
	var hp:=p.health.current
	fire._physics_process(1)
	check(p.health.current==hp-40,"Ground fire ticks twenty damage twice a second through armor")
	p.statuses.ward(["fire"],3)
	hp=p.health.current
	fire._physics_process(0.5)
	check(p.health.current==hp,"Elemental fire immunity applies to the new hazard")
	p.statuses.reset()
	p.position=Vector3(0,0.1,-43.9)
	p.health.armor=0
	g.attack.direction=Vector3.BACK
	g.attack.rng.seed=811
	var bleeds:=0
	for i in range(1000):
		p.health.current=1000
		p.combat_state.reset()
		g.attack._resolve()
		if p.combat_state.bleed_left>0: bleeds+=1
	check(bleeds>260 and bleeds<340,"Garrick's on-hit bleed occurs at thirty percent")
	check(p.combat_state.bleed_damage==2 and p.combat_state.bleed_left<=5,"Garrick bleed is ten damage over five seconds")
	p.combat_state.reset()
	g.receive_damage(DamagePacket.new(120,p))
	check(g.den_combat.releasing,"Quarter-health Garrick commits to the cage sprint")
	for i in range(240):
		g.den_combat.step(1.0/60)
		await physics_frame
		if den.released: break
	check(den.released and not b.dormant and den.cage.opened,"Garrick physically reaches the cage and releases Bloodfang")
	check(g.health.current>0,"Garrick survives the release and continues fighting")
	g.health.receive(DamagePacket.new(999,p))
	check(is_instance_valid(fire) and fire.remaining>0,"Garrick's death leaves existing fires burning")
	check(not quest.cleared,"Garrick's death alone does not complete the quest")
	b.position=Vector3(0,0.1,-49)
	b.aggro=true
	b.den_combat.fury_cooldown=100
	b.den_combat.lunge_cooldown=100
	p.position=Vector3(0,0.1,-44)
	b.receive_damage(DamagePacket.new(70,p))
	b.den_combat.step(0.01)
	b.den_combat.step(1.2)
	check(b.den_combat.howl_count==1 and region.encounter_counts.get(&"bloodfang_pack",0)==2,"Sixty-six percent howl calls exactly two Greyfangs")
	b.receive_damage(DamagePacket.new(65,p))
	b.den_combat.step(0.01)
	b.den_combat.step(1.2)
	check(b.den_combat.howl_count==2 and region.encounter_counts.get(&"bloodfang_pack",0)==4,"Thirty-three percent howl calls the second pair")
	freeze()
	var wolves: Array[Enemy]=[]
	for child in region.actors.get_children():
		if child is Enemy and child.encounter_id==&"bloodfang_pack": wolves.append(child)
	for wolf in wolves: wolf.health.receive(DamagePacket.new(999,p))
	check(get_nodes_in_group("wolf_corpses").size()==4,"Defeated Greyfangs leave edible corpses")
	var corpse: Enemy=wolves[0]
	b.position=corpse.position
	var before_feed:=b.health.current
	b.den_combat.step(0.01)
	check(b.den_combat.feed_left==3 and b.visual.feeding,"Bloodfang stops and visibly feeds on a corpse underfoot")
	b.den_combat.step(1)
	b.den_combat.step(1)
	b.den_combat.step(1)
	check(b.health.current==before_feed+45 and corpse.corpse_consumed,"Feeding heals fifteen per second for three seconds and consumes the corpse")
	b.position=Vector3(0,0.1,-47)
	p.position=Vector3(0,0.1,-45)
	p.health.current=1000
	p.combat_state.reset()
	b.den_combat.fury_cooldown=0
	b.den_combat.step(0.01)
	check(b.den_combat.warning_kind=="fury","Wolf fury has a visual/audio windup")
	b.den_combat.step(1.3)
	b.den_combat.step(0.01)
	check(b.visual.raging and p.combat_state.bleed_left==5 and p.combat_state.bleed_damage==12,"Nearby fury applies sixty bleed over five seconds")
	hp=p.health.current
	p.combat_state._physics_process(5)
	check(p.health.current==hp-60,"Fury bleed deals its exact five ticks")
	b.den_combat.step(4)
	check(b.den_combat.fury_cooldown>14,"Fury cannot trigger again before twenty seconds")
	b.den_combat.fury_cooldown=100
	b.den_combat.lunge_cooldown=0
	p.position=b.position+Vector3(0,0,6)
	b.den_combat.step(0.01)
	check(b.den_combat.warning_kind=="lunge","Lunge commits its heading with a visible windup")
	b.den_combat.step(0.7)
	hp=p.health.current
	for i in range(40):
		b.den_combat.step(1.0/60)
		await physics_frame
	check(p.health.current==hp-maxf(1,23-p.health.armor) and p.abilities.push_velocity.length()>0,"Lunge makes contact for twenty-three base melee damage through armor and knockback")
	b.health.receive(DamagePacket.new(999,p))
	check(quest.cleared and not quest.rewarded,"Bloodfang's death changes the objective to return to Kasparov")
	var loot_ids: Array[String]=[]
	for child in region.actors.get_children():
		if child is LootDrop and child.item: loot_ids.append(str(child.item.id))
	check("bloodclaw" in loot_ids and "blackroad_belt" in loot_ids,"Both bosses drop their guaranteed unique items")
	var snapshot: Dictionary = session.travel.snapshot()
	check("woods_garrick" in snapshot.dark_woods.defeated and "woods_bloodfang" in snapshot.dark_woods.defeated,"Boss defeats persist independently")
	check(snapshot.dark_woods.fires.size()==1,"Lingering fires are included in region snapshots")
	session.travel.enter(&"briar_march")
	session.hud.show_npc(session.region.get_node("NPCs/kasparov"))
	gold_before=p.inventory.gold
	session._service("claim",0)
	session._service("claim",0)
	check(quest.rewarded and p.inventory.gold==gold_before+50,"Kasparov awards exactly fifty gold once")
	session.hud.close_panel()
	check(quest.offered().next_quest==null,"Into the Lion's Den is the final March quest")
	session.travel.enter(&"dark_woods")
	await frames(2)
	check(not is_instance_valid(session.region.get_node("DenEncounter").bloodfang),"Completed boss does not respawn")
	check(session.region.get_node("NavigationRegion/Scenery/Cage").opened,"Cage remains open on completed revisit")
	check(get_nodes_in_group("ground_fires").size()==1,"Remaining fire lifetime survives leaving and revisiting")
	print("DARK WOODS: %d checks, %d failures" % [checks,failures.size()])
	session.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures.is_empty() else 1)
