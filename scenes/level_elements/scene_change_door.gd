extends Area2D

@export var player_scene: PackedScene
@export var player_spawn_position: Node2D

@export_file var to_scene: String
@export var doorway_id: int = -1
@export var to_doorway_id: int = -1


func _ready() -> void:
	if GameState.doorway_id_requested == doorway_id:
		var player = player_scene.instantiate()
		player.position = player_spawn_position.global_position
		get_tree().current_scene.call_deferred("add_child", player)


func _on_player_entered(_body: Node2D) -> void:
	GameState.doorway_id_requested = to_doorway_id
	get_tree().call_deferred("change_scene_to_file", to_scene)
