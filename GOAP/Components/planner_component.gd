class_name PlannerComponent

# returns the highest priority goal
func get_best_goal(goals: Array) -> Dictionary:
	var best = {}
	for goal in goals:
		if best.is_empty() or goal["priority"] > best["priority"]:
			best = goal
	return best

# checks if the goal's desired world state is already true
func is_goal_satisfied(goal: Dictionary, world_state: WorldState) -> bool:
	for key in goal["desired_state"]:
		if world_state.get_state(key) != goal["desired_state"][key]:
			return false
	return true

# finds the first action whose effects satisfy the goal and whose
# preconditions are currently met in the world state
func get_action_for_goal(goal: Dictionary, actions: Array, world_state: WorldState) -> Dictionary:
	for action in actions:
		# check effects match the goal's desired state
		var effects_match = true
		for key in goal["desired_state"]:
			if action["effects"].get(key) != goal["desired_state"][key]:
				effects_match = false
				break
		if not effects_match:
			continue
		# check preconditions are met
		var preconditions_met = true
		for pre_key in action["preconditions"]:
			if world_state.get_state(pre_key) != action["preconditions"][pre_key]:
				preconditions_met = false
				break
		if preconditions_met:
			return action
	return {}
