class_name PersonalityResource
extends Resource

# -----------------------------------------------------------------------------
# PersonalityResource
# Cost multipliers per action. Save as .tres and assign in Inspector.
# 1.0 = neutral. > 1.0 = reluctant. < 1.0 = eager.
# -----------------------------------------------------------------------------

@export var go_home_cost:   float = 1.0
@export var go_patrol_cost: float = 1.0
@export var chase_cost:     float = 1.0
@export var attack_cost:    float = 1.0
@export var search_cost:    float = 1.0
