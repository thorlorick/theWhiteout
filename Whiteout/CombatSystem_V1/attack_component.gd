class_name AttackComponent
extends Node

# -----------------------------------------------------------------------------
# AttackComponent
# Triggers attacks based on current movement state.
# Builds DamageInfo and signals the agent.
# Knows nothing about hitboxes, targets, health, or what it's hitting.
# Animation player handles hitbox deactivation timing.
# Attack type is set by the agent based on AIMoveComponent signals.
# -----------------------------------------------------------------------------

signal attack_triggered(damage_info: DamageInfo)
signal attack_finished

@export var personality: PersonalityResource

var _can_attack: bool = true
var _is_running: bool = false
var _pending_damage_info: DamageInfo = null  # stored until hit frame

# -----------------------------------------------------------------------------
# set_running — called by agent when velocity_changed fires
# -----------------------------------------------------------------------------
# func set_running(value: bool) -> void:
#	_is_running = value

func on_velocity_changed(_direction: Vector2, _is_moving: bool, is_running: bool) -> void:
	_is_running = is_running

# -----------------------------------------------------------------------------
# try_attack — build DamageInfo and signal the agent
# -----------------------------------------------------------------------------
func try_attack() -> void:
	if not _can_attack:
		return
	_can_attack = false
	_pending_damage_info = _build_damage_info()
	var label = "run_attack" if _is_running else "walk_attack"
	print(">>> ATTACK: %s triggered" % label)
	attack_triggered.emit(_pending_damage_info)

# -----------------------------------------------------------------------------
# _build_damage_info — package up damage based on current movement state
# -----------------------------------------------------------------------------
func _build_damage_info() -> DamageInfo:
	var amount: float
	var force: float
	if _is_running:
		amount = personality.run_attack_damage
		force  = personality.run_attack_force
	else:
		amount = personality.walk_attack_damage
		force  = personality.walk_attack_force
	return DamageInfo.new().init(amount, Vector2.ZERO, force, null)

# -----------------------------------------------------------------------------
# on_attack_finished — let agent know the attack is done.
# -----------------------------------------------------------------------------
func on_attack_finished() -> void:
	_can_attack = true
	_pending_damage_info = null
	print(">>> ATTACK: finished, ready")
	attack_finished.emit()

# -----------------------------------------------------------------------------
# getters
# -----------------------------------------------------------------------------
func can_attack() -> bool: return _can_attack
func is_running() -> bool: return _is_running
func get_pending_damage_info() -> DamageInfo: return _pending_damage_info

