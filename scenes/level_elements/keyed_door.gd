extends StaticBody2D

const MAX_KEYS = 4

@export var key_set_id: int = -1

var _keys_collected = 0
var open = false


func _ready() -> void:
	if GameState.get_key_count(key_set_id) == MAX_KEYS:
		open = true
		$Animation.play("opened")
	
	_keys_collected = GameState.get_key_count(key_set_id)
	GameState.key_count_updated.connect(_on_key_collected)


func _on_key_collected(collected_key_set_id: int, keys_in_set: int) -> void:
	if not collected_key_set_id == key_set_id:
		return
	
	_keys_collected = keys_in_set


func _on_activation_area_body_entered(_body: Node2D) -> void:
	if open:
		return
	
	if _keys_collected == MAX_KEYS:
		$Animation.play("open")
		open = true
		GameState.complete_key_set(key_set_id)
		return
	
	var animation_name = str(_keys_collected) + "_in"
	$Animation.play(animation_name)


func _on_activation_area_body_exited(_body: Node2D) -> void:
	if open:
		return
	
	var animation_name = str(_keys_collected) + "_out"
	$Animation.play(animation_name)
