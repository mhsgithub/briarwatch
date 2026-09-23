extends SceneTree
## Runs real actor physics and screen-space click handling, also against a PCK.
var session: Node
var checks: int = 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if value: print("PASS: ",message)
	else:
		failures.append(message)
		push_error("FAIL: "+message)
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func click_to(point: Vector3, button: MouseButton = MOUSE_BUTTON_RIGHT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = session.player.camera.unproject_position(point)
	event.global_position = event.position
	Input.parse_input_event(event)
	var release := event.duplicate() as InputEventMouseButton
	release.pressed = false
	Input.parse_input_event(release)
func run() -> void:
	root.size = Vector2i(1440,900)
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await frames(4)
	session.quest.completed.assign(["lions_den"])
	session.hud.show_npc(session.region.get_node("NPCs/elric"))
	session._service("travel",0)
	await frames(12)
	var p: Player = session.player
	p.recovery_time = 10000
	check(p.input_enabled and not paused,"Confirmed travel leaves movement input enabled")
	var start := p.position
	click_to(start+Vector3(3,0,0),MOUSE_BUTTON_LEFT)
	await frames(90)
	check(p.position.distance_to(start)>2.0,"A screen-space click moves the grounded player in Lanternwatch")
	# Disable only incidental opponents; the tested pursuer retains normal AI.
	for actor in session.region.actors.get_children():
		if actor is Enemy:
			actor.set_physics_process(false)
			actor.attack.cancel()
	# Start on the bank, not on the deck. Test both ramps of each bridge.
	p.camera.size = 48
	for pair in [[Vector3(-60,0.1,58),Vector3(-60,0,28)],
		[Vector3(-60,0.1,28),Vector3(-60,0,58)],
		[Vector3(10,0.1,18),Vector3(10,0,-8)],
		[Vector3(10,0.1,-8),Vector3(10,0,18)]]:
		p.click_moving = false
		p.position = pair[0]
		await frames(30)
		click_to(pair[1])
		await frames(440)
		if p.position.distance_to(pair[1])>=1.0:
			print("BRIDGE DEBUG next=",p.navigation.get_next_path_position()," path=",p.navigation.get_current_navigation_path()," target=",p.navigation.target_position)
			for i in range(p.get_slide_collision_count()):
				var collider := p.get_slide_collision(i).get_collider() as Node
				print("BRIDGE COLLISION ",collider.get_path()," normal=",p.get_slide_collision(i).get_normal())
		check(p.position.distance_to(pair[1])<1.0,"Normal click crosses bridge from %s to %s (actual %s)" % [pair[0],pair[1],p.position])
	for species in ["crocodile","marsh_widow","broodqueen"]:
		var enemy: Enemy
		for actor in session.region.actors.get_children():
			if actor is Enemy and actor.definition.id == StringName(species):
				enemy = actor
				break
		# Open camp square isolates locomotion from the encounter's authored cover.
		enemy.position = Vector3(-104,0.1,95)
		enemy.home = enemy.position
		enemy.set_physics_process(true)
		p.position = Vector3(-98,0.1,95)
		p.click_moving = false
		start = enemy.position
		AudioLibrary.last_played.clear()
		await frames(250)
		var profile := str(enemy.definition.audio_profile)
		check(enemy.position.distance_to(start)>3.0 and enemy.position.distance_to(p.position)<3.0,species+" pursues to melee contact using normal AI")
		check(AudioLibrary.last_played.has(profile+"_alert") and AudioLibrary.last_played.has(profile+"_attack"),species+" plays alert and attack cues during live combat")
		check(AudioLibrary.last_played.has(profile+"_step"),species+" plays its own movement sound while pursuing")
		enemy.set_physics_process(false)
		enemy.attack.cancel()
		enemy.position = Vector3(-130,0.1,120)
	# Region switch must not reintroduce stale path height or input state.
	session.travel.enter(&"briar_march")
	await frames(3)
	session.travel.enter(&"hollowmere")
	await frames(30)
	start = p.position
	click_to(start+Vector3(3,0,0))
	await frames(90)
	check(p.position.distance_to(start)>2.0,"Click movement survives leaving and re-entering the marsh")
	print("MARSH MOVEMENT: %d checks, %d failures" % [checks,failures.size()])
	session.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
