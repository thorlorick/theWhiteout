class_name PlannerComponent
# -----------------------------------------------------------------------------
# PlannerComponent
# Reads goals and actions, returns the best plan.
# Inertia breaks ties — Joe keeps doing what he's doing unless something
# clearly wins. This prevents twitchy indecision at equal urge values.
# Cost is now factored into goal selection — expensive goals need stronger
# urges to win. This is how costs shape personality.
# -----------------------------------------------------------------------------

# the name of the action Joe is currently executing — used for inertia
var current_action_name: String = ""

# inertia margin — how much a new goal must beat the current one to switch
# keeps Joe from flip-flopping when urges are nearly equal
const INERTIA_MARGIN: float = 0.08

# -----------------------------------------------------------------------------
# get_best_goal — finds the highest value goal (priority / cost)
# applies inertia to prevent constant switching
# now requires actions and world_state to find cheapest valid action per goal
# -----------------------------------------------------------------------------
func get_best_goal(goals: Array, current_goal_name: String, actions: Array, world_state: WorldState) -> Dictionary:
	var best: Dictionary = {}
	var best_score: float = -1.0
	for goal in goals:
		# find cheapest action that satisfies this goal with met preconditions
		var cheapest_cost: float = 999.0
		for action in actions:
			if not _action_satisfies_goal(action, goal):
				continue
			if not _preconditions_met(action, world_state):
				continue
			cheapest_cost = min(cheapest_cost, action["cost"])
		# no valid action found — skip this goal entirely
		if cheapest_cost == 999.0:
			continue
		# score = priority / cost — expensive goals need stronger urges to win
		var score = goal["priority"] / max(cheapest_cost, 0.01)
		# give current goal a free inertia boost so it takes a clear winner to switch
		if goal["name"] == current_goal_name:
			score += INERTIA_MARGIN
		if score > best_score:
			best_score = score
			best       = goal
	return best

# -----------------------------------------------------------------------------
# get_best_action — finds the action that satisfies the goal at lowest cost
# priority / cost = value — highest value wins
# -----------------------------------------------------------------------------
func get_best_action(goal: Dictionary, actions: Array, world_state: WorldState) -> Dictionary:
	var best: Dictionary = {}
	var best_value: float = -1.0
	for action in actions:
		# skip actions whose effects don't satisfy the goal
		if not _action_satisfies_goal(action, goal):
			continue
		# skip actions whose preconditions aren't met
		if not _preconditions_met(action, world_state):
			continue
		# value = priority / cost — cheap actions with high priority win
		var value = goal["priority"] / max(action["cost"], 0.01)
		if value > best_value:
			best_value = value
			best       = action
	return best

# -----------------------------------------------------------------------------
# is_goal_satisfied — checks if desired state already matches world state
# -----------------------------------------------------------------------------
func is_goal_satisfied(goal: Dictionary, world_state: WorldState) -> bool:
	for key in goal["desired_state"]:
		if world_state.get_state(key) != goal["desired_state"][key]:
			return false
	return true

# -----------------------------------------------------------------------------
# _action_satisfies_goal — does this action's effects match the goal's desired state?
# -----------------------------------------------------------------------------
func _action_satisfies_goal(action: Dictionary, goal: Dictionary) -> bool:
	for key in goal["desired_state"]:
		if action["effects"].get(key) == goal["desired_state"][key]:
			return true
	return false

# -----------------------------------------------------------------------------
# _preconditions_met — are all preconditions true in current world state?
# -----------------------------------------------------------------------------
func _preconditions_met(action: Dictionary, world_state: WorldState) -> bool:
	for key in action["preconditions"]:
		if world_state.get_state(key) != action["preconditions"][key]:
			return false
	return true
