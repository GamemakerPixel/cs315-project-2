extends CharacterBody2D

enum States {
	IDLE,
	RUNNING,
	JUMPING,
	FALLING,
}

const ANIMATION_NODEPATH = "Animation"

# Pixels / sec
const SPEED = 350

const ACCELERATION_SECONDS = 0.1
const DECELERATION_SECONDS = 0.1

const TILE_SIZE = 64
const JUMP_HEIGHT = 3

const BUFFER_TIME = 0.1

const STATES := {
	States.IDLE: IdleState,
	States.RUNNING: RunState,
}

var state_machine := PlayerStateMachine.new(STATES, self)


func _ready() -> void:
	
	
	state_machine.change_state_to(States.IDLE)


func _unhandled_input(event: InputEvent) -> void:
	state_machine.unhandled_input(event)


func _process(delta: float) -> void:
	state_machine.process(delta)


func _physics_process(delta: float) -> void:
	state_machine.physics_process(delta)


func run(delta: float, input: int) -> void:
	var acceleration = (delta / ACCELERATION_SECONDS) * SPEED * input
	velocity.x = clampf(velocity.x + acceleration, -SPEED, SPEED)
	
	move_and_slide()


func decelerate(delta: float) -> void:
	var velocity_sign = signf(velocity.x)
	var DECELERATION = (delta / DECELERATION_SECONDS) * SPEED * -velocity_sign
	
	var expected_velocity = velocity.x + DECELERATION
	
	if sign(expected_velocity) != velocity_sign:
		velocity.x = 0.0
	else:
		velocity.x = expected_velocity
	
	move_and_slide()


class PlayerState extends State:
	var player: CharacterBody2D
	
	func _init(player_body: CharacterBody2D) -> void:
		player = player_body


class PlayerStateMachine extends StateMachine:
	var player: CharacterBody2D
	
	func _init(states: Dictionary, player_body: CharacterBody2D) -> void:
		super(states)
		player = player_body
	
	func _construct_state(state_class) -> State:
		return state_class.new(player)


class IdleState extends PlayerState:
	const IDLE_ANIMATION = "idle"
	
	
	func on_entry() -> void:
		player.get_node(ANIMATION_NODEPATH).play(IDLE_ANIMATION)
	
	func unhandled_input(event: InputEvent) -> void:
		if event.is_action("move_right") or event.is_action("move_left"):
			state_machine.change_state_to(States.RUNNING)
	
	func physics_process(delta: float) -> void:
		player.decelerate(delta)


class RunState extends PlayerState:
	const RUN_ANIMATION = "run"
	
	var input := Input.get_axis("move_left", "move_right")
	
	
	func on_entry() -> void:
		player.get_node(ANIMATION_NODEPATH).play(RUN_ANIMATION)
	
	func unhandled_input(event: InputEvent) -> void:
		if event.is_action("move_left") or event.is_action("move_right"):
			input = Input.get_axis("move_left", "move_right")
			if input == 0.0:
				state_machine.change_state_to(States.IDLE)
	
	func physics_process(delta: float) -> void:
		player.run(delta, input)
