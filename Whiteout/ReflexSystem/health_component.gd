class_name HealthComponent
extends Node

# -----------------------------------------------------------------------------
# HealthComponent
# Tracks current and max health for any entity.
# Emits signals when hit and when dead.
# Knows nothing about who hit who — that's the attacker's job.
# -----------------------------------------------------------------------------
signal hit(amount: float)
signal died

@export var max_health: float = 100.0

var current_health: float = max_health
var is_dead: bool = false

# -----------------------------------------------------------------------------
# take_damage — reduce health, emit signals
# -----------------------------------------------------------------------------
func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_health = max(0.0, current_health - amount)
	print(">>> HEALTH: took %.1f damage — %.1f / %.1f remaining" % [
		amount, current_health, max_health
	])
	emit_signal("hit", amount)
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
	emit_signal("died")

# -----------------------------------------------------------------------------
# getters
# -----------------------------------------------------------------------------
func get_health()     -> float: return current_health
func get_max_health() -> float: return max_health
func get_is_dead()    -> bool:  return is_dead
