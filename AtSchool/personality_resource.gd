class_name PersonalityResource
extends Resource
# -----------------------------------------------------------------------------
# PersonalityResource
# Describe your guard in plain numbers.
# Personality traits: 0-10. 5 = standard. 1 = very low. 10 = very high.
# Combat stats: real values, tweak to taste.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# personality traits
# -----------------------------------------------------------------------------
@export_range(0, 10) var comfort:    int = 5
@export_range(0, 10) var duty:       int = 5
@export_range(0, 10) var curiosity:  int = 5
@export_range(0, 10) var aggression: int = 5

# -----------------------------------------------------------------------------
# combat stats
# -----------------------------------------------------------------------------
@export var max_health:        float = 100.0

@export var attack_range: float = 45.0

@export var walk_attack_damage: float = 10.0
@export var walk_attack_force:  float = 150.0

@export var run_attack_damage:  float = 20.0
@export var run_attack_force:   float = 300.0
