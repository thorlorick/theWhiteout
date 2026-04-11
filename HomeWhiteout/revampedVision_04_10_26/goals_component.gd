class_name GoalsComponent
# -----------------------------------------------------------------------------
# GoalsComponent
# Pure data. Four goals, four urges, four priorities.
# Priorities written every frame by GuardAgent from UrgeComponent.
# Goals are INTENTIONS. Actions are how the planner satisfies them.
# -----------------------------------------------------------------------------
var goals: Array = [
	{
		"name":          "BeSafe",
		"desired_state": {"is_safe": true},
		"priority":      0.0
	},
	{
		"name":          "DoWork",
		"desired_state": {"working": true, "sees_target": false},  
		"priority":      0.0
	},
	{
		"name":          "ResolveUnknown",
		"desired_state": {"unknown_resolved": true},
		"priority":      0.0
	},
	{
		"name":          "ClearDanger",
		"desired_state": {"danger_cleared": true, "sees_target": false},  
		"priority":      0.0
	},
]
# -----------------------------------------------------------------------------
# update_priorities — looks up by name, order of array doesn't matter
# -----------------------------------------------------------------------------
func update_priorities(comfort: float, duty: float, curiosity: float, aggression: float) -> void:
	for goal in goals:
		match goal["name"]:
			"BeSafe":         goal["priority"] = comfort
			"DoWork":         goal["priority"] = duty
			"ResolveUnknown": goal["priority"] = curiosity
			"ClearDanger":    goal["priority"] = aggression
