class_name ProximityFade
extends Node
## Compatibility-renderer friendly local fade. Never changes shared materials
## or collision. Only nearby props allocate temporary transparent materials.
var meshes: Array[MeshInstance3D] = []
var originals: Array[Material] = []
var faded: Array[StandardMaterial3D] = []
var bounds := AABB()
var player: Node3D
var opacity: float = 1.0
var wanted: float = 1.0
var refresh_left: float = 0.0

func _ready() -> void:
	var prop := get_parent() as Node3D
	var first := true
	for child in prop.find_children("*","MeshInstance3D",true,false):
		var mesh := child as MeshInstance3D
		if not mesh.material_override is StandardMaterial3D: continue
		meshes.append(mesh)
		originals.append(mesh.material_override)
		var local_box: AABB = (prop.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
		bounds=local_box if first else bounds.merge(local_box)
		first=false

func proximity_opacity(point: Vector3) -> float:
	var local: Vector3 = get_parent().to_local(point)
	var nearest:=Vector2(clampf(local.x,bounds.position.x,bounds.end.x),clampf(local.z,bounds.position.z,bounds.end.z))
	var distance:=Vector2(local.x,local.z).distance_to(nearest)
	return 0.18 if distance<0.65 else 1.0

func _process(delta: float) -> void:
	refresh_left-=delta
	if refresh_left<=0:
		refresh_left=0.1
		if not is_instance_valid(player):
			player=get_tree().get_first_node_in_group("player") as Node3D
		wanted=proximity_opacity(player.global_position) if is_instance_valid(player) else 1.0
	if is_equal_approx(opacity,wanted): return
	opacity=move_toward(opacity,wanted,delta*4.5)
	if faded.is_empty() and opacity<1.0:
		for i in range(meshes.size()):
			var material:=originals[i].duplicate() as StandardMaterial3D
			material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
			faded.append(material)
			meshes[i].material_override=material
	for material in faded:
		material.albedo_color.a=opacity
	if opacity>=1.0:
		for i in range(meshes.size()):
			meshes[i].material_override=originals[i]
		faded.clear()
