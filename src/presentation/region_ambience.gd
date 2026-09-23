class_name RegionAmbience
extends Node
## Sparse environmental one-shots; attached to a region so travel clears voices.
@export var cue: String = "marsh_frogs"
@export var minimum_interval: float = 18.0
@export var maximum_interval: float = 36.0
var remaining: float = 8.0
var rng := RandomNumberGenerator.new()
var region: Region
func _ready() -> void:
	region = get_parent() as Region
	rng.randomize()
	remaining = rng.randf_range(8.0,16.0)
func _process(delta: float) -> void:
	remaining -= delta
	if remaining > 0: return
	remaining = rng.randf_range(minimum_interval,maximum_interval)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.dead or region == null: return
	if region.local_music_bounds.has_point(Vector2(player.position.x,player.position.z)): return
	var angle := rng.randf()*TAU
	var point := player.global_position+Vector3(cos(angle),0,sin(angle))*rng.randf_range(14,20)
	var voice := AudioLibrary.play_world(region,point,cue,rng.randf_range(0.88,1.04))
	if voice:
		voice.attenuation_filter_cutoff_hz = 1600.0
		voice.attenuation_filter_db = -18.0
