class_name HitboxComponent
extends Area2D
# -----------------------------------------------------------------------------
# HitboxComponent
# The danger zone during an attack swing.
# Created by AttackComponent, carries DamageInfo.
# Does nothing until activated.
# -----------------------------------------------------------------------------
var damage_info: DamageInfo = null
# -----------------------------------------------------------------------------
# activate — arm the hitbox with a DamageInfo package
# -----------------------------------------------------------------------------
func activate(p_damage_info: DamageInfo) -> void:
	damage_info = p_damage_info
	monitoring = true
	print(">>> HITBOX: activated — %.1f damage, force %.1f" % [
		damage_info.amount, damage_info.knockback_force
	])
# -----------------------------------------------------------------------------
# deactivate — disarm the hitbox, clear data
# -----------------------------------------------------------------------------
func deactivate() -> void:
	damage_info = null
	monitoring = false
	print(">>> HITBOX: deactivated")
