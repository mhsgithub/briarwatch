extends SceneTree
var session: Node
func _initialize() -> void: call_deferred("run")
func freeze() -> void:
	for enemy in session.region.actors.get_children():
		if enemy is Enemy:
			enemy.set_physics_process(false)
			enemy.attack.set_physics_process(false)
			if enemy.risen_combat: enemy.risen_combat.set_physics_process(false)
func shot(name: String, point: Vector3, zoom: float=26) -> void:
	session.hud.toast_time=0
	session.player.position=point
	session.get_node("Camera").size=zoom
	session.get_node("Camera").initialized=false
	await create_timer(.35).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/"+name+".png")
func run() -> void:
	root.size=Vector2i(1440,900)
	session=load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await physics_frame
	session.player.set_physics_process(false)
	session.player.health.invulnerable=true
	session.quest.restore({"id":"drowned_patrol","accepted":true,"completed":["lions_den","warwick_rescue"],"stage":"find_patrol"})
	session.travel.enter(&"hollowmere")
	freeze()
	await shot("70-patrol",Vector3(-100,.1,27),22)
	session.hud.show_npc(session.companion)
	await shot("71-corvin-dialogue",session.player.position)
	session._service("patrol_report",0)
	session.travel.enter(&"chapel_crypts")
	freeze()
	var ritual: CryptRitual=session.region.get_node("CryptRitual")
	ritual.set_physics_process(false)
	await shot("72-crypt-corridor",Vector3(0,.1,12),28)
	await shot("73-malrec-ritual",Vector3(0,.1,-43),27)
	ritual.begin()
	ritual.phase=2
	ritual._phase_started()
	await shot("74-malrec-dialogue",Vector3(0,.1,-37),29)
	ritual.finish()
	await process_frame
	var boss: Enemy=ritual.soldier
	boss.position=Vector3(0,.1,-40)
	boss.risen_combat._physics_process(.7)
	for x in [-4,-2,2,4]: boss.risen_combat.field.spread(Vector3(x,0,-39))
	boss.commander.start("cleave",Vector3.BACK)
	boss.commander.special.set_physics_process(false)
	await shot("75-risen-soldier",Vector3(0,.1,-37),22)
	session.player.inventory.add(session.catalog.find_item("captains_breastplate"))
	session.hud.show_inventory()
	await shot("76-captains-breastplate",session.player.position)
	session.hud.close_panel()
	session.queue_free()
	await process_frame
	quit()
