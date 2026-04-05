class_name CombatFSMComponent

# -----------------------------------------------------------------------------
# CombatFSMComponent
# A traffic light for combat. One job: say yes or no to incoming requests.
# Never touches other components. Never makes decisions. Signals only.
# The agent calls change_state(). Everyone else just reads can_act().
# -----------------------------------------------------------------------------

signal state_changed(new_state: int)

enum State {READY, ATTACKING, STUNNED, DEAD}

var current_state: State = State.READY

# -----------------------------------------------------------------------------
# change_state — the only door in. agent calls this, nobody else.
# -----------------------------------------------------------------------------
func change_state(new_state: State) -> void:
	if current_state == State.DEAD:
		return
	if new_state == current_state:
		return
	current_state = new_state
	print(">>> COMBAT FSM: %s" % State.keys()[new_state])
	state_changed.emit(new_state)

# -----------------------------------------------------------------------------
# can_act — the one question everyone asks
# -----------------------------------------------------------------------------
func can_act() -> bool:
	return current_state == State.READY

# -----------------------------------------------------------------------------
# is_vulnerable — stunned guards take extra punishment
# planner can read this to make decisions
# -----------------------------------------------------------------------------
func is_vulnerable() -> bool:
	return current_state == State.STUNNED
