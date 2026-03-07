class_name AnimationComponent

var animation_player: AnimationPlayer
var current_direction: String = "down"
var current_animation: String = ""

func setup(player: AnimationPlayer) -> void:
	animation_player = player

func update(direction: String, is_moving: bool) -> void:
	if direction != "":
		current_direction = direction
	var anim_name = ("walk_" if is_moving else "idle_") + current_direction
	if anim_name != current_animation:
		current_animation = anim_name
		animation_player.play(anim_name)
