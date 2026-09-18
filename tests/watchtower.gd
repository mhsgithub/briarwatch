extends SceneTree
## Isolated second-region, boss, quest and minor-feedback regression tests.
var checks := 0
var failures: Array[String] = []
var session: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition: print("PASS: ", message)
	else:
		failures.append(message)
		push_error("FAIL: " + message)

func tick(seconds: float) -> void:
	await create_timer(seconds).timeout

func run() -> void:
	root.size = Vector2i(1440, 900)
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await physics_frame
	await physics_frame
	var player: Player = session.player
	var state := player.combat_state
	var inventory := player.inventory
	player.set_physics_process(false)
	state.set_physics_process(false)
	player.health.current = 80
	state._physics_process(1.99)
	check(player.health.current == 80, "Resting recovery waits two full seconds")
	state._physics_process(0.02)
	check(player.health.current == 81, "Resting recovery restores exactly one vitality")
	state.engage()
	state._physics_process(2)
	check(player.health.current == 81, "Recent combat prevents passive healing")
	var pursuer: Enemy = get_nodes_in_group("enemies")[0]
	pursuer.aggro = true
	state.combat_left = 0
	state._physics_process(3)
	check(player.health.current == 81, "A chasing enemy blocks resting recovery even without recent damage")
	pursuer.returning = true
	state._physics_process(2)
	check(player.health.current == 82, "Leashed enemies returning home no longer block recovery")
	pursuer.aggro = false
	pursuer.returning = false
	player.health.current = 99.7
	state._physics_process(2)
	check(player.health.current == 100, "Passive healing never exceeds maximum vitality")
	state.regeneration_enabled = false
	state.set_physics_process(true)
	var foot_audio: GameAudio = player.get_node("Audio")
	foot_audio.step_distance = 0
	for i in range(8):
		player.position.x += 0.3
		foot_audio._physics_process(0.06)
	check(foot_audio.step_distance == 0, "Player movement never accumulates or plays footsteps")
	player.position = Vector3(-35, 0.1, 46)
	player.health.invulnerable = true
	var bowman: Enemy = load("res://scenes/entities/enemy.tscn").instantiate()
	bowman.definition = load("res://content/enemies/archer.tres")
	bowman.position = player.position + Vector3(0, 0, 3)
	session.region.actors.add_child(bowman)
	bowman.aggro = true
	var start := bowman.position
	await tick(0.8)
	var after_retreat := bowman.position
	check(after_retreat.distance_to(start) > 0.5 and after_retreat.distance_to(start) < 2.4, "Bowman retreats only a short distance")
	await tick(0.7)
	check(Vector2(bowman.position.x, bowman.position.z).distance_to(Vector2(after_retreat.x, after_retreat.z)) < 0.15 and bowman.stand_left > 0, "Bowman stands and shoots after the short retreat")
	bowman.queue_free()
	player.health.invulnerable = false
	session.quest.accept()
	session.quest.encounter_cleared(&"watchtower")
	check(not session.quest.cleared, "Exterior camp clearance cannot finish the key quest")
	var town_survey: Dictionary = session.exploration.serialize()
	var door: RegionPortal = session.region.get_node("Portals/Tower")
	var door_path := NavigationServer3D.map_get_path(session.region.get_world_3d().navigation_map, Vector3(98, 0, -80), door.global_position + Vector3(0, 0, -1), true)
	check(door_path.size() >= 2 and door_path[-1].distance_to(door.global_position + Vector3(0, 0, -1)) < 1, "Tower entrance is reachable around the preserved exterior")
	session._interact(door)
	await process_frame
	await physics_frame
	check(session.region.region_id == &"watchtower" and get_nodes_in_group("enemies").size() == 3, "Door interaction loads only Darius and two bowmen; outdoor AI is unloaded")
	check(session.region.navigation_region.navigation_mesh.get_polygon_count() > 0, "Watchtower interior bakes navigable ground")
	var boss: Enemy
	var archers := 0
	var navigable := true
	for enemy in get_nodes_in_group("enemies"):
		var nearest := NavigationServer3D.map_get_closest_point(session.region.get_world_3d().navigation_map, enemy.home)
		navigable = navigable and nearest.distance_to(enemy.home) < 1
		enemy.set_physics_process(false)
		enemy.attack.cancel()
		if enemy.definition.commander: boss = enemy
		else:
			archers += 1
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
	check(navigable and archers == 2, "Both existing-type bowmen and Darius have reachable authored positions")
	await verify_interior_movement(player, boss)
	check(boss.health.maximum == 125 and boss.attack.definition.damage == 15 and boss.attack.definition.cooldown == 2.0 and boss.visual.scale.x > 1, "Darius has 125 vitality, a larger silhouette and slow 15-damage axe swings")
	check(is_equal_approx(boss.definition.move_speed, 2.4) and boss.definition.move_speed < load("res://content/enemies/archer.tres").move_speed and boss.definition.move_speed < load("res://content/enemies/raider.tres").move_speed, "Darius moves slower than bowmen and raiders at 2.4 metres per second")
	check(session.hud.large_map.objective_location().label == "Quest objective", "Interior map points to Darius, not outdoor coordinates")
	boss.position = Vector3(0, 0.1, -2)
	player.position = Vector3(0, 0.1, 0)
	player.health.armor = 5
	player.health.revive()
	boss.attack.request(Vector3.BACK)
	await tick(0.9)
	check(player.health.current == 90, "Darius basic axe hit deals 15 minus armor")
	player.health.revive()
	boss.commander.start("cleave", Vector3.BACK)
	check(is_instance_valid(boss.commander.warning) and boss.visual.special_left > 0 and not boss.find_children("*", "Label3D", true, false).any(func(label): return label.text in ["HEAVY CLEAVE", "KICK"]), "Heavy Cleave uses its warning animation without ability-name text")
	await tick(0.85)
	check(player.health.current == 100 and boss.commander.special.pending, "Heavy Cleave cannot hit before its one-second cast finishes")
	await tick(0.22)
	check(player.health.current == 85 and state.bleed_left == 5, "Heavy Cleave deals 20 minus armor and applies five bleed ticks")
	player.health.armor = 1000
	await tick(5.1)
	check(player.health.current == 70 and state.bleed_left == 0, "Bleed deals exactly 3 per second for five seconds, ignoring armor")
	player.health.revive()
	player.health.armor = 5
	boss.commander.start("cleave", Vector3.BACK)
	await tick(0.45)
	player.position = boss.position + Vector3(0, 0, -2)
	await tick(0.65)
	check(player.health.current == 100 and state.bleed_left == 0, "Moving behind the locked cleave avoids both hit and bleed")
	player.position = boss.position + Vector3(0, 0, 2)
	boss.commander.start("cleave", Vector3.BACK)
	player.position = boss.position + Vector3(0, 0, 5)
	await tick(1.1)
	check(player.health.current == 100 and state.bleed_left == 0, "Moving beyond the cleave's reach avoids both damage and bleed")
	player.position = boss.position + Vector3(0, 0, 2)
	var blocker := Node3D.new()
	session.region.add_child(blocker)
	Geometry.collider(blocker, boss.position + Vector3(0, 1, 1), Vector3(3, 2, 0.2))
	await physics_frame
	await physics_frame
	boss.commander.start("cleave", Vector3.BACK)
	await tick(1.1)
	check(player.health.current == 100 and state.bleed_left == 0, "Heavy Cleave cannot hit through solid scenery")
	blocker.queue_free()
	await physics_frame
	player.health.armor = 1000
	boss.commander.start("cleave", Vector3.BACK)
	await tick(1.1)
	check(player.health.current == 99 and state.bleed_left == 5, "A connecting cleave retains the one-damage armor floor and its bleed")
	state.reset()
	player.health.armor = 5
	player.health.revive()
	player.position = boss.position + Vector3(0, 0, 2)
	boss.commander.start("kick", Vector3.BACK)
	await tick(0.4)
	check(player.health.current == 100 and state.knockdown_left > 0 and not player.attack.pending, "Kick deals zero damage and briefly knocks the player down")
	var position_before := player.position
	player.set_physics_process(true)
	var move_key := InputEventKey.new()
	move_key.physical_keycode = KEY_W
	move_key.pressed = true
	Input.parse_input_event(move_key)
	await tick(0.2)
	check(player.position.distance_to(position_before) < 0.01, "Knockdown prevents movement through the real player input loop")
	move_key.pressed = false
	Input.parse_input_event(move_key)
	player.set_physics_process(false)
	paused = true
	var knockdown_before := state.knockdown_left
	await tick(0.3)
	check(state.knockdown_left == knockdown_before, "Combat status timers pause with menus")
	paused = false
	await tick(0.75)
	check(state.knockdown_left == 0 and player.visual.rotation.z == 0, "Player stands back up after the short knockdown")
	await verify_live_fight(boss, player)
	var valid_cooldowns := true
	boss.aggro = true
	for i in range(20):
		boss.commander.cancel()
		boss.commander.cleave_left = 0
		boss.commander.kick_left = 100
		boss.commander.step(0)
		valid_cooldowns = valid_cooldowns and boss.commander.cleave_left >= 7 and boss.commander.cleave_left <= 10
	check(valid_cooldowns, "Heavy Cleave cooldown samples only the requested 7–10 seconds")
	boss.receive_damage(DamagePacket.new(10000, player))
	check(not boss.commander.special.pending, "Killing Darius cancels an in-progress special attack")
	check(not session.quest.cleared, "Defeating Darius alone does not substitute for collecting his key")
	var drops := get_nodes_in_group("interactables").filter(func(node): return node is LootDrop)
	check(drops.size() == 2, "Darius drops exactly the guaranteed cellar key and Outlaw's Mantle")
	while inventory.items.size() < Inventory.CAPACITY: inventory.add(session.catalog.find_item("tonic"))
	for drop in drops:
		if drop.item.id == &"cellar_key": session._interact(drop)
	check(session.quest.cleared and inventory.quest_items.has("cellar_key") and inventory.items.size() == Inventory.CAPACITY, "Full packs cannot block key collection; quest pouch completes the objective")
	check(session.hud.large_map.objective_location().label == "Return to Elric", "After key pickup, interior map points to the exit")
	await process_frame
	var snapshots: Dictionary = JSON.parse_string(JSON.stringify(session.travel.snapshot()))
	check(snapshots.watchtower.defeated.has("tower_darius") and snapshots.watchtower.loot.size() == 1, "Region snapshot preserves the boss defeat and uncollected mantle without duplicating the key")
	var save_data := {"inventory": inventory.serialize(), "quest": session.quest.serialize(), "regions": snapshots, "actions": player.actions.serialize()}
	var save_path := "user://watchtower_integration.json"
	check(SaveStore.write(save_data, save_path) == OK, "Tower progress writes through the real save-file format")
	var restored := SaveStore.read(save_path)
	var restored_bag := Inventory.new()
	restored_bag.restore(restored.inventory, session.catalog)
	var restored_quest := QuestLog.new()
	restored_quest.definition = session.quest.definition
	restored_quest.bind(restored_bag)
	restored_quest.restore(restored.quest)
	check(restored_bag.quest_items.has("cellar_key") and restored_quest.cleared and not restored_quest.rewarded and restored.regions.watchtower.defeated.has("tower_darius"), "Disk round-trip preserves key possession, pending hand-in and Darius's defeat")
	restored_quest.free()
	restored_bag.free()
	session.travel.enter(&"briar_march", &"tower")
	check(session.region.region_id == &"briar_march" and player.position.distance_to(Vector3(98, 0.1, -94.7)) < 0.1, "Leaving returns to the exterior doorway arrival")
	check(session.exploration.visited.count(1) >= town_survey.cells.size(), "Outdoor exploration survives the interior transition")
	check(session.hud.large_map.objective_location().label == "Warden Elric", "With the key, outdoor map points to Elric")
	session.travel.states = snapshots
	session.travel.enter(&"watchtower")
	await process_frame
	check(get_nodes_in_group("enemies").size() == 2, "Re-entering after a JSON round-trip does not respawn Darius")
	var mantle: LootDrop
	for node in get_nodes_in_group("interactables"):
		if node is LootDrop and node.item.id == &"outlaw_mantle": mantle = node
	check(is_instance_valid(mantle), "Uncollected mantle persists across region travel")
	inventory.items.remove_at(0)
	if mantle: session._interact(mantle)
	check(inventory.equip(inventory.items.size() - 1) and inventory.equipment.shoulders.id == &"outlaw_mantle" and inventory.equipment.shoulders.armor_bonus == 2, "White Outlaw's Mantle equips in shoulders with two armor")
	player.recovery_time = 0
	player.health.invulnerable = false
	player.receive_damage(DamagePacket.new(10000))
	session.hud.close_panel()
	session._respawn()
	check(not player.dead and session.region.region_id == &"briar_march" and player.position.distance_to(session.region.player_spawn.position) < 0.1, "Death in the tower returns the player safely to Briarwatch")
	var gold_before := inventory.gold
	check(session.quest.claim(inventory) and inventory.gold == gold_before + 50 and inventory.quest_items.is_empty(), "Elric consumes the key and pays exactly 50 gold")
	check(not session.quest.claim(inventory), "New quest reward is one-time only")
	session.hud.show_quest()
	var journal_titles: Array[Node] = session.hud.panel_body.find_children("*", "Label", true, false)
	check(not journal_titles.any(func(label): return label.text == session.quest.definition.title), "Quest journal hides completed quests")
	session.hud.close_panel()
	session.quest.restore({"accepted": true, "cleared": true, "rewarded": true})
	check(session.quest.accepted and not session.quest.rewarded and not session.quest.cleared, "Legacy camp-clear saves receive the new key objective without resetting the character")
	print("WATCHTOWER RESULT: %d checks, %d failures" % [checks, failures.size()])
	session.queue_free()
	await process_frame
	await tick(0.2)
	quit(0 if failures.is_empty() else 1)

