class_name HurtboxComponent
extends Area2D
# -----------------------------------------------------------------------------
# HurtboxComponent
# Sole collision detector for incoming attacks.
# Signals the agent. Does nothing else.
# -----------------------------------------------------------------------------

signal hurt(damage_info: DamageInfo)

var is_invulnerable: bool = false

# -----------------------------------------------------------------------------
# _ready — connect to area entered
# -----------------------------------------------------------------------------
func _ready() -> void:
	area_entered.connect(_on_area_entered)

# -----------------------------------------------------------------------------
# _on_area_entered — something entered hurtbox
# only care if it's an armed HitboxComponent
# deactivates hitbox immediately — one hit per swing
# -----------------------------------------------------------------------------
func _on_area_entered(area: Area2D) -> void:
	if is_invulnerable:
		return
	if not area is HitboxComponent:
		return
	if area.damage_info == null:
		return
	print(">>> HURTBOX: hit received — %.1f damage" % area.damage_info.amount)
	hurt.emit(area.damage_info)
	area.deactivate()

# -----------------------------------------------------------------------------
# set_invulnerable — i-frames on/off, called by agent
# -----------------------------------------------------------------------------
func set_invulnerable(value: bool) -> void:
	is_invulnerable = value
	print(">>> HURTBOX: invulnerable set to %s" % str(value))
