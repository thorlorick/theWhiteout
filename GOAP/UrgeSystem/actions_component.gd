class_name ActionsComponent

# -----------------------------------------------------------------------------
# ActionsComponent
# Actions have names, costs, preconditions, and effects.
# Costs are personality — change these to change how Joe behaves.
# A cheap action gets picked easily. An expensive action needs strong urge to win.
#
# TUNING GUIDE:
#   cost 0.1 — Joe does this very readily
#   cost 0.3 — Joe does this when the urge is moderate
#   cost 0.6 — Joe only does this when the urge is strong
#   cost 0.9 — Joe resists this heavily, needs overwhelming urge
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
]
