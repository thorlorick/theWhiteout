extends Camera2D

@export var player_node_path : NodePath
var player : Node2D
var view_half_width  := 200
var view_half_height := 150
var follow_speed := 0.1  # smaller = slower, bigger = snappier

func _ready():
    player = get_node(player_node_path)

func _process(delta):
    if not player:
        return

    # Smooth follow using move_toward
    global_position.x = global_position.x + (player.global_position.x - global_position.x) * follow_speed
    global_position.y = global_position.y + (player.global_position.y - global_position.y) * follow_speed

    # Keep a fixed visible rectangle around the player
    limit_left   = player.global_position.x - view_half_width
    limit_right  = player.global_position.x + view_half_width
    limit_top    = player.global_position.y - view_half_height
    limit_bottom = player.global_position.y + view_half_height
