class_name ActionsComponent
# -----------------------------------------------------------------------------
# ActionsComponent
# Actions have names, costs, preconditions, and effects.
# Costs are personality — tuning comes later.
# -----------------------------------------------------------------------------
var actions: Array = [
	{
		"name":          "GoHome",
		"cost":          1.0,
		"preconditions": {"at_home": false},
		"effects":       {"at_home": true}
	},
	{
		"name":          "GoPatrol",
		"cost":          1.0,
		"preconditions": {"at_home": true},
		"effects":       {"patrolling": true, "at_home": false}
	},
	{
		"name":          "ChaseUE",
		"cost":          1.0,
		"preconditions": {"sees_ue": true, "gap_closed": false},
		"effects":       {"gap_closed": true}
	},
	{
		"name":          "Attack",
		"cost":          1.0,
		"preconditions": {"sees_ue": true, "gap_closed": true},
		"effects":       {"is_attacking": true}
	},
	{
		"name":          "Search",
		"cost":          1.0,
		"preconditions": {"target_lost": true},
		"effects":       {"target_lost": false}
	},
]
