extends Node

const ENABLED = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_restart_scene"):
		get_tree().reload_current_scene()
