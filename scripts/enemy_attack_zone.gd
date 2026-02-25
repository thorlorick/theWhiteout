extends Node2D

signal body_entered_attack_zone(body)
signal body_exited_attack_zone(body)

@onready var attack_zone = $AttackZone

func _ready():
    attack_zone.body_entered.connect(_on_body_entered)
    attack_zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
    body_entered_attack_zone.emit(body)

func _on_body_exited(body):
    body_exited_attack_zone.emit(body)
