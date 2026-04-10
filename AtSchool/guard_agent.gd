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
var speed       := SpeedComponent.new()
var attack      := AttackComponent.new()
var reflex      := ReflexComponent.new()
var combat_fsm := CombatFSMComponent.new()

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
@export var knockback_component: KnockbackComponent
@export var animation_events:   AnimationEvents
@export var combat_meter: CombatMeterComponent
@export var personal_space: PersonalSpace

# -----------------------------------------------------------------------------
# INTERNAL STATE
# -----------------------------------------------------------------------------
var _current_goal_name:    String  = "DoWork"
var _last_known_position:  Vector2 = Vector2.ZERO
var _last_known_direction: Vector2 = Vector2.ZERO
var _last_damage_info:     DamageInfo = null
var _in_alert_range:       bool    = false
var _in_danger_range:      bool    = false
var _facing_direction:     Vector2 = Vector2.DOWN
var _hold_ground_timer: float = 0.0
var in_combat: bool = false

# replan timer — urges decide in quiet moments, events decide in loud ones
const REPLAN_INTERVAL: float = 1.5
var   _replan_timer:   float = REPLAN_INTERVAL

# -----------------------------------------------------------------------------
# READY
# -----------------------------------------------------------------------------
func _ready() -> void:
	if personality != null:
		urge.apply_personality(personality)
		attack.personality = personality
		vision_component.apply_awareness(personality.awareness)

	add_child(attack)
	add_child(animation)

	ai_move_component.set_speed(speed.get_speed())

	knockback_component.setup(self)

	patrol_component.nav_region    = nav_region
	patrol_component.home_position = home_position

	search_component.nav_region    = nav_region
	

	_connect_signals()
	_connect_reflex_signals()
	_setup_animation()

	# start in a safe state — world state reflects reality
	world_state.set_state("at_home",  true)
	world_state.set_state("is_safe",  true)
	world_state.set_state("working",  false)

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

	vision_component.target_spotted.connect(_on_spotted_target)
	vision_component.target_lost.connect(_on_confirmed_target_lost)

	# vision_component.danger_range.connect(_on_danger_range)
	# vision_component.gap_closed.connect(_on_gap_closed)
	# vision_component.alert_range.connect(_on_alert_range)
	# vision_component.gap_opened.connect(_on_gap_opened)
	# vision_component.partial_sighting_lost.connect(_on_partial_sighting_lost)

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
# PROCESS — urges tick every frame, planner checks in periodically
# no decisions made here directly — urges decide, timer calls replan
# -----------------------------------------------------------------------------
func _process(delta: float) -> void:
	if not in_combat:
		var vision_intensity = vision_component.get_current_intensity() 
		combat_meter.add_to_meter(vision_intensity * delta)
		if personal_space.is_player_inside():
			combat_meter.add_to_meter(combat_meter.personal_space_fill_rate * delta)


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
		print(">>> TIMER: firing replan")
		_replan()

# -----------------------------------------------------------------------------
# _get_urge_state — maps world state to urge tick categories
# agent reads the room and tells the urge component how to feel
# five states: "safe", "working", "threatened", "hunting", "fighting"
# -----------------------------------------------------------------------------
func _get_urge_state() -> String:
	if world_state.get_state("gap_closed"):
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
# _replan — reads urges, finds best unsatisfied goal, acts
# single decision point. called by timer and by dramatic events.
# -----------------------------------------------------------------------------
func _replan() -> void:
	var best_goal = planner.get_best_goal(goals.goals, _current_goal_name)
	if planner.is_goal_satisfied(best_goal, world_state):
		return
	var best_action = planner.get_best_action(best_goal, actions.actions, world_state)
	if best_action.is_empty():
		return
	if best_action["name"] == planner.current_action_name and best_goal["name"] == _current_goal_name:
		return  # already doing the best thing
	_current_goal_name = best_goal["name"]
	planner.current_action_name = best_action["name"]
	print(">>> REPLAN — goal: %s | action: %s" % [best_goal["name"], best_action["name"]])
	_on_best_chosen_action(best_action)

