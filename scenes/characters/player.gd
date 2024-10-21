extends CharacterBody2D

enum States {
	IDLE,
	RUNNING,
	ASCENDING,
	DESCENDING,
}

const ANIMATION_NODEPATH = "Animation"

# Pixels / sec
const SPEED = 350

const ACCELERATION_SECONDS = 0.1
const DECELERATION_SECONDS = 0.1

const TILE_SIZE = 64
const JUMP_HEIGHT = 2.65
const JUMP_EARLY_RELEASE_DAMPING = 0.5
const JUMP_BUFFER_TIME = 0.1

@onready var gravity = PhysicsServer2D.area_get_param(
	get_viewport().find_world_2d().space,
	PhysicsServer2D.AREA_PARAM_GRAVITY
)

@onready var jump_speed = 2.0 * sqrt(gravity * JUMP_HEIGHT * TILE_SIZE)

const STATES := {
	States.IDLE: IdleState,
	States.RUNNING: RunState,
	States.ASCENDING: AscendingState,
	States.DESCENDING: DescendingState,
}

var state_machine := PlayerStateMachine.new(STATES, self)


var run_input := 0.0


func _ready() -> void:
	print("jump: " + str(jump_speed))
	
	state_machine.change_state_to(States.IDLE)


func _unhandled_input(event: InputEvent) -> void:
	_read_run_input(event)
	state_machine.unhandled_input(event)


func _process(delta: float) -> void:
	state_machine.process(delta)


func _physics_process(delta: float) -> void:
	state_machine.physics_process(delta)


func run(delta: float) -> void:
	var acceleration = (delta / ACCELERATION_SECONDS) * SPEED * run_input
	velocity.x = clampf(velocity.x + acceleration, -SPEED, SPEED)


func decelerate(delta: float) -> void:
	var velocity_sign = signf(velocity.x)
	var DECELERATION = (delta / DECELERATION_SECONDS) * SPEED * -velocity_sign
	
	var expected_velocity = velocity.x + DECELERATION
	
	if sign(expected_velocity) != velocity_sign:
		velocity.x = 0.0
	else:
		velocity.x = expected_velocity


func jump() -> void:
	velocity.y = -jump_speed


func dampen_jump() -> void:
	velocity.y *= JUMP_EARLY_RELEASE_DAMPING


func fall(delta: float) -> void:
	velocity.y += 2.0 * gravity * delta


func _read_run_input(event: InputEvent) -> void:
	if event.is_action("move_left") or event.is_action("move_right"):
		run_input = Input.get_axis("move_left", "move_right")


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
	
	
	func change_state_to(state_identifier) -> void:
		var state_name = States.keys()[state_identifier]
		print("Changing state to " + state_name)
		super.change_state_to(state_identifier)


class IdleState extends PlayerState:
	const IDLE_ANIMATION = "idle"
	
	
	func on_entry() -> void:
		player.get_node(ANIMATION_NODEPATH).play(IDLE_ANIMATION)
	
	func unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("jump") and player.is_on_floor():
			player.jump()
			state_machine.change_state_to(States.ASCENDING)
		
		if event.is_action("move_right") or event.is_action("move_left"):
			state_machine.change_state_to(States.RUNNING)
	
	func physics_process(delta: float) -> void:
		player.decelerate(delta)
		player.move_and_slide()


class RunState extends PlayerState:
	const RUN_ANIMATION = "run"
	
	var input := Input.get_axis("move_left", "move_right")
	
	
	func on_entry() -> void:
		player.get_node(ANIMATION_NODEPATH).play(RUN_ANIMATION)
	
	func unhandled_input(event: InputEvent) -> void:
		if player.run_input == 0.0:
			state_machine.change_state_to(States.IDLE)
		
		if event.is_action_pressed("jump") and player.is_on_floor():
			player.jump()
			state_machine.change_state_to(States.ASCENDING)
	
	func physics_process(delta: float) -> void:
		player.run(delta)
		
		player.move_and_slide()
		
		if not player.is_on_floor():
			state_machine.change_state_to(States.DESCENDING)


class AscendingState extends PlayerState:
	var jump_dampened = false
	
	
	func unhandled_input(event: InputEvent) -> void:
		if event.is_action_released("jump") and not jump_dampened:
			player.dampen_jump()
			jump_dampened = true
	
	func physics_process(delta: float) -> void:
		if player.run_input != 0.0:
			player.run(delta)
		else:
			player.decelerate(delta)
		
		player.fall(delta)
		
		player.move_and_slide()
		
		if player.velocity.y > 0.0:
			state_machine.change_state_to(States.DESCENDING)


class DescendingState extends PlayerState:
	func physics_process(delta: float) -> void:
		if player.run_input != 0.0:
			player.run(delta)
		else:
			player.decelerate(delta)
		
		player.fall(delta)
		
		player.move_and_slide()
		
		if player.is_on_floor():
			if player.run_input == 0.0:
				state_machine.change_state_to(States.IDLE)
			else:
				state_machine.change_state_to(States.RUNNING)
