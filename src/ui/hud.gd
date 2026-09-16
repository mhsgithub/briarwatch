class_name GameHUD
extends CanvasLayer

signal service_action(action: String, index: int)
signal save_requested
signal respawn_requested

var player: Player
var quest: QuestLog
var root: Control
var health_bar: ProgressBar
var health_text: Label
var gold_text: Label
var quest_text: Label
var prompt: Label
var toast_label: Label
var toast_time: float = 0
var panel: PanelContainer
var panel_body: VBoxContainer
var mode: String = ""
var current_npc: Npc
var mini_map: RegionMap
var large_map: RegionMap
var damage_flash: ColorRect
var region_label: Label
var font: Font = ThemeDB.fallback_font

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.theme = _theme()
	_build()

func _theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 17
	theme.set_color("font_color", "Label", Color("e2ddc9"))
	theme.set_color("font_color", "Button", Color("eddfb9"))
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("293b38") if state == "normal" else Color("3c5148")
		if state == "disabled":
			style.bg_color = Color("202b29")
		style.border_color = Color("8b7c54") if state == "hover" else Color("4f5e4c")
		style.set_border_width_all(1)
		style.set_corner_radius_all(3)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		theme.set_stylebox(state, "Button", style)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.055, 0.087, 0.083, 0.97)
	box.border_color = Color("8d7a50")
	box.set_border_width_all(1)
	box.content_margin_left = 24
	box.content_margin_right = 24
	box.content_margin_top = 20
	box.content_margin_bottom = 20
	theme.set_stylebox("panel", "PanelContainer", box)
	return theme

func _label(text: String, size_value: int = 17, color: Color = Color("e2ddc9")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size_value)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, callback: Callable, parent: Node) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	button.focus_mode = Control.FOCUS_NONE
	parent.add_child(button)
	return button

func _build() -> void:
	var title := _label("B R I A R W A T C H", 25, Color("e3c794"))
	root.add_child(title)
	title.position = Vector2(30, 22)
	region_label = _label("THE BRIAR MARCH  /  FRONTIER", 12, Color("a6b4a3"))
	root.add_child(region_label)
	region_label.position = Vector2(32, 58)
	var quest_box := PanelContainer.new()
	root.add_child(quest_box)
	quest_box.position = Vector2(28, 93)
	quest_box.custom_minimum_size = Vector2(350, 100)
	quest_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var qcol := VBoxContainer.new()
	quest_box.add_child(qcol)
	qcol.add_child(_label("A ROAD THROUGH THE BRIAR", 13, Color("c5a66c")))
	quest_text = _label("Speak with Warden Elric.", 16)
	quest_text.custom_minimum_size.x = 310
	quest_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	qcol.add_child(quest_text)
	mini_map = RegionMap.new()
	root.add_child(mini_map)
	mini_map.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	mini_map.offset_left = -242
	mini_map.offset_right = -28
	mini_map.offset_top = 24
	mini_map.offset_bottom = 218
	var map_hint := _label("M  Region map", 13, Color("d0c5a4"))
	root.add_child(map_hint)
	map_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	map_hint.offset_left = -225
	map_hint.offset_right = -28
	map_hint.offset_top = 221
	map_hint.offset_bottom = 250
	var bottom := PanelContainer.new()
	root.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -113
	bottom.offset_left = 28
	bottom.offset_right = -28
	bottom.offset_bottom = -22
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	bottom.add_child(row)
	var hp_col := VBoxContainer.new()
	hp_col.custom_minimum_size.x = 250
	row.add_child(hp_col)
	health_text = _label("VITALITY", 14, Color("d7c9b0"))
	hp_col.add_child(health_text)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(250, 16)
	health_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("a55140")
	fill.set_corner_radius_all(3)
	health_bar.add_theme_stylebox_override("fill", fill)
	hp_col.add_child(health_bar)
	var controls := VBoxContainer.new()
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(controls)
	controls.add_child(_label("LMB  Move / attack     WASD  Move     E  Interact", 15))
	controls.add_child(_label("Shift + LMB  Stand & attack     Q  Tonic     Wheel  Zoom", 13, Color("9ba99b")))
	gold_text = _label("0 crowns", 17, Color("dfc88f"))
	row.add_child(gold_text)
	_button("I  Equipment", func(): show_inventory(), row)
	_button("Esc  Menu", func(): show_pause(), row)
	prompt = _label("", 18, Color("ffe1a0"))
	root.add_child(prompt)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -250
	prompt.offset_right = 250
	prompt.offset_top = -153
	prompt.offset_bottom = -123
	prompt.custom_minimum_size = Vector2(500, 30)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label = _label("", 18, Color("f2d294"))
	root.add_child(toast_label)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_label.offset_left = -330
	toast_label.offset_right = 330
	toast_label.offset_top = 35
	toast_label.offset_bottom = 65
	toast_label.custom_minimum_size.x = 660
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_flash = ColorRect.new()
	root.add_child(damage_flash)
	damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_flash.color = Color(0.6, 0.1, 0.07, 0)
	panel = PanelContainer.new()
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -355
	panel.offset_right = 355
	panel.offset_top = -330
	panel.offset_bottom = 310
	panel.custom_minimum_size = Vector2(710, 620)
	panel.visible = false
	panel_body = VBoxContainer.new()
	panel_body.add_theme_constant_override("separation", 12)
	panel.add_child(panel_body)
	large_map = RegionMap.new()
	root.add_child(large_map)
	large_map.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	large_map.offset_left = -420
	large_map.offset_right = 420
	large_map.offset_top = -315
	large_map.offset_bottom = 315
	large_map.expanded = true
	large_map.visible = false

