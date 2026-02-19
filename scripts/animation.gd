extends AnimatedSprite2D

@onready connect

func _ready():
    movement.connect("moved_left", play_walk_left)
    movement.connect("moved_right", play_walk_right)
    movement.connect("moved_up", play_walk_up)
    movement.connect("moved_down", play_walk_down)
	

func update_animation():
	if body.velocity != Vector2.ZERO:
		sprite.play("walk")
	else:
		sprite.play("idle")
