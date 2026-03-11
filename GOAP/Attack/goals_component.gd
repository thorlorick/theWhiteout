class_name GoalsComponent
# -----------------------------------------------------------------------------
# GoalsComponent
# Pure data. Three goals, three urges, three priorities.
# Priorities written every frame by EnemyAgent from UrgeComponent.
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
]

func update_priorities(comfort: float, duty: float, curiosity: float) -> void:
	goals[0]["priority"] = home
	goals[1]["priority"] = patrol
	goals[2]["priority"] = curiosity
