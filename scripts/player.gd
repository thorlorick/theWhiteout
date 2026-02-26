# hero.gd
extends CharacterBody2D

@onready var fsm: FSM = $FSM
@onready var health = $Health
@onready var movement = $Movement
@onready var animation = $Animation
@onready var combat = $Combat

func _ready() -> void:
    fsm.init(self)

func _physics_process(delta: float) -> void:
    fsm.update(delta)

func _input(event: InputEvent) -> void:
    fsm.handle_input(event)
