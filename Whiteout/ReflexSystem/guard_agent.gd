class_name GuardAgent
extends CharacterBody2D
# -----------------------------------------------------------------------------
# GuardAgent
# Lean orchestrator. Owns the components, wires signals, runs the loop.
# Makes no decisions of its own — that's the planner's job.
# Reflex handles immediate interrupts — agent just hears and shouts.
# -----------------------------------------------------------------------------

var urge        := UrgeComponent.new()
var planner     := PlannerComponent.new()
var world_state := WorldState.new()
var goals       := GoalsComponent.new()
var actions     := ActionsComponent.new()
var speed       := SpeedComponent.new()
var animation   := EnemyAnimationComponent.new()
var attack      := AttackComponent.new()
var reflex      := ReflexComponent.new()

@export var ai_move_component:  AIMoveComponent
@export var vision_component:   VisionComponent
@export var chase_component:    ChaseComponent
@export var patrol_component:   PatrolComponent
@export var search_component:   SearchComponent
@export var health_component:   HealthComponent
@export var hitbox_component:   HitboxComponent
@export var hurtbox_component:  HurtboxComponent
@export var nav_region:         NavigationRegion2D
@export var home_position:      Vector2
@export var personality:        PersonalityResource

var _current_goal_name:    String  = "Patrol"
var _last_known_position:  Vector2 = Vector2.ZERO
var _last_known_direction: Vector2 = Vector2.ZERO
var _in_alert_range:       bool    = false
var _in_danger_range:      bool    = false

# -----------------------------------------------------------------------------
# _ready
# -----------------------------------------------------------------------------
func _ready() -> void:
	if personality != null:
		urge.apply_personality(personality)
		attack.personality = personality

	add_child(attack)

	ai_move_component.set_speed(speed.get_speed())

	patrol_component.nav_region    = nav_region
	patrol_component.home_position = home_position
	search_component.nav_region    = nav_region

	_connect_signals()
	_connect_reflex_signals()
	_setup_animation()

	patrol_component.start()

# -----------------------------------------------------------------------------
# _connect_signals
# -----------------------------------------------------------------------------
func _connect_signals() -> void:
	ai_move_component.velocity_changed.connect(animation.update)
	ai_move_component.velocity_changed.connect(vision_component.update_direction)
	ai_move_component.velocity_changed.connect(_on_velocity_changed)

	health_component.hit.connect(_on_hit_received)
	health_component.died.connect(_on_died)

	vision_component.spotted_ue.connect(_on_spotted_ue)
	vision_component.lost_ue.connect(_on_lost_ue)
	vision_component.alert_range.connect(_on_alert_entered)
	vision_component.danger_range.connect(_on_danger_entered)
	vision_component.range_lost.connect(_on_range_lost)
	vision_component.gap_closed_signal.connect(_on_gap_closed)

	chase_component.move_to.connect(_on_chase_move_to)
	chase_component.ue_lost.connect(_on_ue_lost)

	attack.attack_triggered.connect(_on_attack_triggered)
	attack.attack_finished.connect(_on_attack_finished)

	hurtbox_component.hurt.connect(_on_hurtbox_hurt)

	patrol_component.new_patrol_target.connect(_on_new_patrol_target)

	search_component.search_move_to.connect(_on_search_move_to)
	search_component.search_finished.connect(_on_search_finished)

# -----------------------------------------------------------------------------
# _connect_reflex_signals
# agent hears reflex, agent shouts at components — nothing talks directly
# -----------------------------------------------------------------------------
func _connect_reflex_signals() -> void:
	reflex.interrupt_chase_started.connect(_on_reflex_chase_started)
	reflex.interrupt_chase_stopped.connect(_on_reflex_chase_stopped)
	reflex.interrupt_patrol_stopped.connect(_on_reflex_patrol_stopped)
	reflex.interrupt_search_stopped.connect(_on_reflex_search_stopped)
	reflex.interrupt_movement_stopped.connect(_on_reflex_movement_stopped)
	reflex.interrupt_speed_reset.connect(_on_reflex_speed_reset)
	reflex.interrupt_run_started.connect(_on_reflex_run_started)
	reflex.interrupt_attack_stopped.connect(_on_reflex_attack_stopped)
	reflex.interrupt_hurt_started.connect(_on_reflex_hurt_started)
	reflex.interrupt_death_started.connect(_on_reflex_death_started)

