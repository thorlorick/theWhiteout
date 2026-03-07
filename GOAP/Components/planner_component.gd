class_name PlannerComponent

func get_best_goal(goals: Array) -> Dictionary:
	var best = {}
	for goal in goals:
		if best.is_empty() or goal["priority"] > best["priority"]:
			best = goal
	return best

func is_goal_satisfied(goal: Dictionary, world_state: Dictionary) -> bool:
	if goal["name"] == "Patrol":
		return false
	for key in goal["desired_state"]:
		if world_state.get(key) != goal["desired_state"][key]:
			return false
	return true

func get_action_for_goal(goal: Dictionary, actions: Array, world_state: Dictionary) -> Dictionary:
	for action in actions:
		for key in goal["desired_state"]:
			if action["effects"].get(key) == goal["desired_state"][key]:
				var preconditions_met = true
				for pre_key in action["preconditions"]:
					if world_state.get(pre_key) != action["preconditions"][pre_key]:
						preconditions_met = false
				if preconditions_met:
					return action
	return {}
