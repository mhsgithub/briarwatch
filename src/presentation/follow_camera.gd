extends Camera3D
@export var target: Node3D
@export var offset := Vector3(16, 23, 20)
var initialized: bool = false

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var desired := target.global_position + offset
	global_position = global_position.lerp(desired, 1 - exp(-delta * 9)) if initialized else desired
	# Aim relative to the camera, not the moving target: follow lag must never
	# change yaw/pitch and cause motion sickness.
	look_at(global_position - offset + Vector3.UP * 0.4)
	initialized = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			size = maxf(15, size - 1.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			size = minf(32, size + 1.5)