# -----------------------------------------------------------------------------
# _setup_animation
# -----------------------------------------------------------------------------
func _setup_animation() -> void:
	var anim_tree = $EnemyAnimations/AnimationTree
	animation.setup(anim_tree)

# -----------------------------------------------------------------------------
# _process
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

	if guard_state == "attacking":
		if attack.can_attack():
			attack.try_attack()

	_replan()

# -----------------------------------------------------------------------------
# _get_guard_state
# -----------------------------------------------------------------------------
func _get_guard_state() -> String:
	if world_state.get_state("sees_ue"):
		return "attacking" if world_state.get_state("gap_closed") else "chasing"
	if world_state.get_state("target_lost"):
		return "searching"
	if world_state.get_state("at_home"):
		return "at_home"
	return "patrolling"

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
			ai_move_component.destination_reached.connect(_on_arrived_home, CONNECT_ONE_SHOT)
			ai_move_component.set_target(home_position)

		"GoPatrol":
			print(">>> ACTION: going on patrol")
			world_state.set_state("at_home",    false)
			world_state.set_state("patrolling", true)
			patrol_component.start()

		"ChaseUE":
			print(">>> ACTION: chasing UE")
			var ue = world_state.get_state("ue_target")
			if ue != null and not chase_component.active:
				world_state.set_state("patrolling",   false)
				world_state.set_state("gap_closed",   false)
				world_state.set_state("target_lost",  false)
				world_state.set_state("target_found", true)
				ai_move_component.set_speed(speed.get_run_speed())
				ai_move_component.set_running(true)
				chase_component.start_chase(ue)

		"Attack":
			print(">>> ACTION: attacking UE — attack loop running in _process")

		"Search":
			print(">>> ACTION: searching for lost target")
			patrol_component.stop()
			world_state.set_state("patrolling", false)
			world_state.set_state("at_home",    false)
			search_component.start_search(_last_known_position, _last_known_direction)

# -----------------------------------------------------------------------------
# _clear_pending_arrivals
# -----------------------------------------------------------------------------
func _clear_pending_arrivals() -> void:
	if ai_move_component.destination_reached.is_connected(patrol_component.arrived):
		ai_move_component.destination_reached.disconnect(patrol_component.arrived)
	if ai_move_component.destination_reached.is_connected(search_component.arrived):
		ai_move_component.destination_reached.disconnect(search_component.arrived)
	if ai_move_component.destination_reached.is_connected(_on_arrived_home):
		ai_move_component.destination_reached.disconnect(_on_arrived_home)

# -----------------------------------------------------------------------------
# REFLEX SIGNAL HANDLERS
# agent hears reflex signal, agent shouts at the right component
# -----------------------------------------------------------------------------

func _on_reflex_chase_started() -> void:
	var ue = world_state.get_state("ue_target")
	if ue == null or chase_component.active:
		return
	_clear_pending_arrivals()
	world_state.set_state("patrolling",   false)
	world_state.set_state("gap_closed",   false)
	world_state.set_state("target_lost",  false)
	world_state.set_state("target_found", true)
	_current_goal_name = "Chase"
	chase_component.start_chase(ue)

func _on_reflex_chase_stopped() -> void:
	chase_component.stop_chase()

func _on_reflex_patrol_stopped() -> void:
	patrol_component.stop()

func _on_reflex_search_stopped() -> void:
	search_component.stop()

func _on_reflex_movement_stopped() -> void:
	ai_move_component.stop()

func _on_reflex_speed_reset() -> void:
	ai_move_component.set_speed(speed.get_speed())
	ai_move_component.set_running(false)

func _on_reflex_run_started() -> void:
	ai_move_component.set_speed(speed.get_run_speed())
	ai_move_component.set_running(true)

func _on_reflex_attack_stopped() -> void:
	hitbox_component.deactivate()

func _on_reflex_hurt_started() -> void:
	hurtbox_component.set_invulnerable(true)
	animation.play_hurt()

func _on_reflex_death_started() -> void:
	animation.play_death()
	ai_move_component.stop()
	set_physics_process(false)
	set_process(false)

