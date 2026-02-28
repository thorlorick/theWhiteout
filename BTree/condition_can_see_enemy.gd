# condition_can_see_enemy.gd
class_name ConditionCanSeeEnemy
extends BTNode

func tick(actor, blackboard) -> Status:
    var target = blackboard["target_position"]
    
    if actor.can_see(target):
        return Status.SUCCESS
    
    return Status.FAILURE
