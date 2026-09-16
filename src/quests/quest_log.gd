class_name QuestLog
extends Node

signal changed
var definition: QuestDefinition
var accepted: bool = false
var cleared: bool = false
var rewarded: bool = false

func accept() -> void:
	accepted = true
	changed.emit()

func encounter_cleared(id: StringName) -> void:
	if id == definition.target_encounter:
		cleared = true
		changed.emit()

func claim(inventory: Inventory) -> bool:
	if not accepted or not cleared or rewarded:
		return false
	if definition.reward_item and not inventory.add(definition.reward_item):
		return false
	rewarded = true
	inventory.gold += definition.reward_gold
	inventory.changed.emit()
	changed.emit()
	return true

func status_text() -> String:
	if rewarded:
		return "The road is open. Explore the March."
	if not accepted:
		return "Speak with Warden Elric in Briarwatch."
	if cleared:
		return "Return to Warden Elric for your reward."
	return "Clear the raiders at the Old Watchtower."

func serialize() -> Dictionary:
	return {"accepted": accepted, "cleared": cleared, "rewarded": rewarded}

func restore(data: Dictionary) -> void:
	accepted = bool(data.get("accepted", false))
	cleared = bool(data.get("cleared", false))
	rewarded = accepted and cleared and bool(data.get("rewarded", false))
	changed.emit()
