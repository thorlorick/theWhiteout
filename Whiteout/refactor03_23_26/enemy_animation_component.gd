class_name EnemyAnimationComponent
extends Node

# -----------------------------------------------------------------------------
# EnemyAnimationComponent
# Pure animation driver.
# Receives direction + movement state + attack triggers.
# -----------------------------------------------------------------------------

var animation_tree: AnimationTree
var state_machine: AnimationNodeStateMachinePlayback

var current_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false

# -----------------------------------------------------------------------------

func setup(tree: AnimationTree) -> void:
	animation_tree = tree
	state_machine = animation_tree["parameters/playback"]

# -----------------------------------------------------------------------------

func update(direction: Vector2, is_moving: bool, is_running: bool) -> void:
	# Always update facing direction
	if direction != Vector2.ZERO:
		current_direction = direction.normalized()

	# Always feed direction into ALL blendspaces
	animation_tree["parameters/idle/blend_position"] = current_direction
	animation_tree["parameters/walk/blend_position"] = current_direction
	animation_tree["parameters/run/blend_position"]  = current_direction
	animation_tree["parameters/walk_attack/blend_position"] = current_direction
	animation_tree["parameters/run_attack/blend_position"]  = current_direction

	# 🚨 If attacking → DO NOT override state
	if is_attacking:
		return

	# Normal movement state control
	if is_running and direction != Vector2.ZERO:
		state_machine.travel("run")
	elif is_moving and direction != Vector2.ZERO:
		state_machine.travel("walk")
	else:
		state_machine.travel("idle")

# -----------------------------------------------------------------------------

func play_attack(is_running: bool) -> void:
	if is_attacking:
		return

	is_attacking = true

	if is_running:
		state_machine.travel("run_attack")
	else:
		state_machine.travel("walk_attack")

