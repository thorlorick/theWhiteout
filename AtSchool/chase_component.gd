class_name ChaseComponent
extends Node

# -----------------------------------------------------------------------------
# ChaseComponent
# Moves the guard toward a confirmed target.
# No longer measures gap — vision owns that now.
# Emits target_lost only when the target gets too far away as a safety fallback.
# -----------------------------------------------------------------------------

signal target_lost
signal move_to(position: Vector2)

const GIVEUP_DISTANCE: float = 400.0   # too far — guard gives up this should be the distance for rays

var target: Node2D = null
var active: bool   = false

@export var body: CharacterBody2D

func start_chase(target_body: Node2D) -> void:
	target = target_body
	active = true
# what - is this for?

func stop_chase() -> void:
	target = null
	active = false

func _process(delta: float) -> void:
	if not active or target == null:
		return
	var distance = body.global_position.distance_to(target.global_position)
	if distance >= GIVEUP_DISTANCE:
		print(">>> CHASE: too far — giving up")
		stop_chase()
		target_lost.emit()
		return
	move_to.emit(target.global_position)
