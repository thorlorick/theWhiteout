class_name HitboxComponent
extends Area2D

var damage_info: DamageInfo = null

func activate(p_damage_info: DamageInfo) -> void:
	damage_info = p_damage_info
	monitorable = true
	print(">>> HITBOX: activated — %.1f damage, force %.1f" % [
		damage_info.amount, damage_info.knockback_force
	])

func deactivate() -> void:
	damage_info = null
	monitorable = false
	print(">>> HITBOX: deactivated")
