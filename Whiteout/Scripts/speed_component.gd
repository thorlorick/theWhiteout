class_name SpeedComponent
extends Node

@export var base_speed: float = 200.0
@export var run_speed: float = 350.0

func get_speed() -> float:
	return base_speed

func get_run_speed() -> float:
	return run_speed
