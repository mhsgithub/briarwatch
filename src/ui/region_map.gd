class_name RegionMap
extends Control
var player: Player
var expanded: bool = false
var region: Region
var roads: Array[PackedVector2Array] = []
var points_of_interest: Array[Dictionary] = []

func bind_region(value: Region) -> void:
	region = value
	roads.clear()
	points_of_interest.clear()
	for child in region.navigation_region.get_children():
		if child.get_script() == preload("res://src/world/road.gd"):
			var line := PackedVector2Array()
			for p in child.points:
				var world: Vector3 = child.to_global(p)
				line.append(Vector2(world.x, world.z))
			roads.append(line)
	var spawn := region.player_spawn.global_position
	points_of_interest.append({"name": "Briarwatch", "position": Vector2(spawn.x, spawn.z), "friendly": true})
	for encounter in region.get_node("Encounters").get_children():
		if encounter is Encounter and not encounter.markers().is_empty() and encounter.markers()[0].definition.behavior != "wolf":
			points_of_interest.append({"name": encounter.display_name, "position": Vector2(encounter.global_position.x, encounter.global_position.z), "friendly": false})

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func point(world: Vector2) -> Vector2:
	return (world - region.map_bounds.position) / region.map_bounds.size * size

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("142423"))
	draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color("756b4c"), false, 1)
	if region == null:
		return
	for road in roads:
		for i in range(road.size() - 1):
			draw_line(point(road[i]), point(road[i + 1]), Color("98866a"), 2)
	for poi in points_of_interest:
		var color := Color("80aea1") if poi.friendly else Color("bd765b")
		draw_circle(point(poi.position), 6, color)
		if expanded:
			draw_string(ThemeDB.fallback_font, point(poi.position) + Vector2(10, -10), poi.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, color.lightened(0.35))
	draw_string(ThemeDB.fallback_font, Vector2(12, 23), region.display_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("dbc69c"))
	if is_instance_valid(player):
		var p := point(Vector2(player.global_position.x, player.global_position.z))
		draw_circle(p, 4, Color("f7e6ab"))
		draw_arc(p, 7, 0, TAU, 24, Color("f7e6ab"), 1.2)
