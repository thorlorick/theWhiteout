# condition_is_at_home.gd
class_name ConditionIsAtHome
extends BTNode

func tick(actor, blackboard) -> Status:
    if actor.position.distance_to(blackboard["home_position"]) <= 5:
        return Status.SUCCESS
    
    return Status.FAILURE

