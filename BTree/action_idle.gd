# action_idle.gd
class_name ActionIdle
extends BTNode

func tick(actor, blackboard) -> Status:
    blackboard["idle_timer"] += 1
    return Status.SUCCESS
