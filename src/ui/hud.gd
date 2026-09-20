class_name GameHUD
extends CanvasLayer
## UI composition and input routing. Rules and transactions live in gameplay owners.
signal service_action(action: String, index: int)
signal save_requested
signal respawn_requested
var player: Player
var quest: QuestLog
var root: Control
var health_text: Label
var status_text: Label
var catalog: ContentCatalog
var action_slots: HBoxContainer
var quest_text: Label
var quest_title: Label
var prompt: Label
var toast_label: Label
var toast_time: float = 0
var panel: PanelContainer
var panel_body: VBoxContainer
var mode: String = ""
var current_npc: Npc
var large_map: RegionMap
var damage_flash: ColorRect
var region_label: Label
var orb: VitalityOrb
var scrim: ColorRect
var target_box: VBoxContainer
var target_text: Label
var target_health: ProgressBar
var experience_bar: ProgressBar
var level_label: Label
var talent_button: Button
var map_button: Button

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	root=Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.theme=ArtTheme.theme()
	_build()

func _label(text: String,size_value: int=16,color: Color=ArtTheme.PALE,heading: bool=false) -> Label:
	return ArtTheme.label(text,size_value,color,heading)

func _button(text: String,callback: Callable,parent: Node) -> Button:
	var button:=Button.new()
	button.text=text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _place(control: Control,preset: int,rect: Rect2) -> void:
	root.add_child(control)
	control.set_anchors_and_offsets_preset(preset)
	control.offset_left=rect.position.x
	control.offset_top=rect.position.y
	control.offset_right=rect.end.x
	control.offset_bottom=rect.end.y

