class_name MusicDirector
extends Node
## Selects region music and crossfades without coupling music to combat audio.

const TRACKS := {
	&"town": {"path": "res://assets/music/briarwatch_town.mp3", "volume": -18.0},
	&"hollowmere": {"path": "res://assets/music/hollowmere_marshes.ogg", "volume": -19.0},
	&"hollowmere_camp": {"path": "res://assets/music/hollowmere_camp.ogg", "volume": -19.0},
	&"wilderness": {"path": "res://assets/music/briar_march_wilderness.mp3", "volume": -18.0},
	&"cellars": {"path": "res://assets/music/warwick_cellars.mp3", "volume": -20.0},
	&"dark_woods": {"path": "res://assets/music/dark_woods.ogg", "volume": -20.0},
	&"vanes_den": {"path": "res://assets/music/vanes_den_boss.wav", "volume": -15.0},
}
const FADE_SECONDS := 1.75
const SILENT_DB := -60.0

var session: Node
var current_track: StringName
var current_player: AudioStreamPlayer
var other_player: AudioStreamPlayer
var fade: Tween
var refresh_left: float = 0.0

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	current_player=_make_player()
	other_player=_make_player()
	call_deferred("refresh")

func _make_player() -> AudioStreamPlayer:
	var player:=AudioStreamPlayer.new()
	player.volume_db=SILENT_DB
	add_child(player)
	return player

func _process(delta: float) -> void:
	refresh_left-=delta
	if refresh_left<=0:
		refresh_left=0.2
		refresh()

func refresh() -> void:
	var requested:=requested_track()
	if requested.is_empty() or requested==current_track: return
	_switch_to(requested)

func requested_track() -> StringName:
	if not is_instance_valid(session) or not is_instance_valid(session.region): return &""
	var region: Region=session.region
	if not region.local_music_track.is_empty() and region.local_music_bounds.has_point(Vector2(session.player.position.x,session.player.position.z)):
		return region.local_music_track
	if not region.encounter_music_track.is_empty():
		var den:=region.get_node_or_null("DenEncounter") as DenEncounter
		if den and den.music_active() and not session.player.dead:
			return region.encounter_music_track
	return region.music_track

func _switch_to(id: StringName) -> void:
	if not TRACKS.has(id): return
	if fade and fade.is_valid(): fade.kill()
	var previous:=current_player
	var next:=other_player
	var spec: Dictionary=TRACKS[id]
	next.stop()
	var source:=ResourceLoader.load(str(spec.path),"",ResourceLoader.CACHE_MODE_IGNORE) as AudioStream
	if source==null: return
	next.stream=_looping_copy(source)
	next.volume_db=SILENT_DB
	next.play()
	current_player=next
	other_player=previous
	current_track=id
	fade=create_tween().set_parallel(true)
	fade.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(next,"volume_db",float(spec.volume),FADE_SECONDS)
	if previous.playing:
		fade.tween_property(previous,"volume_db",SILENT_DB,FADE_SECONDS)
		fade.chain().tween_callback(previous.stop)

func _looping_copy(source: AudioStream) -> AudioStream:
	var stream:=source.duplicate() as AudioStream
	if stream is AudioStreamMP3:
		stream.loop=true
	elif stream is AudioStreamOggVorbis:
		stream.loop=true
	elif stream is AudioStreamWAV:
		stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin=0
		stream.loop_end=stream.data.size()/4 if stream.format==AudioStreamWAV.FORMAT_16_BITS and stream.stereo else stream.data.size()/2
	return stream

func _exit_tree() -> void:
	if fade and fade.is_valid(): fade.kill()
	if is_instance_valid(current_player): current_player.stop()
	if is_instance_valid(other_player): other_player.stop()
