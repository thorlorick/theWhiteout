extends AnimatedSprite2D

@onready var movement = $"../Movement"

func _ready():
    movement.connect("moved_left", play_walk_left)
    movement.connect("moved_right", play_walk_right)
    movement.connect("moved_up", play_walk_up)
    movement.connect("moved_down", play_walk_down)


func play_walk_left():
    play("walk_left")

func play_walk_right():
    play("walk_right")

func play_walk_up():
    play("walk_up")

func play_walk_down():
    play("walk_down")


