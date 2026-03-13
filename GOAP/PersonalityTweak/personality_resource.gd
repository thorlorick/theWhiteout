class_name PersonalityResource
extends Resource
# -----------------------------------------------------------------------------
# PersonalityResource
# Describe your guard in plain numbers out of 10.
# 5 = standard. 1 = very low. 10 = very high.
# -----------------------------------------------------------------------------

@export_range(0, 10) var comfort:    int = 5
@export_range(0, 10) var duty:       int = 5
@export_range(0, 10) var curiosity:  int = 5
@export_range(0, 10) var aggression: int = 5
