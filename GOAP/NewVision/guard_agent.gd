class_name GuardAgent
extends CharacterBody2D
# -----------------------------------------------------------------------------
# GuardAgent
# Lean orchestrator. Owns the components, wires signals, runs the loop.
# Makes no decisions of its own — that's the planner's job.
# Zone-equivalent signals now come from VisionComponent, not colliders.
# -----------------------------------------------------------------------------
var urge        := UrgeComponent.new()
var planner     := PlannerComponent.new()
var world_state := WorldState.new()
var goals       := GoalsComponent.new()
var actions     := ActionsComponent.new()
var speed       := SpeedComponent.new()
var animation   := AnimationComponent.new()
var attack      := AttackComponent.new()

@export var move_component:   MoveComponent
@export var vision_component: VisionComponent
@export var chase_component:  ChaseComponent
@export var patrol_component: PatrolComponent
@export var search_component: SearchComponent
@export var nav_region:       NavigationRegion2D
@export var home_position:    Vector2
@export var personality:      PersonalityResource

@export var damage: float = 10.0

var _current_goal_name:    String  = "Patrol"
var _last_known_position:  Vector2 = Vector2.ZERO
var _last_known_direction: Vector2 = Vector2.ZERO

var _in_danger_range: bool = false
var _in_alert_range:  bool = false

# -----------------------------------------------------------------------------
# _ready — wire everything up, guard starts patrolling
# -----------------------------------------------------------------------------
func _ready() -> void:
	if personality != null:
		actions.apply_personality(personality)

	add_child(attack)

	move_component.set_speed(speed.get_speed())

	patrol_component.nav_region    = nav_region
	patrol_component.home_position = home_position
	search_component.nav_region    = nav_region

	move_component.velocity_changed.connect(animation.update)
	move_component.velocity_changed.connect(vision_component.update_direction)

	# vision — confirmed sighting signals
	vision_component.spotted_ue.connect(_on_spotted_ue)
	vision_component.lost_ue.connect(_on_lost_ue)

	# vision — zone-equivalent signals replace ZoneComponent
	vision_component.alert_range.connect(_on_alert_entered)
	vision_component.danger_range.connect(_on_danger_entered)
	vision_component.range_lost.connect(_on_range_lost)
	vision_component.gap_closed_signal.connect(_on_gap_closed)

	# chase
	chase_component.move_to.connect(_on_chase_move_to)
	chase_component.ue_lost.connect(_on_ue_lost)

	# attack
	attack.attack_landed.connect(_on_attack_landed)

	# patrol
	patrol_component.new_patrol_target.connect(_on_new_patrol_target)

	# search
	search_component.search_move_to.connect(_on_search_move_to)
	search_component.search_finished.connect(_on_search_finished)

	var anim_player = $EnemyAnimations/AnimationPlayer
	animation.setup(anim_player)

	world_state.set_state("patrolling",    true)
	world_state.set_state("at_home",       false)
	world_state.set_state("sees_ue",       false)
	world_state.set_state("gap_closed",    false)
	world_state.set_state("target_lost",   false)
	world_state.set_state("target_found",  true)
	world_state.set_state("ue_eliminated", false)

	patrol_component.start()

# -----------------------------------------------------------------------------
# _process — urges tick, priorities update, planner runs, attack loop
# -----------------------------------------------------------------------------
func _process(delta: float) -> void:
	var guard_state: String = _get_guard_state()

	if _in_alert_range:
		urge.on_alert_tick(delta)

	urge.tick(delta, guard_state)

	goals.update_priorities(
		urge.get_comfort_urge(),
		urge.get_duty_urge(),
		urge.get_curiosity_urge(),
		urge.get_aggression_urge()
	)

	# attack loop — runs in process while gap is closed
	if guard_state == "attacking":
		var ue = world_state.get_state("ue_target")
		if ue != null:
			attack.tick(delta)
			attack.try_attack(ue)

	# gap closed check — vision owns the measurement, agent reacts
	if vision_component.is_gap_closed() and not world_state.get_state("gap_closed"):
		_on_gap_closed()

	_replan()

