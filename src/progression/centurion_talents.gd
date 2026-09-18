class_name CenturionTalents
extends RefCounted
## Immutable content catalog. Stable IDs, connections and tuning live in JSON.
static var _content: Dictionary = {}
static var _icons: Dictionary = {}
static func content() -> Dictionary:
	if _content.is_empty():
		_content = JSON.parse_string(FileAccess.get_file_as_string("res://content/progression/centurion.json"))
	return _content
static func all() -> Array:
	return content().talents
static func find(id: String) -> Dictionary:
	for talent: Dictionary in all():
		if talent.id == id: return talent
	return {}
static func icon(index: int) -> Texture2D:
	if _icons.has(index): return _icons[index]
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://assets/ui/talent_atlas.png")
	var cell := atlas.atlas.get_size() / 4.0
	atlas.region = Rect2(Vector2(index % 4, index / 4) * cell, cell)
	atlas.filter_clip = true
	_icons[index] = atlas
	return atlas
