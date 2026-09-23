class_name EquipmentPanel
extends HBoxContainer
signal use_requested(index: int)
var player: Player
var catalog: ContentCatalog
var detail: VBoxContainer
var tiles: Array[ItemTile] = []

func _ready() -> void:
	add_theme_constant_override("separation",28)
	var character := VBoxContainer.new()
	character.custom_minimum_size.x=486
	add_child(character)
	character.add_child(ArtTheme.label("CENTURION · LEVEL %d" % player.progression.level,13,ArtTheme.GOLD))
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation",25)
	character.add_child(stats)
	stats.add_child(ArtTheme.label("%d  Melee damage" % player.melee_damage(),17,ArtTheme.PALE,true))
	stats.add_child(ArtTheme.label("%d  Armor" % player.inventory.bonus("armor_bonus"),17,ArtTheme.PALE,true))
	stats.add_child(ArtTheme.label("%d  Vitality" % player.health.maximum,17,ArtTheme.PALE,true))
	character.add_child(ArtTheme.label("Strength  %d   ·   Attack speed  %.1f seconds / swing" % [player.strength(),player.swing_seconds()],13,ArtTheme.MUTED))
	var secondary := ArtTheme.label("Crit rating  %d   ·   Critical chance  %.0f%%   ·   Movement  %d%%" % [player.crit_rating(),clampf(player.crit_rating(),0,100),player.abilities.movement_multiplier()*100],13,ArtTheme.MUTED)
	secondary.tooltip_text = "Each point of crit rating grants 1% critical chance. Critical strikes deal twice the damage."
	character.add_child(secondary)
	var doll := Control.new()
	doll.custom_minimum_size=Vector2(486,490)
	character.add_child(doll)
	var preview := CharacterPreview.new()
	preview.equipment=player.inventory.equipment
	preview.position=Vector2(113,78)
	preview.size=Vector2(230,330)
	doll.add_child(preview)
	var positions := {
		"head": Vector2(198,0), "amulet": Vector2(384,0), "shoulders": Vector2(12,0),
		"weapon": Vector2(12,119), "body": Vector2(384,119), "shield": Vector2(384,238),
		"gloves": Vector2(12,238), "belt": Vector2(12,340), "boots": Vector2(384,340),
		"ring_left": Vector2(146,386), "ring_right": Vector2(250,386)}
	for slot in EquipmentSlots.DEFINITIONS:
		var label := ArtTheme.label(slot.label.to_upper(),11,ArtTheme.MUTED)
		label.position=positions[slot.id]
		label.size.x=84
		label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		doll.add_child(label)
		var blocked := player.inventory.blocking_slot(slot.id)
		var displayed: ItemDefinition = player.inventory.equipment[slot.id] if blocked.is_empty() else player.inventory.equipment[blocked]
		var tile := _tile(displayed,-1,slot.id,slot.icon)
		tile.blocked_by=blocked
		tile.position=positions[slot.id]+Vector2(0,19)
		tile.size=Vector2(84,84)
		doll.add_child(tile)
	var divider := VSeparator.new()
	add_child(divider)
	var pack := VBoxContainer.new()
	pack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	pack.add_theme_constant_override("separation",10)
	add_child(pack)
	pack.add_child(ArtTheme.label("TRAVEL PACK",13,ArtTheme.GOLD))
	var pack_info := HBoxContainer.new()
	pack_info.add_theme_constant_override("separation",20)
	pack.add_child(pack_info)
	pack_info.add_child(ArtTheme.label("%d / %d spaces" % [player.inventory.items.size(),Inventory.CAPACITY],17,ArtTheme.PALE))
	var gold := GoldAmount.new()
	gold.amount=player.inventory.gold
	pack_info.add_child(gold)
	if not player.inventory.pending_rewards.is_empty():
		var claim := Button.new()
		claim.text = "Claim reward"
		claim.tooltip_text = "Reserved quest reward: "+player.inventory.pending_rewards[0].display_name+"\nMake room in your pack to collect it."
		claim.disabled = player.inventory.items.size()>=Inventory.CAPACITY
		claim.pressed.connect(player.inventory.claim_pending)
		pack_info.add_child(claim)
	for id in player.inventory.quest_items:
		var item := catalog.find_item(id) if catalog else null
		if item == null: continue
		var keys := TextureRect.new()
		keys.texture = ArtTheme.item_icon(item)
		keys.custom_minimum_size = Vector2(28, 28)
		keys.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		keys.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		keys.tooltip_text = "Quest pouch: " + item.display_name + "\n" + item.description
		pack_info.add_child(keys)
	var grid := GridContainer.new()
	grid.columns=5
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	pack.add_child(grid)
	for i in range(Inventory.CAPACITY):
		var item: ItemDefinition=player.inventory.items[i] if i<player.inventory.items.size() else null
		grid.add_child(_tile(item,i,"",-1))
	pack.add_child(ArtTheme.label("Inspect: click   ·   Equip / use: double-click   ·   Drag to a slot",12,ArtTheme.MUTED))
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel",ArtTheme.box(Color("1b2523"),Color("494d3d"),14))
	box.custom_minimum_size=Vector2(440,170)
	box.size_flags_vertical=Control.SIZE_EXPAND_FILL
	pack.add_child(box)
	detail=VBoxContainer.new()
	detail.add_theme_constant_override("separation",7)
	box.add_child(detail)
	_inspect(null,-1,"")

