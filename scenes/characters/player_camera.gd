extends Camera2D


func _ready() -> void:
	var scene_root: Node = get_tree().current_scene
	
	if not "bottom_right_limit" in scene_root:
		return
	
	var bottom_right_limit: Node2D = scene_root.bottom_right_limit
	var upper_left_limit: Node2D = scene_root.upper_left_limit
	limit_right = int(bottom_right_limit.global_position.x)
	limit_left = int(upper_left_limit.global_position.x)
	limit_bottom = int(bottom_right_limit.global_position.y)
	limit_top = int(upper_left_limit.global_position.y)
