# fsm.gd
class_name FSM
extends Node2D

var current_state: Node2D = null
var entity = null

func init(owner) -> void:
    entity = owner
    for child in get_children():
        if child.has_signal("transition_requested"):
            child.transition_requested.connect(_on_transition_requested)
    if get_children().size() > 0:
        _enter_state(get_children()[0])

func update(delta: float) -> void:
    if current_state != null:
        current_state.update(delta)

func handle_input(event: InputEvent) -> void:
    if current_state != null:
        current_state.handle_input(event)

func _enter_state(new_state: Node2D) -> void:
    if current_state != null:
        current_state.exit()
    current_state = new_state
    current_state.enter(entity)

func _on_transition_requested(state_name: String) -> void:
    for child in get_children():
        if child.name == state_name:
            _enter_state(child)
            return
