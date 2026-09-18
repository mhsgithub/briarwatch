class_name ItemTile
extends Button
## Shared inventory/equipment cell; all transactions remain in Inventory.
signal inspected(item: ItemDefinition, bag_index: int, equipment_slot: String)
signal activated(bag_index: int, equipment_slot: String)
signal item_dropped(data: Dictionary, equipment_slot: String)
var blocked_by: String = ""
var item: ItemDefinition
var bag_index: int = -1
var equipment_slot: String = ""
var empty_icon: int = -1
var selected: bool = false
var inventory: Inventory
var cell_size: int=76

func _ready() -> void:
	custom_minimum_size=Vector2.ONE*cell_size
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	focus_mode=Control.FOCUS_ALL
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	resized.connect(queue_redraw)
	pressed.connect(func(): inspected.emit(item,bag_index,equipment_slot))
	tooltip_text=(item.display_name+"\n"+ArtTheme.item_properties(item)+"\n"+item.description+"\nDouble-click or right-click to "+("use" if item.slot=="consumable" else "equip")+".") if item else EquipmentSlots.label_for(equipment_slot)+" · Empty"
	if not equipment_slot.is_empty() and item:
		tooltip_text=item.display_name+"\n"+ArtTheme.item_properties(item)+"\nDouble-click to unequip."

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_RIGHT or (event.button_index==MOUSE_BUTTON_LEFT and event.double_click):
			activated.emit(bag_index,equipment_slot)
			accept_event()

func _draw() -> void:
	var hovered := is_hovered() or has_focus()
	var frame := ArtTheme.box(Color("182322") if item else Color("101819"),ArtTheme.GOLD if hovered or selected else Color("494b3e"),0)
	frame.set_border_width_all(2)
	draw_style_box(frame,Rect2(Vector2.ZERO,size))
	draw_rect(Rect2(Vector2(4,4),size-Vector2(8,8)),Color("2d3730"),false,1)
	if item:
		draw_texture_rect(ArtTheme.item_icon(item),Rect2(Vector2(7,7),size-Vector2(14,14)),false,Color(1,1,1,0.35) if not blocked_by.is_empty() else Color.WHITE)
		draw_line(Vector2(10,size.y-5),Vector2(size.x-10,size.y-5),ArtTheme.tier_color(item),2)
	elif empty_icon>=0:
		draw_texture_rect(ArtTheme.icon(empty_icon),Rect2(Vector2(12,12),size-Vector2(24,24)),false,Color(0.55,0.64,0.60,0.24))
	else:
		draw_line(size*0.5-Vector2(4,0),size*0.5+Vector2(4,0),Color("323b32"),1)
		draw_line(size*0.5-Vector2(0,4),size*0.5+Vector2(0,4),Color("323b32"),1)
	for point in [Vector2(3,3),Vector2(size.x-4,3),Vector2(3,size.y-4),size-Vector2(4,4)]:
		draw_circle(point,1.2,ArtTheme.GOLD.darkened(0.35))

func _get_drag_data(_position: Vector2) -> Variant:
	if item==null:
		return null
	var preview := TextureRect.new()
	preview.texture=ArtTheme.item_icon(item)
	preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size=Vector2(64,64)
	set_drag_preview(preview)
	return {"inventory":inventory,"index":bag_index,"slot":equipment_slot}

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary or data.get("inventory")!=inventory:
		return false
	if equipment_slot.is_empty():
		return not str(data.get("slot","")).is_empty() and inventory.items.size()<Inventory.CAPACITY
	var index := int(data.get("index",-1))
	return inventory.can_equip(index,equipment_slot)

func _drop_data(_position: Vector2, data: Variant) -> void:
	item_dropped.emit(data,equipment_slot)
func _make_custom_tooltip(_text: String) -> Object:
	var box := VBoxContainer.new()
	if item:
		box.add_child(ArtTheme.label(item.display_name,18,ArtTheme.tier_color(item),true))
		box.add_child(ArtTheme.label(ArtTheme.item_properties(item),14,ArtTheme.PALE))
		box.add_child(ArtTheme.label(item.description,13,ArtTheme.MUTED))
		if not blocked_by.is_empty():
			box.add_child(ArtTheme.label("Both hands occupied",13,ArtTheme.GOLD))
	else:
		box.add_child(ArtTheme.label(EquipmentSlots.label_for(equipment_slot)+" · Empty"))
	return box