func bind(actor: Player, log: QuestLog) -> void:
	player = actor
	quest = log
	mini_map.player = actor
	large_map.player = actor
	player.health.changed.connect(func(hp: float, maximum: float):
		health_bar.max_value = maximum
		health_bar.value = hp
		health_text.text = "VITALITY   %d / %d" % [hp, maximum])
	player.health.damaged.connect(func(_amount: float): damage_flash.color.a = 0.2)
	player.inventory.changed.connect(_refresh_stats)
	quest.changed.connect(func(): quest_text.text = quest.status_text())
	_refresh_stats()
	player.health.changed.emit(player.health.current, player.health.maximum)
	quest_text.text = quest.status_text()

func _refresh_stats() -> void:
	gold_text.text = "%d crowns" % player.inventory.gold
	if mode == "inventory":
		show_inventory()

func _process(delta: float) -> void:
	toast_time = maxf(0, toast_time - delta)
	toast_label.visible = toast_time > 0
	damage_flash.color.a = maxf(0, damage_flash.color.a - delta * 0.5)
	if not is_instance_valid(player):
		return
	prompt.text = ""
	if mode != "" or player.dead:
		return
	var best_distance := 3.1
	for target in get_tree().get_nodes_in_group("interactables"):
		var distance := player.global_position.distance_to(target.global_position)
		if distance < best_distance:
			best_distance = distance
			prompt.text = "E   " + target.interaction_name()
	region_label.text = "BRIARWATCH  /  SAFE HAVEN" if player.global_position.distance_to(Vector3(-35, 0, 28)) < 20 else "THE BRIAR MARCH  /  WILDERNESS"

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or not is_instance_valid(player):
		return
	match event.physical_keycode:
		KEY_ESCAPE:
			if mode == "death":
				return
			if mode != "":
				close_panel()
			else:
				show_pause()
		KEY_I:
			if player.dead:
				return
			if mode == "inventory":
				close_panel()
			else:
				show_inventory()
		KEY_M:
			if player.dead:
				return
			if mode == "map":
				close_panel()
			else:
				close_panel()
				mode = "map"
				large_map.visible = true
				_set_modal(true)
		KEY_F5:
			save_requested.emit()
		_:
			return
	get_viewport().set_input_as_handled()

func _set_modal(value: bool) -> void:
	get_tree().paused = value
	if is_instance_valid(player):
		player.input_enabled = not value
	root.mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE

func close_panel() -> void:
	mode = ""
	panel.visible = false
	large_map.visible = false
	current_npc = null
	_set_modal(false)

func _begin(new_mode: String, title: String, subtitle: String) -> void:
	mode = new_mode
	large_map.visible = false
	_set_modal(true)
	for child in panel_body.get_children():
		panel_body.remove_child(child)
		child.queue_free()
	panel.visible = true
	panel_body.add_child(_label(title, 27, Color("e4c48e")))
	var description := _label(subtitle, 16, Color("adbba9"))
	description.custom_minimum_size.x = 640
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_body.add_child(description)
	panel_body.add_child(HSeparator.new())

func _scroll_list(height: float = 300) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = height
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_body.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	return list

