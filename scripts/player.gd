extends CharacterBody2D

@onready var stats = $Stats
@onready var movement = $Movement
@onready var combat = $Combat
@onready var animation_player = $Animation

func _ready():
    movement.direction_input.connect(animation_player._on_direction_input)
    combat.attack_input.connect(animation_player._on_attack_input)

func _physics_process(_delta):
    velocity = movement.current_direction * stats.speed
    move_and_slide()
