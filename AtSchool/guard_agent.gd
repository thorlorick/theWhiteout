class_name GuardAgent
extends CharacterBody2D

# -----------------------------------------------------------------------------
# COMPONENTS
# -----------------------------------------------------------------------------
var urge        := UrgeComponent.new()
var planner     := PlannerComponent.new()
var world_state := WorldState.new()
var goals       := GoalsComponent.new()
var actions     := ActionsComponent.new()
var animation   := EnemyAnimationComponent.new()
var attack      := AttackComponent.new()
var reflex      := ReflexComponent.new()
var combat_fsm  := CombatFSMComponent.new()

@export var ai_move_component:   AIMoveComponent
@export var vision_component:    VisionComponent
@export var chase_component:     ChaseComponent
@export var patrol_component:    PatrolComponent
@export var search_component:    SearchComponent
@export var health_component:    HealthComponent
@export var hitbox_component:    HitboxComponent
@export var hurtbox_component:   HurtboxComponent
@export var nav_region:          NavigationRegion2D
@export var home_position:       Vector2
@export var personality:         PersonalityResource
@export var knockback_component: KnockbackComponent
@export var speed_component_node: SpeedComponent
@export var animation_events:    AnimationEvents
@export var combat_meter:        CombatMeterComponent
@export var personal_space:      PersonalSpace

# -----------------------------------------------------------------------------
# INTERNAL STATE
# -----------------------------------------------------------------------------
var _current_goal_name:    String    = "DoWork"
var _last_known_position:  Vector2   = Vector2.ZERO
var _last_known_direction: Vector2   = Vector2.ZERO
var _last_damage_info:     DamageInfo = null
var _facing_direction:     Vector2   = Vector2.DOWN
var _hold_ground_timer:    float     = 0.0

const REPLAN_INTERVAL: float = 1.5
var   _replan_timer:   float = REPLAN_INTERVAL

# -----------------------------------------------------------------------------
# READY
# -----------------------------------------------------------------------------
func _ready() -> void:
	if personality != null:
		urge.apply_personality(personality)
		attack.personality = personality

	add_child(attack)
	add_child(animation)

	ai_move_component.set_speed(speed_component_node.get_speed())

	knockback_component.setup(self)

	patrol_component.nav_region    = nav_region
	patrol_component.home_position = home_position
	search_component.nav_region    = nav_region

	_connect_signals()
	_connect_reflex_signals()
	_setup_animation()

	world_state.set_state("at_home", true)
	world_state.set_state("is_safe", true)
	world_state.set_state("working", false)

# -----------------------------------------------------------------------------
# SIGNAL WIRING
# -----------------------------------------------------------------------------
func _connect_signals() -> void:
	ai_move_component.velocity_changed.connect(animation.update)
	ai_move_component.velocity_changed.connect(vision_component.update_direction)
	ai_move_component.velocity_changed.connect(attack.on_velocity_changed)
	ai_move_component.velocity_changed.connect(_on_velocity_changed)

	animation_events.attack_hit_frame.connect(_on_attack_hit_frame)
	animation_events.attack_animation_finished.connect(_on_attack_animation_finished)

	attack.attack_triggered.connect(_on_attack_triggered)

	chase_component.move_to.connect(_on_chase_move_to)
	chase_component.target_lost.connect(_on_chase_target_lost)

	combat_meter.combat_entered.connect(_on_combat_entered)
	combat_meter.combat_lost.connect(_on_combat_lost)

	health_component.hit.connect(_on_hit_received)
	health_component.died.connect(_on_died)

	hurtbox_component.hurt.connect(_on_hurtbox_hurt)

	knockback_component.knockback_finished.connect(_on_knockback_finished)

	patrol_component.new_patrol_target.connect(_on_new_patrol_target)

	search_component.search_move_to.connect(_on_search_move_to)
	search_component.search_finished.connect(_on_search_finished)

	vision_component.target_spotted.connect(_on_target_spotted)
	vision_component.target_lost.connect(_on_target_lost)

