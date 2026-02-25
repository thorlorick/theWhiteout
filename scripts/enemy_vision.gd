extends Node2D

signal player_spotted(body)
signal player_lost

@onready var ray_center = $RayCast2D_Center
@onready var ray_left = $RayCast2D_Left
@onready var ray_right = $RayCast2D_Right

func _physics_process(delta):
    var target = is_seeing_player()
    if target:
        player_spotted.emit(target)
    else:
        player_lost.emit()

func is_seeing_player():
    if ray_center.is_colliding():
        if ray_center.get_collider().is_in_group("player"):
            return ray_center.get_collider()
    if ray_left.is_colliding():
        if ray_left.get_collider().is_in_group("player"):
            return ray_left.get_collider()
    if ray_right.is_colliding():
        if ray_right.get_collider().is_in_group("player"):
            return ray_right.get_collider()
    return null
