class_name KnockbackComponent
extends Node

# -----------------------------------------------------------------------------
# KnockbackComponent
# Physically shoves the body when a hit lands.
# Owns the tween, owns the timer, emits when done.
# Touches nothing directly — signals out, agent routes.
# -----------------------------------------------------------------------------

signal knockback_finished

@export var knockback_duration: float = 0.2

var _body: CharacterBody2D

# -----------------------------------------------------------------------------
# setup — called by agent in _ready(), hands us the body to push
# -----------------------------------------------------------------------------
func setup(body: CharacterBody2D) -> void:
	_body = body

# -----------------------------------------------------------------------------
# apply — shove the body, start the clock
# -----------------------------------------------------------------------------
func apply(direction: Vector2, force: float) -> void:
	if _body == null:
		return
	var target = _body.global_position + direction.normalized() * force
	var tween = create_tween()
	tween.tween_property(_body, "global_position", target, knockback_duration)
	tween.tween_callback(_on_knockback_finished)
	print(">>> KNOCKBACK: applied — direction: %s force: %.1f" % [direction, force])

# -----------------------------------------------------------------------------
# _on_knockback_finished — tween done, signal out
# -----------------------------------------------------------------------------
func _on_knockback_finished() -> void:
	print(">>> KNOCKBACK: finished")
	knockback_finished.emit()