func show_inventory() -> void:
	if not is_instance_valid(player) or player.dead:
		return
	var inventory := player.inventory
	_begin("inventory", "Equipment & pack", "%d crowns   /   %d damage   /   %d armor   /   %d of %d pack spaces" % [inventory.gold, player.basic_attack.damage + inventory.bonus("damage_bonus"), inventory.bonus("armor_bonus"), inventory.items.size(), Inventory.CAPACITY])
	var gear_row := HBoxContainer.new()
	panel_body.add_child(gear_row)
	for slot in inventory.equipment:
		var item: ItemDefinition = inventory.equipment[slot]
		var button := _button(slot.capitalize() + "\n" + (item.display_name if item else "Empty"), func(): inventory.unequip(slot), gear_row)
		button.tooltip_text = "Click to unequip. " + (item.description if item else "")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var list := _scroll_list(275)
	for i in range(inventory.items.size()):
		var item := inventory.items[i]
		var action := "Use" if item.slot == "consumable" else "Equip"
		var stats := "+%d damage" % item.damage_bonus if item.damage_bonus > 0 else ("+%d armor" % item.armor_bonus if item.armor_bonus > 0 else "+%d health" % item.heal_amount)
		var button := _button("%s   ·   %s     [%s]" % [item.display_name, stats, action], func(): _use_item(i), list)
		button.tooltip_text = item.description
	_button("Return to the March  [I / Esc]", close_panel, panel_body)

func _use_item(index: int) -> void:
	var inventory := player.inventory
	if index >= inventory.items.size():
		return
	var item := inventory.items[index]
	if item.slot == "consumable":
		if player.health.current >= player.health.maximum:
			toast("Your health is already full.")
			return
		player.health.heal(item.heal_amount)
		inventory.items.remove_at(index)
		inventory.changed.emit()
	else:
		inventory.equip(index)

func show_npc(npc: Npc) -> void:
	current_npc = npc
	var definition := npc.definition
	_begin("npc", definition.display_name + "  /  " + definition.title, definition.greeting)
	match definition.service:
		"vendor":
			panel_body.add_child(_label("%d crowns  ·  Buy supplies / sell unequipped items" % player.inventory.gold, 15))
			var list := _scroll_list(315)
			for i in range(definition.stock.size()):
				var item := definition.stock[i]
				var button := _button("Buy  %s    ·    %d crowns" % [item.display_name, item.price], func(): service_action.emit("buy", i), list)
				button.tooltip_text = item.description + "  Damage +%d / Armor +%d" % [item.damage_bonus, item.armor_bonus]
				button.disabled = player.inventory.gold < item.price or player.inventory.items.size() >= Inventory.CAPACITY
			list.add_child(_label("YOUR PACK", 14, Color("c5a66c")))
			for i in range(player.inventory.items.size()):
				var item := player.inventory.items[i]
				_button("Sell  %s    ·    %d crowns" % [item.display_name, maxi(1, item.price / 2)], func(): service_action.emit("sell", i), list)
		"healer":
			_button("Tend my wounds  ·  Free", func(): service_action.emit("heal", 0), panel_body)
			panel_body.add_child(_label("Rest refreshes all encounters and clears uncollected loot.", 15))
			_button("Rest until dawn  ·  Repopulate the March", func(): service_action.emit("rest", 0), panel_body)
		"warden":
			var description := _label(quest.definition.description, 17)
			description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			panel_body.add_child(description)
			if not quest.accepted:
				_button("I will open the road  ·  Accept objective", func(): service_action.emit("accept", 0), panel_body)
			elif quest.cleared and not quest.rewarded:
				_button("The watchtower is clear  ·  Claim reward", func(): service_action.emit("claim", 0), panel_body)
			else:
				panel_body.add_child(_label(quest.status_text(), 17))
	_button("Farewell  [Esc]", close_panel, panel_body)

func show_pause() -> void:
	if player.dead:
		return
	_begin("pause", "The March can wait", "Your journey is saved after discoveries, trades, and recovery. Continue begins in the safety of Briarwatch.")
	_button("Continue", close_panel, panel_body)
	_button("Save journey  [F5]", func(): save_requested.emit(), panel_body)
	_button("Save & quit", func(): save_requested.emit(); get_tree().quit(), panel_body)
	panel_body.add_child(_label("LMB ground: move  /  LMB enemy: approach and attack\nWASD: move  /  Shift + LMB: attack in place\nE: nearby NPC or loot  /  Q: tonic  /  I: gear  /  M: map\nEnemies telegraph attacks. Keep moving to evade arrows.\nDeath costs 10% of carried crowns; your equipment is safe.", 16))

func show_death() -> void:
	_begin("death", "The road takes its due", "Iona's wardens carry you back to Briarwatch. You lose 10% of carried crowns. Your equipment and quest progress remain.")
	_button("Return to Briarwatch", func(): close_panel(); respawn_requested.emit(), panel_body)

func toast(text: String) -> void:
	toast_label.text = text
	toast_time = 4.0