func _build() -> void:
	var vignette:=ColorRect.new()
	root.add_child(vignette)
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material:=ShaderMaterial.new()
	material.shader=preload("res://assets/shaders/vignette.gdshader")
	vignette.material=material
	var title:=_label("B R I A R W A T C H",22,ArtTheme.GOLD,true)
	_place(title,Control.PRESET_TOP_LEFT,Rect2(30,22,310,34))
	region_label=_label("THE BRIAR MARCH",11,ArtTheme.MUTED)
	_place(region_label,Control.PRESET_TOP_LEFT,Rect2(32,60,300,20))
	var quest_column:=VBoxContainer.new()
	_place(quest_column,Control.PRESET_TOP_LEFT,Rect2(32,102,265,100))
	quest_column.mouse_filter=Control.MOUSE_FILTER_IGNORE
	quest_title=_label("",12,ArtTheme.GOLD)
	quest_column.add_child(quest_title)
	quest_text=_label("",15,ArtTheme.PALE)
	quest_text.custom_minimum_size.x=260
	quest_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	quest_column.add_child(quest_text)
	var navigation:=HBoxContainer.new()
	navigation.add_theme_constant_override("separation",8)
	_place(navigation,Control.PRESET_TOP_RIGHT,Rect2(-375,68,345,35))
	_button("Character [I]",show_inventory,navigation)
	talent_button=_button("Talents [N]",show_talents,navigation)
	map_button=_button("Map [M]",show_map,navigation)
	target_box=VBoxContainer.new()
	_place(target_box,Control.PRESET_CENTER_TOP,Rect2(-155,30,310,53))
	target_box.mouse_filter=Control.MOUSE_FILTER_IGNORE
	target_text=_label("",17,ArtTheme.PALE,true)
	target_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	target_box.add_child(target_text)
	target_health=ProgressBar.new()
	target_health.custom_minimum_size.y=7
	target_health.show_percentage=false
	target_health.mouse_filter=Control.MOUSE_FILTER_IGNORE
	target_health.add_theme_stylebox_override("background",ArtTheme.box(Color("1b1112"),Color("77603d"),0))
	target_health.add_theme_stylebox_override("fill",ArtTheme.box(Color("943e32"),Color("943e32"),0))
	target_box.add_child(target_health)
	target_box.hide()
	orb=VitalityOrb.new()
	_place(orb,Control.PRESET_BOTTOM_LEFT,Rect2(35,-172,140,140))
	health_text=_label("",16,ArtTheme.PALE,true)
	health_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_place(health_text,Control.PRESET_BOTTOM_LEFT,Rect2(27,-42,156,24))
	var vitality_title:=_label("V I T A L I T Y",10,ArtTheme.GOLD)
	vitality_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_place(vitality_title,Control.PRESET_BOTTOM_LEFT,Rect2(28,-181,154,20))
	status_text=_label("",13,Color("e49b85"))
	status_text.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_place(status_text,Control.PRESET_BOTTOM_LEFT,Rect2(30,-210,230,24))
	var action_frame:=PanelContainer.new()
	action_frame.z_index=2
	action_frame.add_theme_stylebox_override("panel",ArtTheme.box(Color(0.05,0.08,0.085,0.96),Color("89744e"),4))
	_place(action_frame,Control.PRESET_CENTER_BOTTOM,Rect2(-222,-70,444,68))
	action_slots=HBoxContainer.new()
	action_slots.add_theme_constant_override("separation",8)
	action_frame.add_child(action_slots)
	experience_bar=ProgressBar.new()
	experience_bar.show_percentage=false
	experience_bar.add_theme_stylebox_override("background",ArtTheme.box(Color("12201e"),Color("554b38"),0))
	experience_bar.add_theme_stylebox_override("fill",ArtTheme.box(Color("9a854f"),Color("bca269"),0))
	_place(experience_bar,Control.PRESET_CENTER_BOTTOM,Rect2(-218,-85,436,6))
	level_label=_label("",11,ArtTheme.GOLD)
	level_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_place(level_label,Control.PRESET_CENTER_BOTTOM,Rect2(-218,-110,436,20))
	prompt=_label("",17,ArtTheme.PALE,true)
	prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_place(prompt,Control.PRESET_CENTER_BOTTOM,Rect2(-300,-159,600,30))
	toast_label=_label("",17,ArtTheme.PALE,true)
	toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	toast_label.z_index=10
	toast_label.add_theme_color_override("font_shadow_color",Color.BLACK)
	toast_label.add_theme_constant_override("shadow_offset_y",2)
	_place(toast_label,Control.PRESET_CENTER_TOP,Rect2(-360,92,720,32))
	damage_flash=ColorRect.new()
	root.add_child(damage_flash)
	damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_flash.mouse_filter=Control.MOUSE_FILTER_IGNORE
	damage_flash.color=Color(0.5,0.05,0.025,0)
	scrim=ColorRect.new()
	root.add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.color=Color(0.015,0.025,0.028,0.77)
	scrim.visible=false
	panel=OrnatePanel.new()
	_place(panel,Control.PRESET_CENTER,Rect2(-550,-376,1100,752))
	panel.visible=false
	panel_body=VBoxContainer.new()
	panel_body.add_theme_constant_override("separation",12)
	panel.add_child(panel_body)
	large_map=RegionMap.new()
	_place(large_map,Control.PRESET_CENTER,Rect2(-480,-320,960,640))
	large_map.expanded=true
	large_map.visible=false
	# GUI hit testing follows sibling order, not z_index. Keep the belt usable
	# above the modal scrim so pack items can be dropped on it.
	root.move_child(action_frame,root.get_child_count()-1)

func bind(actor: Player,log: QuestLog) -> void:
	player=actor
	quest=log
	for i in range(ActionLoadout.SIZE):
		var tile:=ActionTile.new()
		tile.player=player
		tile.catalog=catalog
		tile.index=i
		tile.assign_requested.connect(show_action_picker)
		action_slots.add_child(tile)
	player.health.changed.connect(func(hp: float,maximum: float):
		orb.ratio=hp/maximum
		health_text.text="%d / %d" % [hp,maximum])
	player.health.damaged.connect(func(_amount: float): damage_flash.color.a=0.17)
	player.inventory.changed.connect(_refresh_stats)
	player.progression.changed.connect(_refresh_progression)
	player.progression.leveled.connect(func(level: int):
		toast("Level %d · Talent point earned.  [N]" % level)
		AudioLibrary.play_ui(self,"level_up"))
	_refresh_progression()
	quest.changed.connect(_refresh_quest)
	_refresh_stats()
	player.health.changed.emit(player.health.current,player.health.maximum)
	_refresh_quest()

