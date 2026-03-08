class_name WorldState

var state = {
	"at_home":        true,
	"patrolling":     false,
	"patrol_complete": true,
	"gap_closed":     true,    # NEW: replaces "sees_ue" as a goal-relevant state
	"sees_ue":        false,   # still used internally by vision/chase logic
	"ue_target":      null
}

func get_state(key: String):
	return state.get(key)

func set_state(key: String, value) -> void:
	state[key] = value

func has_state(key: String) -> bool:
	return state.has(key)