# -----------------------------------------------------------------------------
# _clear_pending_arrivals
# -----------------------------------------------------------------------------
func _clear_pending_arrivals() -> void:
	if move_component.destination_reached.is_connected(patrol_component.arrived):
		move_component.destination_reached.disconnect(patrol_component.arrived)
	if move_component.destination_reached.is_connected(search_component.arrived):
		move_component.destination_reached.disconnect(search_component.arrived)
	if move_component.destination_reached.is_connected(_on_arrived_home):
		move_component.destination_reached.disconnect(_on_arrived_home)

# -----------------------------------------------------------------------------
# _trigger_chase — danger range entered, bypass planner and chase immediately
# -----------------------------------------------------------------------------
func _trigger_chase() -> void:
	var ue = world_state.get_state("ue_target")
	if ue == null:
		print(">>> DANGER RANGE — no target acquired")
		return
	if chase_component.active:
		return
	print(">>> DANGER RANGE — triggering chase directly")
	_clear_pending_arrivals()
	patrol_component.stop()
	search_component.stop()
	world_state.set_state("patrolling",   false)
	world_state.set_state("gap_closed",   false)
	world_state.set_state("target_lost",  false)
	world_state.set_state("target_found", true)
	_current_goal_name = "Chase"
	chase_component.start_chase(ue)

# -----------------------------------------------------------------------------
# _replan
# -----------------------------------------------------------------------------
func _replan() -> void:
	var best_goal = planner.get_best_goal(goals.goals, _current_goal_name)

	if planner.is_goal_satisfied(best_goal, world_state):
		return

	var best_action = planner.get_best_action(best_goal, actions.actions, world_state)
	if best_action.is_empty():
		return

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
# _execute_action
# -----------------------------------------------------------------------------
func _execute_action(action: Dictionary) -> void:
	_clear_pending_arrivals()

	match action["name"]:

		"GoHome":
			print(">>> ACTION: going home")
			patrol_component.stop()
			search_component.stop()
			world_state.set_state("patrolling", false)
			world_state.set_state("at_home",    false)
			move_component.destination_reached.connect(_on_arrived_home, CONNECT_ONE_SHOT)
			move_component.set_target(home_position)

		"GoPatrol":
			print(">>> ACTION: going on patrol")
			world_state.set_state("at_home",    false)
			world_state.set_state("patrolling", true)
			urge.committed_to_patrol()
			patrol_component.start()

		"ChaseUE":
			print(">>> ACTION: chasing UE")
			var ue = world_state.get_state("ue_target")
			if ue != null and not chase_component.active:
				patrol_component.stop()
				search_component.stop()
				world_state.set_state("patrolling",   false)
				world_state.set_state("gap_closed",   false)
				world_state.set_state("target_lost",  false)
				world_state.set_state("target_found", true)
				chase_component.start_chase(ue)

		"Attack":
			print(">>> ACTION: attacking UE — attack loop running in _process")

		"Search":
			print(">>> ACTION: searching for lost target")
			patrol_component.stop()
			world_state.set_state("patrolling", false)
			world_state.set_state("at_home",    false)
			urge.committed_to_search()
			search_component.start_search(_last_known_position, _last_known_direction)

# -----------------------------------------------------------------------------
# _get_guard_state
# -----------------------------------------------------------------------------
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
# VISION ZONE-EQUIVALENT HANDLERS
# -----------------------------------------------------------------------------

func _on_alert_entered(body: Node2D) -> void:
	print(">>> VISION: alert range — pressure building")
	_in_alert_range = true
	urge.on_danger_entered()

func _on_danger_entered(body: Node2D) -> void:
	print(">>> VISION: danger range — triggering chase")
	_in_danger_range = true
	_trigger_chase()

func _on_range_lost(body: Node2D) -> void:
	print(">>> VISION: range lost — clearing zone states")
	_in_alert_range  = false
	_in_danger_range = false

