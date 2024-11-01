extends CanvasLayer


var last_key_set_id := GameState.last_key_collected_set_id
var keys_from_set_collected := 0 : set = _set_keys_from_set_collected


func _ready() -> void:
	GameState.key_count_updated.connect(_on_key_count_updated)
	GameState.key_set_completed.connect(_on_key_set_completed)


func _on_key_count_updated(key_set_id: int, count: int) -> void:
	last_key_set_id = key_set_id
	keys_from_set_collected = count


func _on_key_set_completed(key_set_id: int) -> void:
	last_key_set_id = key_set_id
	keys_from_set_collected = 0


func _set_keys_from_set_collected(new_count: int) -> void:
	if new_count == 0 and not keys_from_set_collected == 0:
		$Margin/TopBar/Animation.play("fade_out")
	elif new_count != 0 and keys_from_set_collected == 0:
		$Margin/TopBar/Animation.play("fade_in")
	
	keys_from_set_collected = new_count
	
	$Margin/TopBar/KeyCount.text = str(new_count)