func _tile(item: ItemDefinition,index: int,slot: String,empty_icon: int) -> ItemTile:
	var tile := ItemTile.new()
	tile.item=item
	tile.inventory=player.inventory
	tile.bag_index=index
	tile.equipment_slot=slot
	tile.empty_icon=empty_icon
	tile.cell_size=72 if slot.is_empty() else 84
	tile.inspected.connect(_inspect)
	tile.activated.connect(_activate)
	tile.item_dropped.connect(_drop)
	tiles.append(tile)
	return tile

func _activate(index: int,slot: String) -> void:
	if not slot.is_empty():
		if not player.inventory.unequip(slot): player.feedback.emit("Make space in your pack to unequip this item.")
		else: AudioLibrary.play_ui(player.get_parent(),"equip")
	elif index>=0 and index<player.inventory.items.size():
		use_requested.emit(index)

func _drop(data: Dictionary,slot: String) -> void:
	if slot.is_empty():
		if player.inventory.unequip(data.slot): AudioLibrary.play_ui(player.get_parent(),"equip")
	else:
		if not player.inventory.equip(data.index,slot): player.feedback.emit("Make room for the displaced equipment.")
		else: AudioLibrary.play_ui(player.get_parent(),"equip")

func _inspect(item: ItemDefinition,index: int,slot: String) -> void:
	for child in detail.get_children():
		detail.remove_child(child)
		child.queue_free()
	for tile in tiles:
		tile.selected=tile.item==item and tile.bag_index==index and tile.equipment_slot==slot and item!=null
		tile.queue_redraw()
	if item==null:
		detail.add_child(ArtTheme.label("Ready for the road",23,ArtTheme.PALE,true))
		var hint := ArtTheme.label("Select an item to inspect its properties. Empty equipment slots are ready for future finds.",15,ArtTheme.MUTED)
		hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		detail.add_child(hint)
		return
	detail.add_child(ArtTheme.label(item.display_name,21,ArtTheme.tier_color(item),true))
	var properties := ArtTheme.label(ArtTheme.item_properties(item).replace("\n","  ·  "),13,Color("a9ba91"))
	properties.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(properties)
	var description := ArtTheme.label(item.description,13,ArtTheme.MUTED)
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(description)
	var button := Button.new()
	button.text="Unequip" if not slot.is_empty() else ("Drink tonic" if item.slot=="consumable" else "Equip item")
	button.pressed.connect(func(): _activate(index,slot))
	detail.add_child(button)
