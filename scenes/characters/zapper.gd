extends CharacterBody2D

enum States {
	PATROL,
	PURSUE,
	STARTING_LASER,
	LASERING,
	ENDING_LASER,
}

var state_map = {
	States.PATROL: PatrolState,
	States.PURSUE: PursueState,
}

const PATROL_SPEED = 64
const PURSUIT_SPEED = 128

var player: Node2D = null

var player_in_detection_area := false
var current_patrol_direction := 1

var state_machine = ZapperStateMachine.new(state_map, self)


func _ready() -> void:
	state_machine.change_state_to(States.PATROL)


func _physics_process(delta: float) -> void:
	state_machine.physics_process(delta)


func player_in_sight() -> bool:
	if not player_in_detection_area:
		return false
	
	var cast_vector: Vector2 = player.global_position - $DetectionRange/DetectionRay.global_position
	$DetectionRange/DetectionRay.target_position = cast_vector
	$DetectionRange/DetectionRay.force_raycast_update()
	
	if not $DetectionRange/DetectionRay.is_colliding():
		print("No ray collision")
		return false
	
	if not $DetectionRange/DetectionRay.get_collider() == player:
		print("Collision not player")
		return false
	
	return true


func patrol() -> void:
	velocity.x = current_patrol_direction * PATROL_SPEED
	move_and_slide()
	
	if velocity.x == 0:
		current_patrol_direction *= -1


func _on_player_entered_detection_range(body: Node2D) -> void:
	player = body
	player_in_detection_area = true


func _on_player_exited_detection_range(_body: Node2D) -> void:
	player = null
	player_in_detection_area = false


class ZapperState extends State:
	var zapper: CharacterBody2D
	var animation: AnimationPlayer
	
	func _init(zapper_body: CharacterBody2D) -> void:
		zapper = zapper_body
		animation = zapper_body.get_node("Animation")


class ZapperStateMachine extends StateMachine:
	var zapper: CharacterBody2D
	
	func _init(states: Dictionary, zapper_body: CharacterBody2D) -> void:
		super(states)
		zapper = zapper_body
	
	func _construct_state(state_class) -> State:
		return state_class.new(zapper)


class PatrolState extends ZapperState:
	func on_entry() -> void:
		animation.play("patrol")
	
	func physics_process(_delta: float) -> void:
		if zapper.player_in_sight():
			state_machine.change_state_to(States.PURSUE)
		zapper.patrol()


class PursueState extends ZapperState:
	func on_entry() -> void:
		animation.play("pursue")
	
	func physics_process(_delta: float) -> void:
		if not zapper.player_in_sight():
			print("player left")
			state_machine.change_state_to(States.PATROL)
		zapper.patrol()
