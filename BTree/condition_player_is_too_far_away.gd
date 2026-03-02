# condition_player_is_too_far_away.gd
class_name ConditionPlayerIsTooFarAway
extends BTNode

func tick(actor, blackboard) -> Status:
    if actor.position.distance_to(blackboard["target_location"]) >= 100:
        return Status.SUCCESS
    
    return Status.FAILURE
