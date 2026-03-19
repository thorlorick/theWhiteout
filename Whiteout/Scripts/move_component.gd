class_name MovementComponent
extends Node

signal movement_changed(velocity: Vector2, state: String)

var walk_speed: float
var run_speed: float
var run_action: String

func setup(p_walk_speed: float, p_run_speed: float, p_run_action: String) -> void:
	walk_speed = p_walk_speed
	run_speed = p_run_speed
	run_action = p_run_action

func process_movement() -> void:
	var input = Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	var is_running = Input.is_action_pressed(run_action)
	
	if input == Vector2.ZERO:
		movement_changed.emit(Vector2.ZERO, "idle")
		return
	
	var speed = run_speed if is_running else walk_speed
	var velocity = input.normalized() * speed
	var state = "run" if is_running else "walk"
	
	movement_changed.emit(velocity, state)
