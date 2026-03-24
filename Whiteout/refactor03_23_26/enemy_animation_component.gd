class_name EnemyAnimationComponent
extends Node
# -----------------------------------------------------------------------------
# EnemyAnimationComponent
# Receives direction + state from GuardAgent.
# Drives AnimationTree blendspaces and conditions.
# Knows nothing about AI, movement, or health — just animations.
# -----------------------------------------------------------------------------

var animation_tree:  AnimationTree
var current_direction: Vector2 = Vector2.DOWN

func setup(tree: AnimationTree) -> void:
	animation_tree = tree

func update(direction: Vector2, is_moving: bool, is_running: bool) -> void:
	if direction != Vector2.ZERO:
		current_direction = direction

	animation_tree["parameters/walk/blend_position"] = current_direction
	animation_tree["parameters/run/blend_position"]  = current_direction
	animation_tree["parameters/idle/blend_position"] = current_direction

	var state_machine = animation_tree["parameters/playback"] as AnimationNodeStateMachinePlayback

	if is_running and direction != Vector2.ZERO:
		state_machine.travel("run")
	elif is_moving and direction != Vector2.ZERO:
		state_machine.travel("walk")
	else:
		state_machine.travel("idle")

func play_attack(is_running: bool) -> void:
	var state_machine = animation_tree["parameters/playback"] as AnimationNodeStateMachinePlayback
	if is_running:
		state_machine.travel("run_attack")
	else:
		state_machine.travel("walk_attack")

func play_hurt() -> void:
	var state_machine = animation_tree["parameters/playback"] as AnimationNodeStateMachinePlayback
	state_machine.travel("hurt")

func play_death() -> void:
	var state_machine = animation_tree["parameters/playback"] as AnimationNodeStateMachinePlayback
	state_machine.travel("death")
