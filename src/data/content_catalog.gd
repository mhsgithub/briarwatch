class_name ContentCatalog
extends Resource
## Explicit portable catalog: save data stores stable IDs, never serialized objects.
@export var items: Array[ItemDefinition] = []
@export var quest: QuestDefinition

func find_item(id: String) -> ItemDefinition:
	for item in items:
		if str(item.id) == id:
			return item
	return null
