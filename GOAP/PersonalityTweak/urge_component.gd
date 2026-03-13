class_name UrgeComponent
# -----------------------------------------------------------------------------
# UrgeComponent
# Four independent drives that build and decay on their own schedules.
# Comfort, duty, curiosity, and aggression.
# This component only measures. It never decides. The planner decides.
# Rates and spikes come from PersonalityResource — no hardcoded values.
# -----------------------------------------------------------------------------
var comfort_urge:    float = 0.0
var duty_urge:       float = 0.5
var curiosity_urge:  float = 0.0
var aggression_urge: float = 0.0

var _print_timer: float = 0.0

# rates — set by apply_personality, not hardcoded
var aggression_build_rate:  float = 0.05
var aggression_decay_rate:  float = 0.08
var aggression_spike:       float = 0.8

var curiosity_build_rate:   float = 0.0
var curiosity_decay_rate:   float = 0.05
var curiosity_spike:        float = 0.8

var comfort_build_rate:     float = 0.02
var comfort_decay_rate:     float = 0.03

var duty_build_rate:        float = 0.02
var duty_decay_rate:        float = 0.02

var alert_zone_boost:       float = 0.003
var danger_zone_boost:      float = 0.25
var hit_landed_bonus:       float = 0.1

const COMFORT_URGE_REST:    float = 0.05
const DUTY_URGE_REST:       float = 0.05
const CURIOSITY_URGE_REST:  float = 0.0
const AGGRESSION_URGE_REST: float = 0.0

# -----------------------------------------------------------------------------
# apply_personality — called once by GuardAgent in _ready()
# -----------------------------------------------------------------------------
func apply_personality(p: PersonalityResource) -> void:
	aggression_build_rate = p.aggression_build_rate
	aggression_decay_rate = p.aggression_decay_rate
	aggression_spike      = p.aggression_spike
	curiosity_build_rate  = p.curiosity_build_rate
	curiosity_decay_rate  = p.curiosity_decay_rate
	curiosity_spike       = p.curiosity_spike
	comfort_build_rate    = p.comfort_build_rate
	comfort_decay_rate    = p.comfort_decay_rate
	duty_build_rate       = p.duty_build_rate
	duty_decay_rate       = p.duty_decay_rate
	alert_zone_boost      = p.alert_zone_boost
	danger_zone_boost     = p.danger_zone_boost
	hit_landed_bonus      = p.hit_landed_bonus

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
# on_danger_entered
# -----------------------------------------------------------------------------
func on_danger_entered() -> void:
	print(">>> URGE: danger zone entered")

# -----------------------------------------------------------------------------
# on_ue_spotted
# -----------------------------------------------------------------------------
func on_ue_spotted() -> void:
	comfort_urge    = max(COMFORT_URGE_REST, comfort_urge - 0.1)
	aggression_urge = min(1.0, aggression_urge + 0.1)
	print(">>> URGE: ue spotted — threat registered")

# -----------------------------------------------------------------------------
# on_alert_tick
# -----------------------------------------------------------------------------
func on_alert_tick(delta: float) -> void:
	comfort_urge = min(1.0, comfort_urge + alert_zone_boost * delta)

# -----------------------------------------------------------------------------
# on_ue_lost
# -----------------------------------------------------------------------------
func on_ue_lost() -> void:
	curiosity_urge = min(1.0, curiosity_urge + curiosity_spike)
	print(">>> URGE: ue lost — curiosity spiked")

# -----------------------------------------------------------------------------
# on_gap_closed
# -----------------------------------------------------------------------------
func on_gap_closed() -> void:
	aggression_urge = max(aggression_urge, aggression_spike)
	print(">>> URGE: gap closed — aggression spiked")

# -----------------------------------------------------------------------------
# on_hit_landed
# -----------------------------------------------------------------------------
func on_hit_landed() -> void:
	aggression_urge = min(1.0, aggression_urge + hit_landed_bonus)
	print(">>> URGE: hit landed — aggression bonus")

# -----------------------------------------------------------------------------
# committed_to_patrol
# -----------------------------------------------------------------------------
func committed_to_patrol() -> void:
	comfort_urge = COMFORT_URGE_REST
	duty_urge    = 0.6
	print(">>> URGE: committed to patrol — comfort reset, duty boosted")

# -----------------------------------------------------------------------------
# committed_to_search
# -----------------------------------------------------------------------------
func committed_to_search() -> void:
	curiosity_urge = 0.8
	print(">>> URGE: committed to search")

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