# -----------------------------------------------------------------------------
# SIGNAL HANDLERS
# -----------------------------------------------------------------------------

func _on_attack_landed(target: Node) -> void:
	if not is_instance_valid(target):  # ← is it still alive/in the scene?
		return
	if world_state.get_state("ue_eliminated"):  # ← has death already been handled?
		return
	var health = target.get_node_or_null("HealthComponent")
	if health == null:
		return
	health.take_damage(damage)
	urge.on_hit_landed()
	print(">>> AGENT: dealt %.1f damage to UE" % damage)

func _on_arrived_home() -> void:
	print(">>> ARRIVED HOME")
	world_state.set_state("at_home",      true)
	world_state.set_state("patrolling",   false)
	world_state.set_state("gap_closed",   false)
	world_state.set_state("target_lost",  false)
	world_state.set_state("target_found", true)
	search_component.stop()
	move_component.stop()

func _on_new_patrol_target(position: Vector2) -> void:
	move_component.destination_reached.connect(patrol_component.arrived, CONNECT_ONE_SHOT)
	move_component.set_target(position)

func _on_search_move_to(position: Vector2) -> void:
	move_component.destination_reached.connect(search_component.arrived, CONNECT_ONE_SHOT)
	move_component.set_target(position)

func _on_search_finished() -> void:
	print(">>> SEARCH FINISHED — target not found, resuming normal life")
	world_state.set_state("target_lost",  false)
	world_state.set_state("target_found", true)

func _on_spotted_ue(ue_body: Node2D) -> void:
	if world_state.get_state("sees_ue"):
		return
	print(">>> UE SPOTTED")
	_clear_pending_arrivals()
	patrol_component.stop()
	search_component.stop()
	urge.on_ue_spotted()
	world_state.set_state("sees_ue",      true)
	world_state.set_state("ue_target",    ue_body)
	world_state.set_state("gap_closed",   false)
	world_state.set_state("target_lost",  false)
	world_state.set_state("target_found", true)

	var health = ue_body.get_node_or_null("HealthComponent")
	if health != null:
		health.died.connect(_on_ue_died)

func _on_lost_ue() -> void:
	print(">>> VISION: lost sight of UE — curiosity spike")
	var ue = world_state.get_state("ue_target")
	_last_known_position  = ue.global_position if ue != null else home_position
	_last_known_direction = (ue.global_position - global_position).normalized() if ue != null else Vector2.ZERO
	world_state.set_state("sees_ue",      false)
	world_state.set_state("gap_closed",   false)
	world_state.set_state("target_lost",  true)
	world_state.set_state("target_found", false)
	chase_component.stop_chase()
	urge.on_ue_lost()

func _on_gap_closed() -> void:
	print(">>> GAP CLOSED — aggression spike")
	world_state.set_state("gap_closed", true)
	urge.on_gap_closed()

func _on_ue_died() -> void:
	print(">>> UE DIED — cleaning up")
	_clear_pending_arrivals()
	var ue = world_state.get_state("ue_target")
	if ue != null:
		ue.queue_free()
	world_state.set_state("sees_ue",       false)
	world_state.set_state("ue_target",     null)
	world_state.set_state("gap_closed",    false)
	world_state.set_state("target_lost",   false)
	world_state.set_state("target_found",  true)
	world_state.set_state("ue_eliminated", true)
	_in_alert_range  = false
	_in_danger_range = false
	vision_component.clear_target()
	chase_component.stop_chase()
	move_component.stop()
	search_component.stop()

func _on_chase_move_to(position: Vector2) -> void:
	move_component.set_target(position)

func _on_ue_lost() -> void:
	print(">>> CHASE: ue lost — giving up")
	world_state.set_state("target_lost",  false)
	world_state.set_state("target_found", true)
	world_state.set_state("sees_ue",      false)
	world_state.set_state("gap_closed",   false)
	chase_component.stop_chase()
