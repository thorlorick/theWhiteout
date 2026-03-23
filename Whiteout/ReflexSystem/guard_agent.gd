class_name GuardAgent
extends CharacterBody2D

# -----------------------------------------------------------------------------
# SIGNAL HUB (central decoupling point)
# -----------------------------------------------------------------------------
signal action_started(action_name: String)
signal damage_received(damage_info: DamageInfo)
signal target_spotted(target: Node2D)
signal target_lost()

# -----------------------------------------------------------------------------
# COMPONENTS
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

var _current_goal_name: String = "Patrol"
var _last_known_position:  Vector2 = Vector2.ZERO
var _last_known_direction: Vector2 = Vector2.ZERO
var _in_alert_range: bool = false
var _in_danger_range: bool = false

# -----------------------------------------------------------------------------
# READY
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
# SIGNAL WIRING
# -----------------------------------------------------------------------------
func _connect_signals() -> void:
	ai_move_component.velocity_changed.connect(animation.update)
	ai_move_component.velocity_changed.connect(vision_component.update_direction)

	health_component.hit.connect(_on_hit_received)
	health_component.died.connect(_on_died)
	damage_received.connect(health_component.take_damage)

	vision_component.spotted_ue.connect(_on_spotted_ue)
	vision_component.lost_ue.connect(_on_lost_ue)
	vision_component.gap_closed_signal.connect(_on_gap_closed)

	chase_component.move_to.connect(_on_chase_move_to)
	chase_component.ue_lost.connect(_on_ue_lost)

	hurtbox_component.hurt.connect(_on_hurtbox_hurt)

	patrol_component.new_patrol_target.connect(_on_new_patrol_target)
	search_component.search_move_to.connect(_on_search_move_to)
	search_component.search_finished.connect(_on_search_finished)

# -----------------------------------------------------------------------------
# REFLEX SIGNALS (agent routes only)
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
# ANIMATION SETUP
# -----------------------------------------------------------------------------
func _setup_animation() -> void:
	var anim_tree = $EnemyAnimations/AnimationTree
	animation.setup(anim_tree)

# -----------------------------------------------------------------------------
# PROCESS (NO DECISIONS HERE)
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

	_replan()

# -----------------------------------------------------------------------------
# DERIVED STATE (acceptable for now)
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
# REPLAN → EMITS INTENT ONLY
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

		print(">>> REPLAN — goal: %s | action: %s" % [
			best_goal["name"],
			best_action["name"]
		])

		emit_signal("action_started", best_action["name"])

# -----------------------------------------------------------------------------
# EVENTS → SIGNAL HUB
# -----------------------------------------------------------------------------
func _on_spotted_ue(ue_body: Node2D) -> void:
	if world_state.get_state("sees_ue"):
		return

	world_state.set_state("sees_ue", true)
	world_state.set_state("ue_target", ue_body)

	emit_signal("target_spotted", ue_body)
	urge.on_ue_spotted()

func _on_lost_ue() -> void:
	world_state.set_state("sees_ue", false)
	world_state.set_state("target_lost", true)

	emit_signal("target_lost")
	urge.on_ue_lost()

func _on_gap_closed() -> void:
	world_state.set_state("gap_closed", true)
	urge.on_gap_closed()

# -----------------------------------------------------------------------------
# DAMAGE FLOW (DECOUPLED)
# -----------------------------------------------------------------------------
func _on_hurtbox_hurt(damage_info: DamageInfo) -> void:
	emit_signal("damage_received", damage_info)

func _on_hit_received(damage_info: DamageInfo) -> void:
	print(">>> GUARD: took %.1f damage" % damage_info.amount)
	emit_signal("damage_received", damage_info)

func _on_died() -> void:
	print(">>> GUARD: died")

# -----------------------------------------------------------------------------
# MOVEMENT ROUTING
# -----------------------------------------------------------------------------
func _on_new_patrol_target(position: Vector2) -> void:
	ai_move_component.destination_reached.connect(patrol_component.arrived, CONNECT_ONE_SHOT)
	ai_move_component.set_target(position)

func _on_search_move_to(position: Vector2) -> void:
	ai_move_component.destination_reached.connect(search_component.arrived, CONNECT_ONE_SHOT)
	ai_move_component.set_target(position)

func _on_search_finished() -> void:
	world_state.set_state("target_lost", false)

func _on_chase_move_to(position: Vector2) -> void:
	ai_move_component.set_target(position)

func _on_ue_lost() -> void:
	world_state.set_state("sees_ue", false)
	world_state.set_state("gap_closed", false)

# -----------------------------------------------------------------------------
# REFLEX HANDLERS (still routing, allowed)
# -----------------------------------------------------------------------------
func _on_reflex_chase_started() -> void:
	var ue = world_state.get_state("ue_target")
	if ue == null or chase_component.active:
		return
	_clear_pending_arrivals()
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
	set_process(false)

# -----------------------------------------------------------------------------
# CLEANUP
# -----------------------------------------------------------------------------
func _clear_pending_arrivals() -> void:
	if ai_move_component.destination_reached.is_connected(patrol_component.arrived):
		ai_move_component.destination_reached.disconnect(patrol_component.arrived)
	if ai_move_component.destination_reached.is_connected(search_component.arrived):
		ai_move_component.destination_reached.disconnect(search_component.arrived)
	if ai_move_component.destination_reached.is_connected(_on_arrived_home):
		ai_move_component.destination_reached.disconnect(_on_arrived_home)
