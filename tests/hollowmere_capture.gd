extends SceneTree
var session: Node
func _initialize() -> void: call_deferred("run")
func shot(file: String, point: Vector3, zoom: float = 26) -> void:
	session.player.position = point
	session.get_node("Camera").size = zoom
	session.get_node("Camera").initialized = false
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/"+file+".png")
func run() -> void:
	root.size = Vector2i(1440,900)
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	Input.warp_mouse(Vector2(12,12))
	await create_timer(0.2).timeout
	session.quest.completed.assign(["warwick_rescue","lions_den"])
	session.quest.definition = load("res://content/quests/lions_den.tres")
	session.quest.rewarded = true
	session.quest.changed.emit()
	session.hud.show_npc(session.region.get_node("NPCs/elric"))
	await shot("50-hollowmere-travel",session.player.position)
	session.hud.close_panel()
	session.travel.enter(&"hollowmere")
	session.hud.toast_time = 0
	session.player.recovery_time = 9999
	session.player.set_physics_process(false)
	for enemy in session.region.actors.get_children():
		if enemy is Enemy:
			enemy.set_physics_process(false)
			enemy.attack.set_physics_process(false)
	await shot("51-lanternwatch-camp",Vector3(-105,0.1,94),34)
	await shot("52-marsh-bridge",Vector3(-60,0.2,43),30)
	await shot("53-sunken-chapel",Vector3(40,0.1,42),31)
	await shot("54-widows-weald",Vector3(-104,0.1,-34),25)
	await shot("55-pilgrim-graves",Vector3(-44,0.1,-82),30)
	var crocodile: Enemy = session.region.actors.get_child(0)
	crocodile.position = Vector3(-59,0.2,29)
	crocodile._face(Vector3(0,0,1))
	await shot("56-crocodile",Vector3(-58,0.2,32),16)
	session.player.inventory.equipment.weapon = session.catalog.find_item("bogiron_greatblade")
	session.player.inventory.equipment.shield = null
	session.player.inventory.equipment.body = session.catalog.find_item("gloomhide_vest")
	session.player.inventory.equipment.head = session.catalog.find_item("marshguard_crown")
	session.player.inventory.equipment.boots = session.catalog.find_item("marshrunner_boots")
	for item in session.catalog.items:
		if str(item.id) in ["marshscale_tunic","bogwalker_boots","rotcap_cowl","swampgrip_mitts","mud_stained_sash","bogwood_shield","marsh_cleaver","gloomhide_vest","marshrunner_boots","marshguard_crown","marshwarden_sash","fenwarden_charm","marshwarden_band","bogiron_greatblade"]: session.player.inventory.add(item)
	session.player.inventory.changed.emit()
	session.hud.show_inventory()
	await shot("57-marsh-equipment",session.player.position)
	session.hud.close_panel()
	session.hud.show_npc(session.region.get_node("NPCs/tamsin"))
	await shot("58-talent-reset",Vector3(-104,0.1,94))
	session.hud.close_panel()
	# Survey capture reveals only for the isolated test session.
	for x in range(-140,141,10):
		for z in range(-120,121,10): session.exploration.reveal(Vector2(x,z))
	session.hud.show_map()
	await shot("59-hollowmere-map",Vector3(-104,0.1,94))
	session.hud.close_panel()
	session.hud.show_npc(session.region.get_node("NPCs/rowan"))
	await shot("60-rowan-stock",Vector3(-112,0.1,94))
	session.hud.close_panel()
	session.player.inventory.equipment.weapon = session.catalog.find_item("wyrmfang")
	session.player.inventory.equipment.shoulders = session.catalog.find_item("wyrmsteel_shoulders")
	session.player.inventory.equipment.gloves = session.catalog.find_item("wyrmhide_grips")
	session.player.inventory.equipment.ring_left = session.catalog.find_item("emerald_band")
	session.player.inventory.changed.emit()
	session.hud.show_inventory()
	await shot("61-wyrmfang-equipment",Vector3(-104,0.1,94))
	session.hud.close_panel()
	session.queue_free()
	await process_frame
	quit()
