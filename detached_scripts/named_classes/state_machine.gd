extends Object
class_name StateMachine

# {State identifier (Variant) : State}
var _states: Dictionary = {}

# Using a state with no functionality to avoid checking if there is a __current_state
# every frame.
var _current_state: State = State.new()


func _init(states: Dictionary) -> void:
	_states = states


func change_state_to(state_identifier) -> void:
	if not _states.has(state_identifier):
		return

	_current_state.on_exit()
	_current_state = _construct_state(_states[state_identifier])
	_current_state.state_machine = self
	_current_state.on_entry()


func unhandled_input(event: InputEvent) -> void:
	_current_state.unhandled_input(event)


func process(delta: float) -> void:
	_current_state.process(delta)


func physics_process(delta: float) -> void:
	_current_state.physics_process(delta)


func _construct_state(state_class) -> State:
	return state_class.new()
