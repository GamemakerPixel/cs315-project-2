extends CharacterBody2D

enum States {
	IDLE,
	RUNNING,
}

const ANIMATION_NODEPATH = "Animation"

# Pixels / sec
const SPEED = 350

const STATES := {
	States.IDLE: IdleState,
	States.RUNNING: 0,
}

var state_machine := PlayerStateMachine.new(STATES, self)


func _unhandled_input(event: InputEvent) -> void:
	state_machine.unhandled_input(event)


func _process(delta: float) -> void:
	state_machine.process(delta)


func _physics_process(delta: float) -> void:
	state_machine.physics_process(delta)


class PlayerState extends State:
	var player: CharacterBody2D
	
	func _init(player_body: CharacterBody2D) -> void:
		player = player_body


class PlayerStateMachine extends StateMachine:
	var player: CharacterBody2D
	
	func _init(states: Dictionary, player_body: CharacterBody2D) -> void:
		super(states)
		player = player_body
	
	func _construct_state(state_class: State) -> State:
		return state_class.new(player)


class IdleState extends PlayerState:
	const IDLE_ANIMATION = "idle"
	
	
	func on_entry() -> void:
		player.get_node(ANIMATION_NODEPATH).play(IDLE_ANIMATION)
	
	func unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("move_right") or event.is_action_pressed("move_left"):
			state_machine.change_state_to(States.RUNNING)
