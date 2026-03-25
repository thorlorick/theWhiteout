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
signal interrupt_attack_stopped
signal interrupt_hurt_started
signal interrupt_death_started

# -----------------------------------------------------------------------------
# on_danger_entered — threat is too close, chase must start now
# doesn't wait for the planner
# -----------------------------------------------------------------------------
func on_danger_entered() -> void:
	print(">>> REFLEX: danger entered — interrupt chase start")
	interrupt_patrol_stopped.emit()
	interrupt_search_stopped.emit()
	interrupt_run_started.emit()
	interrupt_chase_started.emit()

# -----------------------------------------------------------------------------
# on_target_spotted — eyes just locked on, stop everything else
# -----------------------------------------------------------------------------
func on_target_spotted() -> void:
	print(">>> REFLEX: target spotted — drop everything, start chase")
	interrupt_patrol_stopped.emit()
	interrupt_search_stopped.emit()

# -----------------------------------------------------------------------------
# on_target_lost — lost visual, stop chasing and reset speed
# -----------------------------------------------------------------------------
func on_target_lost() -> void:
	print(">>> REFLEX: target lost — interrupt stop chase, reset speed")
	interrupt_chase_stopped.emit()
	interrupt_speed_reset.emit()

# -----------------------------------------------------------------------------
# on_chase_target_lost — chase component gave up entirely
# -----------------------------------------------------------------------------
func on_chase_target_lost() -> void:
	print(">>> REFLEX: chase gave up — interrupt stop chase, reset speed")
	interrupt_chase_stopped.emit()
	interrupt_speed_reset.emit()

# -----------------------------------------------------------------------------
# on_target_died — target eliminated, full stop
# -----------------------------------------------------------------------------
func on_target_died() -> void:
	print(">>> REFLEX: target died — interrupt full stop")
	interrupt_chase_stopped.emit()
	interrupt_patrol_stopped.emit()
	interrupt_search_stopped.emit()
	interrupt_movement_stopped.emit()
	interrupt_speed_reset.emit()

# -----------------------------------------------------------------------------
# on_hit_received — holy @#$% something just hit me
# brain offline, body reacting, stop everything
# -----------------------------------------------------------------------------
func on_hit_received() -> void:
	print(">>> REFLEX: hit received — interrupt everything, play hurt")
	interrupt_attack_stopped.emit()
	interrupt_chase_stopped.emit()
	interrupt_patrol_stopped.emit()
	interrupt_search_stopped.emit()
	interrupt_movement_stopped.emit()
	interrupt_hurt_started.emit()

# -----------------------------------------------------------------------------
# on_died — I am dying, full stop, no recovery
# -----------------------------------------------------------------------------
func on_died() -> void:
	print(">>> REFLEX: died — interrupt everything, play death")
	interrupt_attack_stopped.emit()
	interrupt_chase_stopped.emit()
	interrupt_patrol_stopped.emit()
	interrupt_search_stopped.emit()
	interrupt_movement_stopped.emit()
	interrupt_death_started.emit()
