extends Node

signal walk_left
signal walk_right
signal walk_down
signal walk_up

func onready ()

if Input.is_action_pressed("walk_left"):
    emit_signal("walk_left")

if Input.is_action_pressed("walk_right"):
    emit_signal("walk_right")

if Input.is_action_pressed("walk_down"):
    emit_signal("walk_down")

if Input.is_action_pressed("walk_up"):
    emit_signal("walk_up")

