class_name ActionLoadout
extends Node
## Stable content references, not bag indices. Future ability handlers use the
## same kind/id dispatch without coupling the belt to a skill-tree implementation.
signal changed
signal activated(kind: StringName, id: StringName)
const SIZE := 6
var slots: Array[Dictionary] = [{}, {}, {}, {}, {}, {}]
var progression: CharacterProgression

func assign_ability(index: int, id: String) -> bool:
	var talent := CenturionTalents.find(id)
	if index < 0 or index >= SIZE or talent.is_empty() or not talent.active or not progression or progression.rank(id) == 0: return false
	slots[index] = {"kind":"ability","id":id}
	changed.emit()
	return true

func assign_item(index: int, item: ItemDefinition) -> bool:
	if index < 0 or index >= SIZE or item == null or item.slot != "consumable":
		return false
	slots[index] = {"kind": "item", "id": str(item.id)}
	changed.emit()
	return true

func clear(index: int) -> void:
	if index >= 0 and index < SIZE:
		slots[index] = {}
		changed.emit()

func swap(a: int, b: int) -> void:
	if a < 0 or a >= SIZE or b < 0 or b >= SIZE:
		return
	var previous := slots[a]
	slots[a] = slots[b]
	slots[b] = previous
	changed.emit()

func activate(index: int) -> void:
	if index >= 0 and index < SIZE and not slots[index].is_empty():
		activated.emit(StringName(slots[index].kind), StringName(slots[index].id))

func serialize() -> Array:
	return slots.duplicate(true)

func restore(value: Variant, catalog: ContentCatalog) -> void:
	slots = [{}, {}, {}, {}, {}, {}]
	if value is Array:
		for i in range(mini(value.size(), SIZE)):
			if value[i] is Dictionary and value[i].get("kind","") == "ability":
				assign_ability(i,str(value[i].get("id","")))
			if value[i] is Dictionary and value[i].get("kind", "") == "item":
				var item := catalog.find_item(str(value[i].get("id", "")))
				if item and item.slot == "consumable":
					slots[i] = {"kind": "item", "id": str(item.id)}
	changed.emit()
