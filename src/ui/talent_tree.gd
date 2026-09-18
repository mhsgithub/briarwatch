class_name TalentTree
extends Control
var progression: CharacterProgression
var tree_name: String
var positions: Dictionary = {}
var selected_id: String
signal selected(id: String)
func _ready() -> void:
	custom_minimum_size = Vector2(600,438)
	for tier in range(1,5):
		var entries: Array = CenturionTalents.all().filter(func(t: Dictionary): return t.tree == tree_name and int(t.tier) == tier)
		for i in range(entries.size()):
			var data: Dictionary = entries[i]
			var center := Vector2(300+(i-(entries.size()-1)*0.5)*196,48+(tier-1)*108)
			positions[data.id] = center
			var tile := TalentTile.new()
			tile.data = data
			tile.progression = progression
			tile.position = center-Vector2(77,47)
			tile.size = Vector2(154,94)
			if data.id==selected_id:
				tile.add_theme_stylebox_override("normal",ArtTheme.box(Color("26332c"),ArtTheme.GOLD,2))
			tile.pressed.connect(func(): selected.emit(data.id))
			add_child(tile)
func _draw() -> void:
	for tier in range(4):
		draw_string(ThemeDB.fallback_font,Vector2(3,52+tier*108),["I","II","III","IV"][tier],HORIZONTAL_ALIGNMENT_LEFT,-1,12,ArtTheme.MUTED)
	for data: Dictionary in CenturionTalents.all():
		if data.tree != tree_name: continue
		for parent: String in data.parents:
			if not positions.has(parent) or not positions.has(data.id): continue
			var a: Vector2 = positions[parent]+Vector2(0,47)
			var b: Vector2 = positions[data.id]-Vector2(0,47)
			var color := ArtTheme.GOLD if progression.mastered(parent) else Color("394743")
			draw_line(a,b,color,2,true)
			draw_circle(b,3,color)
