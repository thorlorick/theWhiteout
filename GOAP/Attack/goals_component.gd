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
		"desired_state": {"ue_eliminated": true},
		"priority":      0.0
	}
]

func update_priorities(comfort: float, duty: float, curiosity: float, aggression: float) -> void:
	goals[0]["priority"] = comfort
	goals[1]["priority"] = duty
	goals[2]["priority"] = curiosity
	goals[3]["priority"] = aggression
