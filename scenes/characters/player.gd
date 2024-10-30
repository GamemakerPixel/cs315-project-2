extends CharacterBody2D

enum States {
	IDLE,
	RUNNING,
	ASCENDING,
	DESCENDING,
	WARPING,
}

const ANIMATION_NODEPATH = "Animation"
const WARP_ANIMATION_NODEPATH = "WarpIndicator/Animation"

# Speed - Pixels / sec
const SPEED = 350
const FLOAT_SPEED = 25

const ACCELERATION_SECONDS = 0.1
const DECELERATION_SECONDS = 0.1

# Slow-mo effect
const TIME_SCALE_CHANGE_PER_SECOND = 2.0

# Jumping
const TILE_SIZE = 64
const JUMP_HEIGHT = 2.65
const JUMP_EARLY_RELEASE_DAMPING = 0.5
const JUMP_BUFFER_TIME = 0.1
const COYOTE_TIME = 0.1
const WARP_JUMP_SCALE = 0.8

var on_floor_recently := false
var jump_buffered_recently := false

var warp_used := false


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
	States.WARPING: WarpingState,
}

var state_machine := PlayerStateMachine.new(STATES, self)

var run_input := 0.0

var warping_enabled = GameState.warping_enabled




func _ready() -> void:
	GameState.warp_enabled.connect(func(): warping_enabled = true)
	
	$CoyoteTimer.wait_time = COYOTE_TIME
	$JumpBufferTimer.wait_time = JUMP_BUFFER_TIME
	
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


func _jump() -> void:
	velocity.y = -jump_speed

func reset_jump_and_warp() -> bool:
	warp_used = false
	
	$CoyoteTimer.stop()
	$JumpBufferTimer.stop()
	if jump_buffered_recently:
		_jump()
		on_floor_recently = false
		jump_buffered_recently = false
		return true
	
	on_floor_recently = true
	return false


func attempt_jump() -> bool:
	if is_on_floor() or on_floor_recently:
		_jump()
		on_floor_recently = false
		return true
	
	jump_buffered_recently = true
	$JumpBufferTimer.start()
	return false


func start_coyote_timer() -> void:
	$CoyoteTimer.start()


func dampen_jump() -> void:
	velocity.y *= JUMP_EARLY_RELEASE_DAMPING


func fall(delta: float) -> void:
	velocity.y += 2.0 * gravity * delta


func start_floating() -> void:
	var direction = velocity.normalized()
	velocity = FLOAT_SPEED * direction


func point_warp_indicator_at_mouse() -> void:
	$WarpIndicator.look_at(get_global_mouse_position())


func warp_avaliable() -> bool:
	return warping_enabled and not warp_used


func _get_best_warp_position() -> Vector2:
	if (
		not $WarpIndicator.has_overlapping_bodies()
		or not $WarpIndicator/WallCheckRay.is_colliding()
	):
		return $WarpIndicator/Sprite.global_position
	return $WarpIndicator/WallCheckRay.get_collision_point()


func warp() -> void:
	var to_position: Vector2 = _get_best_warp_position()
	var direction := (to_position - position).normalized()
	
	var new_velocity = (WARP_JUMP_SCALE * jump_speed) * direction
	
	position = to_position
	velocity = new_velocity
	
	warp_used = true


func _read_run_input(event: InputEvent) -> void:
	if event.is_action("move_left") or event.is_action("move_right"):
		run_input = Input.get_axis("move_left", "move_right")


func _on_coyote_timeout() -> void:
	on_floor_recently = false


func _on_jump_buffer_timeout() -> void:
	jump_buffered_recently = false


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
		super.change_state_to(state_identifier)


class IdleState extends PlayerState:
	const IDLE_ANIMATION = "idle"
	
	
	func on_entry() -> void:
		if player.reset_jump_and_warp():
			state_machine.change_state_to(States.ASCENDING)
		player.get_node(ANIMATION_NODEPATH).play(IDLE_ANIMATION)
	
	func unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("jump"):
			if player.attempt_jump():
				state_machine.change_state_to(States.ASCENDING)
		
		if event.is_action_pressed("warp") and player.warp_avaliable():
			state_machine.change_state_to(States.WARPING)
		
		if event.is_action("move_right") or event.is_action("move_left"):
			state_machine.change_state_to(States.RUNNING)
	
	func physics_process(delta: float) -> void:
		player.decelerate(delta)
		player.move_and_slide()


class RunState extends PlayerState:
	const RUN_ANIMATION = "run"
	
	var input := Input.get_axis("move_left", "move_right")
	
	
	func on_entry() -> void:
		if player.reset_jump_and_warp():
			state_machine.change_state_to(States.ASCENDING)
		player.get_node(ANIMATION_NODEPATH).play(RUN_ANIMATION)
	
	func unhandled_input(event: InputEvent) -> void:
		if player.run_input == 0.0:
			state_machine.change_state_to(States.IDLE)
		
		if event.is_action_pressed("jump"):
			if player.attempt_jump():
				state_machine.change_state_to(States.ASCENDING)
		
		if event.is_action_pressed("warp") and player.warp_avaliable():
			state_machine.change_state_to(States.WARPING)
	
	func physics_process(delta: float) -> void:
		player.run(delta)
		
		player.move_and_slide()
		
		if not player.is_on_floor():
			state_machine.change_state_to(States.DESCENDING)


class AscendingState extends PlayerState:
	var jump_dampened = false
	
	
	func unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("jump"):
			if player.attempt_jump():
				state_machine.change_state_to(States.ASCENDING)
		
		if event.is_action_released("jump") and not jump_dampened:
			player.dampen_jump()
			jump_dampened = true
		
		if event.is_action_pressed("warp") and player.warp_avaliable():
			state_machine.change_state_to(States.WARPING)
	
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
	func on_entry() -> void:
		player.start_coyote_timer()
	
	func unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("jump"):
			if player.attempt_jump():
				state_machine.change_state_to(States.ASCENDING)
		
		if event.is_action_pressed("warp") and player.warp_avaliable():
			state_machine.change_state_to(States.WARPING)
	
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


class WarpingState extends PlayerState:
	func on_entry() -> void:
		var slow_mo_tween = player.get_tree().create_tween()
		slow_mo_tween.tween_property(Engine, "time_scale", 0.25, 0.05)
		player.get_node(WARP_ANIMATION_NODEPATH).play("activate")
		player.start_floating()
	
	func unhandled_input(event: InputEvent) -> void:
		if event.is_action_released("warp"):
			player.warp()
			if player.velocity.y < 0:
				state_machine.change_state_to(States.ASCENDING)
			else:
				state_machine.change_state_to(States.DESCENDING)
	
	func process(_delta: float) -> void:
		player.point_warp_indicator_at_mouse()
	
	func physics_process(_delta: float) -> void:
		#player.adjust_time_scale_towards(delta, 0.5)
		#player.fall(delta)
		player.move_and_slide()
	
	func on_exit() -> void:
		var slow_mo_tween = player.get_tree().create_tween()
		slow_mo_tween.tween_property(Engine, "time_scale", 1.0, 0.05)
		player.get_node(WARP_ANIMATION_NODEPATH).play("disappear")
