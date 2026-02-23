extends Node

signal attack_input

func _process(_delta):
    if Input.is_action_just_pressed("attack"):
        attack_input.emit()
