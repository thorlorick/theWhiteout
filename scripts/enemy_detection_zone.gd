extends Node2D

signal body_entered_detection_zone(body)
signal body_exited_detection_zone(body)

@onready var detection_zone = $DetectionZone

func _ready():
    detection_zone.body_entered.connect(_on_body_entered)
    detection_zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
    body_entered_detection_zone.emit(body)

func _on_body_exited(body):
    body_exited_detection_zone.emit(body)
