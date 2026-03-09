class_name WorldState

var state = {
	"at_home":   false,
	"gap_closed": true,
	"sees_ue":   false,
	"ue_target": null
}

func get_state(key: String):
	return state.get(key)
func set_state(key: String, value) -> void:
	state[key] = value
func has_state(key: String) -> bool:
	return state.has(key)
