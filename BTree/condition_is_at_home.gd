# condition_is_at_home.gd
class_name ConditionIsAtHome
extends BTNode

func tick(actor, blackboard) -> Status:
	print("ConditionIsAtHome - position: ", actor.position, " home: ", blackboard["home_position"], " distance: ", actor.position.distance_to(blackboard["home_position"]))
	if actor.position.distance_to(blackboard["home_position"]) <= 15:
		return Status.SUCCESS
	return Status.FAILURE

