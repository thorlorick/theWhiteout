class_name ChaseComponent
extends Node
# -----------------------------------------------------------------------------
# ChaseComponent
# Follows the UE and signals when close enough to attack or too far to continue.
# Does not attack — that's AttackComponent's job.
# Does not move — emits move_to for GuardAgent to handle.
# -----------------------------------------------------------------------------
signal gap_closed
signal ue_lost
signal move_to(position: Vector2)

const STRIKE_DISTANCE: float = 50.0    # close enough to attack
const GIVEUP_DISTANCE: float = 400.0   # too far — give up chase

var target:      Node2D = null
var active:      bool   = false
var _gap_closed: bool   = false

@export var body: CharacterBody2D

# -----------------------------------------------------------------------------
# start_chase — begin following the UE
# -----------------------------------------------------------------------------
func start_chase(ue_body: Node2D) -> void:
	target      = ue_body
	active      = true
	_gap_closed = false

# -----------------------------------------------------------------------------
# stop_chase — clean up
# -----------------------------------------------------------------------------
func stop_chase() -> void:
	target      = null
	active      = false
	_gap_closed = false

# -----------------------------------------------------------------------------
# _process — measure distance every frame, emit signals on thresholds
# -----------------------------------------------------------------------------
func _process(_delta: float) -> void:
	if not active or target == null:
		return

	var distance = body.global_position.distance_to(target.global_position)

	if distance <= STRIKE_DISTANCE:
		if not _gap_closed:
			print(">>> CHASE: strike range reached — gap closed")
			_gap_closed = true
			gap_closed.emit()
		return  # stay here, let AttackComponent do its job

	if distance >= GIVEUP_DISTANCE:
		print(">>> CHASE: too far — giving up")
		stop_chase()
		ue_lost.emit()
		return

	# UE moved away — gap reopened
	if _gap_closed:
		print(">>> CHASE: UE escaped strike range — resuming chase")
		_gap_closed = false

	move_to.emit(target.global_position)
