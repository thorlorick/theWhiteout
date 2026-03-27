class_name AnimationEvents
extends Node
# -----------------------------------------------------------------------------
# AnimationEvents
# Emits signals at key animation frames.
# Called by AnimationPlayer method tracks.
# Knows nothing about hitboxes, damage, or components.
# -----------------------------------------------------------------------------

signal attack_hit_frame
signal attack_animation_finished

func on_attack_hit_frame() -> void:
	attack_hit_frame.emit()

func on_attack_animation_finished() -> void:
	attack_animation_finished.emit()
