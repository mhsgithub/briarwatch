class_name ActionTile
extends Button
signal assign_requested(index: int)
var player: Player
var catalog: ContentCatalog
var index: int
var item: ItemDefinition
var talent: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pressed.connect(func():
		if player.dead: return
		if player.actions.slots[index].is_empty():
			assign_requested.emit(index)
		elif not player.dead:
			if talent.is_empty() or player.input_enabled: player.actions.activate(index))
	player.inventory.changed.connect(refresh)
	player.actions.changed.connect(refresh)
	refresh()

func refresh() -> void:
	var binding := player.actions.slots[index]
	item = catalog.find_item(binding.get("id", "")) if binding.get("kind", "") == "item" else null
	talent = CenturionTalents.find(binding.get("id","")) if binding.get("kind","") == "ability" else {}
	tooltip_text = (item.display_name + "\n" + item.description + "\nRight-click to clear") if item else "Assign a consumable"
	if not talent.is_empty(): tooltip_text = talent.name+"\n"+talent.description+"\nRight-click to clear"
	queue_redraw()

func _process(_delta: float) -> void:
	if not talent.is_empty(): queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		player.actions.clear(index)
		accept_event()

func _draw() -> void:
	if not talent.is_empty():
		draw_texture_rect(CenturionTalents.icon(int(talent.icon)),Rect2(6,4,52,52),false)
		var remaining := player.abilities.remaining(talent.id)
		if remaining > 0:
			draw_rect(Rect2(5,4,54,52),Color(0,0,0,0.65))
			draw_string(ThemeDB.fallback_font,Vector2(9,34),str(ceili(remaining)),HORIZONTAL_ALIGNMENT_CENTER,46,20,ArtTheme.PALE)
		elif not player.abilities.ready_reason(talent.id).is_empty():
			draw_rect(Rect2(5,4,54,52),Color(0,0,0,0.4))
	if item:
		var count := 0
		for entry in player.inventory.items:
			if entry.id == item.id:
				count += 1
		draw_texture_rect(ArtTheme.item_icon(item), Rect2(10, 6, 44, 44), false, Color.WHITE if count > 0 else Color(0.5,0.5,0.5,0.5))
		draw_string(ThemeDB.fallback_font, Vector2(43,56),str(count),HORIZONTAL_ALIGNMENT_RIGHT,16,12,ArtTheme.PALE)
	draw_string(ThemeDB.fallback_font,Vector2(6,57),str(index+1),HORIZONTAL_ALIGNMENT_LEFT,-1,11,ArtTheme.MUTED)

func _get_drag_data(_point: Vector2) -> Variant:
	if player.actions.slots[index].is_empty():
		return null
	var preview := TextureRect.new()
	preview.texture = CenturionTalents.icon(int(talent.icon)) if not talent.is_empty() else ArtTheme.item_icon(item)
	preview.custom_minimum_size = Vector2(48,48)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	set_drag_preview(preview)
	return {"loadout": player.actions, "action_index": index}

func _can_drop_data(_point: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	if data.get("loadout") == player.actions:
		return true
	if data.get("progression") == player.progression:
		var entry := CenturionTalents.find(str(data.get("talent_id","")))
		return not entry.is_empty() and entry.active and player.progression.rank(entry.id)>0
	var bag_index := int(data.get("index",-1))
	return data.get("inventory") == player.inventory and bag_index >= 0 and bag_index < player.inventory.items.size() and player.inventory.items[bag_index].slot == "consumable"

func _drop_data(_point: Vector2, data: Variant) -> void:
	if data.has("action_index"):
		player.actions.swap(data.action_index,index)
	elif data.has("talent_id"):
		player.actions.assign_ability(index,str(data.talent_id))
	else:
		player.actions.assign_item(index,player.inventory.items[data.index])
