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

signal direction_input(direction)

func _process(delta):
    if Input.is_action_pressed("walk_left"):
        direction_input.emit("left")
    elif Input.is_action_pressed("walk_right"):
        direction_input.emit("right")
    elif Input.is_action_pressed("walk_down"):
        direction_input.emit("down")
    elif Input.is_action_pressed("walk_up"):
        direction_input.emit("up")