func _refresh_stats() -> void:
	if mode=="inventory":
		show_inventory()

func _refresh_progression() -> void:
	talent_button.text="Talents [N]%s" % (" · %d" % player.progression.points() if player.progression.points()>0 else "")
	experience_bar.max_value=maxi(1,player.progression.required())
	experience_bar.value=experience_bar.max_value if player.progression.level==20 else player.progression.experience
	level_label.text="LEVEL %d   ·   %s" % [player.progression.level,"MAXIMUM" if player.progression.level==20 else "%d / %d EXP" % [player.progression.experience,player.progression.required()]]
	experience_bar.tooltip_text="One talent point per level.  [N]"

func _process(delta: float) -> void:
	toast_time=maxf(0,toast_time-delta)
	toast_label.visible=toast_time>0
	if toast_time>0:
		_place_toast()
	damage_flash.color.a=maxf(0,damage_flash.color.a-delta*0.5)
	if not is_instance_valid(player): return
	status_text.text="Knocked down" if player.combat_state.knockdown_left>0 else ("Bleeding · %ds" % player.combat_state.bleed_left if player.combat_state.bleed_left>0 else "")
	prompt.text=""
	target_box.hide()
	if not mode.is_empty() or player.dead: return
	var best_distance:=3.1
	for target in get_tree().get_nodes_in_group("interactables"):
		var distance:=player.global_position.distance_to(target.global_position)
		if distance<best_distance:
			best_distance=distance
			prompt.text="[ E ]  "+target.interaction_name()
	region_label.text=large_map.region.display_name.to_upper() if large_map.region.interior else ("BRIARWATCH  /  SANCTUARY" if player.global_position.distance_to(Vector3(-35,0,28))<20 else "THE BRIAR MARCH  /  WILDERNESS")
	var enemy: Enemy=player.attack_target as Enemy
	if not is_instance_valid(enemy):
		enemy=player._pick_enemy(get_viewport().get_mouse_position()) as Enemy
	if not is_instance_valid(enemy) and large_map.region.interior:
		for candidate in get_tree().get_nodes_in_group("enemies"):
			if candidate.definition.is_boss and candidate.aggro:
				enemy=candidate
				break
	if is_instance_valid(enemy) and enemy.health.current>0:
		target_box.show()
		target_text.text=enemy.definition.display_name
		target_health.max_value=enemy.health.maximum
		target_health.value=enemy.health.current

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or not is_instance_valid(player): return
	if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_6:
		if mode.is_empty() and not player.dead:
			player.actions.activate(event.physical_keycode-KEY_1)
		get_viewport().set_input_as_handled()
		return
	match event.physical_keycode:
		KEY_ESCAPE:
			if mode=="death": return
			if not mode.is_empty(): close_panel()
			else: show_pause()
		KEY_I:
			if player.dead: return
			if mode=="inventory": close_panel()
			else: show_inventory()
		KEY_Q:
			if player.dead: return
			if mode=="quest": close_panel()
			else: show_quest()
		KEY_N:
			if player.dead: return
			if mode=="talents": close_panel()
			else: show_talents()
		KEY_M:
			if player.dead: return
			if mode=="map": close_panel()
			else: show_map()
		KEY_F5: save_requested.emit()
		KEY_U:
			if player.dead: return
			player.progression.grant_test_points(15)
			toast("Testing: 15 talent points received.")
			if mode=="talents": show_talents()
		_: return
	get_viewport().set_input_as_handled()

func _set_modal(value: bool) -> void:
	get_tree().paused=value
	scrim.visible=value
	if is_instance_valid(player): player.input_enabled=not value
	root.mouse_filter=Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE

