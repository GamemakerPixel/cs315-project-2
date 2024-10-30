extends Area2D


func _on_body_entered(body: Node2D) -> void:
	$Sprite.frame = 1
	body.super_warp_avaliable = true


func _on_body_exited(body: Node2D) -> void:
	$Sprite.frame = 0
	body.super_warp_avaliable = false
