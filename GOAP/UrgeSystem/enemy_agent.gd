class_name EnemyAgent
extends CharacterBody2D

# -----------------------------------------------------------------------------
# EnemyAgent
# Lean orchestrator. Owns the components, wires signals, runs the loop.
# Makes no decisions of its own — that's the planner's job.
# No sticky note. No thresholds. No latches.
# Current state is read from WorldState, not tracked separately.
# -----------------------------------------------------------------------------

# pure logic components — no scene tree presence needed
var urge       := UrgeComponent.new()
var planner    := PlannerComponent.new()
var world_state:= WorldState.new()
var goals      := GoalsComponent.new()
var actions    := ActionsComponent.new()
var patrol     := PatrolComponent.new()
var speed      := SpeedComponent.new()
var animation  := AnimationComponent.new()

# scene tree components — need node lifecycle
@export var move_component:   MoveComponent
@export var vision_component: VisionComponent
@export var chase_component:  ChaseComponent
@export var nav_region:       NavigationRegion2D
@export var home_position:    Vector2

# current goal name — used only for inertia in the planner
var _current_goal_name: String = "Patrol"

# -----------------------------------------------------------------------------
# _ready — wire everything up, Joe starts patrolling
# -----------------------------------------------------------------------------
func _ready() -> void:
	move_component.set_speed(speed.get_speed())
	patrol.setup(nav_region)

	# connect signals
	move_component.destination_reached.connect(_on_destination_reached)
	move_component.velocity_changed.connect(animation.update)
	move_component.velocity_changed.connect(vision_component.update_direction)
	vision_component.spotted_ue.connect(_on_spotted_ue)
	chase_component.move_to.connect(_on_chase_move_to)
	chase_component.ue_caught.connect(_on_ue_caught)
	chase_component.ue_lost.connect(_on_ue_lost)

	var anim_player = $EnemyAnimations/AnimationPlayer
	animation.setup(anim_player)

	# Joe starts patrolling
	world_state.set_state("patrolling", true)
	_go_patrol()

# -----------------------------------------------------------------------------
# _process — urges tick, priorities update, planner runs every frame
# -----------------------------------------------------------------------------
func _process(delta: float) -> void:
	# figure out Joe's current state for urge ticking
	var joe_state: String = _get_joe_state()

	# figure out current threat zone (needs UE position if visible)
	var zone: int = -1
	if world_state.get_state("sees_ue"):
		var ue = world_state.get_state("ue_target")
		if ue != null:
			var ue_to_home = ue.global_position.distance_to(home_position)
			var gap_urge   = chase_component.evaluate_threat(ue_to_home)
			urge.set_gap_urge(gap_urge)
			zone = chase_component.get_current_zone()

	# tick urges
	urge.tick(delta, joe_state, zone)

	# push urge values into goals
	goals.update_priorities(
		urge.get_home_urge(),
		urge.get_patrol_urge(),
		urge.get_gap_urge()
	)

	# ask planner what Joe should do
	_replan()

# -----------------------------------------------------------------------------
# _replan — planner picks best goal and action, executes if different
# -----------------------------------------------------------------------------
func _replan() -> void:
	var best_goal = planner.get_best_goal(goals.goals, _current_goal_name)

	# goal already satisfied — nothing to do
	if planner.is_goal_satisfied(best_goal, world_state):
		return

	var best_action = planner.get_best_action(best_goal, actions.actions, world_state)
	if best_action.is_empty():
		return

	# only execute if something actually changed
	if best_goal["name"] != _current_goal_name:
		_current_goal_name = best_goal["name"]
		print(">>> REPLAN — goal: %s | action: %s (priority: %.2f cost: %.2f)" % [
			best_goal["name"],
			best_action["name"],
			best_goal["priority"],
			best_action["cost"]
		])
		_execute_action(best_action)

# -----------------------------------------------------------------------------
# _execute_action — tells Joe what to do, updates world state
# -----------------------------------------------------------------------------
func _execute_action(action: Dictionary) -> void:
	match action["name"]:

		"GoHome":
			print(">>> ACTION: going home")
			world_state.set_state("patrolling", false)
			move_component.set_target(home_position)

		"GoPatrol":
			print(">>> ACTION: going on patrol")
			world_state.set_state("at_home", false)
			world_state.set_state("patrolling", true)
			_go_patrol()

		"ChaseUE":
			print(">>> ACTION: chasing UE")
			var ue = world_state.get_state("ue_target")
			if ue != null and not chase_component.active:
				chase_component.start_chase(ue)

# -----------------------------------------------------------------------------
# _get_joe_state — reads world state to determine urge tick context
# -----------------------------------------------------------------------------
func _get_joe_state() -> String:
	if world_state.get_state("sees_ue"):
		return "chasing"
	if world_state.get_state("at_home"):
		return "at_home"
	return "patrolling"

# -----------------------------------------------------------------------------
# _go_patrol — picks a random patrol point and moves there
# -----------------------------------------------------------------------------
func _go_patrol() -> void:
	move_component.set_target(patrol.get_random_point())

# -----------------------------------------------------------------------------
# SIGNAL HANDLERS
# -----------------------------------------------------------------------------

func _on_destination_reached() -> void:
	var joe_state = _get_joe_state()
	match joe_state:

		"at_home":
			# already home — nothing to do, urges will sort it out
			pass

		"patrolling":
			# waypoint reached — pick the next one
			print(">>> PATROL: waypoint reached — moving to next")
			_go_patrol()

		_:
			# arrived somewhere after going home
			if not world_state.get_state("at_home") and _current_goal_name == "BeHome":
				print(">>> ARRIVED HOME")
				world_state.set_state("at_home", true)
				world_state.set_state("patrolling", false)
				world_state.set_state("gap_closed", true)

func _on_spotted_ue(ue_body: Node2D) -> void:
	if world_state.get_state("sees_ue"):
		return
	print(">>> UE SPOTTED")
	world_state.set_state("sees_ue", true)
	world_state.set_state("ue_target", ue_body)
	world_state.set_state("gap_closed", false)

func _on_chase_move_to(position: Vector2) -> void:
	move_component.set_target(position)

func _on_ue_caught() -> void:
	print(">>> UE CAUGHT — attack coming later")
	world_state.set_state("sees_ue", false)
	world_state.set_state("ue_target", null)
	world_state.set_state("gap_closed", true)
	chase_component.stop_chase()

func _on_ue_lost() -> void:
	print(">>> UE LOST — resuming")
	world_state.set_state("sees_ue", false)
	world_state.set_state("ue_target", null)
	world_state.set_state("gap_closed", true)
	chase_component.stop_chase()
