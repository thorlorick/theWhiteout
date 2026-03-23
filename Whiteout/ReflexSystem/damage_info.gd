class_name DamageInfo
# -----------------------------------------------------------------------------
# DamageInfo
# A plain data container. No logic. No signals. No behavior.
# Created by the attacker, read by the receiver.
# -----------------------------------------------------------------------------
var amount: float
var knockback_direction: Vector2
var knockback_force: float
var source: Node

# -----------------------------------------------------------------------------
# init — build a DamageInfo package in one line
# -----------------------------------------------------------------------------
func init(p_amount: float, p_direction: Vector2, p_force: float, p_source: Node) -> DamageInfo:
	amount = p_amount
	knockback_direction = p_direction
	knockback_force = p_force
	source = p_source
	return self
