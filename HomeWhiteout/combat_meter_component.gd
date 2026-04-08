class_name CombatMeterComponent
extends Node

# -----------------------------------------------------------------------------
# CombatMeterComponent
# A pressure gauge that fills from multiple sources and drives combat state.
# Pre-combat: vision and personal space fill the meter.
# Combat: personal space, hits, and urges drive the dance up and down.
# Vision keeps running throughout — agent simply ignores it during combat.
# When meter >= max_meter, combat_entered fires.
# When meter stays below exit_threshold long enough, combat_lost fires.
# This component only measures and signals. GuardAgent decides everything.
# -----------------------------------------------------------------------------

signal combat_entered(target: Node2D)
signal combat_lost()
signal meter_low()

# -----------------------------------------------------------------------------
# EXPORTS
# -----------------------------------------------------------------------------
@export_group("Meter Settings")
@export var max_meter:      			float = 5.0
@export var drain_rate:     			float = 1.0
@export var exit_threshold: 			float = 1.0
@export var exit_duration:  			float = 2.0
@export var personal_space_fill_rate: 	float = 3.0

# -----------------------------------------------------------------------------
# INTERNAL STATE
# -----------------------------------------------------------------------------
var meter_filled:   float  = 0.0
var in_combat:      bool   = false
var locked_target:  Node2D = null

var _exit_timer:    float  = 0.0
var _exit_counting: bool   = false

# -----------------------------------------------------------------------------
# READY
# -----------------------------------------------------------------------------
func _ready() -> void:
	pass

# -----------------------------------------------------------------------------
# PHYSICS PROCESS
# -----------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	_tick_drain(delta)
	_check_thresholds(delta)

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
# Player leaving personal space, high comfort urge, etc.
# -----------------------------------------------------------------------------
func remove_from_meter(amount: float) -> void:
	meter_filled = max(0.0, meter_filled - amount)

# -----------------------------------------------------------------------------
# _tick_drain
# Meter bleeds down every frame on its own.
# Outside pressure has to keep fighting the drain to keep combat alive.
# -----------------------------------------------------------------------------
func _tick_drain(delta: float) -> void:
	if meter_filled > 0.0:
		meter_filled = max(0.0, meter_filled - drain_rate * delta)

# -----------------------------------------------------------------------------
# _check_thresholds
# Watches the meter level and manages combat entry, exit timer, and signals.
# -----------------------------------------------------------------------------
func _check_thresholds(delta: float) -> void:

	# --- ENTRY ---
	if not in_combat and meter_filled >= max_meter:
		in_combat      = true
		_exit_counting = false
		_exit_timer    = 0.0
		combat_entered.emit(locked_target)
		return

	# --- EXIT GUARD ---
	if in_combat:
		if meter_filled <= exit_threshold:
			if not _exit_counting:
				_exit_counting = true
				_exit_timer    = 0.0
				meter_low.emit()

			_exit_timer += delta

			if _exit_timer >= exit_duration:
				in_combat      = false
				_exit_counting = false
				_exit_timer    = 0.0
				locked_target  = null
				combat_lost.emit()
		else:
			# meter climbed back up — reset the exit timer
			if _exit_counting:
				_exit_counting = false
				_exit_timer    = 0.0
