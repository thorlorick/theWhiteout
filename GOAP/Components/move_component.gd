class_name MoveComponent
extends Node

signal destination_reached
signal velocity_changed(direction: String, is_moving: bool)

@export var body: CharacterBody2D
@export var agent: NavigationAgent2D

var speed: float = 100.0

func _ready() -> void:
	agent.navigation_finished.connect(_on_navigation_finished)

func _physics_process(delta) -> void:
	if agent.is_navigation_finished():
		if body.velocity != Vector2.ZERO:
			body.velocity = Vector2.ZERO
			velocity_changed.emit(_get_direction(body.velocity), false)
		return
	var next_point = agent.get_next_path_position()
	var direction = (next_point - body.global_position).normalized()
	body.velocity = direction * speed
	body.move_and_slide()
	velocity_changed.emit(_get_direction(body.velocity), true)

func set_speed(value: float) -> void:
	speed = value

func set_target(pos: Vector2) -> void:
	agent.target_position = pos

func stop() -> void:
	agent.target_position = body.global_position

func _on_navigation_finished() -> void:
	destination_reached.emit()

func _get_direction(vel: Vector2) -> String:
	if vel == Vector2.ZERO:
		return "down"
	if abs(vel.x) > abs(vel.y):
		return "right" if vel.x > 0 else "left"
	else:
		return "down" if vel.y > 0 else "up"
