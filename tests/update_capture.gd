extends SceneTree
var session: Node
func _initialize() -> void: call_deferred("run")
func capture(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/"+file+".png")
func freeze() -> void:
	for enemy: Enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		enemy.attack.cancel()
		if enemy.commander: enemy.commander.cancel()
func run() -> void:
	root.size=Vector2i(1440,900)
	session=load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	Input.warp_mouse(Vector2(10,10))
	await create_timer(0.5).timeout
	freeze()
	var p: Player=session.player
	p.recovery_time=1000
	p.progression.restore({"level":20,"ranks":{"block":3,"whirlwind":1,"impale":1,"bloodthirst":3,"retaliate":2,"rampage":1,"bladestorm":1,"momentum":3,"leap":1,"unshackled":1,"elemental_resolve":1}})
	p.actions.assign_ability(0,"whirlwind")
	p.actions.assign_ability(1,"impale")
	p.actions.assign_ability(2,"rampage")
	p.actions.assign_ability(3,"leap")
	p.actions.assign_item(5,session.catalog.find_item("tonic"))
	session.hud.toast_time=0
	session.hud.show_talents()
	await create_timer(0.2).timeout
	await capture("23-battle-mastery")
	var tree: TalentPanel=session.hud.panel.find_children("*","TalentPanel",true,false)[0]
	tree.selected_id="bladestorm"
	tree.rebuild()
	await process_frame
	await capture("23b-bladestorm-details")
	tree.tree_name="Pathfinder"
	tree.selected_id="elemental_resolve"
	tree.rebuild()
	await process_frame
	await capture("24-pathfinder")
	session.hud.close_panel()
	p.position=Vector3(74,0.1,80)
	session.get_node("Camera").size=27
	session.get_node("Camera").initialized=false
	await create_timer(0.6).timeout
	freeze()
	await capture("25-warwick-ruins")
	session.quest.accept()
	p.inventory.add(session.catalog.find_item("cellar_key"))
	session.quest.claim(p.inventory)
	session.hud.show_npc(session.region.get_node("NPCs/elric"))
	await capture("26-rescue-offer")
	session.hud.close_panel()
	session.quest.accept()
	session.hud.show_map()
	await capture("27-warwick-map")
	session.hud.close_panel()
	session.travel.enter(&"warwick_cellars")
	await physics_frame
	freeze()
	p.position=Vector3(0,0.1,1)
	p.input_enabled=false
	session.get_node("Camera").size=29
	await create_timer(0.6).timeout
	await capture("28-warwick-cellars")
	var boss: Enemy=get_nodes_in_group("enemies")[0]
	p.position=Vector3(0,0.1,-0.2)
	boss._face(p.position-boss.position)
	p.attack_target=boss
	session.get_node("Camera").size=17
	boss.receive_damage(DamagePacket.new(60,p))
	await create_timer(0.3).timeout
	await capture("29-brutus-rage")
	boss.brute.cancel()
	boss.health.receive(DamagePacket.new(1000,p))
	session._interact(session.region.get_node("PrisonGate"))
	p.position=Vector3(0,0.1,-10)
	session.get_node("Camera").size=16
	await create_timer(0.7).timeout
	await capture("30-kasparov-cell")
	session._interact(session.region.get_node("NPCs/kasparov"))
	await capture("31-kasparov-dialogue")
	session._service("rescue",0)
	await process_frame
	await create_timer(0.5).timeout
	session.get_node("Camera").size=22
	p.position=Vector3(-31,0.1,34)
	await create_timer(0.5).timeout
	await capture("32-kasparov-town")
	session.hud.show_inventory()
	var equipment: EquipmentPanel=session.hud.panel.find_children("*","EquipmentPanel",true,false)[0]
	equipment._inspect(session.catalog.find_item("kasparov_seal"),1,"")
	await create_timer(0.2).timeout
	await capture("33-family-seal")
	session.hud.close_panel()
	p.progression.restore({"level":2,"experience":12})
	for i in range(6): p.actions.clear(i)
	session.hud.toast_time=0
	session.hud.show_talents()
	await process_frame
	await capture("34-first-talent-point")
	session.queue_free()
	await process_frame
	quit()
