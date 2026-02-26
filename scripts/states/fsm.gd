# fsm.gd
class_name FSM
extends Node

var current_state: FSMStateBase = null
var entity = null
var states := {}

func init(owner) -> void:
    entity = owner
    for child in get_children():
        if child is FSMStateBase:
            states[child.state_name] = child
            child.transition_requested.connect(_on_transition_requested)
    if states.has("Idle"):
        _enter_state(states["Idle"])
    elif states.size() > 0:
        _enter_state(states.values()[0])

func update(delta: float) -> void:
    if current_state:
        current_state.update(delta)

func handle_input(event: InputEvent) -> void:
    if current_state:
        current_state.handle_input(event)

func _enter_state(new_state: FSMStateBase) -> void:
    if current_state:
        current_state.exit()
    current_state = new_state
    current_state.enter(entity)

func _on_transition_requested(state_name: String) -> void:
    if states.has(state_name):
        _enter_state(states[state_name])
