class_name CharacterPreview
extends SubViewportContainer
## Isolated render of the same ActorVisual used in the world.
var equipment: Dictionary = {}

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	stretch=true
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(220,350)
	viewport.transparent_bg=true
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var actor:=ActorVisual.new()
	actor.equipment=equipment.duplicate()
	actor.rotation.y=PI-0.28
	viewport.add_child(actor)
	var camera:=Camera3D.new()
	viewport.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=2.85
	camera.position=Vector3(2.4,2.2,5)
	camera.look_at(Vector3(0,1.05,0))
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-35,-30,0)
	light.light_color=Color("ffe3ac")
	light.light_energy=1.5
	viewport.add_child(light)
	var fill:=DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(-15,140,0)
	fill.light_color=Color("649a9f")
	fill.light_energy=0.8
	viewport.add_child(fill)
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color(0,0,0,0)
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("7b8991")
	environment.environment.ambient_light_energy=0.6
	viewport.add_child(environment)
