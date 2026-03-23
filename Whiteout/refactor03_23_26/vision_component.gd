class_name VisionComponent
extends Node2D

# -----------------------------------------------------------------------------
# VisionComponent
# Eyes that scan the room. Sweep rotates around facing direction.
# When idle, plays a look-around sequence before settling.
# Facing is a Vector2 — no hardwired strings.
# Detection meter fills on evidence, drains on nothing — no flicker.
# Emits signals for alert, confirmed sighting, danger, gap closed, and lost.
# All zone logic is distance-based — no Area2D or collision shapes.
# -----------------------------------------------------------------------------
  
signal spotted_target(body)
signal lost_target()

signal alert_range(body)      # meter filling past threshold, target visible at distance
signal danger_range(body)     # confirmed sighting within danger distance
signal range_lost(body)       # target gone — clear all zone states in agent
signal gap_closed_signal()    # strike distance reached — trigger attack

const RAY_COUNT:        int   = 5
const RAY_LENGTH:       float = 200.0
const LOST_TIMER_MAX:   float = 0.5
const MIN_DISTANCE:     float = 20.0

const ALERT_DISTANCE:   float = 150.0   # ~9 tiles — meter filling
const DANGER_DISTANCE:  float = 100.0   # ~6 tiles — confirmed, trigger chase
const STRIKE_DISTANCE:  float = 40.0    # ~2 tiles — gap closed, attack

const ALERT_THRESHOLD:  float = 0.3     # minimum detection before alert fires

# sweep
const SWEEP_ANGLE:      float = 25.0
const SWEEP_SPEED:      float = 60.0

# look-around sequence when idle
const LOOK_ANGLES:      Array = [-40.0, 0.0, 40.0, 0.0]
const LOOK_STEP_TIME:   float = 0.8

# detection meter rates
const FILL_RATE_CENTER: float = 2.5
const FILL_RATE_EDGE:   float = 1.0
const DRAIN_RATE:       float = 1.5

var facing:          Vector2 = Vector2.DOWN
var space_state:     PhysicsDirectSpaceState2D

var _was_seeing_target:  bool   = false
var _lost_timer:     float  = 0.0
var _last_seen_body: Node2D = null

var _sweep_angle:    float  = 0.0
var _sweep_dir:      float  = 1.0

var _is_moving:      bool   = false
var _look_step:      int    = 0
var _look_timer:     float  = 0.0
var _looking_around: bool   = false

# gaze homing
var _gaze_target_angle: float = 0.0
var _homing:            bool  = false

# detection meter
var _detection_value:     float = 0.0
var _detection_confirmed: bool  = false

# gap tracking
var _gap_closed:          bool  = false

# zone state tracking — prevent signal spam
var _in_alert_range:      bool  = false
var _in_danger_range:     bool  = false

@export var body: CharacterBody2D

func _ready() -> void:
	space_state = get_world_2d().direct_space_state

func _physics_process(delta: float) -> void:
	_update_sweep(delta)
	_cast_rays(delta)

# -----------------------------------------------------------------------------
# update_direction — called by GuardAgent when velocity_changed fires
# accepts is_running for future use (animation, cone width, etc.)
# -----------------------------------------------------------------------------
func update_direction(direction: Vector2, is_moving: bool, is_running: bool) -> void:
	var was_moving = _is_moving
	_is_moving = is_moving

	if is_moving and direction != Vector2.ZERO:
		facing          = direction
		_looking_around = false
		_look_step      = 0
		_look_timer     = 0.0

	if was_moving and not is_moving:
		_looking_around = true
		_look_step      = 0
		_look_timer     = 0.0

# -----------------------------------------------------------------------------
# _update_sweep
# -----------------------------------------------------------------------------
func _update_sweep(delta: float) -> void:
	if _looking_around:
		_look_timer += delta
		if _look_timer >= LOOK_STEP_TIME:
			_look_timer = 0.0
			_look_step  += 1
			if _look_step >= LOOK_ANGLES.size():
				_look_step      = LOOK_ANGLES.size() - 1
				_looking_around = false
		_sweep_angle = LOOK_ANGLES[_look_step]
		return

	if _homing:
		var diff     = _gaze_target_angle - _sweep_angle
		_sweep_angle += diff * delta * 5.0
		if abs(diff) < 1.0:
			_sweep_angle = _gaze_target_angle
		return

	_sweep_angle += SWEEP_SPEED * _sweep_dir * delta
	if _sweep_angle > SWEEP_ANGLE:
		_sweep_angle = SWEEP_ANGLE
		_sweep_dir   = -1.0
	elif _sweep_angle < -SWEEP_ANGLE:
		_sweep_angle = -SWEEP_ANGLE
		_sweep_dir   = 1.0

