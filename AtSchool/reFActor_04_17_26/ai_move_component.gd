class_name AIMoveComponent
extends Node

signal destination_reached
signal velocity_changed(direction: Vector2, is_moving: bool, is_running: bool)

@export var body:  CharacterBody2D
@export var agent: NavigationAgent2D
@export var speed_component: SpeedComponent

var speed:      float = 100.0
var is_running: bool  = false
var has_target: bool  = false

# -----------------------------------------------------------------------------
func _ready() -> void:
	agent.navigation_finished.connect(_on_navigation_finished)
	if speed_component:
		speed = speed_component.base_speed

# -----------------------------------------------------------------------------
func _physics_process(_delta) -> void:
	if not has_target or agent.is_navigation_finished():
		if body.velocity != Vector2.ZERO:
			body.velocity = Vector2.ZERO
			body.move_and_slide()
		velocity_changed.emit(Vector2.ZERO, false, false)
		return

	var next_point = agent.get_next_path_position()
	var direction  = (next_point - body.global_position).normalized()

	if direction == Vector2.ZERO:
		velocity_changed.emit(Vector2.ZERO, false, false)
		return

	body.velocity = direction * speed
	body.move_and_slide()
	velocity_changed.emit(direction, true, is_running)

# -----------------------------------------------------------------------------
func set_target(pos: Vector2) -> void:
	has_target = true
	agent.target_position = pos

# -----------------------------------------------------------------------------
func set_speed(value: float) -> void:
	speed = value
	print(">>> SPEED SET: %.1f" % speed)

# -----------------------------------------------------------------------------
func set_running(value: bool) -> void:
	is_running = value

# -----------------------------------------------------------------------------
func stop() -> void:
	has_target = false
	agent.target_position = body.global_position

# -----------------------------------------------------------------------------
func _on_navigation_finished() -> void:
	has_target = false
	agent.target_position = body.global_position
	destination_reached.emit()
