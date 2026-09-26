class_name MeteorImpact
extends Node3D
var warning_seconds: float = 1.15
var remaining: float
var radius: float = 1.8
var damage: float = 40
var source: Enemy
var rock: MeshInstance3D
var marker: MeshInstance3D
var impacted: bool = false
func _ready() -> void:
	add_to_group("malrec_hazards")
	remaining=warning_seconds
	marker=Geometry.ring(self,radius,Color("c8743f"),0.055)
	marker.position.y=0.06
	marker.material_override=Geometry.material(Color("aa5d30"),0.8)
	rock=Geometry.sphere(self,Vector3(0,10,0),Vector3(0.65,1.1,0.65),Color("a7572d"))
	rock.material_override=Geometry.material(Color("d2793c"),1.1)
	AudioLibrary.play_world(self,global_position,"meteor_warning",1,-4)
func _physics_process(delta: float) -> void:
	remaining-=delta
	if impacted:
		rock.scale*=maxf(0,1-delta*4)
		if remaining<=-0.45: queue_free()
		return
	rock.position.y=maxf(0.35,remaining/warning_seconds*10)
	marker.scale=Vector3.ONE*(0.88+0.12*sin(remaining*18))
	if remaining>0: return
	impacted=true
	AudioLibrary.play_world(self,global_position,"meteor_impact")
	for player: Player in get_tree().get_nodes_in_group("player"):
		var offset:=player.global_position-global_position
		offset.y=0
		if offset.length()>radius: continue
		var ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,player.global_position+Vector3.UP,1)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): continue
		var packet:=DamagePacket.new(damage,source,&"fire")
		packet.attack_kind=&"magic"
		packet.burn_damage=2
		packet.burn_seconds=3
		player.receive_damage(packet)
	rock.scale=Vector3(radius*1.4,0.5,radius*1.4)
