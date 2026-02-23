extends Node

signal direction_input(direction: Vector2)

func _process(delta):
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("walk_left"):
		direction.x -= 1
	if Input.is_action_pressed("walk_right"):
		direction.x += 1
	if Input.is_action_pressed("walk_up"):
		direction.y -= 1
	if Input.is_action_pressed("walk_down"):
		direction.y += 1
	
	direction_input.emit(direction.normalized())
