extends SceneTree
## Run with --headless --path . --script res://tests/integration.gd -- --test
var failures: Array[String] = []
var checks: int = 0
var session: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures.append(message)
		push_error("FAIL: " + message)

func tick(seconds: float) -> void:
	await create_timer(seconds).timeout

func run() -> void:
	# Headless windows default to 64x64: use design resolution for GUI hit tests.
	root.size=Vector2i(1440,900)
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await physics_frame
	await physics_frame
	await tick(0.15)
	var player: Player = session.player
	# Isolate existing combat/tonic expectations; resting recovery has its own suite.
	player.combat_state.regeneration_enabled = false
	var region: Region = session.region
	var inventory := player.inventory
	check(session.testing, "Integration tests are isolated from player saves")
	check(inventory.gold==0 and inventory.items.size()==1 and inventory.items[0].id==&"tonic" and player.health.maximum==100,"New character starts with one Tonic, zero gold and 100 vitality")
	check(get_nodes_in_group("enemies").size() == 76, "All 76 authored outdoor enemies spawn, including Warwick guards")
	check(preload("res://tools/validate_region.gd").validate(region).is_empty(), "Region editing contract validates")
	check(region.navigation_region.navigation_mesh.get_polygon_count() > 0, "Native navigation mesh bakes")
	var valid_spawns := true
	for enemy in get_nodes_in_group("enemies"):
		var closest := NavigationServer3D.map_get_closest_point(region.get_world_3d().navigation_map, enemy.home)
		if closest.distance_to(enemy.home) > 1.0:
			print("Spawn outside navigation: ", enemy.spawn_id, " ", closest.distance_to(enemy.home))
			valid_spawns = false
	check(valid_spawns, "Every placed enemy spawns on reachable ground")
	var path := NavigationServer3D.map_get_path(region.get_world_3d().navigation_map, region.player_spawn.global_position, Vector3(97, 0, -75), true)
	check(path.size() >= 2 and path[path.size() - 1].distance_to(Vector3(97, 0, -75)) < 1.0, "Town and watchtower connected by a navigable path")
	var original_pos := player.global_position
	player.navigation.target_position = original_pos + Vector3(0, 0, 4)
	player.click_moving = true
	await tick(1.0)
	check(player.global_position.distance_to(original_pos) > 2.0, "Player actually follows click movement through physics")
	player.click_moving = false
	player.global_position = original_pos
	# Input travels through Godot's normal event pipeline.
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	await tick(0.3)
	key = InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = false
	Input.parse_input_event(key)
	var camera_forward := -player.camera.global_basis.z
	camera_forward.y = 0
	check((player.global_position - original_pos).dot(camera_forward) > 0.5, "W moves toward the top of the camera view")
	player.global_position = original_pos
	# Standard Inspector properties survive an authored scene save/reload.
	var edited: Node = load("res://scenes/world/briar_march.tscn").instantiate()
	var marker: EnemySpawn = edited.get_node("Encounters/watchtower/raider_1")
	marker.health_override = 123
	marker.damage_override = 17
	marker.position.x += 2
	var packed := PackedScene.new()
	check(packed.pack(edited) == OK and ResourceSaver.save(packed, "user://edited_region.tscn") == OK, "Editable region can be repacked and saved")
	var reloaded: Node = load("user://edited_region.tscn").instantiate()
	var edited_marker: EnemySpawn = reloaded.get_node("Encounters/watchtower/raider_1")
	check(edited_marker.health_override == 123 and edited_marker.damage_override == 17 and edited_marker.position == marker.position, "Placed enemy transform and overrides survive scene round-trip")
	check(edited_marker.definition.max_health == 45, "Scene editing does not overwrite type defaults")
	var second: EnemySpawn = reloaded.get_node("Encounters/watchtower/raider_2")
	second.spawn_id = edited_marker.spawn_id
	check(not preload("res://tools/validate_region.gd").validate(reloaded).is_empty(), "Editor validator detects duplicated persistent spawn IDs")
	edited.free()
	reloaded.free()
	check(inventory.bonus("damage_bonus") == 4 and inventory.bonus("armor_bonus") == 3, "Starter gear contributes live stats")
	var original_gold := inventory.gold
	check(not inventory.buy(session.catalog.find_item("mail")) and inventory.gold == original_gold, "Unaffordable purchase is atomic")
	inventory.gold = 100
	check(inventory.buy(session.catalog.find_item("warden_blade")), "Vendor purchase adds item")
	check(inventory.gold == 20, "Vendor deducts exact price")
	inventory.equip(inventory.items.size() - 1)
	check(player.attack.damage_bonus == 8 and inventory.equipment.weapon.id == &"warden_blade", "Equipping replaces gear and updates combat")
	check(inventory.items.back().id == &"old_sword", "Replaced weapon returns to pack")
	check(inventory.sell(inventory.items.size() - 1) and inventory.gold == 22, "Selling credits resale value")
	player.receive_damage(DamagePacket.new(30))
	check(player.health.current == 73, "Incoming physical damage applies equipment armor")
	player.use_potion()
	check(player.health.current == 73 and inventory.items.is_empty(), "Tonic consumes one item without instant healing")
	await tick(5.1)
	check(player.health.current == 100, "Tonic recovery clamps to maximum vitality")
	var full: Inventory = Inventory.new()
	root.add_child(full)
	full.gold = 100
	for i in range(Inventory.CAPACITY):
		full.add(session.catalog.find_item("tonic"))
	check(not full.buy(session.catalog.find_item("tonic")) and full.gold == 100, "Full pack purchase cannot consume gold")
	full.queue_free()
	# Test a configured marker override without mutating its shared resource.
	var captain: Enemy
	for enemy in get_nodes_in_group("enemies"):
		if enemy.spawn_id == &"watchtower_1":
			captain = enemy
	check(captain != null and captain.health.maximum == 45 and captain.definition.max_health == 45, "Tower bandit uses the retuned base health without a stale override")
	# Real timed melee hit, not direct damage to the target.
	var victim: Enemy = get_nodes_in_group("enemies")[0]
	victim.set_physics_process(false)
	victim.global_position = player.global_position + Vector3(0, 0, -1.5)
	var before := victim.health.current
	player._try_attack(Vector3.FORWARD)
	await tick(0.35)
	check(victim.health.current < before, "Sword windup resolves a real directional melee hit")
	check(not player.attack.request(Vector3.FORWARD), "Attack cooldown prevents immediate repeat")
	await tick(0.6)
	# Facing away must not hit.
	before = victim.health.current
	player._try_attack(Vector3.BACK)
	await tick(0.3)
	check(victim.health.current == before, "Melee arc rejects targets behind attacker")
	# Guarantee this orchestration fixture drops currency without mutating type defaults.
	victim.definition = victim.definition.duplicate()
	victim.definition.loot_table = victim.definition.loot_table.duplicate()
	victim.definition.loot_table.gold_weights = PackedFloat32Array([0,1])
	victim.receive_damage(DamagePacket.new(1000, player))
	await physics_frame
	check(str(victim.spawn_id) in region.defeated_ids, "Enemy death is tracked by stable spawn ID")
	var drops := get_nodes_in_group("interactables").filter(func(node): return node is LootDrop)
	check(not drops.is_empty(), "Enemy death produces collectible loot")
	if not drops.is_empty():
		var drop: LootDrop = drops[0]
		var balance := inventory.gold
		var gold := drop.gold
		check(drop.collect(inventory) and inventory.gold == balance + gold, "Ground loot transfers reward to inventory")
		check(not drop.collect(inventory), "Loot cannot be collected twice")
	# Actual projectile physics: archer windup creates an arrow, ray hits player.
	var archer: Enemy
	for enemy in get_nodes_in_group("enemies"):
		if enemy.definition.behavior == "archer":
			archer = enemy
			break
	archer.set_physics_process(false)
	archer.global_position = player.global_position + Vector3(0, 0, 7)
	archer.home = archer.global_position
	before = player.health.current
	archer.attack.request(player.global_position - archer.global_position)
	await tick(1.6)
	check(player.health.current < before, "Archer projectile travels and deals damage")
	archer.queue_free()
	# Objective progression and one-time payout.
	session.quest.accept()
	for enemy in get_nodes_in_group("enemies").duplicate():
		if enemy.encounter_id == &"watchtower":
			enemy.receive_damage(DamagePacket.new(1000, player))
	check(not session.quest.cleared, "Clearing the exterior camp does not replace retrieving Crowbane's key")
	inventory.add(session.catalog.find_item("cellar_key"))
	check(session.quest.cleared, "Picking up the cellar key completes the retrieval objective")
	var reward_gold_before:=inventory.gold
	var reward_items_before:=inventory.items.duplicate()
	check(session.quest.claim(inventory) and inventory.gold==reward_gold_before+50 and inventory.items==reward_items_before, "Quest pays exactly 50 gold and no item")
	check(not session.quest.claim(inventory), "Quest reward cannot be claimed twice")
	# Persistence round-trip, unknown IDs and damaged file fallback.
	var data := {"inventory": inventory.serialize(), "quest": session.quest.serialize(), "defeated": region.defeated_ids, "loot": session._serialize_loot()}
	var test_path := "user://integration_save.json"
	check(SaveStore.write(data, test_path) == OK, "Save writes successfully")
	check(SaveStore.write(data, test_path) == OK, "Save replaces atomically and creates backup")
	var saved := SaveStore.read(test_path)
	check(saved.inventory.items == inventory.serialize().items and saved.inventory.equipment == inventory.serialize().equipment and int(saved.inventory.gold) == inventory.gold, "Inventory save round-trip preserves stable IDs")
	var restored := Inventory.new()
	root.add_child(restored)
	restored.restore(saved.inventory, session.catalog)
	check(restored.bonus("damage_bonus") == inventory.bonus("damage_bonus") and restored.gold == inventory.gold, "Loaded equipment and gold match")
	restored.restore({"gold": -10, "items": ["missing_item"], "equipment": {"weapon": "tonic"}}, session.catalog)
	check(restored.gold == 0 and restored.items.is_empty() and restored.equipment.weapon == null, "Invalid IDs and slot mismatches are safely rejected")
	restored.queue_free()
	var file := FileAccess.open(test_path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	check(not SaveStore.read(test_path).is_empty(), "Corrupt save falls back to last valid backup")
	# Death uses the actual signal / HUD / recovery path.
	var gear_before: Dictionary = inventory.serialize().equipment
	var gold_before := inventory.gold
	player.receive_damage(DamagePacket.new(10000))
	check(player.dead and session.hud.mode == "death" and paused, "Lethal damage opens recovery screen and pauses play")
	session.hud.close_panel()
	session.hud.respawn_requested.emit()
	check(not player.dead and player.health.current == player.health.maximum, "Recovery restores a living player")
	check(player.global_position.distance_to(region.player_spawn.global_position) < 0.1, "Recovery returns to authored town spawn")
	check(inventory.gold == gold_before - int(ceil(gold_before * 0.1)) and inventory.serialize().equipment == gear_before, "Death penalty preserves equipment")
	# NPC UI transactions are routed through the composed session.
	var healer: Npc = region.get_node("NPCs/iona")
	session._interact(healer)
	check(session.hud.mode == "npc" and paused, "NPC interaction opens a modal service")
	var dead_ids:=region.defeated_ids.duplicate()
	player.health.current=50
	session._service("heal",0)
	check(player.health.current==player.health.maximum and region.defeated_ids==dead_ids,"Iona heals without resetting encounters")
	var healer_buttons: Array[Node]=session.hud.panel.find_children("*","Button",true,false)
	check(healer_buttons.all(func(button): return not "Rest" in button.text),"Iona no longer offers Rest until dawn")
	# Internal fixture reset remains available to tests, not as a player service.
	region.reset_encounters()
	session.hud.close_panel()
	await physics_frame
	await verify_overhaul(player, region)
	await verify_feedback(player, region)
	await verify_playtest_feedback(player, region)
	print("INTEGRATION RESULT: %d checks, %d failures" % [checks, failures.size()])
	session.queue_free()
	await process_frame
	await tick(0.2)
	quit(0 if failures.is_empty() else 1)

func verify_overhaul(player: Player, region: Region) -> void:
	# Backward compatibility: a v1 save containing only the original slots.
	var gear := Inventory.new()
	root.add_child(gear)
	gear.restore({"gold":20,"items":[],"equipment":{"weapon":"old_sword","shield":"oak_shield","body":"coat"}},session.catalog)
	check(gear.equipment.size()==11 and gear.equipment.head==null and gear.bonus("armor_bonus")==3, "Old three-slot saves restore into eleven slots without losing gear")
	var ring := ItemDefinition.new()
	ring.id=&"test_ring"
	ring.slot="ring"
	ring.armor_bonus=2
	gear.add(ring)
	gear.add(ring)
	check(gear.equip(0) and gear.equip(0) and gear.equipment.ring_left==ring and gear.equipment.ring_right==ring, "Rings choose the first free compatible slot")
	check(gear.bonus("armor_bonus")==7, "Both ring slots contribute their modifiers")
	gear.add(session.catalog.find_item("tonic"))
	check(not gear.equip(0,"head") and gear.items.size()==1, "Incompatible explicit equipment drops are rejected atomically")
	var local_catalog := ContentCatalog.new()
	local_catalog.items=session.catalog.items.duplicate()
	local_catalog.items.append(ring)
	var restored := Inventory.new()
	root.add_child(restored)
	restored.restore(gear.serialize(),local_catalog)
	check(restored.equipment.ring_left==ring and restored.equipment.ring_right==ring, "Expanded equipment survives a stable-ID save round-trip")
	while gear.items.size()<Inventory.CAPACITY:
		gear.add(session.catalog.find_item("tonic"))
	check(not gear.unequip("ring_left") and gear.equipment.ring_left==ring, "A full pack cannot discard equipped gear")
	gear.queue_free()
	restored.queue_free()
	var label := FloatingText.spawn(region.actors,player.global_position+Vector3.UP*2,14)
	var start_y := label.position.y
	await tick(0.25)
	check(is_instance_valid(label) and label.position.y>start_y+0.1, "Damage numbers animate immediately after spawning")
	await tick(1.2)
	check(not is_instance_valid(label), "Damage numbers expire and are removed from the scene")
	# Exercise real archer retreat AI and real player pursuit, timing and hit resolution.
	player.global_position=Vector3(-35,0.05,46)
	player.recovery_time=10
	player.attack.cancel()
	var archer: Enemy=load("res://scenes/entities/enemy.tscn").instantiate()
	archer.definition=load("res://content/enemies/archer.tres")
	archer.spawn_id=&"regression_archer"
	archer.position=Vector3(-35,0.05,49)
	region.actors.add_child(archer)
	archer.aggro=true
	# Shift has priority even when the cursor is directly over an enemy.
	var shift := InputEventKey.new()
	shift.keycode=KEY_SHIFT
	shift.physical_keycode=KEY_SHIFT
	shift.pressed=true
	Input.parse_input_event(shift)
	# Let Godot process the buffered modifier before dispatching the click.
	await process_frame
	var standing_click := InputEventMouseButton.new()
	standing_click.button_index=MOUSE_BUTTON_LEFT
	standing_click.pressed=true
	standing_click.position=player.camera.unproject_position(archer.global_position+Vector3.UP*0.8)
	player._unhandled_input(standing_click)
	var standing_started := player.attack.pending
	var standing_position := player.position
	await tick(0.25)
	check(standing_started and player.attack_target==null and Vector2(player.position.x,player.position.z).distance_to(Vector2(standing_position.x,standing_position.z))<0.05, "Shift-clicking an enemy attacks in place without pursuit or forward advance")
	shift.pressed=false
	Input.parse_input_event(shift)
	player.attack.cancel()
	archer.position=Vector3(-35,0.05,49)
	var hit_events: Array[float]=[]
	archer.health.damaged.connect(func(amount: float): hit_events.append(amount))
	player.attack_target=archer
	player.click_moving=true
	var archer_start := archer.position
	await tick(0.30)
	check(archer.position.distance_to(archer_start)>0.3, "Regression archer actually retreats through navigation and physics")
	await tick(1.40)
	check(not hit_events.is_empty(), "Targeted sword pursuit hits a retreating archer without shortening windup")
	player.attack_target=null
	player.click_moving=false
	player.attack.cancel()
	if is_instance_valid(archer): archer.queue_free()
	player.respawn(region.player_spawn.global_position)
	# Floating UI opens with all slots and twenty bag cells; no detached duplicates.
	session.hud.show_inventory()
	await process_frame
	var cells: Array[Node]=session.hud.panel.find_children("*","ItemTile",true,false)
	check(cells.size()==31, "Inventory renders eleven equipment slots and twenty pack cells")
	session.hud.close_panel()
func verify_feedback(player: Player, region: Region) -> void:
	var catalog: ContentCatalog = session.catalog
	var camera: Camera3D = player.camera
	var original := player.global_position
	var basis_before := camera.global_basis
	var angle_stable := true
	for offset in [Vector3(5,0,2),Vector3(-4,0,6),Vector3.ZERO]:
		player.global_position=original+offset
		await tick(0.12)
		angle_stable=angle_stable and camera.global_basis.is_equal_approx(basis_before)
	check(angle_stable,"Camera translation never changes pitch or yaw during direction changes")
	player.global_position=original
	check(region.map_bounds.size==Vector2(256,224) and region.encounter_counts.size()==19,"Region retains its size with nineteen outdoor encounters")
	check(region.get_node("Encounters/watchtower").global_position.distance_to(region.player_spawn.global_position)>175,"Watchtower is substantially farther from town")
	var kings_road: Node=region.get_node("NavigationRegion/KingsRoad")
	var road_length:=0.0
	for i in range(1,kings_road.points.size()):
		road_length+=kings_road.points[i-1].distance_to(kings_road.points[i])
	check(road_length>300,"Winding king's road spans the expanded region")
	check(session.hud.root.find_children("*","RegionMap",true,false).size()==1,"HUD has only the M map, no minimap")

	var inventory:=player.inventory
	inventory.restore({"gold":0,"items":[],"equipment":{}},catalog)
	check(player.melee_damage()==0 and player.health.armor==0 and player.health.maximum==100,"Unequipped Centurion has 0 melee damage, 0 armor and 100 vitality")
	check(player.visual.find_children("gear_*","Node3D",true,false).is_empty(),"Unequipped Centurion has no visible equipment")
	var dummy:=HealthComponent.new()
	root.add_child(dummy)
	dummy.configure(100,2)
	dummy.receive(DamagePacket.new(0))
	check(dummy.current==100,"Zero melee damage does not become a minimum one-damage hit")
	dummy.receive(DamagePacket.new(10,null,&"melee"))
	check(dummy.current==92,"Two armor subtracts exactly two incoming melee damage")
	dummy.receive(DamagePacket.new(10,null,&"ranged"))
	check(dummy.current==84,"Two armor subtracts exactly two incoming ranged damage")
	dummy.receive(DamagePacket.new(1,null,&"physical"))
	check(dummy.current==84,"Armor can fully absorb a weak physical hit")
	dummy.queue_free()
	inventory.add(catalog.find_item("old_sword"))
	inventory.equip(0)
	check(player.melee_damage()==4 and player.attack.cooldown_override==0.8,"Watch sword supplies exactly 4 damage and a 0.8 second swing period")
	check(player.visual.find_children("gear_weapon","Node3D",true,false).size()==1,"Equipped weapon is represented on the world character")
	inventory.add(catalog.find_item("oak_shield")); inventory.equip(0)
	inventory.add(catalog.find_item("pitchfork"))
	while inventory.items.size()<Inventory.CAPACITY: inventory.add(catalog.find_item("tonic"))
	var snapshot:=inventory.serialize()
	check(not inventory.equip(0) and inventory.serialize()==snapshot,"Two-handed swap into a full pack is atomic and loses no equipment")
	inventory.items.pop_back()
	check(inventory.equip(0) and inventory.equipment.shield==null and inventory.blocking_slot("shield")=="weapon","Pitchfork displaces both hands into the pack")
	check(player.melee_damage()==10 and player.attack.cooldown_override==1.8 and player.health.armor==0,"Pitchfork supplies 10 melee damage, 1.8 second swings and no shield armor")
	check(player.visual.find_children("gear_shield","Node3D",true,false).is_empty(),"Two-handed weapon removes visible shield")
	var shield_index:=inventory.items.find(catalog.find_item("oak_shield"))
	check(inventory.equip(shield_index) and inventory.equipment.weapon==null,"Equipping a shield displaces a two-handed weapon safely")
	inventory.restore({"items":[],"equipment":{"weapon":"forged_sword"}},catalog)
	check(inventory.equipment.weapon.id==&"old_sword" and catalog.items.all(func(it): return it.id!=&"forged_sword"),"Retired forged sword migrates to Watch sword and is absent from content")
	inventory.add(catalog.find_item("guardian_amulet")); inventory.equip(0)
	check(player.health.maximum==110 and player.health.armor==2,"Guardian amulet contributes armor and maximum vitality")
	check(player.visual.find_children("gear_amulet","Node3D",true,false).size()==1,"Amulet has a visible equipment attachment")
	check(ArtTheme.tier_color(catalog.find_item("guardian_amulet"))==Color("78c684"),"Green quality is reflected by the shared name color")
	inventory.unequip("amulet")
	check(player.health.maximum==100,"Removing vitality gear restores the base maximum without healing")

	inventory.restore({"items":["tonic","greater_tonic"],"equipment":{}},catalog)
	player.health.current=10
	player.use_consumable(&"tonic")
	check(player.health.current==10 and inventory.items.size()==1,"Tonic starts a five-second recovery without an instant heal")
	player.use_consumable(&"greater_tonic")
	check(inventory.items.size()==1,"Active recovery rejects another Tonic without consuming it")
	await tick(2.0)
	check(absf(player.health.current-30)<1.0,"Tonic restores ten vitality per second")
	paused=true
	var paused_hp:=player.health.current
	await tick(0.25)
	check(player.health.current==paused_hp,"Potion recovery pauses with inventory/dialogue gameplay")
	paused=false
	await tick(3.1)
	check(absf(player.health.current-60)<0.1 and player.potion_recovery.remaining==0,"Tonic restores exactly fifty over its complete duration")
	player.health.current=1
	player.use_consumable(&"greater_tonic")
	await tick(2.0)
	check(absf(player.health.current-41)<1.0,"Greater Tonic restores twenty vitality per second")
	player.potion_recovery.cancel()
	check(player.potion_recovery.remaining==0,"Recovery can be cancelled on death and respawn")
	player.health.revive()
	inventory.add(catalog.find_item("tonic"))
	player.use_consumable(&"tonic")
	check(inventory.items.size()==1,"Full-health Tonic use preserves the item")
	check(player.actions.slots.all(func(slot): return slot.is_empty()),"All six action slots start empty")
	check(player.actions.assign_item(0,catalog.find_item("tonic")) and not player.actions.assign_item(1,catalog.find_item("old_sword")),"Action slots accept consumables and reject equipment")
	var action_saved:=player.actions.serialize()
	player.actions.clear(0)
	player.actions.restore(action_saved,catalog)
	check(player.actions.slots[0].id=="tonic","Action bindings round-trip by stable content ID")
	player.health.current=20
	player.actions.activate(0)
	check(inventory.items.is_empty() and player.potion_recovery.remaining>0,"Assigned action consumes the matching item through the player")
	player.actions.activate(0)
	check(inventory.items.is_empty(),"Empty-stock action is safe and keeps its binding")
	player.actions.clear(0)
	player.potion_recovery.cancel()
	player.health.revive()

	var table: LootTable=load("res://content/loot/march_enemies.tres")
	var same_table:=true
	for id in ["wolf","raider","archer"]:
		var definition: EnemyDefinition=load("res://content/enemies/"+id+".tres")
		same_table=same_table and definition.loot_table==table
	check(same_table and EnemyDefinition.new().loot_table==null,"Only current enemy definitions opt into the shared loot table")
	var rng:=RandomNumberGenerator.new()
	rng.seed=9917
	var gold_counts: Array[int]=[0,0,0,0]
	var item_counts: Dictionary={}
	var only_allowed_consumables:=true
	for i in range(10000):
		var roll:=table.roll(rng)
		gold_counts[roll.gold]+=1
		for item in roll.items:
			item_counts[item.id]=item_counts.get(item.id,0)+1
			only_allowed_consumables=only_allowed_consumables and (item.slot!="consumable" or item.id==&"tonic")
	check(gold_counts[0]>gold_counts[1] and gold_counts[1]>gold_counts[2] and gold_counts[2]>gold_counts[3],"Gold drops only 0–3, weighted toward zero")
	var gold_rates := [0.55, 0.27, 0.12, 0.06]
	var gold_valid := true
	for i in range(4):
		gold_valid = gold_valid and absf(float(gold_counts[i]) / 10000.0 - gold_rates[i]) < 0.02
	check(gold_valid, "Gold outcomes match 55/27/12/6 percent: a modest increase with zero still most likely")
	var expected: Dictionary={"worn_gloves":0.035,"worn_belt":0.035,"ragged_hood":0.035,"stitched_vest":0.025,"ragged_boots":0.035,"pitchfork":0.015,"tonic":0.02}
	var rates_valid:=table.entries.size()==7
	for id in expected:
		rates_valid=rates_valid and absf(float(item_counts.get(StringName(id),0))/10000.0-expected[id])<0.009
	check(rates_valid and only_allowed_consumables,"Seeded loot matches six reduced gear rates and 2% Tonic drops")
	var stock: Array[ItemDefinition]=region.get_node("NPCs/mara").definition.stock
	var prices: Dictionary={"tonic":5,"greater_tonic":40,"mail":60,"warden_blade":80,"iron_shield":65,"watchkeeper_helmet":50,"outrider_gloves":30,"outrider_belt":30,"outrider_boots":40,"guardian_amulet":100}
	check(stock.size()==10 and stock.all(func(item): return prices.get(str(item.id),-1)==item.price),"Mara stocks exactly the ten requested items at the requested prices")
	check(catalog.items.all(func(item): return item.slot=="quest" or (item.sell_price>=1 and item.sell_price<=16 and item.sell_price<item.price)),"All tradeable items have explicit modest sell values")
	GameAudio.play_drop(region.actors,original,false)
	GameAudio.play_drop(region.actors,original,true)
	check(AudioLibrary.sample("gold")!=AudioLibrary.sample("gear"),"Gold and gear drops use distinct recorded cues")

	var prop: WorldProp=region.get_node("NavigationRegion/Scenery/house_3")
	var fade: ProximityFade=prop.find_children("*","ProximityFade",true,false)[0]
	player.set_physics_process(false)
	player.global_position=prop.global_position+Vector3(0,0.1,2.9)
	await tick(0.4)
	check(fade.opacity<0.3 and not fade.faded.is_empty(),"Very close large scenery fades smoothly in the Compatibility renderer")
	player.global_position=original
	await tick(0.4)
	check(fade.opacity==1.0 and fade.faded.is_empty() and fade.meshes[0].material_override==fade.originals[0],"Leaving restores original shared materials and full opacity")
	player.set_physics_process(true)
	var fire: FireVisual=region.get_node("NavigationRegion/Scenery/fire_8").find_children("*","FireVisual",true,false)[0]
	var energy:=fire.light.light_energy
	var flame_pos:=fire.flames[0].position
	await tick(0.2)
	check(fire.light.light_energy!=energy and fire.flames[0].position!=flame_pos,"Fire animation and illumination vary over time")
	check(fire.find_children("*","CPUParticles3D",true,false).size()==1,"Reusable fires include rising ember particles")
	session.hud.show_inventory()
	await process_frame
	var preview: CharacterPreview=session.hud.panel.find_children("*","CharacterPreview",true,false)[0]
	check(preview.equipment==inventory.equipment,"Character preview receives the real equipped appearance state")
	session.hud.close_panel()
	# Real GUI drop routing: the modal scrim must not swallow the action belt.
	inventory.add(catalog.find_item("tonic"))
	session.hud.show_inventory()
	await process_frame
	var cells: Array[Node]=session.hud.panel.find_children("*","ItemTile",true,false)
	var source: ItemTile
	for cell in cells:
		if cell.bag_index==0 and cell.equipment_slot.is_empty(): source=cell
	var target: ActionTile=session.hud.action_slots.get_child(0)
	var preview_icon:=TextureRect.new()
	preview_icon.texture=ArtTheme.item_icon(catalog.find_item("tonic"))
	preview_icon.custom_minimum_size=Vector2(32,32)
	source.force_drag({"inventory":inventory,"index":0,"slot":""},preview_icon)
	var motion:=InputEventMouseMotion.new()
	motion.position=target.get_global_rect().get_center()
	motion.global_position=motion.position
	motion.button_mask=MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await process_frame
	var release:=InputEventMouseButton.new()
	release.button_index=MOUSE_BUTTON_LEFT
	release.position=motion.position
	release.global_position=motion.position
	release.pressed=false
	Input.parse_input_event(release)
	await process_frame
	check(player.actions.slots[0].get("id","")=="tonic","Dragging from the open pack reaches the action belt through real GUI hit testing")
	var toggle:=InputEventKey.new()
	toggle.physical_keycode=KEY_I
	toggle.pressed=true
	Input.parse_input_event(toggle)
	await process_frame
	check(session.hud.mode.is_empty() and not paused,"I closes the inventory through real input dispatch")
	toggle.pressed=false
	Input.parse_input_event(toggle)
	player.health.current=20
	var hotkey:=InputEventKey.new()
	hotkey.physical_keycode=KEY_1
	hotkey.pressed=true
	Input.parse_input_event(hotkey)
	await process_frame
	check(inventory.items.is_empty() and player.potion_recovery.remaining>0,"Number key activates a bound Tonic through real input dispatch")
	hotkey.pressed=false
	Input.parse_input_event(hotkey)
	player.potion_recovery.cancel()
	player.health.revive()

func verify_playtest_feedback(player: Player, region: Region) -> void:
	var inventory:=player.inventory
	check(is_equal_approx(player.move_speed,4.96),"Player base speed is reduced by exactly 20 percent")
	var expected: Dictionary={"raider":[45,8,0.7,2.8],"archer":[35,11,1.0,2.64],"wolf":[30,6,0.6,4.24]}
	for id in expected:
		var definition: EnemyDefinition=load("res://content/enemies/"+id+".tres")
		var values: Array=expected[id]
		check(definition.max_health==values[0] and definition.attack.damage==values[1] and is_equal_approx(definition.hit_chance,values[2]) and is_equal_approx(definition.move_speed,values[3]),id+" has requested health, damage, accuracy and reduced speed")
		var accuracy:=AttackComponent.new()
		accuracy.hit_chance=definition.hit_chance
		accuracy.rng.seed=7891
		var hits:=0
		for i in range(50000):
			if accuracy.roll_hit(): hits+=1
		check(absf(float(hits)/50000.0-definition.hit_chance)<0.01,id+" accuracy distribution matches its configured chance")
		accuracy.free()
	var bandit: Enemy=load("res://scenes/entities/enemy.tscn").instantiate()
	bandit.definition=load("res://content/enemies/raider.tres")
	region.actors.add_child(bandit)
	bandit.global_position=player.global_position+Vector3(0,0,1.4)
	bandit.set_physics_process(false)
	player.recovery_time=0
	player.health.invulnerable=false
	player.health.armor=1000
	player.health.current=20
	bandit.attack.hit_chance=0
	bandit.attack.request(Vector3.FORWARD)
	await tick(0.75)
	check(player.health.current==20,"A geometrically valid enemy miss deals no damage")
	bandit.attack.cancel()
	bandit.attack.hit_chance=1
	bandit.attack.request(Vector3.FORWARD)
	await tick(0.75)
	check(player.health.current==19,"A successful enemy melee hit deals one through overwhelming armor")
	bandit.attack.cancel()
	bandit.attack.definition=load("res://content/attacks/arrow.tres")
	bandit.attack.hit_chance=0
	bandit.global_position=player.global_position+Vector3(0,0,6)
	bandit.attack.request(Vector3.FORWARD)
	await tick(1.5)
	check(player.health.current==18,"Arrow collision bypasses accuracy and preserves enemy minimum damage")
	bandit.queue_free()
	player._equipment_changed()
	player.health.revive()

	inventory.add(session.catalog.find_item("tonic"))
	player.health.current=70
	var before_items:=inventory.items.size()
	var key:=InputEventKey.new()
	key.physical_keycode=KEY_Q
	key.pressed=true
	Input.parse_input_event(key)
	await process_frame
	check(session.hud.mode=="quest" and paused and inventory.items.size()==before_items and player.potion_recovery.remaining==0,"Q opens the paused quest journal without drinking a potion")
	key.pressed=false
	Input.parse_input_event(key)
	session.hud.close_panel()
	check(session.hud.root.find_children("*","GoldAmount",true,false).all(func(control): return session.hud.panel.is_ancestor_of(control)),"HUD has no corner gold balance")

	var survey:=Exploration.new()
	survey.configure(region.map_bounds,null)
	var town:=Vector2(region.player_spawn.position.x,region.player_spawn.position.z)
	var tower:=Vector2(98,-80)
	check(not survey.is_explored(town) and not survey.is_explored(tower),"Fresh exploration contains no revealed geographic cells")
	survey.reveal(town)
	check(survey.is_explored(town) and not survey.is_explored(tower),"Exploring town does not reveal the distant objective terrain")
	var saved: Dictionary=JSON.parse_string(JSON.stringify(survey.serialize()))
	survey.reveal(tower)
	survey.restore(saved)
	check(survey.is_explored(town) and not survey.is_explored(tower),"Exploration survives JSON round-trip without leaking unsaved areas")
	survey.restore({"cells":[-1,999999,"invalid"],"bounds":saved.bounds,"cell_size":2})
	check(not survey.is_explored(town),"Malformed exploration cell indices are safely ignored")
	survey.free()
	var old_quest: Dictionary=session.quest.serialize()
	session.quest.restore({"accepted":true,"cleared":false,"rewarded":false})
	check(session.hud.large_map.objective_location().position==Vector2(98,-91.65),"Only the watchtower doorway is marked as the active destination")
	inventory.add(session.catalog.find_item("cellar_key"))
	check(session.hud.large_map.objective_location().label=="Warden Elric","Collecting the cellar key changes the objective pin to Elric")
	session.quest.claim(inventory)
	check(session.hud.large_map.objective_location().is_empty(),"Rewarded quest leaves no points of interest on map")
	session.quest.restore(old_quest)
	var catalog_valid:=true
	for cue in AudioLibrary.definitions:
		var clip:=AudioLibrary.sample(cue)
		catalog_valid=catalog_valid and clip!=null and clip.get_length()>0.05
	check(catalog_valid,"All sampled audio cues decode and contain nonempty recordings")
	AudioLibrary.last_played.erase("potion")
	player.use_consumable(&"tonic")
	var potion_stream:=AudioLibrary.sample("potion")
	check(get_nodes_in_group("interface_audio").any(func(voice): return voice.stream==potion_stream),"Successful potion use dispatches the dedicated bottle/liquid sound")
	player.potion_recovery.cancel()
	player.health.revive()
