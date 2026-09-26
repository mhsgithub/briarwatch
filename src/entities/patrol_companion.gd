class_name PatrolCompanion
extends CharacterBody3D
## Friendly escort: no health, targeting group or attack component.
var definition: NpcDefinition = preload("res://content/npcs/corvin.tres")
var player: Player
var following: bool = false
var staged: bool = false
var visual: ActorVisual
var navigation: NavigationAgent3D
var label: Label3D
var repath: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.6
	collider.shape = shape
	collider.position.y = 0.8
	add_child(collider)
	visual = ActorVisual.new()
	visual.style = "corvin"
	add_child(visual)
	navigation = NavigationAgent3D.new()
	navigation.path_desired_distance = 0.4
	navigation.target_desired_distance = 1.8
	navigation.path_height_offset = NavigationServer3D.map_get_cell_height(get_world_3d().navigation_map)
	add_child(navigation)
	label = Geometry.label(self,definition.display_name,Vector3(0,2.55,0),Color("b3cdb5"),23)
	add_to_group("interactables")
	set_following(following)

func set_following(value: bool) -> void:
	following = value
	if not is_instance_valid(visual): return
	visual.rotation.z = 0 if value else -0.32
	visual.position.y = 0 if value else -0.25

func interaction_name() -> String:
	return "Speak with Sergeant Corvin Marr"

func _physics_process(delta: float) -> void:
	if staged or not following or not is_instance_valid(player) or player.dead: return
	velocity = Vector3(0,-2,0)
	repath -= delta
	if global_position.distance_to(player.global_position) > 2.6:
		if repath <= 0:
			navigation.target_position = player.global_position
			repath = 0.3
		if NavigationServer3D.map_get_iteration_id(get_world_3d().navigation_map) > 0:
			var direction := navigation.get_next_path_position()-global_position
			direction.y = 0
			velocity += direction.normalized()*maxf(5.25,player.move_speed*player.abilities.movement_multiplier())
			if direction.length() > 0.1: visual.rotation.y = atan2(-direction.x,-direction.z)
	move_and_slide()
	visual.moving = Vector2(velocity.x,velocity.z).length() > 0.1
