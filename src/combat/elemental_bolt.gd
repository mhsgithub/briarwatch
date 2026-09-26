class_name ElementalBolt
extends Node3D
var direction := Vector3.FORWARD
var speed: float = 23
var damage: float = 25
var element: StringName = &"fire"
var dot_damage: float = 2
var dot_seconds: float = 3
var source: Enemy
var lifetime: float = 3
func _ready() -> void:
	add_to_group("malrec_hazards")
	var color := Color("e18a41") if element==&"fire" else Color("72a657")
	for i in range(5):
		var mote := Geometry.sphere(self,-direction*i*0.16,Vector3.ONE*(0.30-i*0.045),color)
		mote.material_override = Geometry.material(color,1.2)
	AudioLibrary.play_world(self,global_position,"malrec_bolt_"+str(element))
func _physics_process(delta: float) -> void:
	lifetime -= delta
	var end := global_position+direction*speed*delta
	var ray := PhysicsRayQueryParameters3D.create(global_position,end,3)
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		if hit.collider is Player:
			var packet := DamagePacket.new(damage,source,element)
			packet.attack_kind = &"magic"
			if element==&"fire":
				packet.burn_damage=dot_damage
				packet.burn_seconds=dot_seconds
			else:
				packet.poison_damage=dot_damage
				packet.poison_seconds=dot_seconds
			hit.collider.receive_damage(packet)
		AudioLibrary.play_world(self,hit.position,"malrec_bolt_impact")
		queue_free()
	global_position=end
	if lifetime<=0: queue_free()
