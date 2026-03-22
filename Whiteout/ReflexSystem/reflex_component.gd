class_name ReflexComponent
# -----------------------------------------------------------------------------
# ReflexComponent
# Immediate, pre-deliberate responses to startling events.
# No decisions. No component touching. Signals only.
# The agent wires these signals and does the shouting.
# -----------------------------------------------------------------------------

signal interrupt_chase_started
signal interrupt_movement_stopped
signal interrupt_patrol_stopped
signal interrupt_search_stopped
signal interrupt_speed_reset
signal interrupt_run_started
signal interrupt_chase_stopped

# -----------------------------------------------------------------------------
# on_danger_entered — threat is too close, chase must start now
# doesn't wait for the planner
# -----------------------------------------------------------------------------
func on_danger_entered() -> void:
	print(">>> REFLEX: danger entered — interrupt chase start")
	emit_signal("interrupt_patrol_stopped")
	emit_signal("interrupt_search_stopped")
	emit_signal("interrupt_run_started")
	emit_signal("interrupt_chase_started")

# -----------------------------------------------------------------------------
# on_ue_spotted — eyes just locked on, stop everything else
# -----------------------------------------------------------------------------
func on_ue_spotted() -> void:
	print(">>> REFLEX: ue spotted — interrupt stop patrol and search")
	emit_signal("interrupt_patrol_stopped")
	emit_signal("interrupt_search_stopped")

# -----------------------------------------------------------------------------
# on_ue_lost — lost visual, stop chasing and reset speed
# -----------------------------------------------------------------------------
func on_ue_lost() -> void:
	print(">>> REFLEX: ue lost — interrupt stop chase, reset speed")
	emit_signal("interrupt_chase_stopped")
	emit_signal("interrupt_speed_reset")

# -----------------------------------------------------------------------------
# on_chase_ue_lost — chase component gave up entirely
# -----------------------------------------------------------------------------
func on_chase_ue_lost() -> void:
	print(">>> REFLEX: chase gave up — interrupt stop chase, reset speed")
	emit_signal("interrupt_chase_stopped")
	emit_signal("interrupt_speed_reset")

# -----------------------------------------------------------------------------
# on_ue_died — target eliminated, full stop
# -----------------------------------------------------------------------------
func on_ue_died() -> void:
	print(">>> REFLEX: ue died — interrupt full stop")
	emit_signal("interrupt_chase_stopped")
	emit_signal("interrupt_patrol_stopped")
	emit_signal("interrupt_search_stopped")
	emit_signal("interrupt_movement_stopped")
	emit_signal("interrupt_speed_reset")
