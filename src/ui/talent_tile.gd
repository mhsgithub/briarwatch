class_name TalentTile
extends Button
var data: Dictionary
var progression: CharacterProgression
func _ready() -> void:
	custom_minimum_size = Vector2(154,94)
	tooltip_text = data.description
func _get_drag_data(_position: Vector2) -> Variant:
	if not data.active or progression.rank(data.id) == 0: return null
	var preview := TextureRect.new()
	preview.texture = CenturionTalents.icon(int(data.icon))
	preview.custom_minimum_size = Vector2(52,52)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	set_drag_preview(preview)
	return {"progression":progression,"talent_id":data.id}
func _draw() -> void:
	var learned := progression.rank(data.id)>0
	draw_texture_rect(CenturionTalents.icon(int(data.icon)),Rect2(50,5,54,54),false,Color.WHITE if learned or progression.available(data.id) else Color(0.43,0.48,0.46))
	draw_string(get_theme_font("font"),Vector2(3,74),data.name,HORIZONTAL_ALIGNMENT_CENTER,148,13,ArtTheme.PALE if learned else ArtTheme.MUTED)
	draw_string(ThemeDB.fallback_font,Vector2(3,89),"%d / %d" % [progression.rank(data.id),int(data.max_rank)],HORIZONTAL_ALIGNMENT_CENTER,148,11,ArtTheme.GOLD)
