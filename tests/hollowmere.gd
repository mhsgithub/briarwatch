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
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func freeze() -> void:
	for e in session.region.actors.get_children():
		if e is Enemy:
			e.set_physics_process(false)
			e.attack.set_physics_process(false)
			e.attack.cancel()
func run() -> void:
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await frames(2)
	freeze()
	var p: Player = session.player
	p.set_physics_process(false)
	p.combat_state.set_physics_process(false)
	p.abilities.set_physics_process(false)
	p.statuses.set_physics_process(false)
	p.health.invulnerable = false
	check(session.region.has_node("NPCs/oswin"),"Briarwatch has a talent instructor")
	check(session.region.get_node("NPCs/oswin").position.distance_to(Vector3(-26,0,27))<4,"Oswin stands beside the town campfire")
	session.hud.show_npc(session.region.get_node("NPCs/elric"))
	session._service("travel",0)
	session.hud.close_panel()
	await frames(1)
	check(session.region.region_id == &"briar_march","Elric cannot travel before quest three is handed in")
	check(session.saved_recovery_region({"recovery_region":"hollowmere"})==&"briar_march","A locked marsh cannot become the saved recovery hub")
	session.quest.completed.assign(["warwick_rescue","lions_den"])
	check(session.saved_recovery_region({})==&"briar_march","Older saves retain safe Briarwatch recovery")
	check(session.saved_recovery_region({"recovery_region":"hollowmere"})==&"hollowmere","Unlocked marsh saves restore to the expedition camp")
	session.hud.show_npc(session.region.get_node("NPCs/elric"))
	session._service("travel",0)
	await frames(3)
	freeze()
	check(session.region.region_id == &"hollowmere","Elric's confirmed journey loads Hollowmere")
	check(p.position.distance_to(session.region.player_spawn.position)<1,"Travel arrives safely in Lanternwatch Camp")
	var region: Region = session.region
	var stock: Array[ItemDefinition] = region.get_node("NPCs/rowan").definition.stock
	var expected_stock := {"tonic":5,"greater_tonic":40,"guardian_amulet":100,"wyrmhide_grips":125,"emerald_band":125,"wyrmsteel_shoulders":150,"oakheart_guard":150,"wyrmfang":225}
	check(stock.size()==expected_stock.size(),"Rowan stocks exactly eight requested items")
	var shop_inventory := Inventory.new()
	shop_inventory.gold = 2000
	for item in stock:
		check(expected_stock.has(str(item.id)) and item.price==expected_stock.get(str(item.id),-1),"Rowan stock and price: "+str(item.id))
		var before := shop_inventory.gold
		check(shop_inventory.buy(item) and shop_inventory.gold==before-item.price,"Vendor purchase charges the listed price: "+str(item.id))
		if item.slot not in ["consumable","amulet"]:
			check(item.tier=="green" and item.icon!=null,"Vendor gear has green quality and painted art: "+str(item.id))
	check(shop_inventory.equip(7,"weapon"),"Wyrmfang equips through ordinary inventory interaction")
	check(shop_inventory.equipment.weapon.two_handed and shop_inventory.equipment.weapon.appearance=="polearm","Wyrmfang uses a two-handed polearm model")
	var shop_save := shop_inventory.serialize()
	shop_inventory.restore(shop_save,session.catalog)
	check(shop_inventory.equipment.weapon.id==&"wyrmfang" and shop_inventory.items.size()==7,"All Rowan stock survives inventory save restoration")
	shop_inventory.free()
	var vendor_stats := {
		"wyrmhide_grips":{"armor_bonus":3,"strength_bonus":1,"crit_rating":1},
		"emerald_band":{"crit_rating":1,"strength_bonus":1},
		"wyrmsteel_shoulders":{"armor_bonus":4,"vitality_bonus":10},
		"oakheart_guard":{"armor_bonus":5,"vitality_bonus":10},
		"wyrmfang":{"damage_bonus":23,"swing_seconds":2.0,"strength_bonus":2,"vitality_bonus":10}}
	for id in vendor_stats:
		var item: ItemDefinition = session.catalog.find_item(id)
		for field in vendor_stats[id]:
			check(item!=null and is_equal_approx(float(item.get(field)),float(vendor_stats[id][field])),"Vendor property: "+id+" "+field)
	check(region.has_node("Ambience"),"Marsh has sparse environmental ambience")
	for variant in range(1,4):
		var frog := load("res://assets/audio/marsh_frog_%d.mp3" % variant) as AudioStream
		check(frog!=null and frog.get_length()>0,"Frog recording variant imports for offline playback: %d" % variant)
	var ambience: RegionAmbience = region.get_node("Ambience")
	AudioLibrary.last_played.erase("marsh_frogs")
	ambience.remaining = 0
	ambience._process(0)
	check(not AudioLibrary.last_played.has("marsh_frogs"),"Frog ambience stays outside Lanternwatch")
	p.position = Vector3(-60,0.1,30)
	ambience.remaining = 0
	ambience._process(0)
	check(AudioLibrary.last_played.has("marsh_frogs") and ambience.remaining>=18 and ambience.remaining<=36,"Distant frog cue plays in the wilderness with a sparse random interval")
	p.position = region.player_spawn.position
	var map := region.navigation_region.get_navigation_map()
	check(region.map_bounds.get_area()>256*224,"Hollowmere is larger than the Briar March")
	check(region.actors.get_child_count()==81,"Eighty-one authored wildlife enemies inhabit the marsh")
	for actor in region.actors.get_children():
		if not actor is Enemy: continue
		var route := NavigationServer3D.map_get_path(map,p.position,actor.position,true)
		check(not route.is_empty() and route[-1].distance_to(actor.position)<1.6,"Reachable wildlife: "+str(actor.spawn_id))
	for child in region.get_children():
		if child is TreasureChest:
			var route := NavigationServer3D.map_get_path(map,p.position,child.position,true)
			check(not route.is_empty() and route[-1].distance_to(child.position)<1.5,"Reachable cache: "+child.chest_id)
	for marker in region.get_node("PointsOfInterest").get_children():
		var route := NavigationServer3D.map_get_path(map,p.position,marker.position,true)
		check(not route.is_empty() and route[-1].distance_to(marker.position)<3,"Reachable landmark: "+str(marker.name))
	check(session.music.requested_track()==&"hollowmere_camp","Camp selects the quieter soundtrack")
	p.position = Vector3(-60,0.1,30)
	check(session.music.requested_track()==&"hollowmere","Leaving camp selects the marsh soundtrack")
	var crossing := NavigationServer3D.map_get_path(map,Vector3(-60,0,54),Vector3(-60,0,30),true)
	var crossing_length := 0.0
	for i in range(1,crossing.size()): crossing_length += crossing[i-1].distance_to(crossing[i])
	check(crossing_length<28 and crossing_length>20,"Navigation uses the bridge directly across the flood")
	var chest: TreasureChest = region.get_node("Cache0")
	var gold := p.inventory.gold
	check(chest.open() and not chest.open(),"A marsh cache opens only once")
	check(p.inventory.gold==gold,"Cache gold lands on the floor")
	var table: LootTable = load("res://content/loot/marsh_wildlife.tres")
	var random := RandomNumberGenerator.new()
	random.seed = 44827
	var counts: Dictionary = {}
	var gold_counts := [0,0,0,0,0,0]
	for i in range(100000):
		var rolled := table.roll(random)
		gold_counts[rolled.gold] += 1
		for item in rolled.items: counts[item.id] = int(counts.get(item.id,0))+1
	check(gold_counts[0]>65000 and gold_counts[1]==0 and gold_counts[2]==0,"Sampled wildlife gold favors zero and only drops three through five otherwise")
	for entry in table.entries:
		check(absf(float(counts.get(entry.item.id,0))/100000.0-entry.chance)<0.002,"Sampled item drop probability: "+str(entry.item.id))
		check(entry.item.icon!=null and entry.item.icon.get_width()>250,"Marsh icon loads: "+str(entry.item.id))
	var drops: Array = []
	for actor in region.actors.get_children():
		if actor is LootDrop: drops.append(actor)
	check(drops.size()==1 and drops[0].gold==12,"Cache creates its authored gold drop")
	var e: Enemy = region.actors.get_child(0)
	p.inventory.equipment.weapon = session.catalog.find_item("bogiron_greatblade")
	p.inventory.equipment.shield = null
	p.inventory.equipment.boots = session.catalog.find_item("marshrunner_boots")
	p.inventory.changed.emit()
	check(p.crit_rating()==2 and p.melee_damage()==20 and p.swing_seconds()==1.9,"Greatblade applies its damage, swing period and crit rating")
	check(is_equal_approx(p.abilities.movement_multiplier(),1.05),"Marshrunner Boots increase movement by five percent")
	var test_item := ItemDefinition.new()
	test_item.crit_rating=100
	p.inventory.equipment.ring_left=test_item
	e.health.configure(200,3)
	e.receive_damage(DamagePacket.new(20,p))
	check(e.health.current==166 and e.health.last_critical,"Guaranteed critical strike doubles damage after armor")
	var crit_text: FloatingText
	for child in region.actors.get_children():
		if child is FloatingText: crit_text=child
	check(crit_text!=null and crit_text.font_size==58 and crit_text.modulate==Color("ffdb37"),"Critical damage displays a larger yellow number")
	p.inventory.equipment.weapon=null
	p.inventory.equipment.ring_left=null
	p.inventory.changed.emit()
	check(p.crit_rating()==0,"Unequipped base critical chance is zero")
	e.health.configure(200)
	e.receive_damage(DamagePacket.new(20,p))
	check(e.health.current==180 and not e.health.last_critical,"Zero rating never critically strikes")
	p.health.configure(100,0)
	var poison := DamagePacket.new(17,e)
	poison.poison_damage=1
	poison.poison_seconds=3
	p.receive_damage(poison)
	p.statuses._physics_process(3.0)
	check(p.health.current==80 and not p.statuses.has("poison"),"Widow bite deals its physical hit plus exactly three poison damage")
	p.statuses.ward(["poison"],5)
	p.receive_damage(poison)
	check(not p.statuses.has("poison"),"Elemental Resolve blocks widow poison")
	p.statuses.reset()
	p.statuses.apply("root",2)
	check(p.statuses.movement_factor()==0,"Web root prevents ordinary movement")
	p.progression.grant_test_points(15)
	p.progression.ranks={"momentum":3,"fleetfooted":3,"unshackled":1}
	p.abilities.activate("unshackled")
	check(not p.statuses.has("root"),"Unshackled clears Broodqueen roots")
	p.statuses.control_immune=true
	check(not p.statuses.apply("root",2),"Bladestorm movement immunity rejects roots")
	p.statuses.reset()
	p.actions.assign_ability(1,"unshackled")
	p.actions.assign_item(0,session.catalog.find_item("tonic"))
	p.inventory.gold=99
	check(not p.reset_talents() and p.progression.rank("momentum")==3,"Unaffordable reset is atomic")
	p.inventory.gold=150
	p.abilities.rampage_left=5
	var earned := p.progression.level-1+p.progression.test_points
	check(p.reset_talents() and p.inventory.gold==50 and p.progression.points()==earned,"Reset costs 100 gold and refunds every spent point")
	check(p.actions.slots[1].is_empty() and p.actions.slots[0].get("kind")=="item" and p.abilities.rampage_left==0,"Reset clears learned bindings and buffs, preserving consumables")
	check(not p.reset_talents() and p.inventory.gold==50,"An empty tree cannot charge twice")
	# Exercise projectile physics, rather than applying the root directly.
	p.position=Vector3(-104,0.1,94)
	var bolt := WebProjectile.new()
	bolt.source=e
	bolt.direction=Vector3.BACK
	region.actors.add_child(bolt)
	bolt.position=p.position+Vector3(0,0.65,-6)
	await frames(40)
	check(p.statuses.has("root"),"Swept web collision roots a stationary player")
	p.statuses._physics_process(1.99)
	check(p.statuses.has("root"),"Web root lasts the full two seconds")
	p.statuses._physics_process(0.02)
	check(not p.statuses.has("root"),"Web expires and restores movement")
	bolt=WebProjectile.new()
	bolt.source=e
	bolt.direction=Vector3.BACK
	region.actors.add_child(bolt)
	bolt.position=p.position+Vector3(0,0.65,-6)
	p.position.x += 2
	await frames(45)
	check(not p.statuses.has("root"),"Sidestepping the locked web trajectory avoids rooting")
	if is_instance_valid(bolt): bolt.queue_free()
	p.position=Vector3(-104,0.1,94)
	var wall := Node3D.new()
	region.actors.add_child(wall)
	wall.position=p.position+Vector3(0,0,-3)
	Geometry.collider(wall,Vector3.UP,Vector3(3,2,0.4))
	await frames(2)
	bolt=WebProjectile.new()
	bolt.source=e
	bolt.direction=Vector3.BACK
	region.actors.add_child(bolt)
	bolt.position=p.position+Vector3(0,0.65,-6)
	await frames(45)
	check(not p.statuses.has("root") and not is_instance_valid(bolt),"Solid scenery intercepts the web before the player")
	wall.queue_free()
	# Real click-to-move traverses the planks; water physically blocks stepping off.
	p.position=Vector3(-60,0.25,54)
	p.navigation.target_position=Vector3(-60,0.2,30)
	p.click_moving=true
	p.input_enabled=true
	for i in range(360):
		p._physics_process(1.0/60.0)
		await physics_frame
	check(p.position.distance_to(Vector3(-60,0.2,30))<2,"Real player movement crosses the causeway bridge")
	p.click_moving=false
	p.position=Vector3(-60,0.3,43)
	for i in range(80): p.move_and_collide(Vector3(0.1,0,0))
	check(p.position.x<-58,"Bridge rails and deep water prevent walking off the crossing")
	var gear_save := p.inventory.serialize()
	p.inventory.add(session.catalog.find_item("fenwarden_charm"))
	gear_save=p.inventory.serialize()
	p.inventory.restore(gear_save,session.catalog)
	check(p.inventory.items.any(func(item: ItemDefinition): return item.id==&"fenwarden_charm"),"Marsh gear survives stable-ID inventory persistence")
	var snapshot: Dictionary=session.travel.snapshot()
	session.travel.enter(&"briar_march")
	await frames(2)
	freeze()
	session.travel.enter(&"hollowmere")
	await frames(2)
	freeze()
	check(session.region.get_node("Cache0").opened,"Opened caches persist on return travel")
	check(snapshot.hollowmere.world.hollowmere_cache_0,"Marsh chest state is included in save snapshots")
	p.health.invulnerable=false
	p.receive_damage(DamagePacket.new(1000))
	session.hud.close_panel()
	session._respawn()
	check(not p.dead and session.region.region_id==&"hollowmere" and p.position.distance_to(session.region.player_spawn.position)<1,"Death recovers at the marsh camp")
	print("HOLLOWMERE: %d checks, %d failures" % [checks,failures.size()])
	session.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
