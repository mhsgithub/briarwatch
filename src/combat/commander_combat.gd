class_name CommanderCombat
extends Node
## Enemy-composed special attacks. Locked aim and geometry use AttackComponent.
var actor: Enemy
var special: AttackComponent
var cleave_left: float = 3.0
var kick_left: float = 6.0
var recovery_left: float = 0.0
var warning: MeshInstance3D
var kind: String = ""
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	special = AttackComponent.new()
	special.name = "SpecialAttack"
	special.target_group = &"player"
	actor.add_child(special)
	special.resolved.connect(_resolved)

func step(delta: float) -> bool:
	if not actor.aggro or actor.returning or actor.target.dead:
		cancel()
		return false
	cleave_left -= delta
	kick_left -= delta
	recovery_left = maxf(0, recovery_left - delta)
	if special.pending:
		if is_instance_valid(warning):
			warning.transparency = 0.15 + 0.18 * sin(special.windup_left * 22)
		return true
	if recovery_left > 0: return true
	if actor.attack.pending: return false
	var offset := actor.target.global_position - actor.global_position
	if not actor._has_sight(actor.target.global_position): return false
	var kit := actor.definition.commander
	if cleave_left <= 0 and offset.length() <= kit.cleave.reach + 1.0:
		start("cleave", offset)
		cleave_left = rng.randf_range(kit.cleave_cooldown.x, kit.cleave_cooldown.y)
		return true
	if kick_left <= 0 and offset.length() <= kit.kick.reach:
		start("kick", offset)
		kick_left = rng.randf_range(kit.kick_cooldown.x, kit.kick_cooldown.y)
		return true
	return false

func start(ability: String, direction: Vector3) -> void:
	kind = ability
	actor.attack.cancel()
	special.cancel()
	special.definition = actor.definition.commander.cleave if kind == "cleave" else actor.definition.commander.kick
	special.minimum_damage = 1.0 if kind == "cleave" else 0.0
	actor._face(direction)
	special.request(direction)
	actor.visual.special_started(kind, special.definition.windup)
	AudioLibrary.play_world(actor, actor.global_position + Vector3.UP, "boss_roar" if kind == "cleave" else "human_effort", 0.74, -2)
	_show_warning()

func _show_warning() -> void:
	if is_instance_valid(warning): warning.queue_free()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var arc := deg_to_rad(special.definition.arc_degrees)
	for i in range(32):
		var a := -arc / 2 + arc * i / 32
		var b := -arc / 2 + arc * (i + 1) / 32
		for vertex in [Vector3.ZERO, Vector3(sin(a), 0, -cos(a)) * special.definition.reach, Vector3(sin(b), 0, -cos(b)) * special.definition.reach]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	warning = Geometry.mesh_node(actor, surface.commit(), Vector3(0, 0.07, 0), Color("cf6136"))
	warning.rotation.y = actor.visual.rotation.y
	var material := Geometry.material(Color(0.85, 0.25, 0.08, 0.38), 0.6).duplicate() as StandardMaterial3D
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	warning.material_override = material
	warning.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _resolved() -> void:
	if is_instance_valid(warning): warning.queue_free()
	recovery_left = 0.65 if kind == "cleave" else 0.4
	actor.attack.remaining = recovery_left + 0.3
	AudioLibrary.play_world(actor, actor.global_position + Vector3.UP, "heavy_cleave" if kind == "cleave" else "impact", 0.72, 1)
	if kind == "cleave": AudioLibrary.play_world(actor, actor.global_position, "metal", 0.8, -4)

func cancel() -> void:
	special.cancel()
	recovery_left = 0
	if is_instance_valid(warning): warning.queue_free()
	actor.visual.special_left = 0
