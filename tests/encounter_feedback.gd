extends SceneTree
var session: Node
var checks: int=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	checks+=1
	if value: print("PASS: ",message)
	else:
		failures.append(message)
		push_error("FAIL: "+message)
func freeze() -> void:
	for actor in session.region.actors.get_children():
		if actor is Enemy:
			actor.set_physics_process(false)
			actor.attack.cancel()
			actor.attack.set_physics_process(false)
func knife(point: Vector3, parent: Node3D) -> KnifeProjectile:
	var projectile:=KnifeProjectile.new()
	projectile.direction=Vector3.FORWARD
	projectile.packet=DamagePacket.new(20,null,&"ranged",1)
	projectile.packet.attack_kind=&"ranged"
	projectile.packet.accuracy=1
	parent.add_child(projectile)
	projectile.global_position=point
	projectile.set_physics_process(false)
	return projectile
func run() -> void:
	session=load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await physics_frame
	await physics_frame
	freeze()
	var p: Player=session.player
	p.set_physics_process(false)
	p.combat_state.set_physics_process(false)
	p.abilities.set_physics_process(false)
	p.statuses.set_physics_process(false)
	p.health.invulnerable=false
	var key:=InputEventKey.new()
	key.physical_keycode=KEY_U
	key.pressed=true
	session.hud._input(key)
	check(p.progression.points()==15 and p.progression.level==1,"U grants fifteen points without changing the level")
	check(p.progression.learn("block"),"Testing points can be spent at level one")
	var saved:=p.progression.serialize()
	p.progression.restore(saved)
	check(p.progression.points()==14 and p.progression.rank("block")==1,"Testing points and learned ranks survive restore")
	session.hud.show_talents()
	check(session.hud.mode=="talents","N's talent panel is accessible after the test grant")
	session.hud.close_panel()
	p.progression.restore({})
	for id in ["raider","archer","wolf","elite_bandit","darius","brutus","garrick","bloodfang"]:
		var definition: EnemyDefinition=load("res://content/enemies/"+id+".tres")
		check(definition.leash_radius>=23,"Expanded leash: "+id)
	check(ArtTheme.item_properties(session.catalog.find_item("bloodclaw")).contains("+1 strength") and not ArtTheme.item_properties(session.catalog.find_item("bloodclaw")).contains("(+1 melee"),"Strength tooltip contains only the stat bonus")
	var beast: EnemyDefinition=load("res://content/enemies/bloodfang.tres")
	check(beast.voice_pitch<0.7,"Bloodfang's normal attack, hurt and death vocals are distinctly deep")
	session.quest.definition=load("res://content/quests/lions_den.tres")
	session.quest.accepted=true
	session.travel.enter(&"dark_woods")
	await physics_frame
	await physics_frame
	freeze()
	var region: Region=session.region
	session.hud.show_map()
	check(session.hud.mode.is_empty() and not paused and not session.hud.map_button.visible,"Dark Woods suppresses M and the map button without pausing")
	p.health.configure(1000,100)
	p.receive_ground_fire(DamagePacket.new(20,null,&"fire"))
	check(p.health.current==980 and p.burn_visual.visible,"Ground fire bypasses armor and lights subtle player flames")
	check(AudioLibrary.sample("fire_hurt")!=null,"Dedicated original burn sound decodes")
	p.burn_visual._process(0.7)
	check(not p.burn_visual.visible,"Player flames stop promptly after leaving fire")
	p.statuses.ward(["fire"],2)
	p.receive_ground_fire(DamagePacket.new(20,null,&"fire"))
	check(p.health.current==980,"Fire ward prevents damage with the new presentation path")
	p.statuses.reset()
	# Exact blade-sized sweep checks, including fast traversal and obstruction.
	p.position=Vector3(0,0.1,-45)
	p.health.configure(1000,0)
	await physics_frame
	var direct:=knife(p.position+Vector3(0,1,3),region.actors)
	direct._physics_process(0.3)
	check(p.health.current==980,"Fast knife crossing hits for twenty physical damage")
	direct._physics_process(0.3)
	check(p.health.current==980,"A knife cannot damage twice after contact")
	var miss:=knife(p.position+Vector3(0.55,1,3),region.actors)
	miss._physics_process(0.3)
	check(p.health.current==980 and not miss.is_queued_for_deletion(),"Knife just outside the player capsule is a real near miss")
	miss.queue_free()
	var graze:=knife(p.position+Vector3(0.43,1,3),region.actors)
	graze._physics_process(0.3)
	check(p.health.current==960,"Blade-width grazing contact is detected")
	var cover:=Node3D.new()
	region.add_child(cover)
	Geometry.collider(cover,p.position+Vector3(0,1,1.5),Vector3(3,2,0.2))
	await physics_frame
	var blocked:=knife(p.position+Vector3(0,1,3),region.actors)
	blocked._physics_process(0.3)
	check(p.health.current==960 and blocked.is_queued_for_deletion(),"World geometry stops knives before they hit the player")
	cover.queue_free()
	# A failed attempt restores the bosses without repeating earned loot or EXP.
	var den: DenEncounter=region.get_node("DenEncounter")
	den.started=true
	den.garrick.aggro=true
	p.progression.restore({"level":10})
	var cache: TreasureChest=region.get_node("Cache")
	cache.open()
	den.garrick.health.receive(DamagePacket.new(999,p))
	check(den.released and not den.bloodfang.dormant,"A lethal hit crossing the cage threshold still releases Bloodfang")
	var belt: LootDrop
	for actor in region.actors.get_children():
		if actor is LootDrop and actor.item and actor.item.id==&"blackroad_belt": belt=actor
	check(belt!=null and belt.collect(p.inventory),"First Garrick defeat awards his belt")
	var xp:=p.progression.experience
	var fire:=GroundFire.new()
	region.actors.add_child(fire)
	fire.position=Vector3(0,0,-44)
	p.health.receive(DamagePacket.new(99999,null,&"fire"))
	await process_frame
	await process_frame
	check(den.garrick.health.current==160 and den.bloodfang.health.current==200 and den.bloodfang.dormant,"Player death restores both bosses and cages Bloodfang")
	check(not den.cage.opened and den.cage.gate.position.y==0 and den.cage.barrier.collision_layer==1,"Death restores a visibly and physically locked cage")
	check(get_nodes_in_group("ground_fires").is_empty(),"Failed encounter clears its ground fires")
	check(cache.opened and region.world_state.woods_cache,"Failed encounter preserves the opened maze chest")
	check(not session.quest.cleared and not region.world_state.bloodfang_released,"Death clears unfinished encounter and release progress")
	var snapshot: Dictionary=session.travel.snapshot()
	check(not "woods_garrick" in snapshot.dark_woods.defeated and "woods_garrick" in snapshot.dark_woods.world.credited_defeats,"Snapshot retains reward credit while resetting fight completion")
	session.hud.close_panel()
	session._respawn()
	session.travel.enter(&"dark_woods")
	await physics_frame
	freeze()
	den=session.region.get_node("DenEncounter")
	check(den.bloodfang.dormant and not den.cage.opened,"Returning after respawn begins with Bloodfang locked up")
	den.garrick.health.receive(DamagePacket.new(999,p))
	check(p.progression.experience==xp,"Defeating Garrick again does not farm extra EXP")
	var duplicate:=false
	for actor in session.region.actors.get_children():
		if actor is LootDrop and actor.item and actor.item.id==&"blackroad_belt": duplicate=true
	check(not duplicate,"Defeating Garrick again does not duplicate his already collected belt")
	session.travel.enter(&"briar_march")
	session.hud.show_map()
	check(session.hud.mode=="map" and session.hud.map_button.visible,"M remains available outside Dark Woods")
	session.hud.close_panel()
	print("FEEDBACK: %d checks, %d failures" % [checks,failures.size()])
	session.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	quit(0 if failures.is_empty() else 1)