# -----------------------------------------------------------------------------
# _on_best_chosen_action — planner has spoken, agent routes to components
# no decisions made here, just the right doors knocked on
# -----------------------------------------------------------------------------
func _on_best_chosen_action(action: Dictionary) -> void:
	_clear_pending_arrivals()
	match action["name"]:

		"GoHome":
			print(">>> ACTION: going home")
			patrol_component.stop()
			search_component.stop()
			chase_component.stop_chase()
			world_state.set_state("working",   false)
			world_state.set_state("at_home",   false)
			urge.committed_to_safe()
			ai_move_component.destination_reached.connect(_on_arrived_home, CONNECT_ONE_SHOT)
			ai_move_component.set_target(home_position)

		"Flee":
			print(">>> ACTION: fleeing")
			patrol_component.stop()
			search_component.stop()
			chase_component.stop_chase()
			world_state.set_state("working",      false)
			world_state.set_state("threat_nearby", false)
			urge.committed_to_safe()
			ai_move_component.set_running(true)
			ai_move_component.destination_reached.connect(_on_arrived_home, CONNECT_ONE_SHOT)
			ai_move_component.set_target(home_position)

		"Heal":
			print(">>> ACTION: healing")
			# placeholder — heal logic lives in health component, wired later
			patrol_component.stop()
			search_component.stop()

		"Patrol":
			print(">>> ACTION: starting patrol")
			world_state.set_state("at_home", false)
			world_state.set_state("working", true)
			world_state.set_state("is_safe", false)
			urge.committed_to_work()
			patrol_component.start()

		"StandGuard":
			print(">>> ACTION: standing guard")
			patrol_component.stop()
			world_state.set_state("working", true)
			world_state.set_state("is_safe", false)
			urge.committed_to_work()
			ai_move_component.stop()

		"ChaseAsWork":
			print(">>> ACTION: chasing — duty driven")
			var target = world_state.get_state("known_target")
			if target != null:
				patrol_component.stop()
				search_component.stop()
				world_state.set_state("working",     true)
				world_state.set_state("target_lost", false)
				chase_component.start_chase(target)

		"ChaseAsDanger":
			print(">>> ACTION: chasing — aggression driven")
			var target = world_state.get_state("known_target")
			if target != null:
				patrol_component.stop()
				search_component.stop()
				world_state.set_state("gap_closed",  false)
				world_state.set_state("target_lost", false)
				chase_component.start_chase(target)

		"ChaseAsUnknown":
			print(">>> ACTION: chasing — curiosity driven")
			var target = world_state.get_state("known_target")
			if target != null:
				patrol_component.stop()
				search_component.stop()
				world_state.set_state("target_lost", false)
				urge.committed_to_search()
				chase_component.start_chase(target)

		"HoldGround":
			print(">>> ACTION: holding ground")
			chase_component.stop_chase()
			patrol_component.stop()
			ai_move_component.stop()
			world_state.set_state("threat_nearby", true)
			_hold_ground_timer = randf_range(0.0, 3.0)

		"Search":
			print(">>> ACTION: searching for lost target")
			patrol_component.stop()
			chase_component.stop_chase()
			world_state.set_state("at_home",  false)
			world_state.set_state("working",  false)
			urge.committed_to_search()
			search_component.start_search(_last_known_position, _last_known_direction)

# -----------------------------------------------------------------------------
# EVENTS — signal hub, no decisions, just world state updates and routing
# -----------------------------------------------------------------------------
func _on_spotted_target(target_body: Node2D) -> void:
	if world_state.get_state("sees_target"):
		return
	world_state.set_state("sees_target",   true)
	world_state.set_state("known_target",  target_body)
	world_state.set_state("is_safe",       false)
	world_state.set_state("danger_cleared",false)
	_last_known_position  = target_body.global_position
	_last_known_direction = (target_body.global_position - global_position).normalized()
	urge.on_target_spotted()
	_replan()

func _on_confirmed_target_lost() -> void:
	_last_known_position  = world_state.get_state("known_target").global_position if world_state.get_state("known_target") != null else _last_known_position
	world_state.set_state("sees_target",      false)
	world_state.set_state("threat_nearby", false)
	world_state.set_state("target_lost",      true)
	world_state.set_state("unknown_resolved", false)
	world_state.set_state("is_safe",          false)
	vision_component.on_target_lost()
	urge.on_target_lost()
	# reflex.on_target_lost()
	print(">>> AGENT: target_lost=%s | unknown_resolved=%s" % [
	# world_state.get_state("target_lost"),
	# world_state.get_state("unknown_resolved")
])
	_replan()

func _on_combat_entered() -> void:
	in_combat = true
	_replan()

func _on_combat_lost() -> void:
	in_combat = false
	_replan()

# -----------------------------------------------------------------------------
# DAMAGE FLOW
# -----------------------------------------------------------------------------
func _on_hurtbox_hurt(damage_info: DamageInfo) -> void:
	urge.on_hit_landed()
	print(">>> GUARD: hit landed — aggression fed")
	if damage_info.source != null:
		damage_info.knockback_direction = (global_position - damage_info.source.global_position).normalized()
	_last_damage_info = damage_info
	health_component.take_damage(damage_info)

func _on_hit_received(damage_info: DamageInfo) -> void:
	print(">>> GUARD: took %.1f damage" % damage_info.amount)
	world_state.set_state("is_injured",  true)
	world_state.set_state("is_safe",     false)
    reflex.on_hit_received()
    _replan()

func _on_attack_triggered(damage_info: DamageInfo) -> void:
	animation.play_attack(attack.is_running())

func _on_attack_hit_frame() -> void:
	var info = attack.get_pending_damage_info()
	info.source = self
	hitbox_component.activate(info)
	print(">>> GUARD: hit frame")

func _on_attack_animation_finished() -> void:
    hitbox_component.deactivate()
    attack.on_attack_finished()
    animation.on_attack_finished()
    combat_fsm.change_state(CombatFSMComponent.State.READY)
    _replan()

func _on_died() -> void:
	print(">>> GUARD: died")
	combat_fsm.change_state(CombatFSMComponent.State.DEAD)
    reflex.on_died()

# -----------------------------------------------------------------------------
# MOVEMENT ROUTING
# -----------------------------------------------------------------------------
func _on_arrived_home() -> void:
	print(">>> ARRIVED HOME")
	world_state.set_state("at_home",         true)
	world_state.set_state("is_safe",          true)
	world_state.set_state("working",          false)
	world_state.set_state("gap_closed",       false)
	world_state.set_state("target_lost",      false)
	world_state.set_state("unknown_resolved", true)
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

func _on_chase_target_lost() -> void:
	world_state.set_state("sees_target", false)
	world_state.set_state("gap_closed",  false)
	reflex.on_chase_target_lost()
	_replan()

# -----------------------------------------------------------------------------
# REFLEX HANDLERS (routing only)
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
	ai_move_component.set_speed(speed.get_speed())
	ai_move_component.set_running(false)

func _on_reflex_run_started() -> void:
	ai_move_component.set_speed(speed.get_run_speed())
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
	print(">>> GUARD: knockback finished — replanning")
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
