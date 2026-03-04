# condition_is_patrol_complete.gd
class_name ConditionIsPatrolComplete
extends BTNode
func tick(actor, blackboard) -> Status:
    if blackboard["patrol_complete"] == true:
        return Status.SUCCESS
    return Status.FAILURE
