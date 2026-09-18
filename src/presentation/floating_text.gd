class_name FloatingText
extends Label3D
var elapsed: float = 0

static func spawn(parent: Node3D, point: Vector3, amount: float) -> FloatingText:
	# Attach the script before entering the tree so Godot registers _process.
	var label := FloatingText.new()
	label.text = str(int(amount))
	label.font_size = 42
	label.pixel_size = 0.009
	label.modulate = Color("ffe5b0")
	label.outline_modulate = Color("19110e")
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	parent.add_child(label)
	label.global_position = point
	return label

func _process(delta: float) -> void:
	elapsed += delta
	position.y += delta * 0.8
	modulate.a = clampf(1.3 - elapsed, 0, 1)
	if elapsed > 1.3:
		queue_free()
