class_name ActionsComponent

var actions = [
	{
		"name":          "GoHome",
		"preconditions": {"at_home": false},
		"effects":       {"at_home": true},
		"cost": 1.0
	},
	{
		"name":          "GoPatrol",
		"preconditions": {},
		"effects":       {"at_home": false},
		"cost": 1.0
	},
	{
		"name":          "ChaseUE",
		"preconditions": {"sees_ue": true},
		"effects":       {"gap_closed": true},
		"cost": 1.0
	},
]

