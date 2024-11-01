extends Node

signal warp_enabled
signal key_count_updated
signal key_set_completed

var warping_enabled = false

# { key_set_id: [key_id, key_id, ...], ... }
var keys_collected: Dictionary = {}
var completed_key_sets: Array[int] = []
var last_key_collected_set_id := -1


func enable_warping() -> void:
	warping_enabled = true
	warp_enabled.emit()


func collect_key(key_set_id: int, key_id: int) -> void:
	if not key_set_id in keys_collected:
		keys_collected[key_set_id] = []
	
	if not key_id in keys_collected[key_set_id]:
		keys_collected[key_set_id].append(key_id)
	
	last_key_collected_set_id = key_set_id
	key_count_updated.emit(key_set_id, keys_collected[key_set_id].size())


func complete_key_set(key_set_id: int) -> void:
	if key_set_id in completed_key_sets:
		return
	
	completed_key_sets.append(key_set_id)
	key_set_completed.emit(key_set_id)


func get_key_count(key_set_id: int) -> int:
	if key_set_id in keys_collected:
		return keys_collected[key_set_id].size()
	
	return 0


func is_key_collected(key_set_id: int, key_id: int) -> bool:
	return key_set_id in keys_collected and key_id in keys_collected[key_set_id]
