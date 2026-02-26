# state_base.gd
class_name StateBase
extends Node2D

signal transition_requested(state_name: String)

var entity = null

func enter(owner) -> void:
    entity = owner

func exit() -> void:
    pass

func update(_delta: float) -> void:
    pass

func handle_input(_event: InputEvent) -> void:
    pass
