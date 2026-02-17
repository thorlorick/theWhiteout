extends Node

var body: CharacterBody2D
@onready var sprite = $"../AnimatedSprite2D"

func _ready():
	body = get_parent()

func update_animation():
	if body.velocity != Vector2.ZERO:
		sprite.play("walk")
	else:
		sprite.play("idle")
