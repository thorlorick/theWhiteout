class_name ChaseComponent
extends Node

signal ue_caught
signal ue_lost
signal move_to(position: Vector2)

const STRIKE_DISTANCE: float = 50.0  # Joe to UE — close enough to hit

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

	# close enough — stop closing the gap
	if distance <= STRIKE_DISTANCE:
		print(">>> CHASE: close enough — strike range reached")
		stop_chase()
		ue_caught.emit()
		return

	move_to.emit(target.global_position)
