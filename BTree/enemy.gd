# enemy.gd
extends CharacterBody2D

var blackboard = {
    "target_position": Vector2.ZERO,
    "idle_timer": 0,
    "current_waypoint_index": 0,
    "waypoints": [],
    "home_position": Vector2.ZERO
}

var tree

func _ready():
    home_position = global_position
    blackboard["home_position"] = global_position
    blackboard["waypoints"] = [
        $Waypoint1.position,
        $Waypoint2.position,
        $Waypoint3.position
    ]
    tree = _build_tree()

func _build_tree():
    var root = BTSelector.new()
    
    var patrol_sequence = BTSequence.new()
    patrol_sequence.children = [
        ConditionIsPatrolTimerReady.new(),
        ActionPatrol.new(),
        ActionNextWaypoint.new(),
        ActionReturnHome.new(),
        ConditionIsAtHome.new(),
        ActionResetTimer.new()
    ]
    
    root.children = [
        patrol_sequence,
        ActionIdle.new()
    ]
    
    return root

func _process(delta):
    tree.tick(self, blackboard)
