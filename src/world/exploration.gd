class_name Exploration
extends Node
## Persistent survey cells belong to gameplay state, not to whether M is open.
signal changed
@export var cell_size: float = 2.0
@export var reveal_radius: float = 18.0
var bounds: Rect2
var dimensions: Vector2i
var visited := PackedByteArray()
var player: Node3D
var refresh_left: float = 0.0
var fog_image: Image
var fog_texture: ImageTexture

func configure(area: Rect2, actor: Node3D) -> void:
	bounds = area
	player = actor
	dimensions = Vector2i(ceil(area.size.x / cell_size), ceil(area.size.y / cell_size))
	visited.resize(dimensions.x * dimensions.y)
	visited.fill(0)
	fog_image = Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	fog_image.fill(Color("101918"))
	fog_texture = ImageTexture.create_from_image(fog_image)

func _physics_process(delta: float) -> void:
	refresh_left -= delta
	if refresh_left <= 0 and is_instance_valid(player):
		refresh_left = 0.2
		reveal(Vector2(player.global_position.x, player.global_position.z))

func reveal(world: Vector2) -> void:
	var center := Vector2i((world - bounds.position) / cell_size)
	var radius := ceili(reveal_radius / cell_size)
	var dirty := false
	for y in range(maxi(0,center.y-radius),mini(dimensions.y,center.y+radius+1)):
		for x in range(maxi(0,center.x-radius),mini(dimensions.x,center.x+radius+1)):
			var index := y * dimensions.x + x
			var cell_center := bounds.position + (Vector2(x,y)+Vector2.ONE*0.5)*cell_size
			if visited[index] == 0 and cell_center.distance_squared_to(world) <= reveal_radius * reveal_radius:
				visited[index] = 1
				fog_image.set_pixel(x,y,Color(0,0,0,0))
				dirty = true
	if dirty:
		fog_texture.update(fog_image)
		changed.emit()

func is_explored(world: Vector2) -> bool:
	if not bounds.has_point(world): return false
	var cell := Vector2i((world-bounds.position)/cell_size)
	return visited[cell.y*dimensions.x+cell.x] != 0

func serialize() -> Dictionary:
	var cells: Array[int] = []
	for i in range(visited.size()):
		if visited[i]: cells.append(i)
	return {"bounds":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"cell_size":cell_size,"cells":cells}

func restore(value: Variant) -> void:
	visited.fill(0)
	fog_image.fill(Color("101918"))
	if value is Dictionary and value.get("bounds",[]) == serialize().bounds and float(value.get("cell_size",0)) == cell_size:
		var cells: Variant = value.get("cells",[])
		if cells is Array:
			for entry in cells:
				if not (entry is int or entry is float): continue
				var index := int(entry)
				if index >= 0 and index < visited.size() and float(entry)==index:
					visited[index] = 1
					fog_image.set_pixel(index % dimensions.x,index / dimensions.x,Color(0,0,0,0))
	fog_texture.update(fog_image)
	changed.emit()