# -----------------------------------------------------------------------------
# REFLEX SIGNALS
# -----------------------------------------------------------------------------
func _connect_reflex_signals() -> void:
	reflex.interrupt_chase_started.connect(_on_reflex_chase_started)
	reflex.interrupt_chase_stopped.connect(_on_reflex_chase_stopped)
	reflex.interrupt_patrol_stopped.connect(_on_reflex_patrol_stopped)
	reflex.interrupt_search_stopped.connect(_on_reflex_search_stopped)
	reflex.interrupt_movement_stopped.connect(_on_reflex_movement_stopped)
	reflex.interrupt_speed_reset.connect(_on_reflex_speed_reset)
	reflex.interrupt_run_started.connect(_on_reflex_run_started)
	reflex.interrupt_attack_started.connect(_on_reflex_attack_started)
	reflex.interrupt_attack_stopped.connect(_on_reflex_attack_stopped)
	reflex.interrupt_hurt_started.connect(_on_reflex_hurt_started)
	reflex.interrupt_death_started.connect(_on_reflex_death_started)

# -----------------------------------------------------------------------------
# ANIMATION SETUP
# -----------------------------------------------------------------------------
func _setup_animation() -> void:
	var anim_tree = $AnimationTree
	animation.setup(anim_tree)

# -----------------------------------------------------------------------------
# PROCESS
# -----------------------------------------------------------------------------
func _process(delta: float) -> void:
	_tick_combat_meter(delta)
	_tick_in_range()

	var guard_state: String = _get_urge_state()
	urge.tick(delta, guard_state)
	goals.update_priorities(
		urge.get_comfort_urge(),
		urge.get_duty_urge(),
		urge.get_curiosity_urge(),
		urge.get_aggression_urge()
	)

	if _hold_ground_timer > 0.0:
		_hold_ground_timer -= delta
		if _hold_ground_timer <= 0.0:
			_hold_ground_timer = 0.0
			_replan()

	_replan_timer -= delta
	if _replan_timer <= 0.0:
		_replan_timer = REPLAN_INTERVAL
		_replan()

# -----------------------------------------------------------------------------
# _tick_combat_meter
# Agent relays information to the meter every frame.
# Vision intensity comes through the signal — stored each frame.
# Personal space is checked directly.
# Meter owns all the math — agent just passes what it knows.
# -----------------------------------------------------------------------------
var _current_vision_intensity: float = 0.0

func _tick_combat_meter(delta: float) -> void:
	if _current_vision_intensity > 0.0:
		combat_meter.add_to_meter(_current_vision_intensity * delta)

	if personal_space.is_player_inside():
		combat_meter.add_to_meter(combat_meter.personal_space_fill_rate * delta)

# -----------------------------------------------------------------------------
# _tick_in_range
# Agent measures distance to known target every frame.
# Writes in_range to world state directly — no signal needed.
# -----------------------------------------------------------------------------
func _tick_in_range() -> void:
	var target = world_state.get_state("known_target")
	if target == null:
		world_state.set_state("in_range", false)
		return
	var dist = global_position.distance_to(target.global_position)
	world_state.set_state("in_range", dist <= personality.attack_range)

# -----------------------------------------------------------------------------
# _get_urge_state
# -----------------------------------------------------------------------------
func _get_urge_state() -> String:
	if world_state.get_state("meter_is_full"):
		return "fighting"
	if world_state.get_state("sees_target"):
		return "hunting"
	if world_state.get_state("threat_nearby"):
		return "threatened"
	if world_state.get_state("target_lost"):
		return "working"
	if world_state.get_state("at_home"):
		return "safe"
	return "working"

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
	if best_action["name"] == planner.current_action_name and best_goal["name"] == _current_goal_name:
		return
	_current_goal_name          = best_goal["name"]
	planner.current_action_name = best_action["name"]
	print(">>> REPLAN — goal: %s | action: %s" % [best_goal["name"], best_action["name"]])
	_on_best_chosen_action(best_action)

