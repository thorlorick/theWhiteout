class_name SearchComponent
extends Node
# -----------------------------------------------------------------------------
# SearchComponent
# Anchored to last known position. Follows breadcrumbs.
# Fires signals only. Knows nothing about who is listening.
# -----------------------------------------------------------------------------
signal search_move_to(position: Vector2)
signal search_finished()

const DWELL_MIN: float = 1.0
const DWELL_MAX: float = 3.0
const EXTRA_STEPS: int = 2
const STEP_DISTANCE: float = 80.0

var _points:        Array = []
var _current_index: int   = 0
var _dwelling:      bool  = false
var _timer:         float = 0.0
var _active:        bool  = false

@export var nav_region: NavigationRegion2D

# -----------------------------------------------------------------------------
# start_search — called by EnemyAgent with last known position and direction
# -----------------------------------------------------------------------------
func start_search(center: Vector2, last_direction: Vector2) -> void:
	_points        = _build_points(center, last_direction)
	_current_index = 0
	_dwelling      = false
	_active        = true
	_move_to_next()

# -----------------------------------------------------------------------------
# stop — cancel search in progress
# -----------------------------------------------------------------------------
func stop() -> void:
	_active   = false
	_dwelling = false
	_timer    = 0.0

# -----------------------------------------------------------------------------
# arrived — called by EnemyAgent when destination reached during search
# -----------------------------------------------------------------------------
func arrived() -> void:
	_dwelling = true
	_timer    = randf_range(DWELL_MIN, DWELL_MAX)
	print(">>> SEARCH: checking point for %.1f seconds" % _timer)

# -----------------------------------------------------------------------------
# _process — counts down dwell, then moves to next point
# -----------------------------------------------------------------------------
func _process(delta: float) -> void:
	if not _active or not _dwelling:
		return
	_timer -= delta
	if _timer <= 0.0:
		_dwelling = false
		_move_to_next()

# -----------------------------------------------------------------------------
# _move_to_next — advance to next breadcrumb or finish
# -----------------------------------------------------------------------------
func _move_to_next() -> void:
	if _current_index >= _points.size():
		_active = false
		print(">>> SEARCH: finished — no target found")
		search_finished.emit()
		return
	search_move_to.emit(_points[_current_index])
	_current_index += 1

# -----------------------------------------------------------------------------
# _build_points — last known position plus steps along last direction
# -----------------------------------------------------------------------------
func _build_points(center: Vector2, last_direction: Vector2) -> Array:
	var points = [center]
	var dir    = last_direction.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	for i in range(1, EXTRA_STEPS + 1):
		points.append(center + dir * STEP_DISTANCE * i)
	return points
