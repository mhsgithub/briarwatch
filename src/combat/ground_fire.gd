class_name GroundFire
extends Node3D
## Region-owned: caster death cannot remove a burning patch.
var radius: float = 2.7
var remaining: float = 40
var damage: float = 20
var interval: float = 0.5
var tick_left: float = 0.5
func _ready() -> void:
	add_to_group("ground_fires")
	Geometry.cylinder(self,Vector3(0,0.025,0),radius,0.03,Color("34221c"),radius,24)
	Geometry.ring(self,radius,Color("d95a22"),0.055)
	for i in range(7):
		var fire := FireVisual.new()
		var angle := float(i)*TAU/6
		fire.position = Vector3(cos(angle),0,sin(angle))*radius*0.62 if i<6 else Vector3.ZERO
		fire.flame_height = 0.8
		fire.light_energy = 0.35
		fire.light_range = radius*2
		fire.sound_enabled = i==6
		fire.embers_enabled = i==6
		add_child(fire)
func _physics_process(delta: float) -> void:
	var elapsed := minf(delta,remaining)
	remaining -= elapsed
	tick_left -= elapsed
	while tick_left <= 0.00001:
		tick_left += interval
		for player: Player in get_tree().get_nodes_in_group("player"):
			var offset := player.global_position-global_position
			offset.y=0
			if not player.dead and offset.length() <= radius:
				var ray := PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,player.global_position+Vector3.UP,1)
				if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
					player.receive_ground_fire(DamagePacket.new(damage,null,&"fire"))
	if remaining <= 0: queue_free()
