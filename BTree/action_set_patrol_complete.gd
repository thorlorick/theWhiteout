# action_set_patrol_complete.gd
class_name ActionSetPatrolComplete
extends BTNode
func tick(actor, blackboard) -> Status:
    blackboard["patrol_complete"] = true
    return Status.SUCCESS

