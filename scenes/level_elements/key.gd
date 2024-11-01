extends Area2D

@export var key_set_id: int = -1
@export var key_id: int = -1


func _ready() -> void:
	if GameState.is_key_collected(key_set_id, key_id):
		queue_free()


func _on_body_entered(_body: Node2D) -> void:
	GameState.collect_key(key_set_id, key_id)
	$AnimationPlayer.animation_finished.connect(_on_anim_finished)
	$AnimationPlayer.play("disappear")


func _on_anim_finished(_anim_name: String) -> void:
	queue_free()
