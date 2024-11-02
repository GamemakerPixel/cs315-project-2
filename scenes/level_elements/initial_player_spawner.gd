extends Node2D

@export var player_scene: PackedScene


func _ready() -> void:
	if GameState.doorway_id_requested == GameState.NO_DOORWAY_REQUESTED:
		var player = player_scene.instantiate()
		player.position = global_position
		get_tree().current_scene.call_deferred("add_child", player)
