extends CharacterBody2D

@onready var movement = $Movement
@onready var animation = $Animation

func _physics_process(delta):
	movement.physics_update()
	animation.update_animation()
