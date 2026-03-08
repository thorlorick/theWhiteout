class_name GoalsComponent

var goals = [
	{
		"name": "BeHome",
		"desired_state": {"at_home": true},
		"priority": 0.0
	},
	{
		"name": "Patrol",
		"desired_state": {"patrolling": true},
		"priority": 0.0
	},
	{
		"name": "CloseTheGap",             # NEW: replaces "Chase"
		"desired_state": {"gap_closed": true},  # resolved when UE is caught or lost
		"priority": 0.0
	},
]
