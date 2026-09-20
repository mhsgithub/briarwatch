class_name KnifeProjectile
extends Node3D
## A blade-sized swept sphere, with world/player collision and no area damage.
var direction := Vector3.FORWARD
var speed: float = 15.5
var packet: DamagePacket
var lifetime: float = 2.5
var radius: float = 0.055
var shape := SphereShape3D.new()
func _ready() -> void:
	add_to_group("brutus_knives")
	shape.radius=radius
	var blade := Geometry.box(self,Vector3(0,0,-0.10),Vector3(0.09,0.045,0.46),Color("c6cdbd"))
	blade.material_override=Geometry.material(Color("bcc8c4"),0.35)
	Geometry.box(self,Vector3(0,0,0.21),Vector3(0.075,0.07,0.20),Color("45332d"))
	Geometry.box(self,Vector3(0,0,0.1),Vector3(0.19,0.05,0.04),Color("c5b38b"))
func _physics_process(delta: float) -> void:
	if is_queued_for_deletion(): return
	look_at(global_position+direction,Vector3.UP)
	lifetime-=delta
	var motion := direction*speed*delta
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape=shape
	query.margin=0.001
	query.transform=Transform3D(Basis.IDENTITY,global_position+direction*0.32)
	query.motion=motion
	query.collision_mask=3
	if is_instance_valid(packet.source): query.exclude=[packet.source.get_rid()]
	var space := get_world_3d().direct_space_state
	var hit := space.get_rest_info(query)
	if hit.is_empty():
		var fractions := space.cast_motion(query)
		if fractions[0]<1.0:
			query.transform.origin+=motion*fractions[1]
			query.motion=Vector3.ZERO
			hit=space.get_rest_info(query)
	if not hit.is_empty():
		var body := instance_from_id(hit.collider_id) as Node
		if is_instance_valid(body) and body.is_in_group("player"):
			body.receive_damage(packet)
		AudioLibrary.play_world(get_parent(),hit.point,"arrow_impact",1.2)
		queue_free()
		return
	global_position+=motion
	if lifetime<=0: queue_free()
