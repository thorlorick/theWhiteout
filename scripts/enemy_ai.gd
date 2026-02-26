# enemy_ai.gd

class_name EnemyAI
extends CharacterBody2D

@onready var fsm: FSM = $FSM

func _ready() -> void:
    fsm.init(self)

func _physics_process(delta: float) -> void:
    fsm.update(delta)

