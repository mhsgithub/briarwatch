class_name AudioLibrary
extends RefCounted
## Shared sampled cues. Content controls files/mix; audio RNG never affects combat.
static var definitions: Dictionary = {}
static var streams: Dictionary = {}
static var last_variant: Dictionary = {}
static var last_played: Dictionary = {}
static var rng := RandomNumberGenerator.new()
const MAX_WORLD_VOICES := 24

static func initialize() -> void:
	if not definitions.is_empty(): return
	definitions = JSON.parse_string(FileAccess.get_file_as_string("res://content/audio/cues.json"))
	rng.randomize()

static func sample(id: String) -> AudioStream:
	initialize()
	if not definitions.has(id): return null
	var files: Array = definitions[id].files
	var previous: int = last_variant.get(id,-1)
	var index := rng.randi_range(0,files.size()-1)
	if files.size()>1 and index==previous: index=(index+1)%files.size()
	last_variant[id]=index
	var path: String = "res://assets/audio/"+str(files[index])+".wav"
	if not streams.has(path): streams[path]=load(path)
	return streams[path]

static func _available(id: String) -> bool:
	initialize()
	if not definitions.has(id): return false
	var time := Time.get_ticks_msec()
	if time-int(last_played.get(id,-10000)) < float(definitions[id].get("cooldown",0.04))*1000: return false
	last_played[id]=time
	return true

static func play_world(parent: Node3D, point: Vector3, id: String, pitch: float=1.0, gain: float=0.0) -> AudioStreamPlayer3D:
	initialize()
	if not definitions.has(id): return null
	var tree := parent.get_tree()
	var listener := tree.get_first_node_in_group("player") as Node3D
	var distance: float = definitions[id].get("range",25.0)
	if listener and listener.global_position.distance_squared_to(point)>distance*distance: return null
	if tree.get_nodes_in_group("transient_audio").size()>=MAX_WORLD_VOICES or not _available(id): return null
	var voice := WorldVoice.new()
	voice.stream=sample(id)
	voice.volume_db=float(definitions[id].volume_db)+gain
	voice.pitch_scale=pitch*rng.randf_range(0.97,1.03)
	voice.max_distance=distance
	voice.unit_size=5.0
	parent.add_child(voice)
	voice.add_to_group("transient_audio")
	voice.global_position=point
	voice.finished.connect(voice.queue_free)
	voice.play()
	return voice

static func play_ui(parent: Node, id: String) -> AudioStreamPlayer:
	if not _available(id): return null
	if parent.get_tree().get_nodes_in_group("interface_audio").size()>=6: return null
	var voice:=InterfaceVoice.new()
	voice.process_mode=Node.PROCESS_MODE_ALWAYS
	voice.stream=sample(id)
	voice.volume_db=definitions[id].volume_db
	voice.pitch_scale=rng.randf_range(0.98,1.02)
	parent.add_child(voice)
	voice.add_to_group("interface_audio")
	voice.finished.connect(voice.queue_free)
	voice.play()
	return voice

static func attach_fire(parent: Node3D) -> void:
	var voice:=WorldVoice.new()
	var stream:=sample("fire").duplicate() as AudioStreamWAV
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin=0
	stream.loop_end=stream.data.size()/2
	voice.stream=stream
	voice.volume_db=definitions.fire.volume_db
	voice.max_distance=12
	voice.unit_size=3
	parent.add_child(voice)
	voice.play(fposmod(parent.global_position.x*0.13,stream.get_length()))

class WorldVoice extends AudioStreamPlayer3D:
	func _exit_tree() -> void:
		stop()

class InterfaceVoice extends AudioStreamPlayer:
	func _exit_tree() -> void:
		stop()
