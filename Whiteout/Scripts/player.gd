class_name Player
extends CharacterBody2D

@onready var speed_component: SpeedComponent = $SpeedComponent
@onready var move_component: MovementComponent = $MoveComponent

func _ready() -> void:
	move_component.setup(speed_component.get_speed(), speed_component.get_run_speed(), "run")
	move_component.movement_changed.connect(_on_movement_changed)

func _physics_process(delta: float) -> void:
	move_component.process_movement()

func _on_movement_changed(vel: Vector2, state: String) -> void:
	velocity = vel
	move_and_slide()
