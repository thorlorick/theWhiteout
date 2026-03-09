class_name UrgeComponent

# -----------------------------------------------------------------------------
# UrgeComponent
# Three independent drives that build and decay on their own schedules.
# This component only measures. It never decides. The planner decides.
# -----------------------------------------------------------------------------

# urge values — always between 0.0 and 1.0
var home_urge:   float = 0.0
var patrol_urge: float = 0.5   # Joe starts with some patrol urge — he's a guard
var gap_urge:    float = 0.0

# build rates — how fast each urge grows per second
const HOME_URGE_BUILD_RATE:   float = 0.04   # builds while away from home
const PATROL_URGE_BUILD_RATE: float = 0.02   # builds while idle at home

# decay rates — how fast each urge settles (not to zero, to a resting value)
const HOME_URGE_DECAY_RATE:   float = 0.03   # settles when Joe arrives home
const PATROL_URGE_DECAY_RATE: float = 0.02   # settles when Joe starts patrolling
const GAP_URGE_DECAY_RATE:    float = 0.15   # drops quickly when threat is gone — tactical not emotional

# resting values — urges settle toward these, not toward zero
const HOME_URGE_REST:   float = 0.05
const PATROL_URGE_REST: float = 0.05
const GAP_URGE_REST:    float = 0.0    # no threat = no gap urge at rest

# threat zone boosts — how much each zone adds to home urge
const MIDDLE_ZONE_BOOST: float = 0.003  # small unease per frame
const INNER_ZONE_BOOST:  float = 0.25   # immediate spike — home is threatened

# -----------------------------------------------------------------------------
# tick — called every frame by EnemyAgent
# state: "at_home" | "patrolling" | "chasing"
# zone:  -1 (no threat) | 0 (outer) | 1 (middle) | 2 (inner)
# delta: frame time
# -----------------------------------------------------------------------------
func tick(delta: float, state: String, zone: int) -> void:
	match state:
		"at_home":
			# patrol urge builds — Joe gets restless
			patrol_urge = min(1.0, patrol_urge + PATROL_URGE_BUILD_RATE * delta)
			# home urge settles toward its resting value
			home_urge   = _decay_toward(home_urge, HOME_URGE_REST, HOME_URGE_DECAY_RATE, delta)
			# gap urge decays — no threat while home
			gap_urge    = _decay_toward(gap_urge, GAP_URGE_REST, GAP_URGE_DECAY_RATE, delta)

		"patrolling":
			# home urge builds — Joe gets homesick
			home_urge   = min(1.0, home_urge + HOME_URGE_BUILD_RATE * delta)
			# patrol urge settles — he's doing his job
			patrol_urge = _decay_toward(patrol_urge, PATROL_URGE_REST, PATROL_URGE_DECAY_RATE, delta)
			# apply zone pressure to home urge
			_apply_zone_pressure(delta, zone)

		"chasing":
			# home urge keeps building — Joe is worried
			home_urge   = min(1.0, home_urge + HOME_URGE_BUILD_RATE * delta)
			# gap urge is set directly by zone in ChaseComponent — not built here
			# apply zone pressure to home urge
			_apply_zone_pressure(delta, zone)

# -----------------------------------------------------------------------------
# _apply_zone_pressure — zone boosts home urge during patrol and chase
# -----------------------------------------------------------------------------
func _apply_zone_pressure(delta: float, zone: int) -> void:
	match zone:
		-1: pass  # outer or no UE — no pressure
		0:  pass  # outer zone — noted but no urge change
		1:  home_urge = min(1.0, home_urge + MIDDLE_ZONE_BOOST * delta)  # unease
		2:  home_urge = min(1.0, home_urge + INNER_ZONE_BOOST)           # spike — immediate

# -----------------------------------------------------------------------------
# set_gap_urge — called by ChaseComponent when zone changes
# gap urge is tactical, driven by geometry not time
# -----------------------------------------------------------------------------
func set_gap_urge(value: float) -> void:
	gap_urge = clamp(value, 0.0, 1.0)

# -----------------------------------------------------------------------------
# _decay_toward — smoothly move a value toward a target resting value
# -----------------------------------------------------------------------------
func _decay_toward(current: float, target: float, rate: float, delta: float) -> float:
	if current > target:
		return max(target, current - rate * delta)
	return current

# -----------------------------------------------------------------------------
# getters — clean read-only access for GoalsComponent and PlannerComponent
# -----------------------------------------------------------------------------
func get_home_urge()   -> float: return home_urge
func get_patrol_urge() -> float: return patrol_urge
func get_gap_urge()    -> float: return gap_urge
