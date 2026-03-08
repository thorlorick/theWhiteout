class_name ChaseComponent
extends Node

signal ue_lost
signal ue_caught
signal move_to(position: Vector2)

const CATCH_DISTANCE: float = 5.0
const LOSE_DISTANCE:  float = 250.0

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
	if distance <= CATCH_DISTANCE:
		print(">>> UE CAUGHT!")
		stop_chase()
		ue_caught.emit()
		return
	if distance >= LOSE_DISTANCE:
		print(">>> UE LOST!")
		stop_chase()
		ue_lost.emit()
		return
	move_to.emit(target.global_position)
