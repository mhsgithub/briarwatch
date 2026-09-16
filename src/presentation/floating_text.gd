extends Label3D
var elapsed: float = 0

func _process(delta: float) -> void:
	elapsed += delta
	position.y += delta * 0.8
	modulate.a = clampf(1.3 - elapsed, 0, 1)
	if elapsed > 1.3:
		queue_free()
