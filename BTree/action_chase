# action_chase.gd
class_name ActionChase
extends BTNode

func tick(actor, blackboard) -> Status:
    var player = blackboard["target_position"]
    
    if actor.position.distance_to(player) > 50:
        actor.move_toward(player)
        return Status.RUNNING
    
    return Status.SUCCESS
