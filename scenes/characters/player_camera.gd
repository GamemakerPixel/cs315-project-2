extends Camera2D

@export var bottom_right_limit: Node2D
@export var upper_left_limit: Node2D


func _ready() -> void:
	limit_right = int(bottom_right_limit.global_position.x)
	limit_left = int(upper_left_limit.global_position.x)
	limit_bottom = int(bottom_right_limit.global_position.y)
	limit_top = int(upper_left_limit.global_position.y)
