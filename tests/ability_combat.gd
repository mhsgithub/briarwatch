extends SceneTree
var checks:=0
var failures: Array[String]=[]
var session: Node
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks+=1
	if value: print("PASS: ",message)
	else:
		failures.append(message)
		push_error("FAIL: "+message)
func freeze() -> void:
	for enemy: Enemy in get_nodes_in_group("enemies"):
		enemy.process_mode=Node.PROCESS_MODE_DISABLED
		enemy.attack.cancel()
func run() -> void:
	session=load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await physics_frame
	await physics_frame
	session.travel.enter(&"watchtower")
	await physics_frame
	await physics_frame
	freeze()
	var p: Player=session.player
	p.set_physics_process(false)
	p.abilities.set_physics_process(false)
	p.combat_state.set_physics_process(false)
	p.statuses.set_physics_process(false)
	var learned:={"block":3,"whirlwind":1,"impale":1,"bloodthirst":3,"retaliate":2,"rampage":1,"bladestorm":1,"momentum":3,"leap":1,"unshackled":1,"elemental_resolve":2}
	p.progression.restore({"level":20,"ranks":learned})
	check(p.progression.points()==0,"Nineteen-point build respects maximum-level budget")
	var boss: Enemy
	var guards: Array[Enemy]=[]
	for enemy: Enemy in get_nodes_in_group("enemies"):
		if enemy.definition.commander: boss=enemy
		else: guards.append(enemy)
	p.position=Vector3(0,0.1,2)
	var boss_impale:=DamagePacket.new(0,p)
	boss_impale.stun_seconds=3
	boss.receive_damage(boss_impale)
	check(not boss.statuses.has("stun"),"Darius explicitly resists Impale stun")
	boss.position=Vector3(0,0.1,0)
	guards[0].position=Vector3(1.5,0.1,2)
	guards[1].position=Vector3(5,0.1,2)
	await physics_frame
	p.health.current=50
	check(p.abilities.activate("whirlwind"),"Whirlwind activates with learned rank")
	check(boss.health.current==117 and guards[0].health.current==27 and guards[1].health.current==35,"Whirlwind deals double weapon damage only within three metres")
	check(is_equal_approx(p.health.current,50.48),"Whirlwind lifesteals actual aggregate damage at Bloodthirst rank three")
	p.abilities.cooldowns["whirlwind"]=0
	# A world obstacle between nearby actors blocks area damage.
	var wall:=StaticBody3D.new()
	session.region.add_child(wall)
	wall.position=Vector3(0,1,1)
	var shape:=CollisionShape3D.new()
	var box:=BoxShape3D.new()
	box.size=Vector3(1,3,0.2)
	shape.shape=box
	wall.add_child(shape)
	await physics_frame
	var before:=boss.health.current
	p.abilities.activate("whirlwind")
	check(boss.health.current==before,"Whirlwind cannot damage through a solid wall")
	wall.queue_free()
	await physics_frame
	guards[0].position=Vector3(6,0.1,2)
	p.abilities.cooldowns["bladestorm"]=0
	check(p.abilities.activate("bladestorm"),"Bladestorm starts")
	check(not p.statuses.apply("stun",3) and not p.statuses.apply("root",3) and not p.statuses.apply("slow",3,0.5),"Bladestorm rejects stun, roots and slows through shared status path")
	var kick:=DamagePacket.new(0,boss)
	kick.knockdown_seconds=1
	kick.knockback=7
	p.receive_damage(kick)
	check(p.combat_state.knockdown_left==0 and p.abilities.push_velocity==Vector3.ZERO,"Bladestorm also prevents knockdown and knockback")
	before=boss.health.current
	p.abilities._physics_process(0.99)
	check(boss.health.current==before,"Bladestorm does not deal an extra immediate tick")
	p.abilities._physics_process(5.01)
	check(boss.health.current==before-24 and p.abilities.storm_left==0,"Bladestorm deals exactly six full weapon-damage pulses")
	check(not p.statuses.control_immune,"Bladestorm immunity ends with the channel")
	p.abilities.cooldowns["leap"]=0
	p.position=Vector3(0,0.1,9)
	p.facing=Vector3.FORWARD
	p.attack.cancel()
	check(p.abilities.activate("leap"),"Forward Leap activates")
	for i in range(30): p.abilities.move_leap(1.0/60)
	check(absf(p.position.z+1)<0.2 and p.visual.position.y<0.01,"Leap travels ten metres and lands with restored visual height")
	p.position=Vector3(0,0.1,9)
	p.abilities.leap_left=0
	p.abilities.cooldowns["leap"]=0
	wall=StaticBody3D.new()
	session.region.add_child(wall)
	wall.position=Vector3(0,1,6)
	shape=CollisionShape3D.new()
	box=BoxShape3D.new()
	box.size=Vector3(5,3,0.3)
	shape.shape=box
	wall.add_child(shape)
	await physics_frame
	p.abilities.activate("leap")
	for i in range(30): p.abilities.move_leap(1.0/60)
	check(p.position.z>6.4 and p.abilities.leap_left==0,"Leap stops before solid walls rather than tunnelling")
	wall.queue_free()
	await physics_frame
	p.position=Vector3(0,0.1,3)
	p._face(Vector3.FORWARD)
	boss.position=Vector3(5,0.1,0)
	guards[0].position=Vector3(0,0.1,1.6)
	guards[0].health.revive()
	p.attack.cancel()
	p.abilities.cooldowns["impale"]=0
	p.abilities.block_window=5
	p.abilities.activate("retaliate")
	p.abilities.activate("impale")
	p._try_attack(Vector3.FORWARD)
	await create_timer(0.3).timeout
	check(guards[0].health.current==27 and guards[0].statuses.has("stun"),"A real rank-two Retaliate/Impale swing deals double damage and stuns ordinary enemies")
	guards[0].statuses._physics_process(3)
	check(not guards[0].statuses.has("stun"),"Impale stun expires after three seconds")
	p.attack.cancel()
	# Actual overkill cannot generate healing based on nominal damage.
	guards[0].health.current=1
	p.health.current=50
	guards[0].receive_damage(DamagePacket.new(1000,p))
	check(is_equal_approx(p.health.current,50.03),"Bloodthirst never heals from overkill damage")
	p.abilities.cooldowns["elemental_resolve"]=0
	p.abilities.activate("elemental_resolve")
	p.statuses._physics_process(5.9)
	check(p.statuses.immune("poison"),"Rank-two Elemental Resolve remains active until six seconds")
	p.statuses._physics_process(0.11)
	check(not p.statuses.immune("poison"),"Rank-two elemental ward expires at six seconds")
	# Accuracy subtraction is tested statistically, with feedback suppressed by
	# keeping this check at the shared acceptance path's deterministic RNG.
	p.progression.restore({"level":20,"ranks":{"momentum":3,"unshackled":1,"fleetfooted":3}})
	p.abilities.rng.seed=3197
	var hits:=0
	for i in range(2000):
		var packet:=DamagePacket.new(1,boss)
		packet.accuracy=0.7
		if p.abilities.accept_hit(packet): hits+=1
	check(absf(float(hits)/2000-0.61)<0.03,"Fleetfooted subtracts nine percentage points from base accuracy")
	await process_frame
	p.progression.restore({"level":20,"ranks":{"block":3}})
	p.inventory.equipment.shield=session.catalog.find_item("oak_shield")
	p.abilities.rng.seed=7393
	var blocked:=0
	for i in range(1000):
		if not p.abilities.accept_hit(DamagePacket.new(1,boss)): blocked+=1
	check(absf(float(blocked)/1000-0.12)<0.03 and p.abilities.block_window==5,"Real melee blocks use twelve percent with shield and open Retaliate window")
	var arrow:=DamagePacket.new(1,boss)
	arrow.attack_kind=&"ranged"
	check(p.abilities.accept_hit(arrow),"Block does not block ranged attacks")
	# Live Brutus follows, punches and physically displaces the player.
	session.travel.enter(&"warwick_cellars")
	await physics_frame
	await physics_frame
	var brute: Enemy=get_nodes_in_group("enemies")[0]
	p.progression.restore({"level":1})
	p.inventory.equipment.shield=null
	p.inventory.equipment.body=null
	p.inventory.changed.emit()
	p.health.configure(1000,0)
	p.position=Vector3(0,0.1,4)
	brute.aggro=true
	var original:=brute.position
	await create_timer(0.8).timeout
	check(brute.position.distance_to(original)>1.2,"Live Brutus navigates toward the player")
	p.position=brute.position+Vector3(0,0,1.7)
	p.abilities.set_physics_process(true)
	p.set_physics_process(true)
	await create_timer(1.8).timeout
	check(p.health.current<1000 and p.position.distance_to(brute.position)>1.8,"Live basic punches deal damage and push the player back")
	p.set_physics_process(false)
	p.abilities.set_physics_process(false)
	brute.set_physics_process(false)
	brute.attack.cancel()
	brute.health.current=120
	p.health.configure(1000,0)
	brute.receive_damage(DamagePacket.new(60,p))
	for i in range(16):
		p.position=brute.position+Vector3(0,0,1.5)
		brute.brute.step(0.5)
	check(p.health.current==520,"Eight-second rage produces exactly sixteen thirty-damage hits")
	check(not brute.attack.pending and brute.attack.remaining>0,"Rage ends with recovery rather than an overlapping ordinary punch")
	# Gate protects the actual route, including Leap.
	var gate: PrisonGate=session.region.get_node("PrisonGate")
	p.progression.restore({"level":5,"ranks":{"momentum":3,"leap":1}})
	p.position=Vector3(0,0.1,-7)
	p.facing=Vector3.FORWARD
	p.abilities.cooldowns["leap"]=0
	var leap_started:=p.abilities.activate("leap")
	for i in range(30): p.abilities.move_leap(1.0/60)
	check(leap_started and p.position.z> -8.6 and p.abilities.leap_left==0,"Leap cannot bypass Kasparov's locked cell")
	# Retain exactly the authored graphical dependencies and portable editor data.
	check(brute.definition.brute.rage_radius==2.8 and brute.definition.is_boss,"Brutus tuning lives in an editable optional kit")
	print("ABILITY COMBAT: %d checks, %d failures" % [checks,failures.size()])
	session.queue_free()
	await create_timer(0.3).timeout
	await process_frame
	quit(0 if failures.is_empty() else 1)
