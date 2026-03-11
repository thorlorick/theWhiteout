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
		"effects":       {"at_home": true, "patrolling": false}
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
		"effects":       {"ue_eliminated": true}
	},
	{
		"name":          "Search",
		"cost":          1.0,
		"preconditions": {"target_lost": true, "target_found": false},
		"effects":       {"target_found": true}
	},
]

# -----------------------------------------------------------------------------
# apply_personality — called once by GuardAgent in _ready()
# multiplies base costs by personality values
# -----------------------------------------------------------------------------
func apply_personality(p: PersonalityResource) -> void:
	for action in actions:
		match action["name"]:
			"GoHome":   action["cost"] *= p.go_home_cost
			"GoPatrol": action["cost"] *= p.go_patrol_cost
			"ChaseUE":  action["cost"] *= p.chase_cost
			"Attack":   action["cost"] *= p.attack_cost
			"Search":   action["cost"] *= p.search_cost
