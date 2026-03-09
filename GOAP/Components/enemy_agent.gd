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

# sticky note — what was Joe last told to do?
var current_action: String = "patrol"

@export var move_component:   MoveComponent
@export var vision_component: VisionComponent
@export var chase_component:  ChaseComponent
@export var nav_region:       NavigationRegion2D
@export var home_position:    Vector2

func _ready() -> void:
	move_component.set_speed(speed.get_speed())
	patrol.setup(nav_region)
	anxiety.arrive_on_patrol()

	# connect signals — these are our replan triggers
	anxiety.replan_please.connect(replan)
	anxiety.threat_detected.connect(replan)
	anxiety.homesick.connect(replan)
	move_component.destination_reached.connect(_on_destination_reached)
	move_component.velocity_changed.connect(animation.update)
	move_component.velocity_changed.connect(vision_component.update_direction)
	vision_component.spotted_ue.connect(_on_spotted_ue)
	chase_component.move_to.connect(_on_chase_move_to)
	chase_component.ue_lost.connect(_on_ue_lost)
	chase_component.ue_caught.connect(_on_ue_caught)

	var anim_player = $EnemyAnimations/AnimationPlayer
	animation.setup(anim_player)

	# Joe starts on patrol — just start moving
	current_action = "patrol"
	move_component.set_target(patrol.get_random_point())

# -----------------------------------------------------------------------------
# _process — anxiety ticks every frame based on sticky note
# -----------------------------------------------------------------------------
func _process(delta: float) -> void:
	if world_state.get_state("sees_ue"):
		var ue = world_state.get_state("ue_target")
		if ue != null:
			var distance = ue.global_position.distance_to(home_position)
			anxiety.tick_chase(delta, distance)
	elif current_action == "patrol":
		anxiety.tick_patrol(delta)
	else:
		anxiety.tick_home(delta)

	# update goal priorities from anxiety every frame
	goals.goals[0]["priority"] = anxiety.get_home_priority()
	goals.goals[1]["priority"] = anxiety.get_patrol_priority()
	goals.goals[2]["priority"] = anxiety.get_chase_priority()

# -----------------------------------------------------------------------------
# replan — called ONLY on significant events, not every frame
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
# execute_action — writes the sticky note and moves Joe
# -----------------------------------------------------------------------------
func execute_action(action: Dictionary) -> void:
	match action["name"]:

		"GoHome":
			print(">>> GOING HOME")
			current_action = "going_home"
			move_component.set_target(home_position)

		"GoPatrol":
			print(">>> GOING ON PATROL")
			current_action = "patrol"
			if world_state.get_state("at_home"):
				anxiety.arrive_on_patrol()
				world_state.set_state("at_home", false)
			else:
				anxiety.resume_patrol()  # already out — just reset the latch
			move_component.set_target(patrol.get_random_point())

		"ChaseUE":
			print(">>> STARTING CHASE")
			current_action = "chase"
			if not chase_component.active:
				chase_component.start_chase(world_state.get_state("ue_target"))

# -----------------------------------------------------------------------------
# SIGNAL HANDLERS — single source of truth for world state
# -----------------------------------------------------------------------------

func _on_destination_reached() -> void:
	match current_action:

		"going_home":
			print(">>> ARRIVED HOME")
			world_state.set_state("at_home", true)
			world_state.set_state("sees_ue", false)
			world_state.set_state("gap_closed", true)
			current_action = "at_home"
			anxiety.arrive_home()
			replan()

		"patrol":
			print(">>> WAYPOINT REACHED — picking next random point")
			move_component.set_target(patrol.get_random_point())

func _on_spotted_ue(ue_body) -> void:
	if world_state.get_state("sees_ue"):
		return
	print(">>> UE SPOTTED!")
	world_state.set_state("sees_ue", true)
	world_state.set_state("ue_target", ue_body)
	world_state.set_state("gap_closed", false)
	anxiety.spotted_ue()
	replan()

func _on_chase_move_to(position: Vector2) -> void:
	move_component.set_target(position)

func _on_ue_lost() -> void:
	print(">>> UE LOST — resuming patrol")
	world_state.set_state("sees_ue", false)
	world_state.set_state("ue_target", null)
	world_state.set_state("gap_closed", true)
	world_state.set_state("at_home", false)
	anxiety.lost_ue()
	replan()

func _on_ue_caught() -> void:
	print(">>> UE CAUGHT — attack phase coming later!")
	world_state.set_state("sees_ue", false)
	world_state.set_state("ue_target", null)
	world_state.set_state("gap_closed", true)
	anxiety.lost_ue()
	replan()
