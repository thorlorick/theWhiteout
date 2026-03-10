class_name ChaseComponent
extends Node
signal ue_caught
signal ue_lost
signal move_to(position: Vector2)

const STRIKE_DISTANCE:  float = 50.0   # close enough to hit
const GIVEUP_DISTANCE:  float = 400.0  # too far — Joe gives up

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

	if distance <= STRIKE_DISTANCE:
		print(">>> CHASE: close enough — strike range reached")
		stop_chase()
		ue_caught.emit()
		return

	if distance >= GIVEUP_DISTANCE:
		print(">>> CHASE: too far — giving up")
		stop_chase()
		ue_lost.emit()
		return

	move_to.emit(target.global_position)
