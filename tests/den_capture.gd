extends SceneTree
var session: Node
func _initialize() -> void: call_deferred("run")
func capture(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/"+file+".png")
func freeze() -> void:
	for actor in session.region.actors.get_children():
		if actor is Enemy:
			actor.set_physics_process(false)
			actor.attack.cancel()
func run() -> void:
	root.size=Vector2i(1440,900)
	session=load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	Input.warp_mouse(Vector2(12,12))
	await create_timer(0.3).timeout
	freeze()
	var p: Player=session.player
	p.recovery_time=10000
	p.position=Vector3(-104,0.1,-81)
	session.get_node("Camera").size=24
	session.get_node("Camera").initialized=false
	session.hud.toast_time=0
	await create_timer(0.5).timeout
	await capture("35-dark-woods-entrance")
	session.quest.accept()
	p.inventory.add(session.catalog.find_item("cellar_key"))
	session.quest.claim(p.inventory)
	session.quest.accept()
	session.quest.encounter_cleared(&"brutus")
	session.quest.flags["kasparov_cell_open"]=true
	session.quest.claim(p.inventory)
	session._finish_rescue()
	await create_timer(0.3).timeout
	session.hud.toast_time=0
	session.hud.show_npc(session.region.get_node("NPCs/kasparov"))
	await capture("36-lions-den-offer")
	session._service("accept",0)
	session.hud.close_panel()
	session.travel.enter(&"dark_woods")
	session.hud.toast_time=0
	freeze()
	p.position=Vector3(0,0.1,53)
	session.get_node("Camera").size=26
	session.get_node("Camera").initialized=false
	await create_timer(0.6).timeout
	await capture("37-dark-woods-maze")
	var cache: TreasureChest=session.region.get_node("Cache")
	p.position=cache.position+Vector3(0,0.1,3)
	session.get_node("Camera").size=19
	session.get_node("Camera").initialized=false
	await create_timer(0.5).timeout
	await capture("38-woods-cache")
	cache.open()
	await capture("46-chest-floor-loot")
	p.position=Vector3(0,0.1,-39)
	session.get_node("Camera").size=38
	session.get_node("Camera").initialized=false
	await create_timer(0.6).timeout
	await capture("39-lions-den-clearing")
	var den: DenEncounter=session.region.get_node("DenEncounter")
	den.garrick.position=Vector3(-3,0.1,-45)
	den.garrick._face(p.position-den.garrick.position)
	p.position=Vector3(0,0.1,-43)
	p.attack_target=den.garrick
	session.get_node("Camera").size=19
	session.get_node("Camera").initialized=false
	den.garrick.aggro=true
	await create_timer(0.1).timeout
	await capture("47-garrick-dialogue")
	den.garrick.den_combat._start_fire()
	await create_timer(0.5).timeout
	den.garrick.den_combat._resolve_warning()
	await create_timer(0.2).timeout
	await capture("48-thrown-torch")
	await create_timer(0.35).timeout
	await capture("40-garrick-fire")
	p.position=den.garrick.den_combat.fire_point+Vector3.UP*0.1
	p.recovery_time=0
	await create_timer(0.55).timeout
	await capture("49-player-burning")
	p.recovery_time=10000
	p.position=Vector3(0,0.1,-43)
	den.release()
	den.bloodfang.position=Vector3(1.8,0.1,-45.5)
	den.bloodfang._face(p.position-den.bloodfang.position)
	den.garrick.position=Vector3(-6,0.1,-49)
	p.attack_target=den.bloodfang
	den.bloodfang.visual.raging=true
	await create_timer(0.5).timeout
	await capture("41-bloodfang")
	den.bloodfang.visual.raging=false
	den.bloodfang.visual.feeding=true
	await create_timer(0.2).timeout
	await capture("42-bloodfang-feeding")
	p.inventory.equipment.weapon=session.catalog.find_item("bloodclaw")
	p.inventory.equipment.belt=session.catalog.find_item("blackroad_belt")
	p.inventory.changed.emit()
	session.hud.show_inventory()
	await create_timer(0.2).timeout
	await capture("43-bloodclaw-equipment")
	session.hud.close_panel()
	session.travel.enter(&"briar_march")
	freeze()
	session.quest.encounter_cleared(&"bloodfang")
	await create_timer(0.5).timeout
	session.hud.show_npc(session.region.get_node("NPCs/kasparov"))
	await capture("44-lions-den-return")
	session._service("claim",0)
	await capture("45-lions-den-complete")
	session.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()
