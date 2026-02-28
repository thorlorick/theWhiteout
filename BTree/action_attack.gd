# action_attack.gd
class_name ActionAttack
extends BTNode

func tick(actor, blackboard) -> Status:
    var player = blackboard["target_position"]
    
    if actor.position.distance_to(player) > 5:
        actor.attack(player)
        return Status.RUNNING
    
    return Status.SUCCESS
