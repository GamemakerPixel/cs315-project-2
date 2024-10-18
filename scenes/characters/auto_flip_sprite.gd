extends Sprite2D

@export var body: CharacterBody2D
@export var flip_on_positive: bool = false

var enable_flipping := true


func _process(_delta: float) -> void:
	if not enable_flipping or body.velocity.x == 0:
		return
	
	flip_h = flip_on_positive != (body.velocity.x < 0)
