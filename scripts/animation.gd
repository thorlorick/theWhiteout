extends Node

func _ready():
    # We need to go UP to the parent (Player_1) and then DOWN to Movement Component
    var movement = get_parent().get_node("Movement")
    
    # Connect its signal to our function below
    movement.direction_input.connect(_on_direction_input)

func _on_direction_input(direction: String):
    if direction == "left":
        $AnimationPlayer.play("walk_left")
    elif direction == "right":
        $AnimationPlayer.play("walk_right")
    elif direction == "up":
        $AnimationPlayer.play("walk_up")
    elif direction == "down":
        $AnimationPlayer.play("walk_down")
