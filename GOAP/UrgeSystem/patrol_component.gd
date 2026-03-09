class_name PatrolComponent
extends Node

# -----------------------------------------------------------------------------
# PatrolComponent
# Home anchored wandering with random dwell time at each point.
# Guard arrives, checks the area for a random duration, moves on.
# Knows where home is — it's part of the geography it operates in.
# Drives movement via signal — knows nothing about MoveComponent.
# -----------------------------------------------------------------------------

signal new_patrol_target(position: Vector2)

const DELAY_MIN: float = 1.0   # shortest check — quick glance
const DELAY_MAX: float = 5.0   # longest check — thorough sweep

@export var nav_region:    NavigationRegion2D
@export var home_position: Vector2

var _timer:    float = 0.0
var _dwelling: bool  = false   # true = guard is checking the area

# -----------------------------------------------------------------------------
# _process — counts down dwell time, then picks next point
# -----------------------------------------------------------------------------
func _process(delta: float) -> void:
	if not _dwelling:
		return
	_timer -= delta
	if _timer <= 0.0:
		_dwelling = false
		new_patrol_target.emit(_get_random_point())

# -----------------------------------------------------------------------------
# arrived — called by EnemyAgent when destination_reached fires during patrol
# starts the dwell timer — guard is checking the area
# -----------------------------------------------------------------------------
func arrived() -> void:
	_dwelling = true
	_timer    = randf_range(DELAY_MIN, DELAY_MAX)
	print(">>> PATROL: checking area for %.1f seconds" % _timer)

# -----------------------------------------------------------------------------
# start — kicks off the first move
# -----------------------------------------------------------------------------
func start() -> void:
	_dwelling = false
	new_patrol_target.emit(_get_random_point())

# -----------------------------------------------------------------------------
# stop — guard is done patrolling, cancel any dwell in progress
# -----------------------------------------------------------------------------
func stop() -> void:
	_dwelling = false
	_timer    = 0.0

# -----------------------------------------------------------------------------
# _get_random_point — random point on nav mesh
# the region itself defines the boundaries
# -----------------------------------------------------------------------------
func _get_random_point() -> Vector2:
	return NavigationServer2D.map_get_random_point(
		nav_region.get_navigation_map(),
		1,
		false
	)
