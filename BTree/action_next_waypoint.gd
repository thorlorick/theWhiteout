# action_next_waypoint.gd
class_name ActionNextWaypoint
extends BTNode
func tick(actor, blackboard) -> Status:
	var index = blackboard["current_waypoint_index"]
	var total = blackboard["waypoints"].size()
	blackboard["current_waypoint_index"] = (index + 1) % total
	blackboard["current_waypoint"] = blackboard["waypoints"][blackboard["current_waypoint_index"]]
	if blackboard["current_waypoint_index"] == 0:
		blackboard["patrol_complete"] = true
		print("Patrol complete!")
	print("ActionNextWaypoint - moving to index: ", blackboard["current_waypoint_index"], " position: ", blackboard["current_waypoint"])
	return Status.SUCC
