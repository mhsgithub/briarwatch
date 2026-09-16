class_name Inventory
extends Node

signal changed
const CAPACITY := 20
var items: Array[ItemDefinition] = []
var equipment: Dictionary = {"weapon": null, "shield": null, "body": null}
var gold: int = 0

func add(item: ItemDefinition) -> bool:
	if item == null or items.size() >= CAPACITY:
		return false
	items.append(item)
	changed.emit()
	return true

func equip(index: int) -> bool:
	if index < 0 or index >= items.size():
		return false
	var item := items[index]
	if not equipment.has(item.slot):
		return false
	var previous: ItemDefinition = equipment[item.slot]
	items.remove_at(index)
	equipment[item.slot] = item
	if previous:
		items.append(previous)
	changed.emit()
	return true

func unequip(slot: String) -> bool:
	if not equipment.has(slot) or equipment[slot] == null or items.size() >= CAPACITY:
		return false
	items.append(equipment[slot])
	equipment[slot] = null
	changed.emit()
	return true

func buy(item: ItemDefinition) -> bool:
	if item == null or gold < item.price or items.size() >= CAPACITY:
		return false
	gold -= item.price
	items.append(item)
	changed.emit()
	return true

func sell(index: int) -> bool:
	if index < 0 or index >= items.size():
		return false
	gold += maxi(1, items[index].price / 2)
	items.remove_at(index)
	changed.emit()
	return true

func bonus(property: String) -> float:
	var total := 0.0
	for item in equipment.values():
		if item != null:
			total += float(item.get(property))
	return total

func serialize() -> Dictionary:
	var bag: Array[String] = []
	var gear := {}
	for item in items:
		bag.append(str(item.id))
	for slot in equipment:
		gear[slot] = str(equipment[slot].id) if equipment[slot] else ""
	return {"gold": gold, "items": bag, "equipment": gear}

func restore(data: Dictionary, catalog: ContentCatalog) -> void:
	items.clear()
	gold = clampi(int(data.get("gold", 0)), 0, 999999)
	var bag: Variant = data.get("items", [])
	if bag is Array:
		for id in bag.slice(0, CAPACITY):
			var item := catalog.find_item(str(id))
			if item:
				items.append(item)
	var gear: Variant = data.get("equipment", {})
	for slot in equipment:
		equipment[slot] = null
		if gear is Dictionary:
			var item := catalog.find_item(str(gear.get(slot, "")))
			if item and item.slot == slot:
				equipment[slot] = item
	changed.emit()
