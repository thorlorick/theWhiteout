# action_reset_timer.gd
class_name ActionResetTimer
extends BTNode

func tick(actor, blackboard) -> Status:
    blackboard["idle_timer"] = 0
    return Status.SUCCESS
