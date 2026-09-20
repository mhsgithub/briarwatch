class_name QuestLog
extends Node

signal changed
var definition: QuestDefinition
var accepted: bool = false
var cleared: bool = false
var rewarded: bool = false
var inventory: Inventory
var completed: Array[String] = []
var flags: Dictionary = {}

func offered() -> QuestDefinition:
	return definition.next_quest if rewarded and definition.next_quest else definition

func is_completed(id: String) -> bool:
	return id in completed or (str(definition.id)==id and rewarded)

func bind(value: Inventory) -> void:
	inventory = value
	inventory.changed.connect(refresh)
	refresh()

func refresh() -> void:
	if definition.required_item.is_empty(): return
	var has_key := rewarded or str(definition.required_item) in inventory.quest_items
	if cleared != has_key:
		cleared = has_key
		changed.emit()

func accept() -> void:
	if rewarded and definition.next_quest:
		definition = definition.next_quest
		accepted = false
		cleared = false
		rewarded = false
	accepted = true
	changed.emit()

func encounter_cleared(id: StringName) -> void:
	if not definition.required_item.is_empty(): return
	if id == definition.target_encounter:
		cleared = true
		changed.emit()

func claim(bag: Inventory) -> bool:
	if not accepted or not cleared or rewarded:
		return false
	if not definition.required_item.is_empty() and not str(definition.required_item) in bag.quest_items:
		return false
	if definition.reward_item and not bag.add(definition.reward_item):
		bag.pending_rewards.append(definition.reward_item)
	rewarded = true
	if not str(definition.id) in completed: completed.append(str(definition.id))
	bag.quest_items.erase(str(definition.required_item))
	bag.gold += definition.reward_gold
	bag.changed.emit()
	changed.emit()
	return true

func status_text() -> String:
	if rewarded:
		return definition.completion_text
	if not accepted:
		return definition.offer_objective
	if cleared:
		return definition.return_objective
	return definition.objective

func serialize() -> Dictionary:
	return {"id": str(definition.id), "accepted": accepted, "cleared": cleared, "rewarded": rewarded, "completed":completed.duplicate(), "flags":flags.duplicate()}

func restore(data: Dictionary) -> void:
	var candidate := definition
	while candidate:
		if str(candidate.id)==str(data.get("id","")):
			definition = candidate
			break
		candidate = candidate.next_quest
	completed.clear()
	for id in data.get("completed",[]):
		if id is String and not id in completed: completed.append(id)
	flags = data.get("flags",{}).duplicate() if data.get("flags",{}) is Dictionary else {}
	accepted = bool(data.get("accepted", false))
	# The old camp-clear quest becomes a new objective without erasing the character.
	var same_quest := str(data.get("id", "")) == str(definition.id)
	cleared = same_quest and bool(data.get("cleared", false))
	rewarded = same_quest and accepted and cleared and bool(data.get("rewarded", false))
	if rewarded and not str(definition.id) in completed: completed.append(str(definition.id))
	if inventory: refresh()
	changed.emit()
