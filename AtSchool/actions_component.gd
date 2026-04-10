class_name ActionsComponent
# -----------------------------------------------------------------------------
# ActionsComponent
# Actions have names, costs, preconditions, and effects.
# 1.0 = natural response, no friction.
# Above 1.0 = resistance — effort, risk, or conflict with nature.
# Costs are base values for a 5/5/5/5 guard. Personality tuning comes later.
# Chase appears in three goals — cost reflects motivation behind it.
# -----------------------------------------------------------------------------
var actions: Array = [

	# --- BeSafe (is_safe: true) -------------------------------------------
	{
		"name":          "GoHome",
		"cost":          1.0,
		"preconditions": {"at_home": false},
		"effects":       {"at_home": true, "is_safe": true}
	},
	{
		"name":          "Flee",
		"cost":          1.3,
		"preconditions": {"threat_nearby": true},
		"effects":       {"is_safe": true}
	},
	{
		"name":          "Heal",
		"cost":          1.2,
		"preconditions": {"is_injured": true},
		"effects":       {"is_safe": true}
	},

	# --- DoWork (working: true) -------------------------------------------
	{
		"name":          "Patrol",
		"cost":          1.0,
		"preconditions": {"is_safe": true},
		"effects":       {"working": true, "at_home": false}
	},
	{
		"name":          "StandGuard",
		"cost":          1.0,
		"preconditions": {"at_post": true},
		"effects":       {"working": true}
	},
	{
		"name":          "ChaseAsWork",
		"cost":          1.5,
		"preconditions": {"sees_target": true},
		"effects":       {"working": true}
	},

	# --- ClearDanger (danger_cleared: true) -------------------------------
	{
		"name":          "HoldGround",
		"cost":          1.2,
		"preconditions": {"threat_nearby": true},
		"effects":       {"danger_cleared": true}
	},
	{
		"name":          "ChaseAsDanger",
		"cost":          1.0,
		"preconditions": {"sees_target": true},
		"effects":       {"danger_cleared": true}
	},

	# --- ResolveUnknown (unknown_resolved: true) --------------------------
	{
		"name":          "Search",
		"cost":          1.0,
		"preconditions": {"target_lost": true},
		"effects":       {"unknown_resolved": true}
	}
]
