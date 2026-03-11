class_name GuardAgent
extends CharacterBody2D
# -----------------------------------------------------------------------------
# GuardAgent
# Lean orchestrator. Owns the components, wires signals, runs the loop.
# -----------------------------------------------------------------------------
var urge         := UrgeComponent.new()
var planner      := PlannerComponent.new()
var world_state := WorldState.new()
var goals        := GoalsComponent.new()
var actions      := ActionsComponent.new()
var speed        := SpeedComponent.new()
var animation    := AnimationComponent.new()

@export var move_component:    MoveComponent
@export var vision_component: VisionComponent
@export var chase_component:   ChaseComponent
@export var patrol_component: PatrolComponent
@export var zone_component:    ZoneComponent
@export var search_component: SearchComponent
@export var nav_region:        NavigationRegion2D
@export var home_position:     Vector2

var _current_goal_name: String = "Patrol"
var _last_known_position: Vector2 = Vector2.ZERO
var _last_known_direction: Vector2 = Vector2.ZERO

var _in_danger_zone: bool = false
var _in_alert_zone:  bool = false

func _ready() -> void:
	move_component.set_speed(speed.get_speed())
	patrol_component.nav_region = nav_region
	patrol_component.home_position = home_position
	search_component.nav_region = nav_region
	zone_component.setup()

	move_component.velocity_changed.connect(animation.update)
	move_component.velocity_changed.connect(vision_component.update_direction)

	vision_component.spotted_ue.connect(_on_spotted_ue)
	vision_component.lost_ue.connect(_on_lost_ue)

	chase_component.move_to.connect(_on_chase_move_to)
	chase_component.ue_caught.connect(_on_ue_caught)
	chase_component.ue_lost.connect(_on_ue_lost)
	chase_component.gap_closed.connect(_on_gap_closed) # New Hook

	patrol_component.new_patrol_target.connect(_on_new_patrol_target)
	search_component.search_move_to.connect(_on_search_move_to)
	search_component.search_finished.connect(_on_search_finished)

	zone_component.body_entered_danger.connect(_on_danger_entered)
	zone_component.body_exited_danger.connect(_on_danger_exited)
	zone_component.body_entered_alert.connect(_on_alert_entered)
	zone_component.body_exited_alert.connect(_on_alert_exited)

	world_state.set_state("patrolling",   true)
	world_state.set_state("at_home",      false)
	world_state.set_state("sees_ue",      false)
	world_state.set_state("gap_closed",   true)
	world_state.set_state("target_lost",  false)
	world_state.set_state("target_found", true)

	patrol_component.start()

func _process(delta: float) -> void:
	var guard_state: String = _get_guard_state()
	if _in_alert_zone:
		urge.on_alert_tick(delta)
	
	urge.tick(delta, guard_state)
	
	goals.update_priorities(
		urge.get_comfort_urge(),
		urge.get_duty_urge(),
		urge.get_curiosity_urge(),
		urge.get_aggression_urge()
	)

	_replan()

func _replan() -> void:
	var best_goal = planner.get_best_goal(goals.goals, _current_goal_name)
	if planner.is_goal_satisfied(best_goal, world_state):
		return

	var best_action = planner.get_best_action(best_goal, actions.actions, world_state)
	if best_action.is_empty():
		return

	if best_goal["name"] != _current_goal_name:
		_current_goal_name = best_goal["name"]
		_execute_action(best_action)

func _execute_action(action: Dictionary) -> void:
	match action["name"]:
		"GoHome":
			patrol_component.stop()
			search_component.stop()
			world_state.set_state("patrolling", false)
			world_state.set_state("at_home",    false)
			_move_to(home_position)
		"GoPatrol":
			world_state.set_state("at_home",    false)
			world_state.set_state("patrolling", true)
			urge.committed_to_patrol()
			patrol_component.start()
		"ChaseUE":
			# Chase component logic handles moving toward UE
			pass
		"Attack":
			# Combat logic/animation triggered here
			print(">>> AGENT: attacking target")
		"Search":
			patrol_component.stop()
			world_state.set_state("patrolling", false)
			world_state.set_state("at_home",    false)
			urge.committed_to_search()
			search_component.start_search(_last_known_position, _last_known_direction)

func _get_guard_state() -> String:
	if world_state.get_state("sees_ue"):
		if world_state.get_state("gap_closed"):
			return "attacking"
		return "chasing"
	if world_state.get_state("target_lost"):
		return "searching"
	if world_state.get_state("at_home"):
		return "at_home"
	return "patrolling"

# -----------------------------------------------------------------------------
# SIGNAL HANDLERS
# -----------------------------------------------------------------------------

func _on_gap_closed() -> void:
	world_state.set_state("gap_closed", true)
	urge.on_gap_closed()

func _on_hit_landed() -> void:
	urge.on_hit_landed()

func _on_spotted_ue(ue_body: Node2D) -> void:
	if world_state.get_state("sees_ue"): return
	world_state.set_state("sees_ue",      true)
	world_state.set_state("ue_target",    ue_body)
	world_state.set_state("gap_closed",   false)
	world_state.set_state("target_lost",  false)
	world_state.set_state("target_found", true)

func _on_lost_ue() -> void:
	var ue = world_state.get_state("ue_target")
	_last_known_position  = ue.global_position if ue != null else home_position
	_last_known_direction = (ue.global_position - global_position).normalized() if ue != null else Vector2.ZERO
	world_state.set_state("sees_ue",      false)
	world_state.set_state("target_lost",  true)
	world_state.set_state("target_found", false)
	urge.on_ue_lost()

func _on_ue_caught() -> void:
	_on_hit_landed() # Optional: catching them counts as a hit/aggression boost
	# ... rest of your elimination logic

func _on_search_finished() -> void:
	world_state.set_state("target_lost",  false)
	world_state.set_state("target_found", true)

# ... (rest of your helper functions: _move_to, _on_destination_reached, etc.)
