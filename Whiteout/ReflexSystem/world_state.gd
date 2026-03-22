class_name WorldState
# -----------------------------------------------------------------------------
# WorldState
# Simple key/value store for Joe's understanding of the world.
# Single source of truth. Everything reads from here, nothing else.
# -----------------------------------------------------------------------------
var _state: Dictionary = {
	"at_home":       false,
	"patrolling":    false,
	"sees_ue":       false,
	"ue_target":     null,
	"gap_closed":    false,
	"target_lost":   false,
	"target_found":  true,
	"ue_eliminated": false,
}

func get_state(key: String) -> Variant:
	return _state.get(key, null)

func set_state(key: String, value: Variant) -> void:
	_state[key] = value
