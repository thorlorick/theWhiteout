extends Node

var body: CharacterBody2D
var speed_component

func _ready():
	body = get_parent()
	speed_component = body.get_node("Speed")

func physics_update():
	var direction = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	body.velocity = direction.normalized() * speed_component.value
	body.move_and_slide()
