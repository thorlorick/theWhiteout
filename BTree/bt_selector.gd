# bt_selector.gd
class_name BTSelector
extends BTNode

var children = []

func tick(actor, blackboard) -> Status:
    for child in children:
        var result = child.tick(actor, blackboard)
        if result != Status.FAILURE:
            return result
    return Status.FAILURE
