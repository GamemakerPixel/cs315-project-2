extends AudioStreamPlayer

var looping_enabled = false


func _ready() -> void:
	finished.connect(_on_finished)


func _on_finished() -> void:
	if looping_enabled:
		play()
