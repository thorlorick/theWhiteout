class_name EnemyAgent
extends CharacterBody2D

var anxiety     := AnxietyComponent.new()
var planner     := PlannerComponent.new()
var world_state := WorldState.new()
var goals       := GoalsComponent.new()
var actions     := ActionsComponent.new()
var patrol      := PatrolComponent.new()
var speed       := SpeedComponent.new()
var animation   := AnimationComponent.new()

@export var move_component:   MoveComponent
@export var vision_component: VisionComponent
@export var chase_component:  ChaseComponent
@export var nav_region:       NavigationRegion2D
@export var home_position:    Vector2

func _ready() -> void:
	move_component.set_speed(speed.get_speed())
	anxiety.arrive_home()
	patrol.generate_waypoints(nav_region)

	# connect signals — these are our replan triggers
	move_component.destination_reached.connect(_on_destination_reached)
	move_component.velocity_changed.connect(animation.update)
	move_component.velocity_changed.connect(vision_component.update_direction)
	vision_component.spotted_ue.connect(_on_spotted_ue)
	chase_component.move_to.connect(_on_chase_move_to)
	chase_component.ue_lost.connect(_on_ue_lost)
	chase_component.ue_caught.connect(_on_ue_caught)

	var anim_player = $EnemyAnimations/AnimationPlayer
	animation.setup(anim_player)

	# kick off the first plan
	replan()

# -----------------------------------------------------------------------------
# _process — anxiety ticks every frame, nothing else
# -----------------------------------------------------------------------------
func _process(delta: float) -> void:
	if world_state.get_state("sees_ue"):
		var ue = world_state.get_state("ue_target")
		if ue != null:
			var distance = global_position.distance_to(ue.global_position)
			anxiety.tick_chase(delta, distance)
	elif world_state.get_state("at_home"):
		anxiety.tick_home(delta)
	else:
		anxiety.tick_patrol(delta)

	# update goal priorities from anxiety every frame
	goals.goals[0]["priority"] = anxiety.get_home_priority()
	goals.goals[1]["priority"] = anxiety.get_patrol_priority()
	goals.goals[2]["priority"] = anxiety.get_chase_priority()

# -----------------------------------------------------------------------------
# replan — called ONLY on significant events, not every frame
# picks the best goal and executes the right action
# -----------------------------------------------------------------------------
func replan() -> void:
	var best_goal = planner.get_best_goal(goals.goals)
	print(">>> REPLAN — best goal: %s (priority: %.2f)" % [best_goal["name"], best_goal["priority"]])

	if planner.is_goal_satisfied(best_goal, world_state):
		print(">>> GOAL ALREADY SATISFIED — holding")
		return

	var best_action = planner.get_action_for_goal(best_goal, actions.actions, world_state)
	print(">>> ACTION SELECTED: ", best_action.get("name", "NONE"))

	if not best_action.is_empty():
		execute_action(best_action)

# -----------------------------------------------------------------------------
# execute_action — clean execution, no redundant guards
# world state is updated HERE, not in the signal handlers
# -----------------------------------------------------------------------------
func execute_action(action: Dictionary) -> void:
	match action["name"]:

		"GoHome":
			print(">>> GOING HOME")
			world_state.set_state("at_home", true)
			world_state.set_state("patrolling", false)
			world_state.set_state("gap_closed", true)
			move_component.set_target(home_position)

		"GoPatrol":
			print(">>> GOING ON PATROL")
			world_state.set_state("at_home", false)
			world_state.set_state("patrolling", true)
			world_state.set_state("patrol_complete", false)
			world_state.set_state("gap_closed", true)
			anxiety.arrive_on_patrol()
			patrol.generate_waypoints(nav_region)
			move_component.set_target(patrol.get_current_waypoint())

		"ChaseUE":
			print(">>> STARTING CHASE")
			world_state.set_state("gap_closed", false)
			world_state.set_state("patrolling", false)
			world_state.set_state("at_home", false)
			if not chase_component.active:
				chase_component.start_chase(world_state.get_state("ue_target"))

# -----------------------------------------------------------------------------
# SIGNAL HANDLERS — these are the replan triggers
# each one updates world state then calls replan()
# -----------------------------------------------------------------------------

# fired by MoveComponent when navigation finishes
func _on_destination_reached() -> void:
	if world_state.get_state("at_home"):
		print(">>> ARRIVED HOME")
		anxiety.arrive_home()
		world_state.set_state("patrol_complete", true)
		world_state.set_state("patrolling", false)
		world_state.set_state("sees_ue", false)
		world_state.set_state("gap_closed", true)
		replan()

	elif world_state.get_state("patrolling"):
		patrol.advance()
		if patrol.is_complete():
			print(">>> PATROL COMPLETE — heading home")
			world_state.set_state("patrolling", false)
			world_state.set_state("at_home", true)
			move_component.set_target(home_position)
			# no replan here — we're already committed to going home
		else:
			print(">>> WAYPOINT %d of %d" % [patrol.current_index, patrol.num_waypoints])
			move_component.set_target(patrol.get_current_waypoint())
			# no replan here — still patrolling, just next waypoint

# fired by VisionComponent when a UE is spotted
func _on_spotted_ue(ue_body) -> void:
	if world_state.get_state("sees_ue"):
		return  # already knows about this UE, ignore repeated signals
	print(">>> UE SPOTTED!")
	anxiety.spotted_ue()
	world_state.set_state("sees_ue", true)
	world_state.set_state("ue_target", ue_body)
	world_state.set_state("gap_closed", false)  # gap is now open — trigger chase goal
	replan()

# fired by ChaseComponent when guard moves toward UE
func _on_chase_move_to(position: Vector2) -> void:
	move_component.set_target(position)

# fired by ChaseComponent when UE escapes
func _on_ue_lost() -> void:
	print(">>> UE LOST — resuming patrol")
	anxiety.lost_ue()
	world_state.set_state("sees_ue", false)
	world_state.set_state("ue_target", null)
	world_state.set_state("gap_closed", true)   # gap resolved — UE is gone
	world_state.set_state("patrolling", false)  # force replan into patrol
	world_state.set_state("at_home", false)
	replan()

# fired by ChaseComponent when guard catches the UE
func _on_ue_caught() -> void:
	print(">>> UE CAUGHT — attack phase coming later!")
	anxiety.lost_ue()
	world_state.set_state("sees_ue", false)
	world_state.set_state("ue_target", null)
	world_state.set_state("gap_closed", true)   # gap resolved — UE is caught
	replan()
