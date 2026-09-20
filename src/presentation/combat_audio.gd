class_name GameAudio
extends Node
## Actor signals select recorded foley and vocals; no runtime waveform generation.
var step_distance: float = 0.0
var previous_position: Vector3
var vocal_cooldown: float = 0.0
var hurt_cooldown: float = 0.0
var last_aggro: bool = false
var actor: CharacterBody3D

func _ready() -> void:
	actor=get_parent()
	previous_position=actor.global_position
	actor.get_node("Attack").resolved.connect(_attack)
	actor.get_node("Health").damaged.connect(_hurt)
	actor.get_node("Health").died.connect(_death)

func profile() -> StringName:
	return actor.definition.audio_profile if actor is Enemy else &"centurion"

func _voice(id: String, gain: float=0.0) -> void:
	var pitch:=0.93 if profile()==&"centurion" else 1.03
	if profile()==&"wolf": pitch=1.0
	if actor is Enemy and actor.definition.brute: pitch=0.73
	if actor is Enemy: pitch *= actor.definition.voice_pitch
	AudioLibrary.play_world(actor,actor.global_position+Vector3.UP,id,pitch,gain)

func _attack() -> void:
	if profile()==&"wolf":
		_voice("wolf_bite")
	elif actor.get_node("Attack").definition.projectile:
		_voice("bow")
	elif actor is Enemy and actor.definition.brute:
		_voice("brutus_punch")
		_voice("human_effort",-5)
	else:
		_voice("swing")
		if vocal_cooldown<=0:
			_voice("human_effort",-5)
			vocal_cooldown=1.6

func _hurt(_amount: float) -> void:
	_voice("impact")
	var health: HealthComponent=actor.get_node("Health")
	if health.armor>0: _voice("metal",-8)
	# Death gets its own reaction rather than stacking a hurt grunt and death cry.
	if health.current<=0 or hurt_cooldown>0: return
	_voice("wolf_hurt" if profile()==&"wolf" else "human_hurt")
	hurt_cooldown=0.3
	vocal_cooldown=0.9

func _death() -> void:
	_voice("wolf_death" if profile()==&"wolf" else "human_death")
	_voice("gear",-5)

func _physics_process(delta: float) -> void:
	vocal_cooldown=maxf(0,vocal_cooldown-delta)
	hurt_cooldown=maxf(0,hurt_cooldown-delta)
	var displacement:=Vector2(actor.global_position.x-previous_position.x,actor.global_position.z-previous_position.z).length()
	previous_position=actor.global_position
	if actor.get_node("Health").current<=0: return
	if actor is Enemy:
		if actor.aggro and not last_aggro and vocal_cooldown<=0:
			_voice("wolf_growl" if profile()==&"wolf" else "human_effort",-3)
			vocal_cooldown=1.5
		last_aggro=actor.aggro
	if actor is Player: return # Player footsteps deliberately silent; enemy foley remains.
	# Ignore teleports, stationary animation and falling; movement drives cadence.
	if displacement<0.002 or displacement>1.5 or not actor.is_on_floor():
		return
	step_distance+=displacement
	var stride:=0.85 if profile()==&"wolf" else 1.55
	if step_distance>=stride:
		step_distance=fmod(step_distance,stride)
		_voice("paw" if profile()==&"wolf" else "step",-4 if actor is Enemy else 0)

static func play_drop(parent: Node3D, point: Vector3, gear: bool) -> void:
	AudioLibrary.play_world(parent,point+Vector3.UP*0.3,"gear" if gear else "gold")