func close_panel() -> void:
	mode=""
	panel.visible=false
	large_map.visible=false
	current_npc=null
	_set_modal(false)

func _begin(new_mode: String,title: String,subtitle: String) -> void:
	if mode!=new_mode: AudioLibrary.play_ui(self,"pack" if new_mode=="inventory" else "page")
	mode=new_mode
	large_map.visible=false
	_set_modal(true)
	for child in panel_body.get_children():
		panel_body.remove_child(child)
		child.queue_free()
	var inventory_mode:=new_mode in ["inventory","talents"]
	panel.offset_left=-550 if inventory_mode else -390
	panel.offset_right=550 if inventory_mode else 390
	panel.offset_top=-376 if inventory_mode else -320
	panel.offset_bottom=376 if inventory_mode else 320
	panel.visible=true
	var heading:=HBoxContainer.new()
	panel_body.add_child(heading)
	var label:=_label(title,30,ArtTheme.PALE,true)
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.add_child(label)
	if new_mode!="death":
		_button("×",close_panel,heading).tooltip_text="Close [Esc]"
	var description:=_label(subtitle,14,ArtTheme.MUTED)
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel_body.add_child(description)
	panel_body.add_child(HSeparator.new())

func _scroll_list(height: float=260) -> VBoxContainer:
	var scroll:=ScrollContainer.new()
	scroll.custom_minimum_size.y=height
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	panel_body.add_child(scroll)
	var list:=VBoxContainer.new()
	list.add_theme_constant_override("separation",7)
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	return list

func show_inventory() -> void:
	if not is_instance_valid(player) or player.dead: return
	_begin("inventory","Character & inventory","A roadwarden carries what the road demands.")
	var equipment:=EquipmentPanel.new()
	equipment.player=player
	equipment.catalog=catalog
	equipment.use_requested.connect(_use_item)
	panel_body.add_child(equipment)

func show_talents() -> void:
	if not is_instance_valid(player) or player.dead: return
	if not player.progression.talents_unlocked():
		toast("Talents unlock at level 2. Earn EXP by defeating enemies.")
		return
	_begin("talents","Centurion talents","One point per level. Fully master every connected prerequisite to advance. Talent choices are permanent.")
	var talents:=TalentPanel.new()
	talents.player=player
	panel_body.add_child(talents)

func _use_item(index: int) -> void:
	player.use_item(index)

func show_action_picker(index: int) -> void:
	if player.dead: return
	_begin("actions","Action slot %d" % (index+1),"Bind a learned ability or a consumable. Bindings remain when supplies run out.")
	var list:=_scroll_list(240)
	for talent: Dictionary in CenturionTalents.all():
		if not talent.active or player.progression.rank(talent.id)==0: continue
		var ability_button:=_button(talent.name,func():
			player.actions.assign_ability(index,talent.id)
			close_panel(),list)
		ability_button.icon=CenturionTalents.icon(int(talent.icon))
		ability_button.expand_icon=true
		ability_button.add_theme_constant_override("icon_max_width",34)
		ability_button.tooltip_text=talent.description
	var shown: Array[StringName]=[]
	for item in player.inventory.items:
		if item.slot!="consumable" or item.id in shown: continue
		shown.append(item.id)
		var button:=_button(item.display_name,func():
			player.actions.assign_item(index,item)
			close_panel(),list)
		button.icon=ArtTheme.item_icon(item)
		button.expand_icon=true
		button.add_theme_constant_override("icon_max_width",34)
	if shown.is_empty(): list.add_child(_label("No consumables in your pack.",16,ArtTheme.MUTED))
	_button("Clear slot",func(): player.actions.clear(index); close_panel(),panel_body)

