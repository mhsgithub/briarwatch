extends SceneTree
var session: Node
func _initialize() -> void: call_deferred("run")
func freeze() -> void:
	for enemy in session.region.actors.get_children():
		if enemy is Enemy:
			enemy.set_physics_process(false)
			enemy.attack.set_physics_process(false)
func shot(name: String, point: Vector3, zoom: float=27) -> void:
	session.hud.toast_time=0
	session.player.position=point
	session.get_node("Camera").size=zoom
	session.get_node("Camera").initialized=false
	await create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/"+name+".png")
func run() -> void:
	root.size=Vector2i(1440,900)
	session=load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await physics_frame
	session.player.set_physics_process(false)
	session.player.health.invulnerable=true
	session.quest.restore({"id":"unseen_hand","accepted":true,"completed":["lions_den","drowned_patrol"]})
	session.travel.enter(&"hollowmere")
	freeze()
	await shot("80-dark-mark",Vector3(-44,.1,-78),20)
	session.hud.show_npc(session.region.get_node("NPCs/elric"))
	await shot("81-investigation-dialogue",Vector3(-105,.1,94))
	session.hud.close_panel()
	await shot("82-darkmere-exterior",Vector3(-111,.1,-109),33)
	session.quest.definition=load("res://content/quests/darkmere.tres")
	session.quest.stage_index=0
	session.travel.enter(&"darkmere_halls")
	freeze()
	await shot("83-darkmere-halls",Vector3(0,.1,12),29)
	session.travel.enter(&"darkmere_sanctum")
	var boss: MalrecEncounter=session.region.get_node("MalrecEncounter")
	boss.set_physics_process(false)
	freeze()
	await shot("84-darkmere-chamber",Vector3(0,.1,1),33)
	boss.begin()
	await shot("85-malrec-opening",session.player.position,33)
	boss._physics_process(10.1)
	boss.cast_dark_patch()
	await shot("90-malrec-dark-patch",Vector3(2,.1,-4),26)
	boss.spawn_meteor(Vector3(-4,0,3))
	boss.spawn_meteor(Vector3(3,0,-4))
	boss.spawn_meteor(Vector3(6,0,3))
	await shot("86-malrec-meteors",Vector3(0,.1,1),33)
	boss.start_ritual()
	freeze()
	await shot("87-malrec-cultists",Vector3(0,.1,5),35)
	for cultist in boss.cultists: cultist.receive_damage(DamagePacket.new(999,session.player))
	boss._physics_process(.01)
	await create_timer(1.0).timeout
	boss.start_bolt()
	boss.fire_bolt()
	for child in session.region.actors.get_children():
		if child is ElementalBolt:
			child.set_physics_process(false)
			child._physics_process(.15)
	await shot("89-malrec-twin-bolts",Vector3(0,.1,7),33)
	session.player.inventory.add(session.catalog.find_item("black_reliquary"))
	session.player.inventory.add(session.catalog.find_item("soldiers_pauldrons"))
	session.hud.show_inventory()
	await shot("88-hollowmere-rewards",session.player.position)
	session.hud.close_panel()
	session.queue_free()
	await process_frame
	quit()
