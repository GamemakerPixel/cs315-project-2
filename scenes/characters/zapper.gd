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
	States.STARTING_LASER: StartingLaserState,
	States.LASERING: LaseringState,
	States.ENDING_LASER: EndingLaserState,
}

const PATROL_SPEED = 64
const PURSUIT_SPEED = 128
const LASERING_SPEED = 96

const LASER_BASE_SIZE = 64
const LASER_SPRITE_BASE_SCALE = 4

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
	
	var cast_vector: Vector2 = player.global_position - $DetectionRay.global_position
	$DetectionRay.target_position = cast_vector
	$DetectionRay.force_raycast_update()
	
	if not $DetectionRay.is_colliding():
		return false
	
	if not $DetectionRay.get_collider() == player:
		return false
	
	return true


func player_directly_below() -> bool:
	return $PlayerRay.is_colliding()


func patrol() -> void:
	velocity.x = current_patrol_direction * PATROL_SPEED
	move_and_slide()
	
	if velocity.x == 0:
		current_patrol_direction *= -1


func pursue(delta: float) -> void:
	if not player:
		return
	
	var position_difference = player.global_position.x - global_position.x
	var player_direction = sign(position_difference)
	
	var speed = PURSUIT_SPEED if abs(position_difference) > PURSUIT_SPEED * delta else 0
	velocity.x = player_direction * speed
	move_and_slide()


func pursue_while_lasering(delta: float) -> void:
	if not player:
		return
	
	var position_difference = player.global_position.x - global_position.x
	var player_direction = sign(position_difference)
	
	var speed = LASERING_SPEED if abs(position_difference) > LASERING_SPEED * delta else 0
	velocity.x = player_direction * speed
	move_and_slide()


func extend_laser_to_ground() -> void:
	if not $GroundRay.is_colliding():
		push_warning("Zapper is too high off the ground to use its laser")
		return
	
	var length = $GroundRay.get_collision_point().y - $LaserSprite.global_position.y
	var laser_scale = length / LASER_BASE_SIZE
	$LaserSprite.scale.y = laser_scale * LASER_SPRITE_BASE_SCALE


func do_laser_damage():
	if $PlayerRay.is_colliding():
		player.on_killed()


func _on_player_entered_detection_range(body: Node2D) -> void:
	player = body
	player_in_detection_area = true


func _on_player_exited_detection_range(_body: Node2D) -> void:
	player = null
	player_in_detection_area = false


class ZapperState extends State:
	var zapper: CharacterBody2D
	var animation: AnimationPlayer
	var laser_timer: Timer
	
	func _init(zapper_body: CharacterBody2D) -> void:
		zapper = zapper_body
		animation = zapper_body.get_node("Animation")
		laser_timer = zapper_body.get_node("MaxLaserTimer")


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
	
	func physics_process(delta: float) -> void:
		if not zapper.player_in_sight():
			state_machine.change_state_to(States.PATROL)
		if zapper.player_directly_below():
			state_machine.change_state_to(States.STARTING_LASER)
		zapper.pursue(delta)


class StartingLaserState extends ZapperState:
	func on_entry() -> void:
		animation.animation_finished.connect(on_animation_finished)
		animation.play("fire_laser")
	
	func on_animation_finished(_anim_name: String) -> void:
		state_machine.change_state_to(States.LASERING)
	
	func on_exit() -> void:
		animation.animation_finished.disconnect(on_animation_finished)


class LaseringState extends ZapperState:
	func on_entry() -> void:
		laser_timer.timeout.connect(on_laser_timer_timeout)
		laser_timer.start()
		animation.play("lasering")
	
	func physics_process(delta: float) -> void:
		if not zapper.player_in_sight():
			state_machine.change_state_to(States.ENDING_LASER)
		zapper.extend_laser_to_ground()
		zapper.pursue_while_lasering(delta)
		zapper.do_laser_damage()
	
	func on_laser_timer_timeout():
		state_machine.change_state_to(States.ENDING_LASER)
	
	func on_exit() -> void:
		laser_timer.timeout.disconnect(on_laser_timer_timeout)


class EndingLaserState extends ZapperState:
	func on_entry() -> void:
		animation.animation_finished.connect(on_animation_finished)
		animation.play("release_laser")
	
	func on_animation_finished(_anim_name: String) -> void:
		state_machine.change_state_to(States.PATROL)
	
	func on_exit() -> void:
		animation.animation_finished.disconnect(on_animation_finished)
