class_name UrgeComponent
# -----------------------------------------------------------------------------
# UrgeComponent
# Three independent drives that build and decay on their own schedules.
# Home, patrol, and curiosity only.
# This component only measures. It never decides. The planner decides.
# -----------------------------------------------------------------------------
var home_urge:      float = 0.0
var patrol_urge:    float = 0.5
var curiosity_urge: float = 0.0

var _print_timer: float = 0.0

const HOME_URGE_BUILD_RATE:      float = 0.02
const PATROL_URGE_BUILD_RATE:    float = 0.02
const CURIOSITY_URGE_BUILD_RATE: float = 0.0

const HOME_URGE_DECAY_RATE:      float = 0.03
const PATROL_URGE_DECAY_RATE:    float = 0.02
const CURIOSITY_URGE_DECAY_RATE: float = 0.05

const HOME_URGE_REST:      float = 0.05
const PATROL_URGE_REST:    float = 0.05
const CURIOSITY_URGE_REST: float = 0.0

const DANGER_ZONE_BOOST:   float = 0.25
const ALERT_ZONE_BOOST:    float = 0.003
const CURIOSITY_SPIKE:     float = 0.8

# -----------------------------------------------------------------------------
# tick — called every frame by EnemyAgent
# state: "at_home" | "patrolling" | "chasing" | "searching"
# -----------------------------------------------------------------------------
func tick(delta: float, state: String) -> void:
	match state:
		"at_home":
			patrol_urge    = min(1.0, patrol_urge + PATROL_URGE_BUILD_RATE * delta)
			home_urge      = _decay_toward(home_urge, HOME_URGE_REST, HOME_URGE_DECAY_RATE, delta)
			curiosity_urge = _decay_toward(curiosity_urge, CURIOSITY_URGE_REST, CURIOSITY_URGE_DECAY_RATE, delta)
		"patrolling":
			home_urge      = min(1.0, home_urge + HOME_URGE_BUILD_RATE * delta)
			patrol_urge    = _decay_toward(patrol_urge, PATROL_URGE_REST, PATROL_URGE_DECAY_RATE, delta)
			curiosity_urge = _decay_toward(curiosity_urge, CURIOSITY_URGE_REST, CURIOSITY_URGE_DECAY_RATE, delta)
		"chasing":
			home_urge      = min(1.0, home_urge + HOME_URGE_BUILD_RATE * delta)
			curiosity_urge = _decay_toward(curiosity_urge, CURIOSITY_URGE_REST, CURIOSITY_URGE_DECAY_RATE, delta)
		"searching":
			home_urge      = min(1.0, home_urge + HOME_URGE_BUILD_RATE * delta)
			curiosity_urge = _decay_toward(curiosity_urge, CURIOSITY_URGE_REST, CURIOSITY_URGE_DECAY_RATE, delta)

	_print_timer -= delta
	if _print_timer <= 0.0:
		_print_timer = 1.0
		print(">>> URGES [%s] — home: %.2f | patrol: %.2f | curiosity: %.2f" % [
			state, home_urge, patrol_urge, curiosity_urge
		])

# -----------------------------------------------------------------------------
# on_danger_entered — immediate spike — threat is at the doorstep
# -----------------------------------------------------------------------------
func on_danger_entered() -> void:
	print(">>> URGE: danger zone entered")

# -----------------------------------------------------------------------------
# on_alert_tick — slow pressure per frame in alert zone
# -----------------------------------------------------------------------------
func on_alert_tick(delta: float) -> void:
	home_urge = min(1.0, home_urge + ALERT_ZONE_BOOST * delta)

# -----------------------------------------------------------------------------
# on_ue_lost — curiosity spikes when Joe loses sight of the UE
# -----------------------------------------------------------------------------
func on_ue_lost() -> void:
	curiosity_urge = min(1.0, curiosity_urge + CURIOSITY_SPIKE)
	print(">>> URGE: ue lost — curiosity spiked")

# -----------------------------------------------------------------------------
# committed_to_patrol — guard just left home
# -----------------------------------------------------------------------------
func committed_to_patrol() -> void:
	home_urge   = HOME_URGE_REST
	patrol_urge = 0.6
	print(">>> URGE: committed to patrol — home reset, patrol boosted")

# -----------------------------------------------------------------------------
# committed_to_search — curiosity committed, reset other urges slightly
# -----------------------------------------------------------------------------
func committed_to_search() -> void:
	curiosity_urge = 0.8
	print(">>> URGE: committed to search")

# -----------------------------------------------------------------------------
# _decay_toward — smoothly move a value toward a resting value
# -----------------------------------------------------------------------------
func _decay_toward(current: float, target: float, rate: float, delta: float) -> float:
	if current > target:
		return max(target, current - rate * delta)
	return current

func get_home_urge()      -> float: return home_urge
func get_patrol_urge()    -> float: return patrol_urge
func get_curiosity_urge() -> float: return curiosity_urge
