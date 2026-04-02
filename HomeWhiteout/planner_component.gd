class_name PlannerComponent
# -----------------------------------------------------------------------------
# PlannerComponent
# Reads goals and actions, returns the best plan.
# Inertia breaks ties — guard keeps doing what he's doing unless something
# clearly wins. This prevents twitchy indecision at equal urge values.
# -----------------------------------------------------------------------------

# how much a new goal must beat the current one to switch
# keeps guard from flip-flopping when urges are nearly equal
const INERTIA_MARGIN: float = 0.08

# the name of the action currently executing
# stored here for the agent to read — action-level inertia tuning comes later
var current_action_name: String = ""

# -----------------------------------------------------------------------------
# get_best_goal — finds the highest priority goal
# applies inertia to prevent constant switching
# -----------------------------------------------------------------------------
func get_best_goal(goals: Array, current_goal_name: String) -> Dictionary:
	var best:       Dictionary = {}
	var best_score: float      = -1.0
	for goal in goals:
		var score = goal["priority"]
		# give current goal a free boost — takes a clear winner to switch
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
	var best:       Dictionary = {}
	var best_value: float      = -1.0
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
# _action_satisfies_goal — ALL of the goal's desired state keys must be
# matched by the action's effects. fixed: was returning true on first match.
# -----------------------------------------------------------------------------
func _action_satisfies_goal(action: Dictionary, goal: Dictionary) -> bool:
	for key in goal["desired_state"]:
		if action["effects"].get(key) != goal["desired_state"][key]:
			return false
	return true

# -----------------------------------------------------------------------------
# _preconditions_met — all preconditions must be true in current world state
# -----------------------------------------------------------------------------
func _preconditions_met(action: Dictionary, world_state: WorldState) -> bool:
	for key in action["preconditions"]:
		if world_state.get_state(key) != action["preconditions"][key]:
			return false
	return true
