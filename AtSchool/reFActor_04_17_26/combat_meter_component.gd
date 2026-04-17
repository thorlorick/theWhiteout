class_name CombatMeterComponent
extends Node

# -----------------------------------------------------------------------------
# CombatMeterComponent
# A pressure gauge that fills from multiple sources.
# This component only measures and signals. GuardAgent decides everything.
# When meter >= max_meter, meter_full fires once.
# When meter stays below exit_threshold long enough, meter_empty fires.
# -----------------------------------------------------------------------------

signal meter_full()
signal meter_empty()
signal meter_low()

# -----------------------------------------------------------------------------
# EXPORTS
# -----------------------------------------------------------------------------
@export_group("Meter Settings")
@export var max_meter:              float = 5.0
@export var drain_rate:             float = 1.0
@export var exit_threshold:         float = 1.0
@export var exit_duration:          float = 2.0
@export var personal_space_fill_rate: float = 3.0

# -----------------------------------------------------------------------------
# INTERNAL STATE
# -----------------------------------------------------------------------------
var meter_filled:   float = 0.0
var _is_full:       bool  = false
var _exit_timer:    float = 0.0
var _exit_counting: bool  = false

# -----------------------------------------------------------------------------
# PHYSICS PROCESS
# -----------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	_check_thresholds(delta)
	_tick_drain(delta)

# -----------------------------------------------------------------------------
# add_to_meter
# Called by GuardAgent when any outside system reports a fill event.
# Vision hit, personal space contact, hit received — all come through here.
# -----------------------------------------------------------------------------
func add_to_meter(amount: float) -> void:
	meter_filled = min(max_meter, meter_filled + amount)

# -----------------------------------------------------------------------------
# remove_from_meter
# Called by GuardAgent when something should pull the meter down.
# -----------------------------------------------------------------------------
func remove_from_meter(amount: float) -> void:
	meter_filled = max(0.0, meter_filled - amount)

# -----------------------------------------------------------------------------
# reset
# Called by GuardAgent when combat is fully over.
# -----------------------------------------------------------------------------
func reset() -> void:
	meter_filled  = 0.0
	_is_full      = false
	_exit_timer   = 0.0
	_exit_counting = false

# -----------------------------------------------------------------------------
# _tick_drain
# Meter bleeds down every frame on its own.
# Outside pressure has to keep fighting the drain to keep it alive.
# -----------------------------------------------------------------------------
func _tick_drain(delta: float) -> void:
	if meter_filled > 0.0:
		meter_filled = max(0.0, meter_filled - drain_rate * delta)

# -----------------------------------------------------------------------------
# _check_thresholds
# Watches the meter level and manages entry, exit timer, and signals.
# -----------------------------------------------------------------------------
func _check_thresholds(delta: float) -> void:

	# --- FULL ---
	if meter_filled >= max_meter:
		if not _is_full:
			_is_full = true
			print(">>> COMBAT METER: full")
			meter_full.emit()
		return

	# meter dropped below full
	if _is_full:
		_is_full = false

	# --- LOW ---
	if meter_filled <= exit_threshold:
		if not _exit_counting:
			_exit_counting = true
			_exit_timer    = 0.0
			meter_low.emit()

		_exit_timer += delta

		if _exit_timer >= exit_duration:
			_exit_counting = false
			_exit_timer    = 0.0
			print(">>> COMBAT METER: empty")
			meter_empty.emit()
	else:
		if _exit_counting:
			_exit_counting = false
			_exit_timer    = 0.0
