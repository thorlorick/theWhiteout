# bt_node.gd
class_name BTNode

enum Status { SUCCESS, FAILURE, RUNNING }

func tick(actor, blackboard) -> Status:
    return Status.FAILURE
