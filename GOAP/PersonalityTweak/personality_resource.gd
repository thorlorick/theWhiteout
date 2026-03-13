class_name PersonalityResource
extends Resource
# -----------------------------------------------------------------------------
# PersonalityResource
# Urge rates and spikes per personality type.
# Save as .tres and assign in Inspector.
# 1.0 = standard guard baseline.
# -----------------------------------------------------------------------------

@export var aggression_build_rate:  float = 0.05
@export var aggression_decay_rate:  float = 0.08
@export var aggression_spike:       float = 0.8

@export var curiosity_build_rate:   float = 0.0
@export var curiosity_decay_rate:   float = 0.05
@export var curiosity_spike:        float = 0.8

@export var comfort_build_rate:     float = 0.02
@export var comfort_decay_rate:     float = 0.03

@export var duty_build_rate:        float = 0.02
@export var duty_decay_rate:        float = 0.02

@export var alert_zone_boost:       float = 0.003
@export var danger_zone_boost:      float = 0.25
@export var hit_landed_bonus:       float = 0.1
