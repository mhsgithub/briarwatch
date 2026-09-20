class_name RegionMap
extends Control
## Cartography derives from authored roads, props and encounter IDs.
var expanded: bool=false
var exploration: Exploration
var quest: QuestLog
var region: Region
var roads: Array[PackedVector2Array]=[]
var trees: PackedVector2Array=[]
var houses: PackedVector2Array=[]
var redraw_timer: float=0

func bind_region(value: Region) -> void:
	region=value
	roads.clear()
	trees.clear()
	houses.clear()
	for child in region.navigation_region.get_children():
		if child.get_script()==preload("res://src/world/road.gd") and child.width<10:
			var line:=PackedVector2Array()
			for p in child.points:
				var world: Vector3=child.to_global(p)
				line.append(Vector2(world.x,world.z))
			roads.append(line)
	for prop in region.get_node("NavigationRegion/Scenery").get_children():
		if prop is DarkThicket:
			trees.append(Vector2(prop.global_position.x,prop.global_position.z))
		if prop is WorldProp:
			var p:=Vector2(prop.global_position.x,prop.global_position.z)
			if prop.kind=="tree": trees.append(p)
			elif prop.kind in ["house","tower"]: houses.append(p)
	if not exploration.changed.is_connected(queue_redraw): exploration.changed.connect(queue_redraw)
	if not quest.changed.is_connected(queue_redraw): quest.changed.connect(queue_redraw)
	queue_redraw()

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	redraw_timer-=delta
	if redraw_timer<=0:
		redraw_timer=0.10
		queue_redraw()

func point(world: Vector2) -> Vector2:
	var margin:=Vector2(74,94) if expanded else Vector2(14,16)
	return margin+(world-region.map_bounds.position)/region.map_bounds.size*(size-margin*2.0)

func _draw() -> void:
	draw_style_box(ArtTheme.box(Color("142322"),Color("8b7754"),0),Rect2(Vector2.ZERO,size))
	draw_rect(Rect2(Vector2(5,5),size-Vector2(10,10)),Color("465143"),false,1)
	if region==null: return
	# Survey grid and subtle contour strokes, with fixed seed for a steady map.
	if expanded:
		for x in range(80,int(size.x)-40,80):
			draw_line(Vector2(x,65),Vector2(x,size.y-65),Color(0.60,0.63,0.47,0.06),1)
		for y in range(80,int(size.y)-40,80):
			draw_line(Vector2(30,y),Vector2(size.x-30,y),Color(0.60,0.63,0.47,0.06),1)
	for tree in trees:
		var p:=point(tree)
		var radius:=3.5 if expanded else 1.5
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-radius),p+Vector2(radius,radius),p+Vector2(-radius,radius)]),Color("314638"))
	for house in houses:
		draw_rect(Rect2(point(house)-Vector2(3,3),Vector2(6,6)),Color("7f8060"))
	for road in roads:
		for i in range(road.size()-1):
			draw_line(point(road[i]),point(road[i+1]),Color("393c2e"),5 if expanded else 3,true)
			draw_line(point(road[i]),point(road[i+1]),Color("a7946b"),2 if expanded else 1,true)
	if region.interior and region.region_id==&"watchtower":
		var outline := PackedVector2Array()
		for i in range(65):
			outline.append(point(Vector2(sin(i * TAU / 64), cos(i * TAU / 64)) * 13.3))
		draw_polyline(outline, Color("a7946b"), 3, true)
	elif region.region_id==&"dark_woods":
		var outline := PackedVector2Array()
		for i in range(65):
			outline.append(point(Vector2(sin(i*TAU/64)*18,-51+cos(i*TAU/64)*18)))
		draw_polyline(outline,Color("a7946b"),2,true)
	elif region.interior:
		draw_rect(Rect2(point(Vector2(-10,-15)),point(Vector2(10,15))-point(Vector2(-10,-15))),Color("a7946b"),false,3)
		for x in [-5.0,5.0]:
			draw_line(point(Vector2(x,-14)),point(Vector2(x,8)),Color("697264"),2)
		draw_line(point(Vector2(-5,-9)),point(Vector2(5,-9)),Color("697264"),2)
	# Fog is painted over every geographic feature, before the objective pin.
	if exploration:
		var top_left:=point(region.map_bounds.position)
		draw_texture_rect(exploration.fog_texture,Rect2(top_left,point(region.map_bounds.end)-top_left),false)
	# Elric marks the objective on your chart even when its surroundings are unknown.
	# Return-to-questgiver is the new objective after the camp has been cleared.
	var objective:=objective_location()
	if not objective.is_empty():
		var p:=point(objective.position)
		draw_arc(p,9,0,TAU,32,ArtTheme.GOLD,2,true)
		draw_circle(p,3,ArtTheme.GOLD)
		var labels: Array[Rect2]=[]
		draw_string(ArtTheme.serif(),_label_position(p,objective.label,labels),objective.label,HORIZONTAL_ALIGNMENT_LEFT,-1,16,ArtTheme.PALE)
	if expanded:
		draw_string(ArtTheme.serif(),Vector2(30,43),region.display_name,HORIZONTAL_ALIGNMENT_LEFT,-1,29,ArtTheme.PALE)
		draw_string(ThemeDB.fallback_font,Vector2(32,65),"FRONTIER CHART  /  BRIARWATCH",HORIZONTAL_ALIGNMENT_LEFT,-1,11,ArtTheme.GOLD)
		draw_string(ThemeDB.fallback_font,Vector2(30,size.y-27),"◉ Quest objective     ·     Explore to chart the March",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ArtTheme.MUTED)
		draw_string(ThemeDB.fallback_font,Vector2(size.x-158,size.y-27),"[ M / Esc ]  Close",HORIZONTAL_ALIGNMENT_LEFT,-1,14,ArtTheme.GOLD)
		var compass:=Vector2(size.x-63,65)
		draw_line(compass-Vector2(0,20),compass+Vector2(0,20),ArtTheme.GOLD,1)
		draw_line(compass-Vector2(20,0),compass+Vector2(20,0),ArtTheme.GOLD,1)
		draw_colored_polygon(PackedVector2Array([compass-Vector2(0,16),compass+Vector2(5,5),compass,compass+Vector2(-5,5)]),ArtTheme.GOLD)
		draw_string(ArtTheme.serif(),compass+Vector2(-5,-25),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,12,ArtTheme.GOLD)
