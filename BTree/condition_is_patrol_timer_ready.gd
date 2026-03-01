# condition_is_patrol_timer_ready.gd
class_name ConditionIsPatrolTimerReady
extends BTNode

func tick(actor, blackboard) -> Status:
    var timer = blackboard["patrol_timer"]
    var current_timer = blackboard["current_timer"]
    
    if timer 
        return Status.SUCCESS
    
    return Status.FAILURE
