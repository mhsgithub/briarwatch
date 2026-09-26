class_name CryptRitual
extends Node3D
## Resumable story boundary: an interrupted scene replays; a finished one never does.
@export var definition: RitualDefinition = preload("res://content/quests/malrec_ritual.tres")
var session: Node
var region: Region
var soldier: Enemy
var playing: bool = false
var phase: int = -1
var elapsed: float = 0
var old_modes: Dictionary = {}
var old_camera_size: float
var risen_position := Vector3(-2,0.1,-39)
@onready var malrec: NecromancerVisual = $Malrec
@onready var ritual: RitualVisual = $Ritual

func _ready() -> void:
	region = get_parent() as Region
	session = region.get_parent()
	region.initialized.connect(_initialize)

func _initialize() -> void:
	for child in region.actors.get_children():
		if child is Enemy and child.definition.risen: soldier = child
	var complete := bool(session.quest.flags.get("corvin_fallen",false))
	malrec.visible = not complete
	ritual.energy = 0 if complete else 1
	if complete:
		var boss: EnemyDefinition = preload("res://content/enemies/risen_soldier.tres")
		RisenCombat.restore_summon(region,boss.risen.reinforcement_marker)
	if not soldier: return
	soldier.dormant = not complete
	soldier.health.invulnerable = not complete
	soldier.visible = complete
	soldier.collision_layer = 4 if complete else 0
	if not complete: soldier.remove_from_group("enemies")

func music_active() -> bool:
	return playing or (is_instance_valid(soldier) and not soldier.dormant and soldier.health.current>0 and soldier.aggro)

func _physics_process(delta: float) -> void:
	if not playing:
		if session.player.dead or session.quest.flags.get("corvin_fallen",false): return
		if session.quest.definition.id != &"drowned_patrol" or not session.quest.accepted or session.quest.stage_index != 2: return
		if session.player.global_position.distance_to(global_position) < definition.trigger_radius:
			begin()
		return
	elapsed += delta
	var durations := [definition.opening_seconds,definition.silence_seconds,definition.revelation_seconds,definition.death_spell_seconds,definition.teleport_seconds,definition.rising_seconds]
	if elapsed >= float(durations[phase]):
		elapsed = 0
		phase += 1
		if phase >= durations.size(): finish()
		else: _phase_started()

func begin() -> void:
	if playing or not is_instance_valid(soldier) or not is_instance_valid(session.companion): return
	playing = true
	session.hud.close_panel()
	session.player.cinematic_locked = true
	session.player.click_moving = false
	session.player.attack_target = null
	session.player.interact_target = null
	session.player.attack.cancel()
	session.player.velocity = Vector3.ZERO
	session.player.visual.moving = false
	for actor in region.actors.get_children()+[session.player]:
		old_modes[actor] = actor.process_mode
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		if actor is Enemy: actor.attack.cancel()
	session.companion.staged = true
	session.companion.visual.moving = false
	# Escort waits immediately behind the player if it has not caught up yet.
	# Project onto the connected floor so staging never lands in a wall or tomb.
	var point: Vector3 = session.player.global_position+Vector3(-1.4,0,-1.8)
	risen_position = NavigationServer3D.map_get_closest_point(region.get_world_3d().navigation_map,point)
	risen_position.y = 0.1
	session.companion.position = risen_position
	session.companion.visual.rotation.y = 0
	old_camera_size = session.get_node("Camera").size
	session.get_node("Camera").target = $Focus
	session.get_node("Camera").size = 29
	phase = 0
	elapsed = 0
	_phase_started()

func _phase_started() -> void:
	match phase:
		0:
			session.hud.roleplay_line("MALREC VEYNE",definition.opening_line)
			AudioLibrary.play_world(self,malrec.global_position,"malrec_presence")
		1:
			session.hud.roleplay_line("","")
			malrec.channeling = false
			create_tween().tween_property(ritual,"energy",0.0,1.3)
		2:
			session.hud.roleplay_line("MALREC VEYNE",definition.revelation)
		3:
			session.hud.roleplay_line("","")
			malrec.spell = true
			death_spell()
		4:
			malrec.spell = false
			teleport()
		5:
			malrec.hide()
			AudioLibrary.play_world(self,risen_position,"bone_rise")
			burst(risen_position,Color("72894b"),2.0)
			var body: ActorVisual = session.companion.visual
			create_tween().tween_property(body,"rotation:z",0.0,2.5)

func death_spell() -> void:
	AudioLibrary.play_world(self,malrec.global_position,"malrec_death_spell")
	var fx := Node3D.new()
	region.add_child(fx)
	var origin: Vector3 = malrec.global_position+Vector3(0,2.2,0)
	var end := risen_position+Vector3.UP*1.2
	for i in range(8):
		var a := origin.lerp(end,i/8.0)
		var b := origin.lerp(end,(i+1)/8.0)
		if i<7: b += Vector3(sin(i*2.4)*0.22,cos(i*1.7)*0.18,0)
		var beam := Geometry.beam(fx,a,b,0.055,Color("aa83bf"))
		beam.material_override = Geometry.material(Color("947aaf"),1.8)
	var tween := create_tween()
	tween.tween_interval(0.55)
	tween.tween_callback(fx.queue_free)
	burst(risen_position,Color("8971a8"),1.5)
	var body: ActorVisual = session.companion.visual
	create_tween().tween_property(body,"rotation:z",1.55,0.65)
	AudioLibrary.play_world(self,risen_position,"human_death",0.9)

func teleport() -> void:
	AudioLibrary.play_world(self,malrec.global_position,"malrec_teleport")
	burst(malrec.global_position,Color("8b729f"),2.4)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(malrec,"scale",Vector3(0.01,1.8,0.01),1.7)
	tween.tween_property(malrec,"position:y",2.0,1.7)

func burst(point: Vector3, color: Color, radius: float) -> void:
	var root := Node3D.new()
	region.add_child(root)
	root.global_position = point
	for i in range(4):
		var ring := Geometry.ring(root,radius,color,0.04)
		ring.material_override = Geometry.material(color,1.3)
		ring.position.y = 0.1+i*0.55
		var tween := ring.create_tween().set_parallel(true)
		tween.tween_property(ring,"scale",Vector3.ONE*0.05,2.0)
		tween.tween_property(ring,"position:y",3.5,2.0)
	var lifetime := root.create_tween()
	lifetime.tween_interval(2.1)
	lifetime.tween_callback(root.queue_free)

func finish() -> void:
	if not playing: return
	session.quest.flags["corvin_fallen"] = true
	session.quest.advance(&"witness_ritual")
	malrec.hide()
	ritual.energy = 0
	soldier.position = risen_position
	soldier.home = Vector3(0,0.1,-43)
	soldier.dormant = false
	soldier.health.invulnerable = false
	soldier.visible = true
	soldier.collision_layer = 4
	soldier.aggro = true
	if not soldier.is_in_group("enemies"): soldier.add_to_group("enemies")
	soldier.attack.remaining = 1
	restore_control()
	session.player.recovery_time = maxf(2,session.player.recovery_time)
	session._schedule_save()

func restore_control() -> void:
	playing = false
	for actor in old_modes:
		if is_instance_valid(actor): actor.process_mode = old_modes[actor]
	old_modes.clear()
	if not is_instance_valid(session): return
	session.player.cinematic_locked = false
	session.hud.roleplay_line("","")
	session.get_node("Camera").target = session.player
	session.get_node("Camera").size = old_camera_size
	if is_instance_valid(session.companion): session.companion.staged = false

func _exit_tree() -> void:
	if playing and is_instance_valid(session) and not session.is_queued_for_deletion(): restore_control()
