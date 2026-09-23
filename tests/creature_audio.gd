extends SceneTree
## Isolated marsh audio regression: real resources, events, voices and web cast.
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ",label)
	else:
		failures.append(label)
		push_error("FAIL: "+label)
func run() -> void:
	var session: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await physics_frame
	session.travel.enter(&"hollowmere")
	await physics_frame
	var player: Player = session.player
	AudioLibrary.initialize()
	player.recovery_time = 9999
	for actor in session.region.actors.get_children():
		if actor is Enemy: actor.set_physics_process(false)
	var forbidden := {}
	for id in ["wolf_growl","wolf_bite","wolf_hurt","wolf_death","human_effort","human_hurt","human_death","bow","arrow_impact","impact","paw","step","pack","gear"]:
		for file in AudioLibrary.definitions[id].files: forbidden[str(file)] = true
	for profile in ["reptile","spider"]:
		for event in ["alert","attack","hurt","death","step"]:
			var id: String = profile+"_"+event
			var definition: Dictionary = AudioLibrary.definitions[id]
			check(not definition.files.is_empty(),id+" has recordings")
			for file in definition.files:
				check(str(file).begins_with(profile+"_") and not forbidden.has(str(file)),id+" uses a dedicated recording")
				var stream := load("res://assets/audio/"+str(file)+".wav") as AudioStream
				check(stream != null and stream.get_length()>0.2 and stream.get_length()<3.0,id+" decodes a short game cue")
	for id in ["spider_web","spider_web_cast","spider_web_impact"]:
		var stream := AudioLibrary.sample(id)
		check(stream != null and stream.get_length()>0.2,"Spider web event plays its own recording: "+id)
	for species in ["crocodile","marsh_widow","broodqueen"]:
		var enemy: Enemy
		for actor in session.region.actors.get_children():
			if actor is Enemy and actor.definition.id==StringName(species):
				enemy=actor
				break
		enemy.position=player.position+Vector3(3,0,0)
		var audio: GameAudio=enemy.get_node("Audio")
		var profile := str(enemy.definition.audio_profile)
		AudioLibrary.last_played.clear()
		audio.last_aggro=false
		enemy.aggro=true
		audio._physics_process(0.02)
		check(AudioLibrary.last_played.has(profile+"_alert"),species+" plays its own alert")
		AudioLibrary.last_played.clear()
		audio._attack()
		check(AudioLibrary.last_played.has(profile+"_attack"),species+" plays its own melee attack")
		AudioLibrary.last_played.clear()
		audio._hurt(3)
		check(AudioLibrary.last_played.has(profile+"_hurt") and not AudioLibrary.last_played.has("impact"),species+" uses a unique hurt voice")
		AudioLibrary.last_played.clear()
		audio._death()
		check(AudioLibrary.last_played.has(profile+"_death"),species+" plays its own death voice")
		if species=="broodqueen":
			check(audio.profile()==&"spider" and is_equal_approx(enemy.web_attack.voice_pitch(),0.884),"Broodqueen web voice is deeper than a Widow")
	session.queue_free()
	await process_frame
	print("CREATURE AUDIO: %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