func _label_position(point_value: Vector2,text: String,occupied: Array[Rect2]) -> Vector2:
	var width:=ArtTheme.serif().get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
	var offsets: Array[Vector2]=[Vector2(12,-10),Vector2(12,19),Vector2(-width-12,-10),Vector2(12,-28),Vector2(-width-12,19),Vector2(12,37)]
	for offset in offsets:
		var rect:=Rect2(point_value+offset-Vector2(0,16),Vector2(width,20))
		if not Rect2(Vector2(24,85),size-Vector2(48,145)).encloses(rect): continue
		var clear:=true
		for existing in occupied:
			if existing.grow(3).intersects(rect): clear=false
		if clear:
			occupied.append(rect)
			return point_value+offset
	var fallback:=point_value+Vector2(12,-10)
	occupied.append(Rect2(fallback-Vector2(0,16),Vector2(width,20)))
	return fallback

func objective_location() -> Dictionary:
	if not quest or not quest.accepted or quest.rewarded: return {}
	if quest.cleared:
		var npc := region.get_node_or_null("NPCs/"+quest.definition.handin_npc) as Npc
		if npc: return {"position":Vector2(npc.global_position.x,npc.global_position.z),"label":npc.definition.display_name}
		return _portal_objective(quest.definition.handin_region, "Return to "+quest.definition.handin_npc.capitalize())
	if region.region_id != quest.definition.target_region:
		var entrance:=_portal_objective(quest.definition.target_region, quest.definition.entrance_label)
		return entrance if not entrance.is_empty() else _portal_objective(&"briar_march","Return to the March")
	for encounter in region.get_node("Encounters").get_children():
		if encounter is Encounter and encounter.encounter_id==quest.definition.target_encounter:
			return {"position":Vector2(encounter.global_position.x,encounter.global_position.z),"label":"Quest objective"}
	return {}

func _portal_objective(destination: StringName, label: String) -> Dictionary:
	var portals := region.get_node_or_null("Portals")
	if portals:
		for portal in portals.get_children():
			if portal is RegionPortal and portal.destination == destination:
				return {"position": Vector2(portal.global_position.x, portal.global_position.z), "label": label}
	return {}
