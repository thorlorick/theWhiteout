extends AnimatedSprite2D

@onready var movement = $"../Movement"

func _ready():
    movement.connect("moved_left", play_walk_left)
    movement.connect("moved_right", play_walk_right)
    movement.connect("moved_up", play_walk_up)
    movement.connect("moved_down", play_walk_down)
	


