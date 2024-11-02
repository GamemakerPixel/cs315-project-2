extends Node2D

@export var bottom_right_limit: Node2D
@export var upper_left_limit: Node2D

func _ready() -> void:
	# In case the player floats into a scene change door while in the WARPING state.
	Engine.time_scale = 1.0