func _trade_row(item: ItemDefinition,amount: int,callback: Callable,parent: Node,disabled: bool=false) -> Button:
	var button:=_button("",callback,parent)
	button.custom_minimum_size.y=54
	button.disabled=disabled
	var row:=HBoxContainer.new()
	button.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left=10
	row.offset_right=-10
	row.offset_top=6
	row.offset_bottom=-6
	row.add_theme_constant_override("separation",14)
	var icon:=TextureRect.new()
	icon.texture=ArtTheme.item_icon(item)
	icon.custom_minimum_size=Vector2(38,38)
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var label:=_label(item.display_name,16,ArtTheme.tier_color(item))
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var gold:=GoldAmount.new()
	gold.amount=amount
	row.add_child(gold)
	for control in [row,icon,label,gold]:
		control.mouse_filter=Control.MOUSE_FILTER_IGNORE
	button.tooltip_text=ArtTheme.item_properties(item)+"\n"+item.description
	if disabled: row.modulate.a=0.6
	return button

func show_npc(npc: Npc) -> void:
	current_npc=npc
	var definition:=npc.definition
	_begin("npc",definition.display_name,definition.title.to_upper())
	var greeting:=_label("“"+definition.greeting+"”",18,ArtTheme.PALE,true)
	greeting.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel_body.add_child(greeting)
	match definition.service:
		"vendor":
			var balance:=HBoxContainer.new()
			panel_body.add_child(balance)
			balance.add_child(_label("SUPPLIES     /     ",12,ArtTheme.GOLD))
			var purse:=GoldAmount.new()
			purse.amount=player.inventory.gold
			balance.add_child(purse)
			var list:=_scroll_list(270)
			for i in range(definition.stock.size()):
				var item:=definition.stock[i]
				_trade_row(item,item.price,func(): service_action.emit("buy",i),list,player.inventory.gold<item.price or player.inventory.items.size()>=Inventory.CAPACITY)
			list.add_child(_label("SELL FROM YOUR PACK",12,ArtTheme.GOLD))
			for i in range(player.inventory.items.size()):
				var item:=player.inventory.items[i]
				_trade_row(item,item.sell_price,func(): service_action.emit("sell",i),list)
		"healer":
			panel_body.add_child(_label("SANCTUARY",12,ArtTheme.GOLD))
			_button("Tend my wounds  ·  Free",func(): service_action.emit("heal",0),panel_body)
		"warden":
			var offer:=quest.offered()
			if offer.giver_npc != str(definition.id):
				greeting.text="“Kasparov waits near Sister Iona. The lord has news from our scouts; hear what he has to say.”"
				_button("Farewell  [Esc]",close_panel,panel_body)
				return
			if not offer.offer_dialogue.is_empty(): greeting.text="“"+offer.offer_dialogue+"”"
			panel_body.add_child(_label(offer.title,23,ArtTheme.GOLD,true))
			var description:=_label(offer.description,16)
			description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			panel_body.add_child(description)
			var reward:=HBoxContainer.new()
			panel_body.add_child(reward)
			reward.add_child(_label("REWARD   ",13,ArtTheme.GOLD))
			var gold:=GoldAmount.new()
			gold.amount=offer.reward_gold
			reward.add_child(gold)
			if offer.reward_item:
				reward.add_child(_label("  & "+offer.reward_item.display_name,13,ArtTheme.tier_color(offer.reward_item)))
			if not quest.accepted or offer!=quest.definition:
				_button(offer.accept_text,func(): service_action.emit("accept",0),panel_body)
			elif quest.cleared and not quest.rewarded and quest.definition.handin_npc=="elric":
				_button("Hand over the cellar key",func(): service_action.emit("claim",0),panel_body)
			else:
				panel_body.add_child(_label(quest.status_text(),17))
		"rescue":
			if quest.is_completed("warwick_rescue"):
				var offer := quest.offered()
				if offer.giver_npc=="kasparov":
					panel_body.add_child(_label(offer.title,23,ArtTheme.GOLD,true))
					if quest.is_completed(str(offer.id)):
						greeting.text="“"+offer.completed_dialogue+"”"
					elif offer != quest.definition or not quest.accepted:
						greeting.text="“"+offer.offer_dialogue+"”"
						var reward := GoldAmount.new()
						reward.amount=offer.reward_gold
						panel_body.add_child(_label("REWARD",13,ArtTheme.GOLD))
						panel_body.add_child(reward)
						_button(offer.accept_text,func(): service_action.emit("accept",0),panel_body)
					elif quest.cleared:
						greeting.text="“"+offer.handin_dialogue+"”"
						_button("Tell Kasparov of Bloodfang · Receive %d gold" % offer.reward_gold,func(): service_action.emit("claim",0),panel_body)
					else:
						greeting.text="“"+offer.progress_dialogue+"”"
						var objective := _label(quest.status_text(),17)
						objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
						panel_body.add_child(objective)
			elif quest.accepted and quest.cleared and quest.flags.get("kasparov_cell_open",false):
				_button("Let us get you home",func(): service_action.emit("rescue",0),panel_body)
			else:
				panel_body.add_child(_label("Defeat Brutus and unlock the cell first.",17))
	_button("Farewell  [Esc]",close_panel,panel_body)

