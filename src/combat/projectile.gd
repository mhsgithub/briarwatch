extends Node3D

var direction: Vector3
var speed: float = 17
var packet: DamagePacket
var target_group: StringName
var lifetime: float = 3

func _ready() -> void:
	look_at(global_position + direction, Vector3.UP)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	var end := global_position + direction * speed * delta
	var query := PhysicsRayQueryParameters3D.create(global_position, end, 7)
	if is_instance_valid(packet.source):
		query.exclude = [packet.source.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var body: Node = hit.collider
		if body.is_in_group(target_group) and body.has_method("receive_damage"):
			body.receive_damage(packet)
		AudioLibrary.play_world(get_parent(),hit.position,"arrow_impact")
		queue_free()
	global_position = end
	if lifetime <= 0:
		queue_free()
