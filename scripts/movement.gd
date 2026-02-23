extends Node

signal direction_input(direction: Vector2)

var current_direction: Vector2 = Vector2.ZERO
var _last_direction: Vector2 = Vector2.ZERO

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
	
    direction = direction.normalized()
    
    if direction != _last_direction:
        _last_direction = direction
        current_direction = direction
        direction_input.emit(direction)