# -----------------------------------------------------------------------------
# _on_best_chosen_action
# -----------------------------------------------------------------------------
func _on_best_chosen_action(action: Dictionary) -> void:
	_clear_pending_arrivals()
	match action["name"]:

		"GoHome":
			patrol_component.stop()
			search_component.stop()
			chase_component.stop_chase()
			world_state.set_state("working", false)
			world_state.set_state("at_home", false)
			urge.committed_to_safe()
			ai_move_component.destination_reached.connect(_on_arrived_home, CONNECT_ONE_SHOT)
			ai_move_component.set_target(home_position)

		"Flee":
			patrol_component.stop()
			search_component.stop()
			chase_component.stop_chase()
			world_state.set_state("working",       false)
			world_state.set_state("threat_nearby", false)
			urge.committed_to_safe()
			ai_move_component.set_running(true)
			ai_move_component.destination_reached.connect(_on_arrived_home, CONNECT_ONE_SHOT)
			ai_move_component.set_target(home_position)

		"Heal":
			patrol_component.stop()
			search_component.stop()

		"Patrol":
			world_state.set_state("at_home", false)
			world_state.set_state("working", true)
			world_state.set_state("is_safe", false)
			urge.committed_to_work()
			patrol_component.start()

		"StandGuard":
			patrol_component.stop()
			world_state.set_state("working", true)
			world_state.set_state("is_safe", false)
			urge.committed_to_work()
			ai_move_component.stop()

		"ChaseAsWork":
			var target = world_state.get_state("known_target")
			if target != null:
				patrol_component.stop()
				search_component.stop()
				world_state.set_state("working",     true)
				world_state.set_state("target_lost", false)
				chase_component.start_chase(target)

		"Attack":
			attack.try_attack()

		"ChaseAsDanger":
			var target = world_state.get_state("known_target")
			if target != null:
				patrol_component.stop()
				search_component.stop()
				world_state.set_state("target_lost", false)
				chase_component.start_chase(target)

		"ChaseAsUnknown":
			var target = world_state.get_state("known_target")
			if target != null:
				patrol_component.stop()
				search_component.stop()
				world_state.set_state("target_lost", false)
				urge.committed_to_search()
				chase_component.start_chase(target)

		"HoldGround":
			chase_component.stop_chase()
			patrol_component.stop()
			ai_move_component.stop()
			world_state.set_state("threat_nearby", true)
			_hold_ground_timer = randf_range(0.0, 3.0)

		"Search":
			patrol_component.stop()
			chase_component.stop_chase()
			world_state.set_state("at_home",  false)
			world_state.set_state("working",  false)
			urge.committed_to_search()
			search_component.start_search(_last_known_position, _last_known_direction)

# -----------------------------------------------------------------------------
# VISION SIGNAL HANDLERS
# -----------------------------------------------------------------------------
func _on_target_spotted(target_body: Node2D, intensity: float) -> void:
	_current_vision_intensity = intensity
	if not world_state.get_state("sees_target"):
		world_state.set_state("sees_target",    true)
		world_state.set_state("known_target",   target_body)
		world_state.set_state("is_safe",        false)
		world_state.set_state("danger_cleared", false)
		world_state.set_state("target_lost",    false)
		urge.on_target_spotted()
		_replan()
	_last_known_position  = target_body.global_position
	_last_known_direction = (target_body.global_position - global_position).normalized()
	world_state.set_state("last_known_position", target_body.global_position)

func _on_target_lost(last_known_pos: Vector2) -> void:
	_current_vision_intensity = 0.0
	_last_known_position      = last_known_pos
	_last_known_direction     = (last_known_pos - global_position).normalized()
	world_state.set_state("last_known_position", last_known_pos)
	world_state.set_state("sees_target",         false)
	world_state.set_state("threat_nearby",       false)
	world_state.set_state("target_lost",         true)
	world_state.set_state("unknown_resolved",    false)
	world_state.set_state("is_safe",             false)
	urge.on_target_lost()
	_replan()

# -----------------------------------------------------------------------------
# COMBAT METER HANDLERS
# -----------------------------------------------------------------------------
func _on_combat_entered() -> void:
	world_state.set_state("meter_is_full", true)
	_replan()

func _on_combat_lost() -> void:
	world_state.set_state("meter_is_full", false)
	_replan()

# -----------------------------------------------------------------------------
# DAMAGE FLOW
# -----------------------------------------------------------------------------
func _on_hurtbox_hurt(damage_info: DamageInfo) -> void:
	urge.on_hit_landed()
	if damage_info.source != null:
		damage_info.knockback_direction = (global_position - damage_info.source.global_position).normalized()
	_last_damage_info = damage_info
	health_component.take_damage(damage_info)