func verify_live_fight(boss: Enemy, player: Player) -> void:
	# Exercise AI scheduling and navigation, not just direct ability requests.
	var casts: Array[String] = []
	var cleave_times: Array[int] = []
	var basic_swings: Array[int] = []
	var on_special := func(_direction: Vector3, _duration: float):
		casts.append(str(boss.commander.special.definition.id))
		if boss.commander.kind == "cleave": cleave_times.append(Time.get_ticks_msec())
	var on_basic := func(_direction: Vector3, _duration: float): basic_swings.append(Time.get_ticks_msec())
	boss.commander.special.started.connect(on_special)
	boss.attack.started.connect(on_basic)
	boss.commander.cancel()
	boss.commander.cleave_left = 3
	boss.commander.kick_left = 6
	boss.attack.cancel()
	boss.position = Vector3(0, 0.1, -3)
	player.position = Vector3(0, 0.1, 4)
	player.health.invulnerable = true
	boss.aggro = true
	boss.set_physics_process(true)
	var initial_distance := boss.position.distance_to(player.position)
	await tick(1.2)
	if boss.position.distance_to(player.position) >= initial_distance - 1.5:
		print("DARIUS PATH DIAGNOSTIC: boss=", boss.position, " player=", player.position, " velocity=", boss.velocity, " aggro=", boss.aggro, " returning=", boss.returning, " path=", boss.navigation.get_current_navigation_path())
	check(boss.position.distance_to(player.position) < initial_distance - 1.5, "Live Darius navigates toward the player at his slower speed")
	player.position = boss.position + Vector3(0, 0, 1.6)
	var overlap := false
	var locked_aim := true
	for i in range(140):
		await tick(0.1)
		overlap = overlap or (boss.attack.pending and boss.commander.special.pending)
		if boss.commander.special.pending:
			var expected_yaw := atan2(-boss.commander.special.direction.x, -boss.commander.special.direction.z)
			locked_aim = locked_aim and absf(angle_difference(boss.visual.rotation.y, expected_yaw)) < 0.01
	check(not basic_swings.is_empty() and casts.has("heavy_cleave") and casts.has("commander_kick"), "Live AI performs basic axe swings, Heavy Cleave and Kick in one encounter")
	check(not overlap and locked_aim, "Specials never overlap basic windups and retain their committed facing")
	var spaced := cleave_times.size() >= 2
	for i in range(1, cleave_times.size()): spaced = spaced and cleave_times[i] - cleave_times[i - 1] >= 6950
	check(spaced, "Live repeated cleaves honor their cooldown rather than firing consecutively")
	var boss_health := boss.health.current
	player.attack.cancel()
	player._try_attack(boss.position - player.position)
	await tick(0.3)
	check(boss.health.current < boss_health, "Player's real melee attack can damage the live commander")
	boss.set_physics_process(false)
	boss.attack.cancel()
	boss.commander.cancel()
	boss.commander.special.started.disconnect(on_special)
	boss.attack.started.disconnect(on_basic)
	player.health.invulnerable = false
	player.health.revive()
	player.position = boss.position + Vector3(0, 0, 2)

func verify_interior_movement(player: Player, boss: Enemy) -> void:
	var start := player.position
	player.set_physics_process(true)
	player.navigation.target_position = Vector3(0, 0, 4)
	player.click_moving = true
	player.recovery_time = 100
	await tick(0.8)
	check(start.distance_to(player.position) > 2.5, "Player click-to-move advances across the interior's baked navigation")
	player.click_moving = false
	player.set_physics_process(false)
	for guard in get_nodes_in_group("enemies"):
		if guard == boss: continue
		player.position = guard.position + Vector3(0, 0, 3)
		var guard_start: Vector3 = guard.position
		guard.process_mode = Node.PROCESS_MODE_INHERIT
		guard.set_physics_process(true)
		guard.aggro = true
		await tick(0.8)
		check(guard.position.distance_to(guard_start) > 0.5, str(guard.spawn_id) + " can retreat through actual interior physics")
		guard.set_physics_process(false)
		guard.attack.cancel()
		guard.process_mode = Node.PROCESS_MODE_DISABLED
		guard.position = guard_start
	player.recovery_time = 0
	player.health.invulnerable = false
