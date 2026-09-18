extends SceneTree
## Audit the actual assigned table before changing balance; no personal save.
func _initialize() -> void:
	var table: LootTable=load("res://content/loot/march_enemies.tres")
	var rng:=RandomNumberGenerator.new()
	rng.seed=731904
	var counts: Dictionary={}
	var any_item:=0
	for i in range(100000):
		var rolled:=table.roll(rng)
		if not rolled.items.is_empty(): any_item+=1
		for item in rolled.items: counts[item.id]=counts.get(item.id,0)+1
	var valid:=true
	for entry in table.entries:
		var observed:=float(counts.get(entry.item.id,0))/100000.0
		print(entry.item.id, ": configured=",entry.chance," observed=",observed)
		valid=valid and absf(observed-entry.chance)<0.002
	print("Any item per kill: ",float(any_item)/100000.0)
	quit(0 if valid else 1)
