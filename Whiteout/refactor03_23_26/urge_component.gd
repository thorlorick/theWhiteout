class_name UrgeComponent

# -----------------------------------------------------------------------------
# UrgeComponent
# Four independent drives that build and decay on their own schedules.
# Comfort, duty, curiosity, and aggression.
# This component only measures. It never decides. The planner decides.
# Rates and spikes are calculated from PersonalityResource.
# If no personality is assigned, standard guard fallback values are used.
# -----------------------------------------------------------------------------

var comfort_urge:    float = 0.0
var duty_urge:       float = 0.5
var curiosity_urge:  float = 0.0
var aggression_urge: float = 0.0

var _print_timer: float = 0.0

# rates — calculated from personality, fallback = standard guard (5/10)
var aggression_build_rate:  float = 0.10
var aggression_decay_rate:  float = 0.06
var aggression_spike:       float = 0.7
var hit_landed_bonus:       float = 0.15
var hit_received_comfort_spike:    float = 0.2
var hit_received_aggression_spike: float = 0.2

var curiosity_build_rate:   float = 0.02
var curiosity_decay_rate:   float = 0.05
var curiosity_spike:        float = 0.6

var comfort_build_rate:     float = 0.03
var comfort_decay_rate:     float = 0.03

var duty_build_rate:        float = 0.03
var duty_decay_rate:        float = 0.03

var alert_zone_boost:       float = 0.003

const COMFORT_URGE_REST:    float = 0.05
const DUTY_URGE_REST:       float = 0.05
const CURIOSITY_URGE_REST:  float = 0.0
const AGGRESSION_URGE_REST: float = 0.0

# -----------------------------------------------------------------------------
# apply_personality — called once by GuardAgent in _ready()
# translates 0-10 scores into internal rates via lerp
# -----------------------------------------------------------------------------
func apply_personality(p: PersonalityResource) -> void:
	var a  = p.aggression / 10.0
	var c  = p.comfort    / 10.0
	var d  = p.duty       / 10.0
	var cu = p.curiosity  / 10.0

	aggression_build_rate = lerp(0.01, 0.20, a)
	aggression_decay_rate = lerp(0.12, 0.01, a)
	aggression_spike      = lerp(0.4,  1.0,  a)
	hit_landed_bonus      = lerp(0.05, 0.25, a)
	hit_received_comfort_spike    = lerp(0.4,  0.05, a)
	hit_received_aggression_spike = lerp(0.05, 0.4,  a)

	comfort_build_rate    = lerp(0.01, 0.05, c)
	comfort_decay_rate    = lerp(0.05, 0.01, c)

	duty_build_rate       = lerp(0.01, 0.05, d)
	duty_decay_rate       = lerp(0.05, 0.01, d)

	curiosity_build_rate  = lerp(0.0,  0.05, cu)
	curiosity_decay_rate  = lerp(0.08, 0.02, cu)
	curiosity_spike       = lerp(0.2,  1.0,  cu)

