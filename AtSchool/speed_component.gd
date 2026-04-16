class_name SpeedComponent
extends Node

# -------------------------------------------------------
# SpeedComponent
# Holds base speeds. Does the lerp. That's it.
# Sloth modifier comes from UrgeComponent via GuardAgent.
# -------------------------------------------------------

@export var base_speed:  float = 20.0
@export var chase_speed: float = 40.0

# -------------------------------------------------------
# get_speed_for_intensity
# intensity 0.0 = far away = fast (chase_speed)
# intensity 1.0 = right on top = slow (base_speed)
# sloth_modifier scales the whole range (from UrgeComponent)
# -------------------------------------------------------
func get_speed_for_intensity(intensity: float, sloth_modifier: float = 1.0) -> float:
	var raw = lerp(chase_speed, base_speed, intensity)
	return raw * sloth_modifier
