class_name CharacterProgression
extends Node
signal changed
signal leveled(level: int)
const MAX_LEVEL := 20
var level: int = 1
var experience: int = 0
var ranks: Dictionary = {}
var test_points: int = 0

func grant_test_points(amount: int) -> void:
	test_points = clampi(test_points + amount,0,10000)
	changed.emit()

func talents_unlocked() -> bool:
	return level >= 2 or test_points > 0
func required() -> int:
	return 0 if level == MAX_LEVEL else int(CenturionTalents.content().thresholds[level - 1])
func grant(amount: int) -> void:
	if amount <= 0 or level >= MAX_LEVEL: return
	experience += amount
	if experience >= required():
		level += 1
		experience = 0 # Explicit reset; overflow is not carried into the next level.
		leveled.emit(level)
	changed.emit()
func rank(id: String) -> int:
	return int(ranks.get(id, 0))
func mastered(id: String) -> bool:
	var data := CenturionTalents.find(id)
	return not data.is_empty() and rank(id) >= int(data.max_rank)
func points() -> int:
	var spent := 0
	for value in ranks.values(): spent += int(value)
	return maxi(0, level - 1 + test_points - spent)
func available(id: String) -> bool:
	var data := CenturionTalents.find(id)
	if data.is_empty() or not talents_unlocked() or points() < 1 or rank(id) >= int(data.max_rank): return false
	for parent: String in data.parents:
		if not mastered(parent): return false
	return true
func learn(id: String) -> bool:
	if not available(id): return false
	ranks[id] = rank(id) + 1
	changed.emit()
	return true
func serialize() -> Dictionary:
	return {"level":level,"experience":experience,"ranks":ranks.duplicate(),"test_points":test_points}
func restore(data: Dictionary) -> void:
	level = clampi(int(data.get("level",1)),1,MAX_LEVEL)
	test_points = clampi(int(data.get("test_points",0)),0,10000)
	experience = clampi(int(data.get("experience",0)),0,maxi(0,required()-1))
	ranks.clear()
	var saved: Variant = data.get("ranks",{})
	if saved is Dictionary:
		# Content is topologically ordered, so corrupt ranks cannot bypass parents.
		for talent: Dictionary in CenturionTalents.all():
			for ignored in range(clampi(int(saved.get(talent.id,0)),0,int(talent.max_rank))):
				if available(talent.id): ranks[talent.id] = rank(talent.id)+1
	changed.emit()
