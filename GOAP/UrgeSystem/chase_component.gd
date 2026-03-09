class_name ChaseComponent
extends Node

# -----------------------------------------------------------------------------
# ChaseComponent
# Pure geometry. Measures distances, determines threat zone, sets gap urge.
# No emotion here — just spatial awareness.
# Drives gap_urge in UrgeComponent based on UE-to-home distance.
# -----------------------------------------------------------------------------

signal ue_caught
signal ue_lost
signal move_to(position: Vector2)
signal zone_changed(new_zone: int)

# Joe-to-UE distance — close enough to act
const STRIKE_DISTANCE: float = 50.0

# UE-to-home threat zones
const OUTER_ZONE:  float = 300.0
const MIDDLE_ZONE: float = 200.0
const INNER_ZONE:  float = 100.0

# gap urge values per zone — tactical, not emotional
# outer:  not a threat yet
# middle: worth watching
# inner:  close the gap now
const GAP_URGE_OUTER:  float = 0.0
const GAP_URGE_MIDDLE: float = 0.35
const GAP_URGE_INNER:  float = 0.85

@export var body: CharacterBody2D

var target:       Node2D = null
var active:       bool   = false
var _current_zone: int   = -1   # -1 = no threat

# -----------------------------------------------------------------------------
# start_chase / stop_chase
# -----------------------------------------------------------------------------
func start_chase(ue_body: Node2D) -> void:
	target = ue_body
	active = true
	_current_zone = -1

func stop_chase() -> void:
	target        = null
	active        = false
	_current_zone = -1

# -----------------------------------------------------------------------------
# _process — runs every frame when active
# -----------------------------------------------------------------------------
func _process(_delta: float) -> void:
	if not active or target == null:
		return

	var joe_to_ue = body.global_position.distance_to(target.global_position)

	# close enough to act — stop chasing
	if joe_to_ue <= STRIKE_DISTANCE:
		print(">>> CHASE: strike range reached")
		stop_chase()
		ue_caught.emit()
		return

	# keep moving toward UE
	move_to.emit(target.global_position)

# -----------------------------------------------------------------------------
# evaluate_threat — called every frame by EnemyAgent with UE-to-home distance
# returns the gap urge value the zone demands
# emits zone_changed only when zone actually changes
# -----------------------------------------------------------------------------
func evaluate_threat(ue_to_home: float) -> float:
	var new_zone: int
	var gap_urge: float

	if ue_to_home >= OUTER_ZONE:
		new_zone = -1
		gap_urge = GAP_URGE_OUTER
	elif ue_to_home >= MIDDLE_ZONE:
		new_zone = 0
		gap_urge = GAP_URGE_MIDDLE
	elif ue_to_home >= INNER_ZONE:
		new_zone = 1
		gap_urge = GAP_URGE_MIDDLE
	else:
		new_zone = 2
		gap_urge = GAP_URGE_INNER

	if new_zone != _current_zone:
		_current_zone = new_zone
		match new_zone:
			-1: print(">>> ZONE: UE outside threat range (%.1f from home)" % ue_to_home)
			0:  print(">>> ZONE: UE in outer zone — watching (%.1f from home)" % ue_to_home)
			1:  print(">>> ZONE: UE in middle zone — uneasy (%.1f from home)" % ue_to_home)
			2:  print(">>> ZONE: UE in inner zone — HOME THREATENED (%.1f from home)" % ue_to_home)
		zone_changed.emit(new_zone)

	return gap_urge

# -----------------------------------------------------------------------------
# get_current_zone — read-only access for UrgeComponent tick
# -----------------------------------------------------------------------------
func get_current_zone() -> int:
	return _current_zone
