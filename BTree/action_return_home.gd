# action_return_home.gd
class_name ActionReturnHome
extends BTNode

func tick(actor, blackboard) -> Status:
    if actor.position.distance_to(blackboard["home_position"]) > 20:
        actor.move_toward(blackboard["home_position"])
        return Status.RUNNING
    
    return Status.SUCCESS