# -----------------------------------------------------------------------------
# VELOCITY HANDLER
# keeps attack component in sync with movement state
# -----------------------------------------------------------------------------

func _on_velocity_changed(_direction: Vector2, _is_moving: bool, is_running: bool) -> void:
	attack.set_running(is_running)

# -----------------------------------------------------------------------------
# VISION HANDLERS
# -----------------------------------------------------------------------------

func _on_alert_entered(_body: Node2D) -> void:
	print(">>> VISION: alert range — pressure building")
	_in_alert_range = true

func _on_danger_entered(_body: Node2D) -> void:
	print(">>> VISION: danger range")
	_in_danger_range = true
	reflex.on_danger_entered()

func _on_range_lost(_body: Node2D) -> void:
	print(">>> VISION: range lost — clearing zone states")
	_in_alert_range  = false
	_in_danger_range = false

func _on_spotted_ue(ue_body: Node2D) -> void:
	if world_state.get_state("sees_ue"):
		return
	print(">>> UE SPOTTED")
	world_state.set_state("sees_ue",      true)
	world_state.set_state("ue_target",    ue_body)
	world_state.set_state("gap_closed",   false)
	world_state.set_state("target_lost",  false)
	world_state.set_state("target_found", true)
	urge.on_ue_spotted()
	reflex.on_ue_spotted()
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
	urge.on_ue_lost()
	reflex.on_ue_lost()

func _on_gap_closed() -> void:
	print(">>> GAP CLOSED — aggression spike")
	world_state.set_state("gap_closed", true)
	urge.on_gap_closed()

# -----------------------------------------------------------------------------
# ATTACK HANDLERS
# -----------------------------------------------------------------------------

func _on_attack_triggered(damage_info: DamageInfo) -> void:
	var ue = world_state.get_state("ue_target")
	if ue == null:
		return
	var direction = (ue.global_position - global_position).normalized()
	damage_info.knockback_direction = direction
	hitbox_component.activate(damage_info)
	animation.play_attack(attack.is_running())

func _on_attack_finished() -> void:
	urge.on_hit_landed()
	_replan()

# -----------------------------------------------------------------------------
# HURTBOX HANDLER
# something hit us — route through health then reflex
# -----------------------------------------------------------------------------

func _on_hurtbox_hurt(damage_info: DamageInfo) -> void:
	health_component.take_damage(damage_info)

# -----------------------------------------------------------------------------
# HEALTH HANDLERS
# -----------------------------------------------------------------------------

func _on_hit_received(damage_info: DamageInfo) -> void:
	print(">>> GUARD: took %.1f damage" % damage_info.amount)
	reflex.on_hit_received()

func _on_died() -> void:
	print(">>> GUARD: died")
	reflex.on_died()

# -----------------------------------------------------------------------------
# SIGNAL HANDLERS
# -----------------------------------------------------------------------------

func _on_arrived_home() -> void:
	print(">>> ARRIVED HOME")
	world_state.set_state("at_home",      true)
	world_state.set_state("patrolling",   false)
	world_state.set_state("gap_closed",   false)
	world_state.set_state("target_lost",  false)
	world_state.set_state("target_found", true)
	search_component.stop()
	ai_move_component.stop()

func _on_new_patrol_target(position: Vector2) -> void:
	ai_move_component.destination_reached.connect(patrol_component.arrived, CONNECT_ONE_SHOT)
	ai_move_component.set_target(position)

func _on_search_move_to(position: Vector2) -> void:
	ai_move_component.destination_reached.connect(search_component.arrived, CONNECT_ONE_SHOT)
	ai_move_component.set_target(position)

func _on_search_finished() -> void:
	print(">>> SEARCH FINISHED — target not found, resuming normal life")
	world_state.set_state("target_lost",  false)
	world_state.set_state("target_found", true)

func _on_chase_move_to(position: Vector2) -> void:
	ai_move_component.set_target(position)

func _on_ue_lost() -> void:
	print(">>> CHASE: ue lost — giving up")
	world_state.set_state("target_lost",  false)
	world_state.set_state("target_found", true)
	world_state.set_state("sees_ue",      false)
	world_state.set_state("gap_closed",   false)
	reflex.on_chase_ue_lost()

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
	reflex.on_ue_died()
