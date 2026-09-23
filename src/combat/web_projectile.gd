class_name WebProjectile
extends Node3D
var source: Enemy
var direction := Vector3.FORWARD
var speed: float = 11.0
var root_seconds: float = 2.0
var lifetime: float = 2.0
var shape := SphereShape3D.new()

func _ready() -> void:
	shape.radius = 0.18
	Geometry.sphere(self,Vector3.ZERO,Vector3(0.34,0.25,0.34),Color("bdc9b8"))
	for i in range(6):
		var angle := i*TAU/6
		Geometry.beam(self,Vector3.ZERO,Vector3(cos(angle)*0.38,sin(angle)*0.24,0),0.025,Color("d7dfcc"))

func _physics_process(delta: float) -> void:
	lifetime -= delta
	var motion := direction*speed*delta
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY,global_position)
	query.motion = motion
	query.collision_mask = 3
	if is_instance_valid(source): query.exclude = [source.get_rid()]
	var space := get_world_3d().direct_space_state
	var hit := space.get_rest_info(query)
	if hit.is_empty():
		var fractions := space.cast_motion(query)
		if fractions[0] < 1:
			query.transform.origin += motion*fractions[1]
			query.motion = Vector3.ZERO
			hit = space.get_rest_info(query)
	if not hit.is_empty():
		var body := instance_from_id(hit.collider_id) as Node
		if body is Player and not body.dead and not body.health.invulnerable:
			body.statuses.apply("root",root_seconds)
			AudioLibrary.play_world(body,body.global_position,"spider_web_impact",1.0)
		queue_free()
		return
	global_position += motion
	rotation += Vector3(1,2,3)*delta
	if lifetime <= 0: queue_free()
