# bt_sequence.gd
class_name BTSequence
extends BTNode

var children = []

func tick(actor, blackboard) -> Status:
    for child in children:
        var result = child.tick(actor, blackboard)
        if result != Status.SUCCESS:
            return result
    return Status.SUCCESS