# -----------------------------------------------------------------------------
# tick — called every frame by GuardAgent
# -----------------------------------------------------------------------------
func tick(delta: float, state: String) -> void:
	match state:
		"at_home":
			duty_urge       = min(1.0, duty_urge + duty_build_rate * delta)
			comfort_urge    = _decay_toward(comfort_urge, COMFORT_URGE_REST, comfort_decay_rate, delta)
			curiosity_urge  = _decay_toward(curiosity_urge, CURIOSITY_URGE_REST, curiosity_decay_rate, delta)
			aggression_urge = _decay_toward(aggression_urge, AGGRESSION_URGE_REST, aggression_decay_rate, delta)
		"patrolling":
			comfort_urge    = min(1.0, comfort_urge + comfort_build_rate * delta)
			duty_urge       = _decay_toward(duty_urge, DUTY_URGE_REST, duty_decay_rate, delta)
			curiosity_urge  = _decay_toward(curiosity_urge, CURIOSITY_URGE_REST, curiosity_decay_rate, delta)
			aggression_urge = _decay_toward(aggression_urge, AGGRESSION_URGE_REST, aggression_decay_rate, delta)
		"chasing":
			comfort_urge    = _decay_toward(comfort_urge, COMFORT_URGE_REST, comfort_decay_rate, delta)
			duty_urge       = _decay_toward(duty_urge, DUTY_URGE_REST, duty_decay_rate, delta)
			curiosity_urge  = _decay_toward(curiosity_urge, CURIOSITY_URGE_REST, curiosity_decay_rate, delta)
			aggression_urge = min(1.0, aggression_urge + aggression_build_rate * delta)
		"searching":
			comfort_urge    = min(1.0, comfort_urge + comfort_build_rate * delta)
			curiosity_urge  = _decay_toward(curiosity_urge, CURIOSITY_URGE_REST, curiosity_decay_rate, delta)
			aggression_urge = _decay_toward(aggression_urge, AGGRESSION_URGE_REST, aggression_decay_rate, delta)
		"attacking":
			comfort_urge    = _decay_toward(comfort_urge, COMFORT_URGE_REST, comfort_decay_rate, delta)
			duty_urge       = _decay_toward(duty_urge, DUTY_URGE_REST, duty_decay_rate, delta)
			curiosity_urge  = _decay_toward(curiosity_urge, CURIOSITY_URGE_REST, curiosity_decay_rate, delta)
			aggression_urge = _decay_toward(aggression_urge, AGGRESSION_URGE_REST, aggression_decay_rate * 0.5, delta)

	_print_timer -= delta
	if _print_timer <= 0.0:
		_print_timer = 1.0
		print(">>> URGES [%s] — comfort: %.2f | duty: %.2f | curiosity: %.2f | aggression: %.2f" % [
			state, comfort_urge, duty_urge, curiosity_urge, aggression_urge
		])

# -----------------------------------------------------------------------------
# on_alert_tick — called every frame by GuardAgent while in alert range
# slow comfort build — something feels off but nothing confirmed yet
# -----------------------------------------------------------------------------
func on_alert_tick(delta: float) -> void:
	comfort_urge = min(1.0, comfort_urge + alert_zone_boost * delta)

# -----------------------------------------------------------------------------
# on_target_spotted — confirmed sighting, threat registered
# -----------------------------------------------------------------------------
func on_target_spotted() -> void:
	comfort_urge    = max(COMFORT_URGE_REST, comfort_urge - 0.1)
	aggression_urge = min(1.0, aggression_urge + 0.1)
	print(">>> URGE: target spotted — threat registered")

# -----------------------------------------------------------------------------
# on_target_lost — lost visual, curiosity spikes to drive search
# -----------------------------------------------------------------------------
func on_target_lost() -> void:
	curiosity_urge = min(1.0, curiosity_urge + curiosity_spike)
	print(">>> URGE: target lost — curiosity spiked")

# -----------------------------------------------------------------------------
# on_gap_closed — strike distance reached, aggression spikes
# -----------------------------------------------------------------------------
func on_gap_closed() -> void:
	aggression_urge = max(aggression_urge, aggression_spike)
	print(">>> URGE: gap closed — aggression spiked")

# -----------------------------------------------------------------------------
# on_hit_landed — successful hit feeds aggression
# -----------------------------------------------------------------------------
func on_hit_landed() -> void:
	aggression_urge = min(1.0, aggression_urge + hit_landed_bonus)
	print(">>> URGE: hit landed — aggression bonus")

# -----------------------------------------------------------------------------
# on_hit_received — took a hit, emotional wave follows the body reaction
# low aggression: comfort spikes hard, wants to flee
# high aggression: aggression spikes, wants to fight back
# -----------------------------------------------------------------------------
func on_hit_received() -> void:
	comfort_urge    = min(1.0, comfort_urge + hit_received_comfort_spike)
	aggression_urge = min(1.0, aggression_urge + hit_received_aggression_spike)
	print(">>> URGE: hit received — comfort: %.2f | aggression: %.2f" % [comfort_urge, aggression_urge])

# -----------------------------------------------------------------------------
# _decay_toward
# -----------------------------------------------------------------------------
func _decay_toward(current: float, target: float, rate: float, delta: float) -> float:
	if current > target:
		return max(target, current - rate * delta)
	return current

func get_comfort_urge()    -> float: return comfort_urge
func get_duty_urge()       -> float: return duty_urge
func get_curiosity_urge()  -> float: return curiosity_urge
func get_aggression_urge() -> float: return aggression_urge
