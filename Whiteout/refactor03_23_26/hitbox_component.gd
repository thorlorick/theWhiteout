class_name HitboxComponent
extends Area2D

# -----------------------------------------------------------------------------
# HitboxComponent
# The danger zone during an attack swing.
# Created by AttackComponent, carries DamageInfo.
# Does nothing until activated.
# -----------------------------------------------------------------------------

signal hit_landed(damage_info: DamageInfo)

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

func _ready() -> void:
	area_entered.connect(_on_area_entered)

# -----------------------------------------------------------------------------
# _on_area_entered — something entered the danger zone
# only care if it's a HurtboxComponent and we're armed
# one hit per swing, deactivate immediately after connecting
# -----------------------------------------------------------------------------
func _on_area_entered(area: Area2D) -> void:
	if damage_info == null:
		return
	if not area is HurtboxComponent:
		return
	print(">>> HITBOX: connected — %.1f damage" % damage_info.amount)
	hit_landed.emit(damage_info)
	deactivate()

# -----------------------------------------------------------------------------
# deactivate — disarm the hitbox, clear data
# -----------------------------------------------------------------------------
func deactivate() -> void:
	damage_info = null
	monitoring = false
	print(">>> HITBOX: deactivated")
