extends Sprite2D

var last_direction: String = "down"

func _on_direction_input(direction: Vector2):
	if direction == Vector2.ZERO:
		$AnimationPlayer.play("idle_" + last_direction)
		return
	
	if abs(direction.x) > abs(direction.y):
		if direction.x < 0:
			last_direction = "left"
			$AnimationPlayer.play("walk_left")
		else:
			last_direction = "right"
			$AnimationPlayer.play("walk_right")
	else:
		if direction.y < 0:
			last_direction = "up"
			$AnimationPlayer.play("walk_up")
		else:
			last_direction = "down"
			$AnimationPlayer.play("walk_down")
			
func _on_attack_input():
	$AnimationPlayer.play("attack_" + last_direction)
