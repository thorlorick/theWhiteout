# fsm_state_base.gd
class_name FSMStateBase
extends Node

signal transition_requested(state_name: String)

@export var state_name: String = ""
var entity = null

func enter(entity_owner) -> void:
    entity = entity_owner

func exit() -> void:
    pass

func update(_delta: float) -> void:
    pass

func handle_input(_event: InputEvent) -> void:
    pass
