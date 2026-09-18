class_name ContentCatalog
extends Resource
## Explicit portable catalog: save data stores stable IDs, never serialized objects.
@export var items: Array[ItemDefinition] = []
@export var quest: QuestDefinition

func find_item(id: String) -> ItemDefinition:
	# Retired content migrates to an existing starter weapon, never a dangling ID.
	if id == "forged_sword":
		id = "old_sword"
	for item in items:
		if str(item.id) == id:
			return item
	return null
