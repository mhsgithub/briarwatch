class_name Inventory
extends Node

signal changed
const CAPACITY := 20
var items: Array[ItemDefinition] = []
var equipment: Dictionary = EquipmentSlots.empty_equipment()
var gold: int = 0
var quest_items: Array[String] = []

func add(item: ItemDefinition) -> bool:
	if item and item.slot == "quest":
		if not str(item.id) in quest_items: quest_items.append(str(item.id))
		changed.emit()
		return true
	if item == null or items.size() >= CAPACITY:
		return false
	items.append(item)
	changed.emit()
	return true

func displaced_slots(index: int, target_slot: String) -> Array[String]:
	var result: Array[String] = []
	var item := items[index]
	if equipment[target_slot]:
		result.append(target_slot)
	if target_slot == "weapon" and item.two_handed and equipment.shield:
		result.append("shield")
	if target_slot == "shield" and equipment.weapon and equipment.weapon.two_handed:
		result.append("weapon")
	return result

func can_equip(index: int, target_slot: String) -> bool:
	if index < 0 or index >= items.size() or not equipment.has(target_slot):
		return false
	if not EquipmentSlots.accepts(target_slot, items[index].slot):
		return false
	return items.size() - 1 + displaced_slots(index, target_slot).size() <= CAPACITY

func blocking_slot(slot: String) -> String:
	if slot == "shield" and equipment.weapon and equipment.weapon.two_handed:
		return "weapon"
	return ""

func equip(index: int, target_slot: String = "") -> bool:
	if index < 0 or index >= items.size():
		return false
	var item := items[index]
	if target_slot.is_empty():
		for slot in equipment:
			if EquipmentSlots.accepts(slot, item.slot):
				if target_slot.is_empty() or equipment[slot] == null:
					target_slot = slot
				if equipment[slot] == null:
					break
	if not can_equip(index, target_slot):
		return false
	var displaced := displaced_slots(index, target_slot)
	items.remove_at(index)
	for slot in displaced:
		items.append(equipment[slot])
		equipment[slot] = null
	equipment[target_slot] = item
	changed.emit()
	return true

func unequip(slot: String) -> bool:
	var blocked := blocking_slot(slot)
	if not blocked.is_empty():
		slot = blocked
	if not equipment.has(slot) or equipment[slot] == null or items.size() >= CAPACITY:
		return false
	items.append(equipment[slot])
	equipment[slot] = null
	changed.emit()
	return true

func buy(item: ItemDefinition) -> bool:
	if item == null or item.slot == "quest" or gold < item.price or items.size() >= CAPACITY:
		return false
	gold -= item.price
	items.append(item)
	changed.emit()
	return true

func sell(index: int) -> bool:
	if index < 0 or index >= items.size():
		return false
	if items[index].slot == "quest": return false
	gold += maxi(0, items[index].sell_price)
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
	var pending: Array[String] = []
	for item in pending_rewards: pending.append(str(item.id))
	return {"gold": gold, "items": bag, "equipment": gear, "quest_items": quest_items.duplicate(), "pending_rewards":pending}

var pending_rewards: Array[ItemDefinition] = []

func claim_pending() -> void:
	while not pending_rewards.is_empty() and items.size()<CAPACITY:
		items.append(pending_rewards.pop_front())
	changed.emit()

func restore(data: Dictionary, catalog: ContentCatalog) -> void:
	items.clear()
	pending_rewards.clear()
	for id in data.get("pending_rewards",[]):
		var reward := catalog.find_item(str(id))
		if reward: pending_rewards.append(reward)
	quest_items.clear()
	var keys: Variant = data.get("quest_items", [])
	if keys is Array:
		for id in keys:
			var key := catalog.find_item(str(id))
			if key and key.slot == "quest" and not str(key.id) in quest_items:
				quest_items.append(str(key.id))
	gold = clampi(int(data.get("gold", 0)), 0, 999999)
	var bag: Variant = data.get("items", [])
	if bag is Array:
		for id in bag.slice(0, CAPACITY):
			var item := catalog.find_item(str(id))
			if item:
				if item.slot == "quest":
					if not str(item.id) in quest_items: quest_items.append(str(item.id))
				else:
					items.append(item)
	var gear: Variant = data.get("equipment", {})
	for slot in equipment:
		equipment[slot] = null
		if gear is Dictionary:
			var item := catalog.find_item(str(gear.get(slot, "")))
			if item and EquipmentSlots.accepts(slot, item.slot):
				equipment[slot] = item
	# Malformed/legacy combinations must not equip a shield with a two-hander.
	if equipment.weapon and equipment.weapon.two_handed and equipment.shield:
		if items.size() < CAPACITY:
			items.append(equipment.shield)
		else:
			gold += equipment.shield.sell_price
		equipment.shield = null
	changed.emit()
