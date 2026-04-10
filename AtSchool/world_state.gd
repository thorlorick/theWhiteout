class_name WorldState
# -----------------------------------------------------------------------------
# WorldState
# Simple key/value store understanding of the world.
# Single source of truth. Everything reads from here, nothing else.
# -----------------------------------------------------------------------------

var _state: Dictionary = {

	# --- location -----------------------------------------------------------
	"at_home":               false,
	"at_post":               false,

	# --- goal desired states ------------------------------------------------
	"is_safe":               false,
	"working":               false,
	"unknown_resolved":      false,
	"danger_cleared":        false,

	# --- threat -------------------------------------------------------------
	"sees_target":			false,
	"threat_nearby":		false,
	"target_lost":			false,
	"meter_is_full":		false,

	# --- target reference ---------------------------------------------------
	# not a bool — holds the actual target node reference.
	# set when target is first spotted, cleared when target is eliminated
	# or considered truly gone. read by chase, attack, and search components.

	"known_target":          null,

	# --- target position ----------------------------------------------------
	# last_known_position: set when target_lost fires, cleared on search end.
	# target_distance: updated every frame vision reports a sighting.
	# both read by planner, meter, and chase logic.

	"last_known_position":   Vector2.ZERO,
	"target_distance":       0.0,
	"in_range":				false,

	# --- guard condition ----------------------------------------------------
	"is_injured":            false,

}

func get_state(key: String) -> Variant:
	return _state.get(key, null)

func set_state(key: String, value: Variant) -> void:
	_state[key] = value
