class_name SaveStore
extends RefCounted
## Versioned JSON. Validate container types before consumers read them.
const VERSION := 1
const PATH := "user://briarwatch_v1.json"

static func write(data: Dictionary, path: String = PATH) -> Error:
	data["version"] = VERSION
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	# Preserve the last successful save before replacing it.
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path, path + ".bak")
	return DirAccess.rename_absolute(path + ".tmp", path)

static func read(path: String = PATH) -> Dictionary:
	var result := _read_valid(path)
	if result.is_empty():
		result = _read_valid(path + ".bak")
	return result

static func _read_valid(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary or parsed.get("version") != VERSION:
		return {}
	for key in ["inventory", "quest"]:
		if not parsed.get(key) is Dictionary:
			return {}
	if not parsed.get("defeated", []) is Array:
		return {}
	return parsed