func _on_hit_received(damage_info: DamageInfo) -> void:
	world_state.set_state("is_injured", true)
	world_state.set_state("is_safe",    false)
	reflex.on_hit_received()
	_replan()

func _on_attack_triggered(damage_info: DamageInfo) -> void:
	animation.play_attack(attack.is_running())

func _on_attack_hit_frame() -> void:
	var info = attack.get_pending_damage_info()
	info.source = self
	hitbox_component.activate(info)

func _on_attack_animation_finished() -> void:
	hitbox_component.deactivate()
	attack.on_attack_finished()
	animation.on_attack_finished()
	combat_fsm.change_state(CombatFSMComponent.State.READY)
	_replan()

func _on_died() -> void:
	combat_fsm.change_state(CombatFSMComponent.State.DEAD)
	reflex.on_died()

# -----------------------------------------------------------------------------
# MOVEMENT ROUTING
# -----------------------------------------------------------------------------
func _on_arrived_home() -> void:
	world_state.set_state("at_home",         true)
	world_state.set_state("is_safe",         true)
	world_state.set_state("working",         false)
	world_state.set_state("target_lost",     false)
	world_state.set_state("unknown_resolved",true)
	search_component.stop()
	ai_move_component.stop()

func _on_new_patrol_target(position: Vector2) -> void:
	world_state.set_state("at_home", false)
	ai_move_component.destination_reached.connect(patrol_component.arrived, CONNECT_ONE_SHOT)
	ai_move_component.set_target(position)

func _on_search_move_to(position: Vector2) -> void:
	ai_move_component.destination_reached.connect(search_component.arrived, CONNECT_ONE_SHOT)
	ai_move_component.set_target(position)

func _on_search_finished() -> void:
	world_state.set_state("target_lost",      false)
	world_state.set_state("unknown_resolved", true)
	world_state.set_state("known_target",     null)
	_replan()

func _on_chase_move_to(position: Vector2) -> void:
	_last_known_position = position
	ai_move_component.set_target(position)

func _on_velocity_changed(direction: Vector2, is_moving: bool, _is_running: bool) -> void:
	if direction != Vector2.ZERO:
		_facing_direction = direction
		vision_component.update_direction(direction, is_moving)

func _on_chase_target_lost() -> void:
	world_state.set_state("sees_target", false)
	reflex.on_chase_target_lost()
	_replan()

# -----------------------------------------------------------------------------
# REFLEX HANDLERS
# -----------------------------------------------------------------------------
func _on_reflex_chase_started() -> void:
	var target = world_state.get_state("known_target")
	if target != null:
		chase_component.start_chase(target)

func _on_reflex_chase_stopped() -> void:
	chase_component.stop_chase()

func _on_reflex_patrol_stopped() -> void:
	patrol_component.stop()

func _on_reflex_search_stopped() -> void:
	search_component.stop()

func _on_reflex_movement_stopped() -> void:
	ai_move_component.stop()

func _on_reflex_speed_reset() -> void:
	ai_move_component.set_speed(speed_component_node.get_speed())
	ai_move_component.set_running(false)

func _on_reflex_run_started() -> void:
	ai_move_component.set_speed(speed_component_node.get_speed())
	ai_move_component.set_running(true)

func _on_reflex_attack_started() -> void:
	if not combat_fsm.can_act():
		return
	combat_fsm.change_state(CombatFSMComponent.State.ATTACKING)
	attack.try_attack()

func _on_reflex_attack_stopped() -> void:
	hitbox_component.deactivate()

func _on_reflex_hurt_started() -> void:
	hurtbox_component.set_invulnerable(true)
	animation.play_hurt()
	urge.on_hit_received()
	if _last_damage_info != null:
		knockback_component.apply(_last_damage_info.knockback_direction, _last_damage_info.knockback_force)

func _on_reflex_death_started() -> void:
	animation.play_death()
	ai_move_component.stop()
	set_process(false)

func _on_knockback_finished() -> void:
	hurtbox_component.set_invulnerable(false)
	_replan()

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