# -----------------------------------------------------------------------------
# _cast_rays — feeds detection meter, drives zone-equivalent signals
# -----------------------------------------------------------------------------
func _cast_rays(delta: float) -> void:
	var hits:        int   = 0
	var hit_angle:   float = 0.0
	var half_spread: float = 10.0

	if _last_seen_body != null:
		var dist = body.global_position.distance_to(_last_seen_body.global_position)
		if dist < MIN_DISTANCE:
			hits = RAY_COUNT

	if hits == 0:
		var gaze = facing.rotated(deg_to_rad(_sweep_angle))
		for i in range(RAY_COUNT):
			var t       = float(i) / float(RAY_COUNT - 1) if RAY_COUNT > 1 else 0.0
			var angle   = lerp(-half_spread, half_spread, t)
			var ray_dir = gaze.rotated(deg_to_rad(angle))
			var target  = body.global_position + ray_dir * RAY_LENGTH
			var query   = PhysicsRayQueryParameters2D.create(body.global_position, target)
			query.exclude        = [body]
			query.collision_mask = 1
			var result  = space_state.intersect_ray(query)
        if result and result.collider.is_in_group("player"):
				hits      += 1
				hit_angle  = lerp(-half_spread, half_spread, t)
				_last_seen_body = result.collider

	if hits > 0:
		_homing            = true
		_gaze_target_angle = _sweep_angle + hit_angle

		var fill_rate = lerp(FILL_RATE_EDGE, FILL_RATE_CENTER, float(hits) / float(RAY_COUNT))
		_detection_value = min(1.0, _detection_value + fill_rate * delta)

		var dist = body.global_position.distance_to(_last_seen_body.global_position)

		# --- alert range — meter past threshold, target visible at distance
		if _detection_value >= ALERT_THRESHOLD and dist <= ALERT_DISTANCE and not _in_alert_range:
			_in_alert_range = true
			print(">>> VISION: alert range entered")
			alert_range.emit(_last_seen_body)

		# --- confirmed sighting
		if _detection_value >= 1.0 and not _detection_confirmed:
			_detection_confirmed = true
			_was_seeing_target       = true
			_lost_timer          = LOST_TIMER_MAX
			spotted_target.emit(_last_seen_body)

		if _was_seeing_target:
			_lost_timer = LOST_TIMER_MAX

		# --- danger range — confirmed and close enough to trigger chase
		if _detection_confirmed and dist <= DANGER_DISTANCE and not _in_danger_range:
			_in_danger_range = true
			print(">>> VISION: danger range entered")
			danger_range.emit(_last_seen_body)

		# --- gap closed — strike distance reached
		if _was_seeing_target and dist <= STRIKE_DISTANCE and not _gap_closed:
			_gap_closed = true
			print(">>> VISION: gap closed — strike distance reached")
			gap_closed_signal.emit()

	else:
		_detection_value = max(0.0, _detection_value - DRAIN_RATE * delta)

		if _detection_value <= 0.0 and not _was_seeing_target:
			_homing = false

		if _was_seeing_target:
			_lost_timer -= delta
			if _lost_timer <= 0.0:
				_was_seeing_target       = false
				_detection_confirmed = false
				_detection_value     = 0.0
				_lost_timer          = 0.0
				_gap_closed          = false

				# fire range_lost once to clear all zone states in agent
				if _in_alert_range or _in_danger_range:
					_in_alert_range  = false
					_in_danger_range = false
					print(">>> VISION: range lost")
					range_lost.emit(_last_seen_body)

				_last_seen_body = null
				_homing         = false
				lost_target.emit()

func clear_target() -> void:
	_was_seeing_target       = false
	_detection_confirmed = false
	_detection_value     = 0.0
	_lost_timer          = 0.0
	_last_seen_body      = null
	_homing              = false
	_gap_closed          = false
	_in_alert_range      = false
	_in_danger_range     = false
