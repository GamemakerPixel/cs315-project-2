extends Area2D


func _ready() -> void:
	if GameState.warping_enabled:
		queue_free()


func _on_body_entered(_body: Node2D) -> void:
	GameState.enable_warping()
	$Animation.animation_finished.connect(_on_animation_finished)
	$Animation.play("disappear")


func _on_animation_finished(_anim_name: String):
	queue_free()
