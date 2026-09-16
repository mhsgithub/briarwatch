extends SceneTree
## Deterministic rendered checks; no desktop automation or personal save access.
var session: Node

func _initialize() -> void:
	call_deferred("run")

func capture(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-results/" + file + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://test-results")
	session = load("res://scenes/main.tscn").instantiate()
	root.add_child(session)
	await create_timer(1).timeout
	await capture("01-town")
	session.hud.show_inventory()
	await capture("02-inventory")
	session.hud.close_panel()
	session._interact(session.region.get_node("NPCs/mara"))
	await capture("03-vendor")
	session.hud.close_panel()
	session.player.global_position = Vector3(42, 0.1, -33)
	session.player.health.invulnerable = true
	session.player.recovery_time = 20
	await create_timer(1.5).timeout
	await capture("04-watchtower")
	session.player.recovery_time = 0
	session.player.health.invulnerable = false
	session.player.receive_damage(DamagePacket.new(10000))
	await capture("05-recovery")
	session.hud.close_panel()
	session.queue_free()
	await process_frame
	quit()
