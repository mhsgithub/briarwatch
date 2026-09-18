extends SceneTree
## Deterministic rendered checks; no desktop automation or personal save access.
var session: Node

func _initialize() -> void:
	call_deferred("run")

func capture(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + file + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://test-results")
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	Input.warp_mouse(Vector2(10,10))
	await create_timer(1).timeout
	await capture("01-town")
	session.hud.toast_time=0
	session.hud.show_inventory()
	await create_timer(0.3).timeout
	await capture("02-inventory")
	session.hud.close_panel()
	session._interact(session.region.get_node("NPCs/mara"))
	await capture("03-vendor")
	session.hud.close_panel()
	session.player.global_position = Vector3(92, 0.1, -73)
	session.player.health.invulnerable = true
	session.player.recovery_time = 20
	await create_timer(1.5).timeout
	await capture("04-watchtower")
	session.player.recovery_time = 0
	session.player.health.invulnerable = false
	session.player.receive_damage(DamagePacket.new(10000))
	await capture("05-recovery")
	session.hud.close_panel()
	session.player.respawn(session.region.player_spawn.global_position)
	session.hud.show_map()
	await capture("06-map")
	session.hud.close_panel()
	session.hud.show_pause()
	await capture("07-menu")
	session.hud.close_panel()
	session._interact(session.region.get_node("NPCs/iona"))
	await capture("08-healer")
	session.hud.close_panel()
	session._interact(session.region.get_node("NPCs/elric"))
	await capture("09-quest")
	session.hud.close_panel()
	# Inspect a real item in the redesigned details panel.
	session.player.inventory.add(session.catalog.find_item("guardian_amulet"))
	session.hud.show_inventory()
	await process_frame
	var equipment: EquipmentPanel=session.hud.panel.find_children("*","EquipmentPanel",true,false)[0]
	equipment._inspect(session.catalog.find_item("guardian_amulet"),1,"")
	await capture("10-item-details")
	session.hud.close_panel()
	# Equipment-driven silhouette, two-handed occupancy, action binding and fire.
	session.player.inventory.restore({"items":["tonic","pitchfork","guardian_amulet"],"equipment":{"body":"mail","head":"watchkeeper_helmet","gloves":"outrider_gloves","belt":"outrider_belt","boots":"outrider_boots","weapon":"warden_blade","shield":"iron_shield"}},session.catalog)
	session.player.inventory.equip(2)
	session.player.actions.assign_item(0,session.catalog.find_item("tonic"))
	session.hud.show_inventory()
	await create_timer(0.3).timeout
	await capture("11-equipped-centurion")
	session.hud.close_panel()
	session.player.inventory.equip(1)
	session.hud.show_inventory()
	await create_timer(0.3).timeout
	equipment=session.hud.panel.find_children("*","EquipmentPanel",true,false)[0]
	equipment._inspect(session.catalog.find_item("pitchfork"),-1,"weapon")
	await capture("12-two-handed")
	session.hud.close_panel()
	session.player.inventory.restore({"items":[],"equipment":{}},session.catalog)
	session.hud.show_inventory()
	await create_timer(0.3).timeout
	await capture("13-unequipped")
	session.hud.close_panel()
	session.player.global_position=Vector3(-26,0.1,31)
	await create_timer(0.8).timeout
	await capture("14-fire")
	var house: Node3D=session.region.get_node("NavigationRegion/Scenery/house_3")
	session.player.global_position=house.global_position+Vector3(0,0.1,2.9)
	await create_timer(0.6).timeout
	await capture("15-proximity")
	session.player.inventory.add(session.catalog.find_item("greater_tonic"))
	session.hud.show_action_picker(1)
	await capture("16-action-picker")
	session.hud.close_panel()
	session.quest.restore({"accepted":true,"cleared":false,"rewarded":false})
	session.hud.show_quest()
	await capture("17-quest-journal")
	session.hud.close_panel()
	# Show the initial survey and an objective in still-unexplored land.
	session.exploration.restore({})
	session.exploration.reveal(Vector2(-35,35))
	session.hud.show_map()
	await capture("18-fog-of-war")
	session.hud.close_panel()
	# Revealing a travelled road persists while the map window is closed.
	for i in range(36):
		session.exploration.reveal(Vector2(-35,35).lerp(Vector2(20,-20),float(i)/35))
	session.hud.show_map()
	await capture("19-explored-road")
	session.hud.close_panel()
	session.travel.enter(&"watchtower")
	session.player.inventory.restore({"items":["tonic"],"equipment":{"body":"coat","weapon":"old_sword","shield":"oak_shield"}},session.catalog)
	session.player.health.revive()
	session.player.recovery_time=100
	session.player.input_enabled=false
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		enemy.attack.cancel()
	session.player.position=Vector3(0,0.1,4)
	session.get_node("Camera").size=29
	await create_timer(0.7).timeout
	await capture("20-tower-interior")
	var boss: Enemy
	for enemy in get_nodes_in_group("enemies"):
		if enemy.definition.commander: boss=enemy
	session.player.position=Vector3(0,0.1,-0.4)
	session.player.attack_target=boss
	session.get_node("Camera").size=19
	await create_timer(0.6).timeout
	boss.commander.start("cleave",Vector3.BACK)
	await create_timer(0.45).timeout
	await capture("21-heavy-cleave")
	boss.commander.cancel()
	session.player.inventory.add(session.catalog.find_item("cellar_key"))
	session.player.inventory.add(session.catalog.find_item("outlaw_mantle"))
	session.player.inventory.equip(session.player.inventory.items.size()-1)
	session.hud.show_inventory()
	await create_timer(0.3).timeout
	await capture("22-mantle-and-key")
	session.queue_free()
	await process_frame
	quit()
