class_name MoveComponent
extends Node
# -----------------------------------------------------------------------------
# MoveComponent
# Moves the body along a navigation path.
# Emits velocity as a Vector2 — no string conversion here.
# -----------------------------------------------------------------------------
signal destination_reached
signal velocity_changed(direction: Vector2, is_moving: bool)

@export var body:  CharacterBody2D
@export var agent: NavigationAgent2D

var speed: float = 100.0

func _ready() -> void:
	agent.navigation_finished.connect(_on_navigation_finished)

func _physics_process(delta) -> void:
	if agent.is_navigation_finished():
		if body.velocity != Vector2.ZERO:
			body.velocity = Vector2.ZERO
			velocity_changed.emit(Vector2.ZERO, false)
		return
	var next_point = agent.get_next_path_position()
	var direction  = (next_point - body.global_position).normalized()
	body.velocity  = direction * speed
	body.move_and_slide()
	velocity_changed.emit(direction, true)

func set_speed(value: float) -> void:
	speed = value

func set_target(pos: Vector2) -> void:
	agent.target_position = pos

func stop() -> void:
	agent.target_position = body.global_position

func _on_navigation_finished() -> void:
	agent.target_position = body.global_position
	destination_reached.emit()
