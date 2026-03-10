class_name UrgeComponent

# -----------------------------------------------------------------------------
# UrgeComponent
# Two independent drives that build and decay on their own schedules.
# Home and patrol only. No zones — zones are handled by ZoneComponent.
# This component only measures. It never decides. The planner decides.
# -----------------------------------------------------------------------------

var home_urge:   float = 0.0
var patrol_urge: float = 0.5

var _print_timer: float = 0.0

const HOME_URGE_BUILD_RATE:   float = 0.04
const PATROL_URGE_BUILD_RATE: float = 0.02

const HOME_URGE_DECAY_RATE:   float = 0.03
const PATROL_URGE_DECAY_RATE: float = 0.02

const HOME_URGE_REST:   float = 0.05
const PATROL_URGE_REST: float = 0.05

const DANGER_ZONE_BOOST: float = 0.25   # spike on danger zone entry
const ALERT_ZONE_BOOST:  float = 0.003  # slow pressure per frame in alert zone

# -----------------------------------------------------------------------------
# tick — called every frame by EnemyAgent
# state: "at_home" | "patrolling" | "chasing"
# delta: frame time
# -----------------------------------------------------------------------------
func tick(delta: float, state: String) -> void:
	match state:
		"at_home":
			patrol_urge = min(1.0, patrol_urge + PATROL_URGE_BUILD_RATE * delta)
			home_urge   = _decay_toward(home_urge, HOME_URGE_REST, HOME_URGE_DECAY_RATE, delta)

		"patrolling":
			home_urge   = min(1.0, home_urge + HOME_URGE_BUILD_RATE * delta)
			patrol_urge = _decay_toward(patrol_urge, PATROL_URGE_REST, PATROL_URGE_DECAY_RATE, delta)

		"chasing":
			home_urge   = min(1.0, home_urge + HOME_URGE_BUILD_RATE * delta)

	_print_timer -= delta
	if _print_timer <= 0.0:
		_print_timer = 1.0
		print(">>> URGES [%s] — home: %.2f | patrol: %.2f" % [
			state,
			home_urge,
			patrol_urge
		])

# -----------------------------------------------------------------------------
# on_danger_entered — called by EnemyAgent when UE enters danger zone
# immediate spike — threat is at the doorstep
# -----------------------------------------------------------------------------
func on_danger_entered() -> void:
	home_urge = min(1.0, home_urge + DANGER_ZONE_BOOST)
	print(">>> URGE: danger zone entered — home urge spiked")

# -----------------------------------------------------------------------------
# on_alert_entered — called by EnemyAgent when UE enters alert zone
# slow pressure — something is close, unease builds
# -----------------------------------------------------------------------------
func on_alert_tick(delta: float) -> void:
	home_urge = min(1.0, home_urge + ALERT_ZONE_BOOST * delta)

# -----------------------------------------------------------------------------
# _decay_toward — smoothly move a value toward a target resting value
# -----------------------------------------------------------------------------
func _decay_toward(current: float, target: float, rate: float, delta: float) -> float:
	if current > target:
		return max(target, current - rate * delta)
	return current

# -----------------------------------------------------------------------------
# committed_to_patrol — guard just left home, reset home urge, boost patrol
# -----------------------------------------------------------------------------
func committed_to_patrol() -> void:
	home_urge   = HOME_URGE_REST
	patrol_urge = 0.6
	print(">>> URGE: committed to patrol — home reset, patrol boosted")

func get_home_urge()   -> float: return home_urge
func get_patrol_urge() -> float: return patrol_urge
