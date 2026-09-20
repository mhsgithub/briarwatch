extends SceneTree
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks+=1
	if value: print("PASS: ",message)
	else:
		failures.append(message)
		push_error("FAIL: "+message)
func run() -> void:
	var session: Node=load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await process_frame
	await process_frame
	var music: MusicDirector=session.music
	check(music.current_track==&"town","Town starts with calm town music")
	check(music.current_player.playing and music.current_player.stream.get_length()>30,"Town track decodes and plays")
	for id: StringName in MusicDirector.TRACKS:
		var stream:=load(str(MusicDirector.TRACKS[id].path)) as AudioStream
		check(stream!=null and stream.get_length()>30,"Music asset decodes: "+str(id))
	session.player.position=Vector3(0,0.1,0)
	music.refresh()
	check(music.current_track==&"wilderness","Leaving town crossfades to wilderness music")
	session.travel.enter(&"watchtower")
	music.refresh()
	check(music.current_track==&"cellars","Watchtower uses the frightening interior music")
	session.travel.enter(&"briar_march")
	session.travel.enter(&"warwick_cellars")
	music.refresh()
	check(music.current_track==&"cellars","Warwick cellars use the interior music")
	session.travel.enter(&"briar_march")
	session.travel.enter(&"dark_woods")
	music.refresh()
	check(music.current_track==&"dark_woods","Dark Woods has its own exploration music")
	var den:=session.region.get_node("DenEncounter") as DenEncounter
	den.garrick.aggro=true
	den._physics_process(0)
	music.refresh()
	check(den.started and music.current_track==&"vanes_den","Garrick aggro starts boss music")
	session.player.dead=true
	music.refresh()
	check(music.current_track==&"dark_woods","Player death ends boss music")
	session.player.dead=false
	den.garrick.health.current=0
	den.released=true
	den.bloodfang.health.current=0
	music.refresh()
	check(music.current_track==&"dark_woods","Defeating both bosses restores Dark Woods music")
	check(music.current_player!=music.other_player and music.other_player.playing,"Music changes use two-player crossfades")
	print("MUSIC: %d checks, %d failures" % [checks,failures.size()])
	session.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit(0 if failures.is_empty() else 1)
