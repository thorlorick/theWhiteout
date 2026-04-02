class_name HealthComponent
extends Node

# -----------------------------------------------------------------------------
# HealthComponent
# Tracks current and max health for any entity.
# Emits signals when hit and when dead.
# Knows nothing about who hit who — that's the attacker's job.
# -----------------------------------------------------------------------------
  
signal hit(damage_info: DamageInfo)
signal died

@export var personality: PersonalityResource

var max_health: float
var current_health: float
var is_dead: bool = false
  
# -----------------------------------------------------------------------------
# _ready — pull max HP from personality
# -----------------------------------------------------------------------------
func _ready() -> void:
	max_health = personality.max_health
	current_health = max_health
  
# -----------------------------------------------------------------------------
# take_damage — reduce health, emit signals
# -----------------------------------------------------------------------------
func take_damage(damage_info: DamageInfo) -> void:
	if is_dead:
		return
	current_health = max(0.0, current_health - damage_info.amount)
	print(">>> HEALTH: took %.1f damage — %.1f / %.1f remaining" % [
		damage_info.amount, current_health, max_health
	])
	hit.emit(damage_info)
	if current_health <= 0.0:
		_die()

# -----------------------------------------------------------------------------
# heal — restore health, capped at max
# -----------------------------------------------------------------------------
func heal(amount: float) -> void:
	if is_dead:
		return
	current_health = min(max_health, current_health + amount)
	  
# -----------------------------------------------------------------------------
# _die — mark dead, emit signal
# -----------------------------------------------------------------------------
func _die() -> void:
	is_dead = true
	print(">>> HEALTH: entity died")
	died.emit()
  
# -----------------------------------------------------------------------------
# getters
# -----------------------------------------------------------------------------
func get_health()     -> float: return current_health
func get_max_health() -> float: return max_health
func get_is_dead()    -> bool:  return is_dead
