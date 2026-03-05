# action_idle.gd
class_name ActionIdle
extends BTNode

func tick(actor, blackboard) -> Status:
	print("ActionIdle ticking - idle_timer: ", blackboard["idle_timer"])
	blackboard["idle_timer"] += 1
	return Status.SUCCESS
