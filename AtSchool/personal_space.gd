class_name PersonalSpace
extends Area2D

# -----------------------------------------------------------------------------
# PersonalSpace
# Tracks whether the player is currently inside the radius.
# Knows nothing about combat or meters — just reports presence.
# GuardAgent reads player_inside each frame and decides what to do.
# -----------------------------------------------------------------------------

var player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false

func is_player_inside() -> bool:
    return player_inside
