class_name SpeedComponent
extends Node

@export var base_speed: float = 20.0
@export var chase_speed: float = 30.0
@export var run_speed: float = 40.0

func get_speed() -> float:
	return base_speed

func get_chase_speed() -> float:
	return chase_speed

func get_run_speed() -> float:
	return run_speed
	
func apply_personality(p: PersonalityResource) -> void:
	var s = p.sloth / 10.0
	var modifier = lerp(1.2, 0.5, s)
	base_speed  = base_speed  * modifier
	chase_speed = chase_speed * modifier
	run_speed   = run_speed   * modifier
	print(">>> SPEED: base: %.1f | chase: %.1f | run: %.1f" % [base_speed, chase_speed, run_speed])

