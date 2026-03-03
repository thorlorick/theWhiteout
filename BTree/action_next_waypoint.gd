# action_next_waypoint.gd
class_name ActionNextWaypoint
extends BTNode

func tick(actor, blackboard) -> Status:
    var waypoint = blackboard["current_waypoint"]
    
    if actor.position.distance_to(waypoint) > 5:
        actor.move_toward(waypoint)
        return Status.RUNNING
    
    return Status.SUCCESS
