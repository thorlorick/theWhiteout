class_name PersonalSpace
extends Area2D

# -----------------------------------------------------------------------------
# PersonalSpace
# Evaluates a distance against configured zone boundaries.
# Returns which zone that distance falls in.
# Generic — works for any entity on any level.
# -----------------------------------------------------------------------------

# zone radii — set in the editor per level
@export var zone_inner:  float = 80.0

# -----------------------------------------------------------------------------
# get_zone — takes a distance, returns a zone
# -1 = no threat (outside outer zone)
#  0 = outer zone — someone is there, worth knowing
#  1 = middle zone — iffy, keep an eye on it
#  2 = inner zone — danger, act now
# -----------------------------------------------------------------------------
func get_zone(distance: float) -> int:
	if distance > zone_inner:
		return -1
	return 2
