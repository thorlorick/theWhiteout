class_name ChaseComponent
extends Node
# -----------------------------------------------------------------------------
# ChaseComponent
# Moves the guard toward a confirmed target.
# No longer measures gap — vision owns that now.
# Emits ue_lost only when the target gets too far away as a safety fallback.
# -----------------------------------------------------------------------------
signal ue_lost
signal move_to(position: Vector2)

const GIVEUP_DISTANCE: float = 400.0   # too far — guard gives up

var target: Node2D = null
var active: bool   = false

@export var body: CharacterBody2D

func start_chase(ue_body: Node2D) -> void:
	target = ue_body
	active = true

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
		ue_lost.emit()
		return
	move_to.emit(target.global_position)
