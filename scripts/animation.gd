extends Sprite2D

func _ready():
    var movement = get_parent().get_node("Movement")
    movement.direction_input.connect(_on_direction_input)

func _on_direction_input(direction: Vector2):
    if direction == Vector2.ZERO:
        return
    
    if abs(direction.x) > abs(direction.y):
        if direction.x < 0:
            $AnimationPlayer.play("walk_left")
        else:
            $AnimationPlayer.play("walk_right")
    else:
        if direction.y < 0:
            $AnimationPlayer.play("walk_up")
        else:
            $AnimationPlayer.play("walk_down")
