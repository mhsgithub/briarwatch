@tool
class_name Encounter
extends Node3D

@export var encounter_id: StringName
@export var display_name: String

func markers() -> Array[EnemySpawn]:
	var result: Array[EnemySpawn] = []
	for child in get_children():
		if child is EnemySpawn:
			result.append(child)
	return result
