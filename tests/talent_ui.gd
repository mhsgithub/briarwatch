extends SceneTree
var session: Node
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks+=1
	if value: print("PASS: ",message)
	else:
		failures.append(message)
		push_error("FAIL: "+message)
func key(code: Key) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	var release:=InputEventKey.new()
	release.physical_keycode=code
	release.pressed=false
	Input.parse_input_event(release)
	await process_frame
func run() -> void:
	root.size=Vector2i(1440,900)
	session=load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await physics_frame
	await physics_frame
	await key(KEY_N)
	check(session.hud.mode.is_empty(),"N does not open talents at level one")
	var p: Player=session.player
	p.progression.grant(30)
	await key(KEY_N)
	check(session.hud.mode=="talents" and paused,"N opens and pauses talents at level two")
	var talent_panel: TalentPanel=session.hud.panel.find_children("*","TalentPanel",true,false)[0]
	check(talent_panel.find_children("*","TalentTile",true,false).size()==7,"Each tab displays only its seven talents")
	var learn_button: Button
	for button in talent_panel.info.get_children():
		if button is Button and button.text=="Spend 1 point": learn_button=button
	learn_button.pressed.emit()
	await process_frame
	check(p.progression.rank("block")==1 and p.progression.points()==0,"Spend button learns selected talent and refreshes point display")
	await key(KEY_N)
	check(session.hud.mode.is_empty() and not paused,"N closes the tree and resumes")
	p.progression.restore({"level":20,"ranks":{"block":3,"whirlwind":1,"impale":1,"bloodthirst":3,"retaliate":2,"rampage":1,"bladestorm":1}})
	await key(KEY_N)
	talent_panel=session.hud.panel.find_children("*","TalentPanel",true,false)[0]
	talent_panel.selected_id="bladestorm"
	talent_panel.rebuild()
	await process_frame
	await process_frame
	check(session.hud.panel.get_global_rect().end.y<root.size.y-50,"Longest talent description stays inside the modal frame")
	var source: TalentTile
	for tile in talent_panel.find_children("*","TalentTile",true,false):
		if tile.data.id=="whirlwind": source=tile
	var target: ActionTile=session.hud.action_slots.get_child(0)
	var preview:=TextureRect.new()
	preview.texture=CenturionTalents.icon(1)
	preview.custom_minimum_size=Vector2(32,32)
	source.force_drag({"progression":p.progression,"talent_id":"whirlwind"},preview)
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
	check(p.actions.slots[0].get("id","")=="whirlwind","Real GUI drag from talent tree reaches the belt")
	await key(KEY_1)
	check(p.abilities.remaining("whirlwind")==0,"Ability hotkeys cannot attack through paused talent window")
	await key(KEY_N)
	await key(KEY_1)
	check(p.abilities.remaining("whirlwind")>9,"Number hotkey activates the learned bound ability")
	p.progression.restore({"level":20,"ranks":{"momentum":3,"leap":1,"unshackled":1,"iron_constitution":3,"elemental_resolve":2,"fleetfooted":3,"blood_and_breath":1}})
	session.hud.show_talents()
	talent_panel=session.hud.panel.find_children("*","TalentPanel",true,false)[0]
	talent_panel.get_child(0).get_child(1).pressed.emit()
	await process_frame
	var only_path:=true
	for tile in talent_panel.find_children("*","TalentTile",true,false):
		only_path=only_path and tile.data.tree=="Pathfinder"
	check(only_path,"Pathfinder tab switches its actual talent graph")
	session.hud.close_panel()
	print("TALENT UI: %d checks, %d failures" % [checks,failures.size()])
	session.queue_free()
	await create_timer(0.4).timeout
	quit(0 if failures.is_empty() else 1)
