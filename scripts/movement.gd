extends Node

signal walk_left
signal walk_right
signal walk_down
signal walk_up

func _process(delta):
	if Input.is_action_pressed("walk_left"):
		walk_left.emit()
	elif Input.is_action_pressed("walk_right"):
		walk_right.emit()
	elif Input.is_action_pressed("walk_down"):
		walk_down.emit()
	elif Input.is_action_pressed("walk_up"):
		walk_up.emit()

# movement with one direction signal that says which way it's going.

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
    
    direction_input.emit(direction)
