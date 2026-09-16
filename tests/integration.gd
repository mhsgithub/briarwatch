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
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await physics_frame
	await physics_frame
	await tick(0.15)
	var player: Player = session.player
	var region: Region = session.region
	var inventory := player.inventory
	check(session.testing, "Integration tests are isolated from player saves")
	check(get_nodes_in_group("enemies").size() == 24, "All 24 authored enemies spawn")
	check(preload("res://tools/validate_region.gd").validate(region).is_empty(), "Region editing contract validates")
	check(region.navigation_region.navigation_mesh.get_polygon_count() > 0, "Native navigation mesh bakes")
	var valid_spawns := true
	for enemy in get_nodes_in_group("enemies"):
		var closest := NavigationServer3D.map_get_closest_point(region.get_world_3d().navigation_map, enemy.home)
		if closest.distance_to(enemy.home) > 1.0:
			print("Spawn outside navigation: ", enemy.spawn_id, " ", closest.distance_to(enemy.home))
			valid_spawns = false
	check(valid_spawns, "Every placed enemy spawns on reachable ground")
	var path := NavigationServer3D.map_get_path(region.get_world_3d().navigation_map, region.player_spawn.global_position, Vector3(48, 0, -35), true)
	check(path.size() >= 2 and path[path.size() - 1].distance_to(Vector3(48, 0, -35)) < 1.0, "Town and watchtower connected by a navigable path")
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
	check(edited_marker.definition.max_health == 42, "Scene editing does not overwrite type defaults")
	var second: EnemySpawn = reloaded.get_node("Encounters/watchtower/raider_2")
	second.spawn_id = edited_marker.spawn_id
	check(not preload("res://tools/validate_region.gd").validate(reloaded).is_empty(), "Editor validator detects duplicated persistent spawn IDs")
	edited.free()
	reloaded.free()
	check(inventory.bonus("damage_bonus") == 4 and inventory.bonus("armor_bonus") == 3, "Starter gear contributes live stats")
	var original_gold := inventory.gold
	check(not inventory.buy(session.catalog.find_item("mail")) and inventory.gold == original_gold, "Unaffordable purchase is atomic")
	inventory.gold = 100
	check(inventory.buy(session.catalog.find_item("forged_sword")), "Vendor purchase adds item")
	check(inventory.gold == 55, "Vendor deducts exact price")
	inventory.equip(inventory.items.size() - 1)
	check(player.attack.damage_bonus == 10 and inventory.equipment.weapon.id == &"forged_sword", "Equipping replaces gear and updates combat")
	check(inventory.items.back().id == &"old_sword", "Replaced weapon returns to pack")
	check(inventory.sell(inventory.items.size() - 1) and inventory.gold == 59, "Selling credits resale value")
	player.receive_damage(DamagePacket.new(30))
	check(player.health.current == 83, "Incoming physical damage applies equipment armor")
	player.use_potion()
	check(player.health.current == 110 and inventory.items.size() == 2, "Tonic consumes one item and clamps healing")
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
	check(captain != null and captain.health.maximum == 66 and captain.definition.max_health == 42, "Instance override preserves shared enemy defaults")
	# Real timed melee hit, not direct damage to the target.
	var victim: Enemy = get_nodes_in_group("enemies")[0]
	victim.set_physics_process(false)
	victim.global_position = player.global_position + Vector3(0, 0, -1.5)
	var before := victim.health.current
	player._try_attack(Vector3.FORWARD)
	await tick(0.35)
	check(victim.health.current < before, "Sword windup resolves a real directional melee hit")
	check(not player.attack.request(Vector3.FORWARD), "Attack cooldown prevents immediate repeat")
	await tick(0.3)
	# Facing away must not hit.
	before = victim.health.current
	player._try_attack(Vector3.BACK)
	await tick(0.3)
	check(victim.health.current == before, "Melee arc rejects targets behind attacker")
	victim.receive_damage(DamagePacket.new(1000, player))
	await physics_frame
	check(str(victim.spawn_id) in region.defeated_ids, "Enemy death is tracked by stable spawn ID")
	var drops := get_nodes_in_group("interactables").filter(func(node): return node is LootDrop)
	check(not drops.is_empty(), "Enemy death produces collectible loot")
	if not drops.is_empty():
		var drop: LootDrop = drops[0]
		var balance := inventory.gold
		var crowns := drop.gold
		check(drop.collect(inventory) and inventory.gold == balance + crowns, "Ground loot transfers reward to inventory")
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
	check(session.quest.cleared, "Clearing the authored camp completes the quest objective")
	check(session.quest.claim(inventory), "Quest pays its reward")
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
	check(restored.bonus("damage_bonus") == inventory.bonus("damage_bonus") and restored.gold == inventory.gold, "Loaded equipment and crowns match")
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
	session._service("rest", 0)
	check(get_nodes_in_group("enemies").size() == 24 and region.defeated_ids.is_empty(), "Rest repopulates the authored encounters")
	check(session.quest.rewarded, "Rest preserves completed quest reward state")
	session.hud.close_panel()
	await physics_frame
	print("INTEGRATION RESULT: %d checks, %d failures" % [checks, failures.size()])
	session.queue_free()
	await process_frame
	await tick(0.2)
	quit(0 if failures.is_empty() else 1)