func show_quest() -> void:
	if not is_instance_valid(player) or player.dead: return
	_begin("quest","Quest journal","")
	if not quest.accepted or quest.rewarded:
		panel_body.add_child(_label("No current quest.",17,ArtTheme.MUTED))
		return
	panel_body.add_child(_label(quest.definition.title,23,ArtTheme.GOLD,true))
	var description:=_label(quest.definition.description,17)
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel_body.add_child(description)
	panel_body.add_child(HSeparator.new())
	var objective:=_label(quest.status_text(),19,ArtTheme.PALE,true)
	objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel_body.add_child(objective)

func _refresh_quest() -> void:
	var next := quest.offered()
	quest_title.text = "◇  " + (next.title if quest.rewarded and next!=quest.definition else quest.definition.title).to_upper() if not quest.rewarded or next!=quest.definition else ""
	quest_text.text = next.offer_objective if quest.rewarded and next!=quest.definition else (quest.status_text() if not quest.rewarded else "")

func show_map() -> void:
	if not is_instance_valid(player) or player.dead: return
	if large_map.region and not large_map.region.map_enabled: return
	AudioLibrary.play_ui(self,"page")
	close_panel()
	mode="map"
	large_map.visible=true
	_set_modal(true)

func show_pause() -> void:
	if player.dead: return
	_begin("pause","The March can wait","Your journey is saved after discoveries, trades, and recovery.")
	_button("Return to the road",close_panel,panel_body)
	_button("Save journey  [F5]",func(): save_requested.emit(),panel_body)
	_button("Save & quit",func(): save_requested.emit(); get_tree().quit(),panel_body)
	panel_body.add_child(_label("FIELD NOTES",12,ArtTheme.GOLD))
	panel_body.add_child(_label("LMB ground  Move      LMB enemy  Pursue & attack\nWASD  Move      Shift + LMB  Attack in place\nE  Interact      Q  Quest      I  Inventory      M  Map\nN  Talents (level 2+)      1–6  Assigned abilities / tonics\nClick an empty belt slot to assign; right-click to clear\n\nStep out of committed blows and evade arrows.\nDeath costs 10% of gold. Your equipment is safe.",16,ArtTheme.MUTED))

func show_death() -> void:
	_begin("death","The road takes its due","FALLEN IN THE BRIAR MARCH")
	var message:=_label("Iona's wardens carry you home.\n\nYou lose 10% of your carried gold. Your equipment and quest progress remain.",21,ArtTheme.PALE,true)
	message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	panel_body.add_child(message)
	_button("Return to Briarwatch",func(): close_panel(); respawn_requested.emit(),panel_body)

func toast(text: String) -> void:
	toast_label.text=text
	toast_time=4.0
	_place_toast()

func _place_toast() -> void:
	# Modal feedback belongs outside the frame and above the dimming scrim.
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_label.offset_left=-360
	toast_label.offset_right=360
	toast_label.offset_top=92 if mode.is_empty() else 40
	toast_label.offset_bottom=124 if mode.is_empty() else 72
