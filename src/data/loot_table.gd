class_name LootTable
extends Resource
## Explicit per-enemy assignment. Future enemy types have no implicit shared loot.
@export var gold_weights: PackedFloat32Array = PackedFloat32Array([1.0])
@export var entries: Array[LootEntry] = []

func roll(rng: RandomNumberGenerator) -> Dictionary:
	var total := 0.0
	for weight in gold_weights:
		total += maxf(0, weight)
	var value := rng.randf() * total
	var gold := 0
	for i in range(gold_weights.size()):
		value -= maxf(0, gold_weights[i])
		if value < 0:
			gold = i
			break
	var items: Array[ItemDefinition] = []
	for entry in entries:
		if entry and entry.item and (entry.chance >= 1.0 or rng.randf() < entry.chance):
			items.append(entry.item)
	return {"gold": gold, "items": items}
