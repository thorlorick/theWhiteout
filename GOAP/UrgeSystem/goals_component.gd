class_name GoalsComponent

# -----------------------------------------------------------------------------
# GoalsComponent
# Pure data. Goals have names, desired world states, and priorities.
# Priorities are written every frame by EnemyAgent from UrgeComponent.
# This component owns nothing and decides nothing.
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
		"name":          "CloseTheGap",
		"desired_state": {"gap_closed": true},
		"priority":      0.0
	},
]

# -----------------------------------------------------------------------------
# update_priorities — called every frame by EnemyAgent
# -----------------------------------------------------------------------------
func update_priorities(home: float, patrol: float, gap: float) -> void:
	goals[0]["priority"] = home
	goals[1]["priority"] = patrol
	goals[2]["priority"] = gap
