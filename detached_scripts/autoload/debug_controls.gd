extends Node

const ENABLED = false


func _unhandled_input(event: InputEvent) -> void:
	if not ENABLED:
		return
	
	if event.is_action_pressed("debug_restart_scene"):
		get_tree().reload_current_scene()
	
	if event.is_action_pressed("debug_enable_warp"):
		GameState.enable_warping()
