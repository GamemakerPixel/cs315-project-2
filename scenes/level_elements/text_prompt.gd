extends Area2D

@export var text: String = ""

var shown := false


func _on_body_entered(_body: Node2D) -> void:
	if not shown:
		$CanvasLayer/Margin/Label.text = text
		$Animation.play("show")
		shown = true
