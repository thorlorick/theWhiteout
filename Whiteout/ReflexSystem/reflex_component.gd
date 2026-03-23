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
	emit_signal("interrupt_patrol_stopped")
	emit_signal("interrupt_search_stopped")
	emit_signal("interrupt_run_started")
	emit_signal("interrupt_chase_started")
# -----------------------------------------------------------------------------
# on_ue_spotted — eyes just locked on, stop everything else
# -----------------------------------------------------------------------------
func on_ue_spotted() -> void:
	print(">>> REFLEX: ue spotted — drop everything, start chase")
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
# -----------------------------------------------------------------------------
# on_hit_received — holy @#$% something just hit me
# brain offline, body reacting, stop everything
# -----------------------------------------------------------------------------
func on_hit_received() -> void:
	print(">>> REFLEX: hit received — interrupt everything, play hurt")
	emit_signal("interrupt_attack_stopped")
	emit_signal("interrupt_chase_stopped")
	emit_signal("interrupt_patrol_stopped")
	emit_signal("interrupt_search_stopped")
	emit_signal("interrupt_movement_stopped")
	emit_signal("interrupt_hurt_started")
# -----------------------------------------------------------------------------
# on_died — I am dying, full stop, no recovery
# -----------------------------------------------------------------------------
func on_died() -> void:
	print(">>> REFLEX: died — interrupt everything, play death")
	emit_signal("interrupt_attack_stopped")
	emit_signal("interrupt_chase_stopped")
	emit_signal("interrupt_patrol_stopped")
	emit_signal("interrupt_search_stopped")
	emit_signal("interrupt_movement_stopped")
	emit_signal("interrupt_death_started")
