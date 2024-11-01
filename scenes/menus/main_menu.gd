extends Panel


@export_file var game_scene: String


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(game_scene)


func _on_quit_pressed() -> void:
	get_tree().quit()
