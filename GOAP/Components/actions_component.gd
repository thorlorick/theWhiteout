class_name ActionsComponent

var actions = [
	{
		"name": "GoHome",
		"preconditions": {"at_home": false},
		"effects":       {"at_home": true, "patrolling": false},
		"cost": 1.0
	},
	{
		"name": "GoPatrol",
		"preconditions": {},
		"effects":       {"patrolling": true, "at_home": false},
		"cost": 1.0
	},
	{
		"name": "ChaseUE",
		"preconditions": {"sees_ue": true},     # needs to see the UE to chase
		"effects":       {"gap_closed": true},   # NEW: chasing resolves the gap goal
		"cost": 1.0
	},
]
