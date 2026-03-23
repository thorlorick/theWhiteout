class_name GoalsComponent
# -----------------------------------------------------------------------------
# GoalsComponent
# Pure data. Four goals, four urges, four priorities.
# Priorities written every frame by GuardAgent from UrgeComponent.
# -----------------------------------------------------------------------------
var goals: Array = [
	{
		"name":          "BeHome",
		"desired_state": {"at_home": true},
		"priority":      0.0
	},
	{
		"name":          "Patrol",
		"desired_state": {"patrolling": true},
		"priority":      0.0
	},
	{
		"name":          "FindLostTarget",
		"desired_state": {"target_found": true},
		"priority":      0.0
	},
	{
		"name":          "Attack",
		"desired_state": {"target_eliminated": true},
		"priority":      0.0
	}
]

# -----------------------------------------------------------------------------
# update_priorities — looks up by name, order of array doesn't matter
# -----------------------------------------------------------------------------
func update_priorities(comfort: float, duty: float, curiosity: float, aggression: float) -> void:
	for goal in goals:
		match goal["name"]:
			"BeHome":         goal["priority"] = comfort
			"Patrol":         goal["priority"] = duty
			"FindLostTarget": goal["priority"] = curiosity
			"Attack":         goal["priority"] = aggression
