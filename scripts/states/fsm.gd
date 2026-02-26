class_name FSM
extends Node2D

var current_state: Node2D = null

func _ready() -> void:
    for child in get_children():
        if child.has_signal("transition_requested"):
            child.transition_requested.connect(_on_transition_requested)
    
    if get_children().size() > 0:
        _enter_state(get_children()[0])

func _process(delta: float) -> void:
    if current_state != null:
        current_state.update(delta)

func _enter_state(new_state: Node2D) -> void:
    if current_state != null:
        current_state.exit()
    current_state = new_state
    current_state.enter()

func _on_transition_requested(state_name: String) -> void:
    for child in get_children():
        if child.name == state_name:
            _enter_state(child)
            return
