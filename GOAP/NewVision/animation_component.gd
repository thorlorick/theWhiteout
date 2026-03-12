class_name AnimationComponent
# -----------------------------------------------------------------------------
# AnimationComponent
# Receives a Vector2 direction, converts to animation name internally.
# Animation files never change — idle_down, walk_down etc. stay as-is.
# -----------------------------------------------------------------------------
var animation_player: AnimationPlayer
var current_direction: Vector2 = Vector2.DOWN
var current_animation: String  = ""

func setup(player: AnimationPlayer) -> void:
	animation_player = player

func update(direction: Vector2, is_moving: bool) -> void:
	if direction != Vector2.ZERO:
		current_direction = direction
	var anim_name = ("walk_" if is_moving else "idle_") + _direction_to_string(current_direction)
	if anim_name != current_animation:
		current_animation = anim_name
		animation_player.play(anim_name)

func _direction_to_string(dir: Vector2) -> String:
	if dir == Vector2.ZERO:
		return "down"
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	return "down" if dir.y > 0 else "up"
