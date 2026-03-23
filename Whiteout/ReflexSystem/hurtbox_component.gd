class_name HurtboxComponent
extends Area2D
# -----------------------------------------------------------------------------
# HurtboxComponent
# Joe's vulnerable area. Receives incoming DamageInfo.
# Signals the agent. Does nothing else.
# -----------------------------------------------------------------------------
signal hurt(damage_info: DamageInfo)

var is_invulnerable: bool = false
# -----------------------------------------------------------------------------
# _ready — connect to area entered
# -----------------------------------------------------------------------------
func _ready() -> void:
	connect("area_entered", _on_area_entered)
# -----------------------------------------------------------------------------
# _on_area_entered — something entered Joe's hurtbox
# only care if it's a HitboxComponent carrying DamageInfo
# -----------------------------------------------------------------------------
func _on_area_entered(area: Area2D) -> void:
	if is_invulnerable:
		return
	if not area is HitboxComponent:
		return
	if area.damage_info == null:
		return
	print(">>> HURTBOX: hit received — %.1f damage" % area.damage_info.amount)
	emit_signal("hurt", area.damage_info)
# -----------------------------------------------------------------------------
# set_invulnerable — i-frames on/off, called by agent
# -----------------------------------------------------------------------------
func set_invulnerable(value: bool) -> void:
	is_invulnerable = value
	print(">>> HURTBOX: invulnerable set to %s" % str(value))
