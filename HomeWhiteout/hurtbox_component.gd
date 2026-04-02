class_name HurtboxComponent
extends Area2D

signal hurt(damage_info: DamageInfo)
var is_invulnerable: bool = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	print(">>> HURTBOX: ready and listening")

func _on_body_entered(body) -> void:
	print(">>> HURTBOX: BODY entered — %s" % body.name)

func _on_area_entered(area: Area2D) -> void:
	print(">>> HURTBOX: something entered — %s" % area.name)
	if is_invulnerable:
		print(">>> HURTBOX: rejected — invulnerable")
		return
	if not area is HitboxComponent:
		print(">>> HURTBOX: rejected — not a hitbox")
		return
	if area.damage_info == null:
		print(">>> HURTBOX: rejected — damage_info is null")
		return
	print(">>> HURTBOX: hit received — %.1f damage" % area.damage_info.amount)
	hurt.emit(area.damage_info)
	area.deactivate()

func set_invulnerable(value: bool) -> void:
	is_invulnerable = value
	print(">>> HURTBOX: invulnerable set to %s" % str(value))
