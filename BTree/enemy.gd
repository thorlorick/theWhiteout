extends CharacterBody2D

var home_position: Vector2

var blackboard = {
	"target_position": Vector2.ZERO,
	"idle_timer": 0,
	"current_waypoint_index": 0,
	"current_waypoint": Vector2.ZERO,
	"waypoints": [],
	"home_position": Vector2.ZERO
}

var tree

func _ready():
	print("Waypoint1 node: ", $"../Waypoint1")
	home_position = global_position
	blackboard["home_position"] = global_position
	blackboard["waypoints"] = [
		$"../Waypoint1".global_position,
		$"../Waypoint2".global_position,
		$"../Waypoint3".global_position
	]
	blackboard["current_waypoint"] = blackboard["waypoints"][0]
	tree = _build_tree()

func move_toward(target: Vector2):
	var direction = (target - global_position).normalized()
	velocity = direction * 100
	move_and_slide()

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
