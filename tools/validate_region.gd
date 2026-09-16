@tool
extends EditorScript
## Open the region, then run this script with File > Run in the Script editor.

func _run() -> void:
	var root := get_scene()
	if root == null:
		push_error("Open briar_march.tscn before validating.")
		return
	var issues := validate(root)
	if issues.is_empty():
		print("REGION VALID: unique IDs, configured enemies, valid overrides and player spawn.")
	else:
		for issue in issues:
			push_error(issue)

static func validate(root: Node) -> Array[String]:
	var issues: Array[String] = []
	var ids := {}
	var encounter_ids := {}
	var markers := root.find_children("*", "EnemySpawn", true, false)
	if markers.is_empty():
		issues.append("No enemy spawn markers found.")
	for marker in markers:
		if str(marker.spawn_id).is_empty() or ids.has(marker.spawn_id):
			issues.append("Missing or duplicate spawn_id: " + str(marker.name))
		ids[marker.spawn_id] = true
		if not marker.get_parent() is Encounter:
			issues.append("EnemySpawn must be a direct child of Encounter: " + str(marker.name))
		if marker.definition == null or marker.definition.attack == null:
			issues.append("Missing enemy/attack resource: " + str(marker.name))
		elif marker.definition.max_health <= 0 or marker.definition.attack.cooldown < marker.definition.attack.windup:
			issues.append("Invalid health or attack timing: " + str(marker.name))
		if marker.health_override != -1 and marker.health_override <= 0:
			issues.append("Health override must be -1 or positive: " + str(marker.name))
	for encounter in root.find_children("*", "Encounter", true, false):
		if str(encounter.encounter_id).is_empty() or encounter_ids.has(encounter.encounter_id):
			issues.append("Missing or duplicate encounter ID: " + str(encounter.name))
		encounter_ids[encounter.encounter_id] = true
		if encounter.markers().is_empty():
			issues.append("Empty encounter: " + str(encounter.name))
	if root.find_child("PlayerSpawn", true, false) == null:
		issues.append("Missing PlayerSpawn marker.")
	return issues
