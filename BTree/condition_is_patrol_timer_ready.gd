# condition_is_patrol_timer_ready.gd
class_name ConditionIsPatrolTimerReady
extends BTNode

func tick(actor, blackboard) -> Status:
    if blackboard["idle_timer"] >= 20:
        return Status.SUCCESS
    
    return Status.FAILURE
