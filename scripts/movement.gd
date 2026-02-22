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
